import { auth } from '@/lib/firebase';
import { User } from 'firebase/auth';

export interface SecureApiOptions {
  baseURL?: string;
  timeout?: number;
  retries?: number;
}

export class SecureApiClient {
  private baseURL: string;
  private timeout: number;
  private retries: number;

  constructor(options: SecureApiOptions = {}) {
    this.baseURL = options.baseURL || '/api';
    this.timeout = options.timeout || 30000;
    this.retries = options.retries || 3;
  }

  private async getAuthToken(): Promise<string | null> {
    const user = auth.currentUser;
    if (!user) {
      return null;
    }

    try {
      const token = await user.getIdToken(true);
      return token;
    } catch (error) {
      console.error('Failed to get auth token:', error);
      return null;
    }
  }

  private async makeRequest(
    url: string,
    options: RequestInit,
    attempt: number = 0
  ): Promise<Response> {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), this.timeout);

    try {
      const response = await fetch(url, {
        ...options,
        signal: controller.signal,
      });

      clearTimeout(timeoutId);

      if (response.status === 401 && attempt < this.retries) {
        const token = await this.getAuthToken();
        if (token) {
          const retryOptions = {
            ...options,
            headers: {
              ...options.headers,
              Authorization: `Bearer ${token}`,
            },
          };
          return this.makeRequest(url, retryOptions, attempt + 1);
        }
      }

      if (response.status === 429 && attempt < this.retries) {
        const retryAfter = response.headers.get('Retry-After');
        const delay = retryAfter ? parseInt(retryAfter) * 1000 : Math.pow(2, attempt) * 1000;
        
        await new Promise(resolve => setTimeout(resolve, delay));
        return this.makeRequest(url, options, attempt + 1);
      }

      return response;
    } catch (error) {
      clearTimeout(timeoutId);
      
      if (error instanceof DOMException && error.name === 'AbortError') {
        throw new Error(`Request timeout after ${this.timeout}ms`);
      }
      
      if (attempt < this.retries && error instanceof TypeError) {
        const delay = Math.pow(2, attempt) * 1000;
        await new Promise(resolve => setTimeout(resolve, delay));
        return this.makeRequest(url, options, attempt + 1);
      }
      
      throw error;
    }
  }

  private async request<T>(
    endpoint: string,
    options: RequestInit = {}
  ): Promise<T> {
    const token = await this.getAuthToken();
    
    const url = `${this.baseURL}${endpoint}`;
    const requestOptions: RequestInit = {
      ...options,
      headers: {
        'Content-Type': 'application/json',
        ...options.headers,
        ...(token && { Authorization: `Bearer ${token}` }),
      },
    };

    const response = await this.makeRequest(url, requestOptions);

    if (!response.ok) {
      const errorBody = await response.text();
      let errorMessage = `HTTP ${response.status}: ${response.statusText}`;
      
      try {
        const errorJson = JSON.parse(errorBody);
        errorMessage = errorJson.message || errorJson.error || errorMessage;
      } catch {
      }
      
      throw new Error(errorMessage);
    }

    const responseText = await response.text();
    
    if (!responseText) {
      return {} as T;
    }

    try {
      return JSON.parse(responseText);
    } catch {
      return responseText as T;
    }
  }

  async get<T>(endpoint: string, query?: Record<string, string>): Promise<T> {
    let url = endpoint;
    if (query) {
      const params = new URLSearchParams(query);
      url += `?${params.toString()}`;
    }
    
    return this.request<T>(url, { method: 'GET' });
  }

  async post<T>(endpoint: string, data?: any): Promise<T> {
    return this.request<T>(endpoint, {
      method: 'POST',
      body: data ? JSON.stringify(data) : undefined,
    });
  }

  async put<T>(endpoint: string, data?: any): Promise<T> {
    return this.request<T>(endpoint, {
      method: 'PUT',
      body: data ? JSON.stringify(data) : undefined,
    });
  }

  async delete<T>(endpoint: string): Promise<T> {
    return this.request<T>(endpoint, { method: 'DELETE' });
  }

  async patch<T>(endpoint: string, data?: any): Promise<T> {
    return this.request<T>(endpoint, {
      method: 'PATCH',
      body: data ? JSON.stringify(data) : undefined,
    });
  }
}

export const secureApiClient = new SecureApiClient();

export function useSecureApi() {
  return secureApiClient;
}