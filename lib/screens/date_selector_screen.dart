import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/date_provider.dart';
import '../model/job_data.dart';

class DateSelectorScreen extends ConsumerStatefulWidget {
  final String projectId;
  final JobData? initialJob;

  const DateSelectorScreen({
    super.key,
    required this.projectId,
    this.initialJob,
  });

  @override
  ConsumerState<DateSelectorScreen> createState() => _DateSelectorScreenState();
}

class _DateSelectorScreenState extends ConsumerState<DateSelectorScreen> {
  String? selectedDateId;

  @override
  Widget build(BuildContext context) {
    final availableDatesAsync = ref.watch(availableLogDatesProvider(widget.projectId));

    return Scaffold(
      backgroundColor: const Color(0xFF0B132B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B132B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Select Date',
          style: GoogleFonts.nunito(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _createTodayLog(),
            tooltip: 'Add Today',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Project Info Header
            if (widget.initialJob != null) _buildProjectHeader(),
            
            // Date List
            Expanded(
              child: availableDatesAsync.when(
                data: (dates) => _buildDateList(dates),
                loading: () => _buildLoadingState(),
                error: (error, stack) => _buildErrorState(error.toString()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF152042),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.initialJob!.projectName,
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Project: ${widget.projectId}',
            style: GoogleFonts.nunito(
              color: Colors.grey[400],
              fontSize: 14,
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: dates.length,
      itemBuilder: (context, index) {
        final logDate = dates[index];
        final isSelected = selectedDateId == logDate.dateId;
        final isToday = _isToday(logDate.date);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => _handleDateSelect(logDate),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected 
                    ? const Color(0xFF1E40AF).withOpacity(0.3)
                    : const Color(0xFF152042),
                borderRadius: BorderRadius.circular(12),
                border: isSelected 
                    ? Border.all(color: const Color(0xFF3B82F6), width: 2)
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
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
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (isToday) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8, 
                                    vertical: 2
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF059669),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'TODAY',
                                    style: GoogleFonts.nunito(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            logDate.dateId,
                            style: GoogleFonts.nunito(
                              color: Colors.grey[400],
                              fontSize: 12,
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
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 80,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.grey[700],
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: logDate.completionPercentage,
                            child: Container(
                              decoration: BoxDecoration(
                                color: _getProgressColor(logDate.completionPercentage),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${(logDate.completionPercentage * 100).round()}%',
                          style: GoogleFonts.nunito(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey,
                      size: 16,
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
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            'Loading available dates...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 50),
            const SizedBox(height: 16),
            Text(
              'Error loading dates',
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: GoogleFonts.nunito(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => ref.refresh(availableLogDatesProvider(widget.projectId)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            Text(
              'No Log Dates Found',
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start by creating a log for today',
              style: GoogleFonts.nunito(
                color: Colors.grey[400],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _createTodayLog,
              icon: const Icon(Icons.add),
              label: const Text('Create Today\'s Log'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleDateSelect(LogDate logDate) {
    setState(() {
      selectedDateId = logDate.dateId;
    });

    // Navigate to hour selector for this date
    context.pushNamed(
      'hourSelector',
      pathParameters: {
        'projectId': widget.projectId,
        'logDate': logDate.dateId,
      },
      extra: {
        'initialJob': widget.initialJob,
        'logDate': logDate,
        'logType': 'thermal',
      },
    );
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