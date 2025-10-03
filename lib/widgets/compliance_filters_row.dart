/// Compliance Dashboard Filters Row
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ComplianceFiltersRow extends StatefulWidget {
  final String? selectedStatus;
  final String? selectedLogType;
  final String? selectedOperator;
  final DateTimeRange? selectedDateRange;
  final Function(String?)? onStatusChanged;
  final Function(String?)? onLogTypeChanged;
  final Function(String?)? onOperatorChanged;
  final Function(DateTimeRange?)? onDateRangeChanged;

  const ComplianceFiltersRow({
    super.key,
    this.selectedStatus,
    this.selectedLogType,
    this.selectedOperator,
    this.selectedDateRange,
    this.onStatusChanged,
    this.onLogTypeChanged,
    this.onOperatorChanged,
    this.onDateRangeChanged,
  });

  @override
  State<ComplianceFiltersRow> createState() => _ComplianceFiltersRowState();
}

class _ComplianceFiltersRowState extends State<ComplianceFiltersRow> {
  // Mock data for dropdowns
  final List<String> _statusOptions = [
    'All Status',
    'Active', 
    'Incomplete',
    'Complete',
    'Overdue'
  ];

  final List<String> _logTypeOptions = [
    'All Log Types',
    'Methane Hourly',
    'Benzene 12hr',
    'Natural Gas Daily',
    'Thermal Monitoring'
  ];

  final List<String> _operatorOptions = [
    'All Operators',
    'Alex Walker',
    'Maria Johnson',
    'David Chen',
    'Sarah Wilson'
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2A2A2A),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Status Filter
          Expanded(
            child: _buildFilterDropdown(
              label: 'Status',
              value: widget.selectedStatus ?? _statusOptions[0],
              options: _statusOptions,
              onChanged: widget.onStatusChanged,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Log Type Filter
          Expanded(
            child: _buildFilterDropdown(
              label: 'Log Type',
              value: widget.selectedLogType ?? _logTypeOptions[0],
              options: _logTypeOptions,
              onChanged: widget.onLogTypeChanged,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Operator Filter
          Expanded(
            child: _buildFilterDropdown(
              label: 'Operator',
              value: widget.selectedOperator ?? _operatorOptions[0],
              options: _operatorOptions,
              onChanged: widget.onOperatorChanged,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Date Range Filter
          Expanded(
            child: _buildDateRangeFilter(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<String> options,
    required Function(String?)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF9CA3AF),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF2A2A2A),
              width: 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Color(0xFF6B7280),
                size: 18,
              ),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white,
              ),
              dropdownColor: const Color(0xFF1E1E1E),
              items: options.map((option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(
                      option,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: option.startsWith('All') 
                            ? const Color(0xFF9CA3AF) 
                            : Colors.white,
                      ),
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null && !value.startsWith('All')) {
                  onChanged?.call(value);
                } else {
                  onChanged?.call(null);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date Range',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF9CA3AF),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final dateRange = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              initialDateRange: widget.selectedDateRange,
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: Color(0xFF3B82F6),
                      onPrimary: Colors.white,
                      surface: Color(0xFF1E1E1E),
                      onSurface: Colors.white,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            widget.onDateRangeChanged?.call(dateRange);
          },
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF2A2A2A),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: Color(0xFF6B7280),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.selectedDateRange != null
                          ? '${_formatDate(widget.selectedDateRange!.start)} - ${_formatDate(widget.selectedDateRange!.end)}'
                          : 'Select range',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: widget.selectedDateRange != null
                            ? Colors.white
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                  if (widget.selectedDateRange != null)
                    GestureDetector(
                      onTap: () => widget.onDateRangeChanged?.call(null),
                      child: const Icon(
                        Icons.clear,
                        color: Color(0xFF6B7280),
                        size: 16,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
