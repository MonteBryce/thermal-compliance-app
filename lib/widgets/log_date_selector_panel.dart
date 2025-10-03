import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/date_provider.dart';
import '../routes/route_extensions.dart';

enum LogStatus {
  complete,
  incomplete,
  notStarted,
  missing, // For dates that should exist but have no log document
  locked, // For entries older than 7 days (audit compliance)
}

class LogDateSelectorPanel extends ConsumerStatefulWidget {
  final String projectId;
  final DateTime? selectedDate;
  final VoidCallback? onDateSelected;

  const LogDateSelectorPanel({
    super.key,
    required this.projectId,
    this.selectedDate,
    this.onDateSelected,
  });

  @override
  ConsumerState<LogDateSelectorPanel> createState() => _LogDateSelectorPanelState();
}

class _LogDateSelectorPanelState extends ConsumerState<LogDateSelectorPanel> {
  final ScrollController _scrollController = ScrollController();
  int? _todayIndex;
  bool _showStickyHeader = false;
  LogDate? _todayLogDate;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_todayIndex == null || _todayLogDate == null) return;

    // Calculate if today's item is visible
    const itemHeight = 120.0; // Approximate height of each list item
    final todayItemOffset = _todayIndex! * itemHeight;
    final currentScrollOffset = _scrollController.offset;
    final viewportHeight = _scrollController.position.viewportDimension;

    // Show sticky header if today's item is scrolled out of view at the top
    final shouldShowSticky = currentScrollOffset > todayItemOffset + itemHeight;

    if (shouldShowSticky != _showStickyHeader) {
      setState(() {
        _showStickyHeader = shouldShowSticky;
      });
    }
  }

  Widget _buildStickyTodayHeader() {
    if (_todayLogDate == null) return const SizedBox.shrink();
    
    final status = _getLogStatus(_todayLogDate!);
    final isFuture = _isFutureDate(_todayLogDate!.date);
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.95),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            isFuture ? Icons.schedule : _getStatusIcon(status),
            color: Colors.white,
            size: 24,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                _todayLogDate!.formattedDate,
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'TODAY',
                style: GoogleFonts.roboto(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(status),
                    style: GoogleFonts.roboto(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_todayLogDate!.completedHours}/${_todayLogDate!.totalHours} hours',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: isFuture ? null : () {
                    context.goToDailySummary(
                      widget.projectId,
                      _todayLogDate!.dateId,
                      extra: {'selectedDate': _todayLogDate!.date},
                    );
                  },
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('View'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: isFuture ? null : () {
                    _navigateToHourlyEntry(context, _todayLogDate!);
                  },
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          _navigateToHourlyEntry(context, _todayLogDate!);
          widget.onDateSelected?.call();
        },
      ),
    );
  }

  LogStatus _getLogStatus(LogDate logDate) {
    // Check if this is a future date (no logging needed yet)
    if (_isFutureDate(logDate.date)) {
      return LogStatus.notStarted;
    }
    
    // Check if this date is locked (older than 7 days) - takes priority over other statuses
    if (_isLockedDate(logDate.date)) {
      // Still show the underlying status for locked entries
      if (logDate.completedHours == 0) {
        // If it's locked and has no entries, it's a locked missing entry
        return LogStatus.missing; // Keep as missing since it's more critical
      } else {
        // If it has entries but is locked, show as locked
        return LogStatus.locked;
      }
    }
    
    // Check if this date should have entries but doesn't (missing day)
    if (logDate.completedHours == 0) {
      // Determine if this is a missing day or just not started
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final logDay = DateTime(logDate.date.year, logDate.date.month, logDate.date.day);
      
      // If it's more than 1 day old and has no entries, consider it missing
      if (logDay.isBefore(DateTime(yesterday.year, yesterday.month, yesterday.day))) {
        return LogStatus.missing;
      } else {
        return LogStatus.notStarted;
      }
    } else if (logDate.completedHours < logDate.totalHours) {
      return LogStatus.incomplete;
    } else {
      return LogStatus.complete;
    }
  }

  Color _getStatusColor(LogStatus status) {
    switch (status) {
      case LogStatus.complete:
        return Colors.green;
      case LogStatus.incomplete:
        return Colors.orange;
      case LogStatus.notStarted:
        return Colors.grey;
      case LogStatus.missing:
        return Colors.red;
      case LogStatus.locked:
        return Colors.purple;
    }
  }

  String _getStatusText(LogStatus status) {
    switch (status) {
      case LogStatus.complete:
        return 'Complete';
      case LogStatus.incomplete:
        return 'Incomplete';
      case LogStatus.notStarted:
        return 'Not Started';
      case LogStatus.missing:
        return 'Missing';
      case LogStatus.locked:
        return 'Locked';
    }
  }

  IconData _getStatusIcon(LogStatus status) {
    switch (status) {
      case LogStatus.complete:
        return Icons.check_circle;
      case LogStatus.incomplete:
        return Icons.schedule;
      case LogStatus.notStarted:
        return Icons.radio_button_unchecked;
      case LogStatus.missing:
        return Icons.warning;
      case LogStatus.locked:
        return Icons.lock;
    }
  }

  void _scrollToToday() {
    if (_todayIndex != null && _scrollController.hasClients) {
      const itemHeight = 120.0; // Approximate height of each list item
      final offset = _todayIndex! * itemHeight;
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _navigateToHourlyEntry(BuildContext context, LogDate logDate) {
    // Check if the selected date is in the future
    if (_isFutureDate(logDate.date)) {
      _showFutureDateMessage(context);
      return;
    }
    
    // Check if the selected date is locked (older than 7 days)
    if (_isLockedDate(logDate.date)) {
      _showLockedDateMessage(context);
      return;
    }
    
    final hour = _selectBestHourForEntry(logDate);
    
    context.goToHourlyEntry(
      widget.projectId,
      logDate.dateId,
      hour,
      extra: {
        'logType': 'thermal',
        'selectedDate': logDate.date,
        'enteredHours': <int>{}, // Will be populated by the screen
      },
    );
  }

  bool _isFutureDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final logDay = DateTime(date.year, date.month, date.day);
    
    return logDay.isAfter(today);
  }

  bool _isLockedDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final logDay = DateTime(date.year, date.month, date.day);
    
    // Check if the date is more than 7 days old
    final daysDifference = today.difference(logDay).inDays;
    return daysDifference > 7;
  }

  void _showFutureDateMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(
              Icons.schedule,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Logging not available yet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _showLockedDateMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(
              Icons.lock,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Entry locked for audit compliance (>7 days old)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.purple[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  int _selectBestHourForEntry(LogDate logDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final logDay = DateTime(logDate.date.year, logDate.date.month, logDate.date.day);
    
    // If it's today, navigate to the current hour (clamped to 0-23)
    if (logDay == today) {
      return now.hour.clamp(0, 23);
    }
    
    // For future dates, start at a reasonable hour (8 AM)
    if (logDay.isAfter(today)) {
      return 8;
    }
    
    // For past dates, choose the best hour based on completion status
    if (logDate.completedHours == 0) {
      // No entries yet, start at 8 AM
      return 8;
    } else if (logDate.completedHours < 24) {
      // Some entries exist, find the first missing hour or use a reasonable default
      // Since we don't have detailed hour data here, use a smart default
      final estimatedNextHour = (logDate.completedHours + 8).clamp(0, 23);
      return estimatedNextHour;
    } else {
      // All hours completed, go to the first hour for review/editing
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final logDatesAsync = ref.watch(enhancedLogDatesProvider(widget.projectId));
    final today = DateTime.now();
    final todayDateId = DateFormat('yyyy-MM-dd').format(today);

    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with scroll to today button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.date_range,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Log Date Selector',
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const Spacer(),
                if (_todayIndex != null)
                  TextButton.icon(
                    onPressed: _scrollToToday,
                    icon: const Icon(Icons.today, size: 16),
                    label: const Text('Today'),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                  ),
              ],
            ),
          ),
          
          // Date list
          Expanded(
            child: logDatesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load log dates',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              data: (logDates) {
                if (logDates.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_month_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No log dates available',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start logging to see dates here',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  );
                }

                // Find today's index for scrolling and store today's LogDate
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _todayIndex = logDates.indexWhere((date) => date.dateId == todayDateId);
                  if (_todayIndex != -1) {
                    _todayLogDate = logDates[_todayIndex!];
                  }
                });

                return Stack(
                  children: [
                    ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: logDates.length,
                      itemBuilder: (context, index) {
                    final logDate = logDates[index];
                    final status = _getLogStatus(logDate);
                    final isToday = logDate.dateId == todayDateId;
                    final isFuture = _isFutureDate(logDate.date);
                    final isMissing = status == LogStatus.missing;
                    final isLocked = status == LogStatus.locked || _isLockedDate(logDate.date);
                    final isSelected = widget.selectedDate != null && 
                        DateFormat('yyyy-MM-dd').format(widget.selectedDate!) == logDate.dateId;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isFuture
                            ? Colors.grey[100]
                            : isMissing
                                ? Colors.red[50]
                                : isLocked
                                    ? Colors.purple[50]
                                    : isToday 
                                        ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                                        : isSelected 
                                            ? Theme.of(context).colorScheme.secondary.withOpacity(0.1)
                                            : null,
                        borderRadius: BorderRadius.circular(8),
                        border: isFuture
                            ? Border.all(
                                color: Colors.grey[300]!,
                                width: 1,
                              )
                            : isMissing
                                ? Border.all(
                                    color: Colors.red[300]!,
                                    width: 2,
                                  )
                                : isLocked
                                    ? Border.all(
                                        color: Colors.purple[300]!,
                                        width: 2,
                                      )
                                    : isToday 
                                        ? Border.all(
                                            color: Theme.of(context).colorScheme.primary,
                                            width: 2,
                                          )
                                        : isSelected
                                            ? Border.all(
                                                color: Theme.of(context).colorScheme.secondary,
                                                width: 1,
                                              )
                                            : null,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isFuture 
                                    ? Colors.grey[300]
                                    : isMissing
                                        ? Colors.red[100]
                                        : isLocked
                                            ? Colors.purple[100]
                                            : _getStatusColor(status).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Icon(
                                isFuture ? Icons.schedule : _getStatusIcon(status),
                                color: isFuture 
                                    ? Colors.grey[600] 
                                    : _getStatusColor(status),
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                logDate.formattedDate,
                                style: GoogleFonts.roboto(
                                  fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                                  fontSize: 16,
                                  color: isFuture 
                                      ? Colors.grey[600] 
                                      : isMissing 
                                          ? Colors.red[700]
                                          : isLocked
                                              ? Colors.purple[700]
                                              : null,
                                ),
                              ),
                            ),
                            if (isToday)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'TODAY',
                                  style: GoogleFonts.roboto(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            if (isMissing)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red[600],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'MISSING',
                                  style: GoogleFonts.roboto(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            if (isLocked)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.purple[600],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'LOCKED',
                                  style: GoogleFonts.roboto(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            if (isFuture)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey[400],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'FUTURE',
                                  style: GoogleFonts.roboto(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(status).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _getStatusText(status),
                                    style: GoogleFonts.roboto(
                                      color: _getStatusColor(status),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${logDate.completedHours}/${logDate.totalHours} hours',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                TextButton.icon(
                                  onPressed: isFuture ? null : () {
                                    context.goToDailySummary(
                                      widget.projectId,
                                      logDate.dateId,
                                      extra: {'selectedDate': logDate.date},
                                    );
                                  },
                                  icon: const Icon(Icons.visibility, size: 16),
                                  label: const Text('View'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: isFuture 
                                        ? Colors.grey[400] 
                                        : isMissing 
                                            ? Colors.red[600]
                                            : isLocked
                                                ? Colors.purple[600]
                                                : Colors.blue,
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: (isFuture || isLocked) ? null : () {
                                    _navigateToHourlyEntry(context, logDate);
                                  },
                                  icon: Icon(isMissing ? Icons.add : isLocked ? Icons.lock : Icons.edit, size: 16),
                                  label: Text(isMissing ? 'Add' : isLocked ? 'Locked' : 'Edit'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: (isFuture || isLocked)
                                        ? Colors.grey[400] 
                                        : isMissing 
                                            ? Colors.red[600]
                                            : Colors.orange,
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        onTap: () {
                          _navigateToHourlyEntry(context, logDate);
                          widget.onDateSelected?.call();
                        },
                      ),
                    );
                  },
                ),
                
                // Sticky header for today's entry
                if (_showStickyHeader)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: _buildStickyTodayHeader(),
                  ),
                ],
              );
              },
            ),
          ),
        ],
      ),
    );
  }
}