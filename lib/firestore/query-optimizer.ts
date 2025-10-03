import { 
  Query, 
  DocumentSnapshot, 
  QuerySnapshot, 
  QueryConstraint,
  where,
  orderBy,
  limit,
  startAfter,
  endBefore,
  limitToLast,
  getDocs,
  query,
  collection,
  doc,
  getDoc,
  enableNetwork,
  disableNetwork,
} from 'firebase/firestore';
import { db } from '@/lib/firebase';

interface PaginationOptions {
  pageSize?: number;
  cursor?: DocumentSnapshot;
  direction?: 'next' | 'prev';
}

interface QueryOptions {
  useCache?: boolean;
  offline?: boolean;
  pagination?: PaginationOptions;
  timeoutMs?: number;
}

export class FirestoreQueryOptimizer {
  private queryCache = new Map<string, { data: any; timestamp: number; ttl: number }>();
  private readonly DEFAULT_CACHE_TTL = 5 * 60 * 1000;
  private readonly MAX_BATCH_SIZE = 500;

  private getCacheKey(collectionPath: string, constraints: QueryConstraint[]): string {
    const constraintStr = constraints.map(c => c.toString()).join('|');
    return `${collectionPath}:${constraintStr}`;
  }

  private isCacheValid(entry: { timestamp: number; ttl: number }): boolean {
    return Date.now() - entry.timestamp < entry.ttl;
  }

  async optimizedQuery<T>(
    collectionPath: string,
    constraints: QueryConstraint[] = [],
    options: QueryOptions = {}
  ): Promise<T[]> {
    const { useCache = true, pagination, timeoutMs = 10000 } = options;
    
    const cacheKey = this.getCacheKey(collectionPath, constraints);
    
    if (useCache && this.queryCache.has(cacheKey)) {
      const cached = this.queryCache.get(cacheKey)!;
      if (this.isCacheValid(cached)) {
        return cached.data;
      } else {
        this.queryCache.delete(cacheKey);
      }
    }

    try {
      let queryRef = query(collection(db, collectionPath), ...constraints);
      
      if (pagination) {
        const { pageSize = 20, cursor, direction = 'next' } = pagination;
        
        if (direction === 'next' && cursor) {
          queryRef = query(queryRef, startAfter(cursor), limit(pageSize));
        } else if (direction === 'prev' && cursor) {
          queryRef = query(queryRef, endBefore(cursor), limitToLast(pageSize));
        } else {
          queryRef = query(queryRef, limit(pageSize));
        }
      }

      const snapshot = await Promise.race([
        getDocs(queryRef),
        new Promise<never>((_, reject) => 
          setTimeout(() => reject(new Error('Query timeout')), timeoutMs)
        )
      ]);

      const data = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
      })) as T[];

      if (useCache && !pagination) {
        this.queryCache.set(cacheKey, {
          data,
          timestamp: Date.now(),
          ttl: this.DEFAULT_CACHE_TTL,
        });
      }

      return data;
    } catch (error) {
      console.error(`Query failed for ${collectionPath}:`, error);
      throw error;
    }
  }

  async batchGet<T>(
    collectionPath: string,
    docIds: string[],
    options: { useCache?: boolean; timeoutMs?: number } = {}
  ): Promise<(T | null)[]> {
    const { useCache = true, timeoutMs = 10000 } = options;
    
    if (docIds.length === 0) return [];
    
    if (docIds.length > this.MAX_BATCH_SIZE) {
      const batches = [];
      for (let i = 0; i < docIds.length; i += this.MAX_BATCH_SIZE) {
        const batch = docIds.slice(i, i + this.MAX_BATCH_SIZE);
        batches.push(this.batchGet<T>(collectionPath, batch, options));
      }
      const results = await Promise.all(batches);
      return results.flat();
    }

    const results: (T | null)[] = [];
    const uncachedIds: string[] = [];
    const cachedIndices: number[] = [];

    if (useCache) {
      docIds.forEach((id, index) => {
        const cacheKey = `${collectionPath}:${id}`;
        if (this.queryCache.has(cacheKey)) {
          const cached = this.queryCache.get(cacheKey)!;
          if (this.isCacheValid(cached)) {
            results[index] = cached.data;
            cachedIndices.push(index);
          } else {
            this.queryCache.delete(cacheKey);
            uncachedIds.push(id);
          }
        } else {
          uncachedIds.push(id);
        }
      });
    } else {
      uncachedIds.push(...docIds);
    }

    if (uncachedIds.length > 0) {
      const promises = uncachedIds.map(async (id) => {
        try {
          const docRef = doc(db, collectionPath, id);
          const snapshot = await Promise.race([
            getDoc(docRef),
            new Promise<never>((_, reject) => 
              setTimeout(() => reject(new Error('Doc get timeout')), timeoutMs)
            )
          ]);

          if (snapshot.exists()) {
            const data = { id: snapshot.id, ...snapshot.data() } as T;
            
            if (useCache) {
              const cacheKey = `${collectionPath}:${id}`;
              this.queryCache.set(cacheKey, {
                data,
                timestamp: Date.now(),
                ttl: this.DEFAULT_CACHE_TTL,
              });
            }
            
            return data;
          }
          return null;
        } catch (error) {
          console.error(`Failed to get doc ${id} from ${collectionPath}:`, error);
          return null;
        }
      });

      const fetchedDocs = await Promise.all(promises);
      
      let fetchIndex = 0;
      docIds.forEach((_, index) => {
        if (!cachedIndices.includes(index)) {
          results[index] = fetchedDocs[fetchIndex++];
        }
      });
    }

    return results;
  }

  createOptimizedWhere(field: string, operator: any, value: any): QueryConstraint {
    if (Array.isArray(value) && value.length <= 10) {
      return where(field, 'in', value);
    }
    return where(field, operator, value);
  }

  createOptimizedOrderBy(
    field: string, 
    direction: 'asc' | 'desc' = 'asc',
    useIndex: boolean = true
  ): QueryConstraint[] {
    const constraints: QueryConstraint[] = [orderBy(field, direction)];
    
    if (useIndex && field !== '__name__') {
      constraints.unshift(where(field, '!=', null));
    }
    
    return constraints;
  }

  clearCache(pattern?: string): void {
    if (pattern) {
      const regex = new RegExp(pattern);
      for (const [key] of this.queryCache) {
        if (regex.test(key)) {
          this.queryCache.delete(key);
        }
      }
    } else {
      this.queryCache.clear();
    }
  }

  invalidateCache(collectionPath: string): void {
    this.clearCache(`^${collectionPath}:`);
  }

  async enableOfflineMode(): Promise<void> {
    try {
      await disableNetwork(db);
      console.log('Firestore offline mode enabled');
    } catch (error) {
      console.error('Failed to enable offline mode:', error);
    }
  }

  async enableOnlineMode(): Promise<void> {
    try {
      await enableNetwork(db);
      console.log('Firestore online mode enabled');
    } catch (error) {
      console.error('Failed to enable online mode:', error);
    }
  }

  getQueryStats(): {
    cacheSize: number;
    cacheHitRate: number;
    totalQueries: number;
  } {
    const cacheSize = this.queryCache.size;
    
    return {
      cacheSize,
      cacheHitRate: 0,
      totalQueries: 0,
    };
  }
}

export const queryOptimizer = new FirestoreQueryOptimizer();