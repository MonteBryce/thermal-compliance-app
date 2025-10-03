export interface LogVariable {
  id: string;
  name: string;
  category: string;
  dataType: 'text' | 'number' | 'date' | 'select' | 'checkbox' | 'textarea';
  excelColumn?: string;
  description?: string;
  tags?: string[];
  isFavorite?: boolean;
  lastUsed?: Date | null;
  validation?: {
    required?: boolean;
    min?: number;
    max?: number;
    pattern?: string;
    maxLength?: number;
    customRules?: Array<{
      rule: string;
      message: string;
    }>;
  };
  options?: Array<{
    label: string;
    value: string;
  }>;
  defaultValue?: any;
  unit?: string;
  formula?: string;
  dependsOn?: string[];
}

export interface VariableFilter {
  searchTerm?: string;
  category?: string | 'all';
  dataType?: string | 'all';
  tags?: string[];
  excelColumnRange?: {
    start: string;
    end: string;
  };
  showFavorites?: boolean;
  showRecent?: boolean;
}

export interface VariablePaletteState {
  variables: LogVariable[];
  filteredVariables: LogVariable[];
  selectedVariables: string[];
  favorites: string[];
  recentlyUsed: string[];
  searchHistory: string[];
  filters: VariableFilter;
  isCreateModalOpen: boolean;
  isEditModalOpen: boolean;
  editingVariable: LogVariable | null;
}

export interface VariableCategory {
  name: string;
  description: string;
  icon?: string;
  color?: string;
  order?: number;
}

export const DEFAULT_CATEGORIES: VariableCategory[] = [
  { name: 'Job Info', description: 'Job and project identification', order: 1 },
  { name: 'Thermal', description: 'Temperature and thermal measurements', order: 2 },
  { name: 'Equipment', description: 'Equipment and asset information', order: 3 },
  { name: 'Personnel', description: 'Staff and operator information', order: 4 },
  { name: 'Compliance', description: 'Regulatory and compliance fields', order: 5 },
  { name: 'Measurements', description: 'General measurements and readings', order: 6 },
  { name: 'Custom', description: 'User-defined custom fields', order: 99 },
];