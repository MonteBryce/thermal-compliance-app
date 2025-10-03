interface CacheOptions {
  ttl?: number;
  key?: string;
  storage?: 'memory' | 'sessionStorage' | 'localStorage';
}

interface CacheEntry<T> {
  data: T;
  timestamp: number;
  ttl: number;
}

class CacheManager {
  private memoryCache: Map<string, CacheEntry<any>> = new Map();
  private readonly DEFAULT_TTL = 5 * 60 * 1000;

  private isExpired(entry: CacheEntry<any>): boolean {
    return Date.now() - entry.timestamp > entry.ttl;
  }

  private getStorageKey(key: string): string {
    return `cache:${key}`;
  }

  set<T>(key: string, data: T, options: CacheOptions = {}): void {
    const { ttl = this.DEFAULT_TTL, storage = 'memory' } = options;
    
    const entry: CacheEntry<T> = {
      data,
      timestamp: Date.now(),
      ttl,
    };

    if (storage === 'memory') {
      this.memoryCache.set(key, entry);
    } else if (storage === 'sessionStorage' && typeof window !== 'undefined') {
      sessionStorage.setItem(this.getStorageKey(key), JSON.stringify(entry));
    } else if (storage === 'localStorage' && typeof window !== 'undefined') {
      localStorage.setItem(this.getStorageKey(key), JSON.stringify(entry));
    }
  }

  get<T>(key: string, storage: 'memory' | 'sessionStorage' | 'localStorage' = 'memory'): T | null {
    let entry: CacheEntry<T> | null = null;

    if (storage === 'memory') {
      entry = this.memoryCache.get(key) || null;
    } else if (storage === 'sessionStorage' && typeof window !== 'undefined') {
      const stored = sessionStorage.getItem(this.getStorageKey(key));
      if (stored) {
        try {
          entry = JSON.parse(stored);
        } catch {
          return null;
        }
      }
    } else if (storage === 'localStorage' && typeof window !== 'undefined') {
      const stored = localStorage.getItem(this.getStorageKey(key));
      if (stored) {
        try {
          entry = JSON.parse(stored);
        } catch {
          return null;
        }
      }
    }

    if (!entry || this.isExpired(entry)) {
      this.delete(key, storage);
      return null;
    }

    return entry.data;
  }

  delete(key: string, storage: 'memory' | 'sessionStorage' | 'localStorage' = 'memory'): void {
    if (storage === 'memory') {
      this.memoryCache.delete(key);
    } else if (storage === 'sessionStorage' && typeof window !== 'undefined') {
      sessionStorage.removeItem(this.getStorageKey(key));
    } else if (storage === 'localStorage' && typeof window !== 'undefined') {
      localStorage.removeItem(this.getStorageKey(key));
    }
  }

  clear(storage?: 'memory' | 'sessionStorage' | 'localStorage'): void {
    if (!storage || storage === 'memory') {
      this.memoryCache.clear();
    }
    
    if (typeof window !== 'undefined') {
      if (!storage || storage === 'sessionStorage') {
        const keys = Object.keys(sessionStorage);
        keys.forEach(key => {
          if (key.startsWith('cache:')) {
            sessionStorage.removeItem(key);
          }
        });
      }
      
      if (!storage || storage === 'localStorage') {
        const keys = Object.keys(localStorage);
        keys.forEach(key => {
          if (key.startsWith('cache:')) {
            localStorage.removeItem(key);
          }
        });
      }
    }
  }

  cleanExpired(): void {
    this.memoryCache.forEach((entry, key) => {
      if (this.isExpired(entry)) {
        this.memoryCache.delete(key);
      }
    });

    if (typeof window !== 'undefined') {
      ['sessionStorage', 'localStorage'].forEach(storageType => {
        const storage = storageType === 'sessionStorage' ? sessionStorage : localStorage;
        const keys = Object.keys(storage);
        
        keys.forEach(key => {
          if (key.startsWith('cache:')) {
            try {
              const entry = JSON.parse(storage.getItem(key) || '');
              if (this.isExpired(entry)) {
                storage.removeItem(key);
              }
            } catch {
              storage.removeItem(key);
            }
          }
        });
      });
    }
  }
}

export const cacheManager = new CacheManager();

export function withCache<T extends (...args: any[]) => Promise<any>>(
  fn: T,
  options: CacheOptions = {}
): T {
  return (async (...args: Parameters<T>) => {
    const cacheKey = options.key || `${fn.name}:${JSON.stringify(args)}`;
    const cached = cacheManager.get(cacheKey, options.storage);
    
    if (cached !== null) {
      return cached;
    }
    
    const result = await fn(...args);
    cacheManager.set(cacheKey, result, options);
    
    return result;
  }) as T;
}