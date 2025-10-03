import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { TemplateService } from '@/lib/firestore/templates';
import { LogTemplate } from '@/lib/types/logbuilder';
import { cacheKeys } from '@/lib/cache/query-client';

const templateService = new TemplateService();

export function useTemplates(filters?: string) {
  return useQuery({
    queryKey: cacheKeys.templates.list(filters),
    queryFn: async () => {
      const templates = await templateService.getTemplates();
      if (filters) {
        return templates.filter(t => 
          t.name.toLowerCase().includes(filters.toLowerCase()) ||
          t.logType.toLowerCase().includes(filters.toLowerCase())
        );
      }
      return templates;
    },
    staleTime: 5 * 60 * 1000,
    gcTime: 10 * 60 * 1000,
  });
}

export function useTemplate(templateId: string) {
  return useQuery({
    queryKey: cacheKeys.templates.detail(templateId),
    queryFn: () => templateService.getTemplate(templateId),
    enabled: !!templateId,
    staleTime: 10 * 60 * 1000,
    gcTime: 30 * 60 * 1000,
  });
}

export function useCreateTemplate() {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: (template: Partial<LogTemplate>) => 
      templateService.createTemplate(template),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: cacheKeys.templates.all });
    },
  });
}

export function useUpdateTemplate() {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: ({ id, updates }: { id: string; updates: Partial<LogTemplate> }) =>
      templateService.updateTemplate(id, updates),
    onSuccess: (_, { id }) => {
      queryClient.invalidateQueries({ queryKey: cacheKeys.templates.detail(id) });
      queryClient.invalidateQueries({ queryKey: cacheKeys.templates.lists() });
    },
    onMutate: async ({ id, updates }) => {
      await queryClient.cancelQueries({ queryKey: cacheKeys.templates.detail(id) });
      
      const previousTemplate = queryClient.getQueryData(cacheKeys.templates.detail(id));
      
      queryClient.setQueryData(cacheKeys.templates.detail(id), (old: any) => ({
        ...old,
        ...updates,
      }));
      
      return { previousTemplate };
    },
    onError: (err, { id }, context) => {
      if (context?.previousTemplate) {
        queryClient.setQueryData(cacheKeys.templates.detail(id), context.previousTemplate);
      }
    },
  });
}

export function useDeleteTemplate() {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: (templateId: string) => templateService.deleteTemplate(templateId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: cacheKeys.templates.all });
    },
  });
}