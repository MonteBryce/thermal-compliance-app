import { NextRequest, NextResponse } from 'next/server';
import { verifyAuth, requireAuth, requireAdmin } from '@/lib/middleware/auth-middleware';
import { rateLimitMiddleware } from '@/lib/middleware/rate-limit';
import { z } from 'zod';

export interface ApiHandlerOptions {
  requireAuth?: boolean;
  requireAdmin?: boolean;
  requireRoles?: string[];
  rateLimit?: boolean;
  validateBody?: z.ZodSchema;
  validateQuery?: z.ZodSchema;
}

export interface ApiContext {
  user?: any;
  body?: any;
  query?: any;
  params?: any;
}

type ApiHandler = (
  request: NextRequest,
  context: ApiContext
) => Promise<NextResponse> | NextResponse;

export function createSecureApiHandler(
  handler: ApiHandler,
  options: ApiHandlerOptions = {}
) {
  return async function secureHandler(
    request: NextRequest,
    { params }: { params?: any } = {}
  ) {
    try {
      const context: ApiContext = { params };
      
      if (options.rateLimit) {
        const rateLimitResult = await rateLimitMiddleware()(request);
        if (rateLimitResult) {
          return rateLimitResult;
        }
      }
      
      if (options.requireAuth || options.requireAdmin) {
        const authFunc = options.requireAdmin ? requireAdmin : requireAuth;
        const authResult = await authFunc(request);
        
        if (authResult instanceof NextResponse) {
          return authResult;
        }
        
        context.user = authResult;
      }
      
      if (options.validateQuery) {
        const url = new URL(request.url);
        const query = Object.fromEntries(url.searchParams.entries());
        
        try {
          context.query = options.validateQuery.parse(query);
        } catch (error) {
          if (error instanceof z.ZodError) {
            return NextResponse.json(
              {
                error: 'Bad Request',
                message: 'Invalid query parameters',
                details: error.errors,
              },
              { status: 400 }
            );
          }
        }
      }
      
      if (options.validateBody && request.method !== 'GET') {
        try {
          const body = await request.json();
          context.body = options.validateBody.parse(body);
        } catch (error) {
          if (error instanceof z.ZodError) {
            return NextResponse.json(
              {
                error: 'Bad Request',
                message: 'Invalid request body',
                details: error.errors,
              },
              { status: 400 }
            );
          }
          return NextResponse.json(
            {
              error: 'Bad Request',
              message: 'Invalid JSON in request body',
            },
            { status: 400 }
          );
        }
      }
      
      const response = await handler(request, context);
      
      response.headers.set('X-Content-Type-Options', 'nosniff');
      response.headers.set('X-Frame-Options', 'DENY');
      response.headers.set('X-XSS-Protection', '1; mode=block');
      response.headers.set('Referrer-Policy', 'strict-origin-when-cross-origin');
      
      return response;
    } catch (error) {
      console.error('API Error:', error);
      
      return NextResponse.json(
        {
          error: 'Internal Server Error',
          message: process.env.NODE_ENV === 'development' 
            ? (error as Error).message 
            : 'An unexpected error occurred',
        },
        { status: 500 }
      );
    }
  };
}

export function sanitizeInput(input: any): any {
  if (typeof input === 'string') {
    return input
      .replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '')
      .replace(/<iframe\b[^<]*(?:(?!<\/iframe>)<[^<]*)*<\/iframe>/gi, '')
      .replace(/javascript:/gi, '')
      .replace(/on\w+\s*=/gi, '')
      .trim();
  }
  
  if (Array.isArray(input)) {
    return input.map(sanitizeInput);
  }
  
  if (input && typeof input === 'object') {
    const sanitized: any = {};
    for (const key in input) {
      if (input.hasOwnProperty(key)) {
        sanitized[key] = sanitizeInput(input[key]);
      }
    }
    return sanitized;
  }
  
  return input;
}

export function validateApiKey(request: NextRequest): boolean {
  const apiKey = request.headers.get('x-api-key');
  const validApiKey = process.env.API_SECRET_KEY;
  
  if (!validApiKey || !apiKey) {
    return false;
  }
  
  return apiKey === validApiKey;
}