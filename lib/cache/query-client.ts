import { QueryClient } from '@tanstack/react-query';

export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 5 * 60 * 1000,
      gcTime: 10 * 60 * 1000,
      retry: 2,
      refetchOnWindowFocus: false,
      refetchOnMount: true,
    },
    mutations: {
      retry: 1,
    },
  },
});

export const cacheKeys = {
  templates: {
    all: ['templates'] as const,
    lists: () => [...cacheKeys.templates.all, 'list'] as const,
    list: (filters?: string) => [...cacheKeys.templates.lists(), { filters }] as const,
    details: () => [...cacheKeys.templates.all, 'detail'] as const,
    detail: (id: string) => [...cacheKeys.templates.details(), id] as const,
  },
  projects: {
    all: ['projects'] as const,
    lists: () => [...cacheKeys.projects.all, 'list'] as const,
    list: (filters?: string) => [...cacheKeys.projects.lists(), { filters }] as const,
    details: () => [...cacheKeys.projects.all, 'detail'] as const,
    detail: (id: string) => [...cacheKeys.projects.details(), id] as const,
  },
  logs: {
    all: ['logs'] as const,
    byProject: (projectId: string) => [...cacheKeys.logs.all, 'project', projectId] as const,
    byTemplate: (templateId: string) => [...cacheKeys.logs.all, 'template', templateId] as const,
    detail: (id: string) => [...cacheKeys.logs.all, 'detail', id] as const,
  },
  users: {
    all: ['users'] as const,
    current: () => [...cacheKeys.users.all, 'current'] as const,
    profile: (userId: string) => [...cacheKeys.users.all, 'profile', userId] as const,
  },
  compliance: {
    all: ['compliance'] as const,
    activeJobs: () => [...cacheKeys.compliance.all, 'activeJobs'] as const,
    deviations: (jobId?: string) => [...cacheKeys.compliance.all, 'deviations', jobId] as const,
    metrics: (jobId?: string) => [...cacheKeys.compliance.all, 'metrics', jobId] as const,
  },
} as const;