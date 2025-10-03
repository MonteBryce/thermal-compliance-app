import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/date_provider.dart';
import '../model/job_data.dart';

class DateSelectorWidget extends ConsumerStatefulWidget {
  final String projectId;
  final JobData? initialJob;
  final Function(LogDate)? onDateSelected;

  const DateSelectorWidget({
    super.key,
    required this.projectId,
    this.initialJob,
    this.onDateSelected,
  });

  @override
  ConsumerState<DateSelectorWidget> createState() => _DateSelectorWidgetState();
}

class _DateSelectorWidgetState extends ConsumerState<DateSelectorWidget> {
  String? selectedDateId;

  @override
  Widget build(BuildContext context) {
    final availableDatesAsync = ref.watch(availableLogDatesProvider(widget.projectId));

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF152042),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Select Log Date',
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.white, size: 20),
                  onPressed: () => _createTodayLog(),
                  tooltip: 'Add Today',
                ),
              ],
            ),
          ),
          
          // Date List
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            child: availableDatesAsync.when(
              data: (dates) => _buildDateList(dates),
              loading: () => _buildLoadingState(),
              error: (error, stack) => _buildErrorState(error.toString()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateList(List<LogDate> dates) {
    if (dates.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      itemCount: dates.length,
      itemBuilder: (context, index) {
        final logDate = dates[index];
        final isSelected = selectedDateId == logDate.dateId;
        final isToday = _isToday(logDate.date);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => _handleDateSelect(logDate),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected 
                    ? const Color(0xFF1E40AF).withOpacity(0.3)
                    : const Color(0xFF0B132B),
                borderRadius: BorderRadius.circular(8),
                border: isSelected 
                    ? Border.all(color: const Color(0xFF3B82F6), width: 2)
                    : Border.all(color: Colors.grey[700]!, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Date Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                logDate.formattedDate,
                                style: GoogleFonts.nunito(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (isToday) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6, 
                                    vertical: 1
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF059669),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'TODAY',
                                    style: GoogleFonts.nunito(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            logDate.dateId,
                            style: GoogleFonts.nunito(
                              color: Colors.grey[400],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Progress Info
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${logDate.completedHours}/24',
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          width: 60,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[700],
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: logDate.completionPercentage,
                            child: Container(
                              decoration: BoxDecoration(
                                color: _getProgressColor(logDate.completionPercentage),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '${(logDate.completionPercentage * 100).round()}%',
                          style: GoogleFonts.nunito(
                            color: Colors.grey[400],
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey,
                      size: 12,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            SizedBox(height: 12),
            Text(
              'Loading dates...',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 40),
          const SizedBox(height: 12),
          Text(
            'Error loading dates',
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            error,
            style: GoogleFonts.nunito(
              color: Colors.grey[400],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => ref.refresh(availableLogDatesProvider(widget.projectId)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Retry', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(Icons.calendar_today, size: 60, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No Log Dates Found',
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Start by creating a log for today',
            style: GoogleFonts.nunito(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _createTodayLog,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Create Today\'s Log', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  void _handleDateSelect(LogDate logDate) {
    setState(() {
      selectedDateId = logDate.dateId;
    });

    // Call callback if provided - this should update the parent widget's state
    if (widget.onDateSelected != null) {
      widget.onDateSelected!(logDate);
    }

    // Don't navigate away - let the parent widget handle what to do with the selected date
  }

  void _createTodayLog() async {
    try {
      final dateId = await ref.read(createTodayLogProvider(widget.projectId).future);
      
      // Refresh the dates list
      ref.refresh(availableLogDatesProvider(widget.projectId));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Created log for today ($dateId)'),
            backgroundColor: const Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating today\'s log: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _isToday(DateTime date) {
    final today = DateTime.now();
    return date.year == today.year &&
           date.month == today.month &&
           date.day == today.day;
  }

  Color _getProgressColor(double percentage) {
    if (percentage >= 1.0) return const Color(0xFF059669); // Green - Complete
    if (percentage >= 0.75) return const Color(0xFF3B82F6); // Blue - Most done
    if (percentage >= 0.5) return const Color(0xFFF59E0B); // Orange - Half done
    return const Color(0xFFEF4444); // Red - Just started
  }
}