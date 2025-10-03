/// Job Filters Component for Admin Dashboard
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/admin_dashboard_models.dart';
import '../providers/admin_dashboard_providers.dart';

class JobFilters extends ConsumerWidget {
  const JobFilters({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final filters = ref.watch(jobFiltersProvider);
    final availableLogTypes = ref.watch(availableLogTypesProvider);
    final availableOperators = ref.watch(availableOperatorsProvider);
    final filteredJobs = ref.watch(filteredJobsProvider);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.filter_list,
                    size: 20,
                    color: isDarkMode ? Colors.white : const Color(0xFF111827),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Filters',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${filteredJobs.length} results',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF3B82F6),
                      ),
                    ),
                  ),
                ],
              ),
              
              // Clear Filters Button
              if (_hasActiveFilters(filters))
                TextButton.icon(
                  onPressed: () {
                    ref.read(jobFiltersProvider.notifier).state = JobFilters.empty;
                  },
                  icon: const Icon(Icons.clear, size: 16),
                  label: Text(
                    'Clear All',
                    style: GoogleFonts.inter(fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF6B7280),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Filter Controls
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              // Status Filter
              _buildFilterDropdown(
                label: 'Status',
                value: filters.status,
                items: JobStatus.values.map((status) => 
                  DropdownMenuItem(
                    value: status.value,
                    child: Text(status.displayName),
                  ),
                ).toList(),
                onChanged: (value) {
                  ref.read(jobFiltersProvider.notifier).state = 
                      filters.copyWith(status: value);
                },
                isDarkMode: isDarkMode,
              ),
              
              // Log Type Filter
              _buildFilterDropdown(
                label: 'Log Type',
                value: filters.logType,
                items: availableLogTypes.map((logType) => 
                  DropdownMenuItem(
                    value: logType,
                    child: Text(_formatLogType(logType)),
                  ),
                ).toList(),
                onChanged: (value) {
                  ref.read(jobFiltersProvider.notifier).state = 
                      filters.copyWith(logType: value);
                },
                isDarkMode: isDarkMode,
              ),
              
              // Operator Filter
              _buildFilterDropdown(
                label: 'Operator',
                value: filters.operator,
                items: availableOperators.map((operator) => 
                  DropdownMenuItem(
                    value: operator,
                    child: Text(operator),
                  ),
                ).toList(),
                onChanged: (value) {
                  ref.read(jobFiltersProvider.notifier).state = 
                      filters.copyWith(operator: value);
                },
                isDarkMode: isDarkMode,
              ),
              
              // Date Range Filter
              _buildDateRangeFilter(
                filters: filters,
                onChanged: (dateRange) {
                  ref.read(jobFiltersProvider.notifier).state = 
                      filters.copyWith(dateRange: dateRange);
                },
                isDarkMode: isDarkMode,
                context: context,
              ),
              
              // Search Filter (for operator name search)
              _buildSearchFilter(
                filters: filters,
                onChanged: (searchTerm) {
                  ref.read(jobFiltersProvider.notifier).state = 
                      filters.copyWith(operator: searchTerm);
                },
                isDarkMode: isDarkMode,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
    required bool isDarkMode,
  }) {
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDarkMode ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDarkMode ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF3B82F6)),
              ),
              fillColor: isDarkMode ? const Color(0xFF374151) : Colors.white,
              filled: true,
            ),
            hint: Text(
              'All ${label.toLowerCase()}',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              ),
            ),
            items: [
              DropdownMenuItem<String>(
                value: null,
                child: Text(
                  'All ${label.toLowerCase()}',
                  style: GoogleFonts.inter(fontSize: 14),
                ),
              ),
              ...items,
            ],
            onChanged: onChanged,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDarkMode ? Colors.white : const Color(0xFF111827),
            ),
            dropdownColor: isDarkMode ? const Color(0xFF374151) : Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeFilter({
    required JobFilters filters,
    required void Function(DateTimeRange?) onChanged,
    required bool isDarkMode,
    required BuildContext context,
  }) {
    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Date Range',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () async {
              final dateRange = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                initialDateRange: filters.dateRange,
              );
              onChanged(dateRange);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF374151) : Colors.white,
                border: Border.all(
                  color: isDarkMode ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.date_range,
                    size: 16,
                    color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      filters.dateRange != null
                          ? '${_formatDate(filters.dateRange!.start)} - ${_formatDate(filters.dateRange!.end)}'
                          : 'Select range',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: filters.dateRange != null
                            ? (isDarkMode ? Colors.white : const Color(0xFF111827))
                            : (isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
                      ),
                    ),
                  ),
                  if (filters.dateRange != null)
                    GestureDetector(
                      onTap: () => onChanged(null),
                      child: Icon(
                        Icons.clear,
                        size: 16,
                        color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchFilter({
    required JobFilters filters,
    required void Function(String?) onChanged,
    required bool isDarkMode,
  }) {
    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search Operator',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDarkMode ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDarkMode ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF3B82F6)),
              ),
              fillColor: isDarkMode ? const Color(0xFF374151) : Colors.white,
              filled: true,
              hintText: 'Search by name...',
              hintStyle: GoogleFonts.inter(
                fontSize: 14,
                color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              ),
              prefixIcon: Icon(
                Icons.search,
                size: 16,
                color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              ),
            ),
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDarkMode ? Colors.white : const Color(0xFF111827),
            ),
            onChanged: (value) => onChanged(value.isEmpty ? null : value),
          ),
        ],
      ),
    );
  }

  bool _hasActiveFilters(JobFilters filters) {
    return filters.status != null ||
           filters.logType != null ||
           filters.operator != null ||
           filters.dateRange != null;
  }

  String _formatLogType(String logType) {
    return logType.replaceAll('_', ' ').split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
