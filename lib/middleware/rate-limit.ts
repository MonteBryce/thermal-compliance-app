import { NextRequest, NextResponse } from 'next/server';
import { LRUCache } from 'lru-cache';

interface RateLimitOptions {
  interval?: number;
  uniqueTokenPerInterval?: number;
  maxRequests?: number;
}

interface RateLimitEntry {
  count: number;
  resetTime: number;
}

function getIP(request: NextRequest): string {
  const xff = request.headers.get('x-forwarded-for');
  return xff ? xff.split(',')[0] : request.ip || 'unknown';
}

export class RateLimiter {
  private cache: LRUCache<string, RateLimitEntry>;
  private interval: number;
  private maxRequests: number;

  constructor(options: RateLimitOptions = {}) {
    this.interval = options.interval || 60 * 1000;
    this.maxRequests = options.maxRequests || 10;
    
    this.cache = new LRUCache<string, RateLimitEntry>({
      max: options.uniqueTokenPerInterval || 500,
      ttl: this.interval,
    });
  }

  check(identifier: string): { success: boolean; limit: number; remaining: number; reset: number } {
    const now = Date.now();
    const entry = this.cache.get(identifier);
    
    if (!entry || now > entry.resetTime) {
      const newEntry: RateLimitEntry = {
        count: 1,
        resetTime: now + this.interval,
      };
      this.cache.set(identifier, newEntry);
      
      return {
        success: true,
        limit: this.maxRequests,
        remaining: this.maxRequests - 1,
        reset: newEntry.resetTime,
      };
    }
    
    if (entry.count >= this.maxRequests) {
      return {
        success: false,
        limit: this.maxRequests,
        remaining: 0,
        reset: entry.resetTime,
      };
    }
    
    entry.count++;
    this.cache.set(identifier, entry);
    
    return {
      success: true,
      limit: this.maxRequests,
      remaining: this.maxRequests - entry.count,
      reset: entry.resetTime,
    };
  }
}

const defaultLimiter = new RateLimiter({
  interval: 60 * 1000,
  uniqueTokenPerInterval: 500,
  maxRequests: 60,
});

const strictLimiter = new RateLimiter({
  interval: 60 * 1000,
  uniqueTokenPerInterval: 500,
  maxRequests: 10,
});

export function rateLimitMiddleware(options?: {
  limiter?: RateLimiter;
  keyGenerator?: (req: NextRequest) => string;
  skipSuccessfulRequests?: boolean;
  skipFailedRequests?: boolean;
}) {
  const limiter = options?.limiter || defaultLimiter;
  const keyGenerator = options?.keyGenerator || ((req) => getIP(req));
  
  return async function middleware(request: NextRequest) {
    const identifier = keyGenerator(request);
    const result = limiter.check(identifier);
    
    if (!result.success) {
      return NextResponse.json(
        {
          error: 'Too Many Requests',
          message: `Rate limit exceeded. Try again in ${Math.ceil((result.reset - Date.now()) / 1000)} seconds.`,
        },
        {
          status: 429,
          headers: {
            'X-RateLimit-Limit': result.limit.toString(),
            'X-RateLimit-Remaining': result.remaining.toString(),
            'X-RateLimit-Reset': new Date(result.reset).toISOString(),
            'Retry-After': Math.ceil((result.reset - Date.now()) / 1000).toString(),
          },
        }
      );
    }
    
    return null;
  };
}

export { defaultLimiter, strictLimiter };