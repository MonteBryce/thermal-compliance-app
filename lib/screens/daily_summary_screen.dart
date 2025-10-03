import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../routes/route_extensions.dart';
import '../services/project_service.dart';
import '../models/firestore_models.dart';
import '../models/hive_models.dart';
import '../widgets/operator_badge.dart';
import '../providers/daily_summary_providers.dart';
import '../providers/connection_providers.dart';
import '../services/local_database_service.dart';
import '../services/auth_service.dart';
import '../services/connection_service.dart' as connection_svc;

// State provider for the selected log date (re-export from daily_summary_providers)
final selectedLogDateProvider = selectedDateProvider;

// Providers for data loading
final projectProvider =
    FutureProvider.family<ProjectDocument?, String>((ref, projectId) async {
  final projectService = ProjectService();
  return await projectService.getProject(projectId);
});

// Provider for calculating progress data based on real log entries
final progressDataProvider =
    Provider.family<Map<String, dynamic>, (String, DateTime)>((ref, params) {
  final projectId = params.$1;
  final selectedDate = params.$2;

  // Watch the daily summary stats
  final stats = ref.watch(dailySummaryStatsProvider(selectedDate));

  // Watch the daily log entries to determine missing hours
  final logEntriesAsync = ref.watch(dailyLogEntriesProvider(selectedDate));

  final completedHours = stats.completedEntries;
  final totalHours = 24; // A day has 24 hours

  // Calculate missing hours by checking which hours don't have entries
  final missingHours = <int>[];
  if (logEntriesAsync.hasValue) {
    final entries = logEntriesAsync.value!;
    final recordedHours =
        entries.map((e) => int.tryParse(e.hour) ?? -1).toSet();

    for (int hour = 0; hour < 24; hour++) {
      if (!recordedHours.contains(hour)) {
        missingHours.add(hour);
      }
    }
  }

  // Get operator name from auth service
  final operatorName =
      AuthService.getCurrentUserEmail()?.split('@').first ?? 'Operator';

  return {
    'completedHours': completedHours,
    'totalHours': totalHours,
    'missingHours': missingHours,
    'operatorName': operatorName,
    'stats': stats,
  };
});

class DailySummaryScreen extends ConsumerStatefulWidget {
  final String projectId;
  final String logId;
  final DateTime selectedDate;

  const DailySummaryScreen({
    super.key,
    required this.projectId,
    required this.logId,
    required this.selectedDate,
  });

  @override
  ConsumerState<DailySummaryScreen> createState() => _DailySummaryScreenState();
}

class _DailySummaryScreenState extends ConsumerState<DailySummaryScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressAnimationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.easeInOutCubic,
    ));

    // Initialize the selected date provider with the widget's selected date
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedLogDateProvider.notifier).state = widget.selectedDate;
      _progressAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _progressAnimationController.dispose();
    super.dispose();
  }

  void _triggerHapticFeedback() {
    HapticFeedback.lightImpact();
  }

  void _navigateToHourlyLog() {
    _triggerHapticFeedback();
    context.goToHourSelector(
      widget.projectId,
      widget.logId,
      extra: {
        'logType': 'thermal',
        'selectedDate': ref.read(selectedLogDateProvider),
      },
    );
  }

  void _navigateToSystemMetrics() {
    _triggerHapticFeedback();
    context.goToSystemMetrics(
      extra: {
        'projectId': widget.projectId,
        'logId': widget.logId,
        'selectedDate': ref.read(selectedLogDateProvider),
      },
    );
  }

  void _navigateToReviewEntries() {
    _triggerHapticFeedback();
    context.goToReviewAll(
      widget.projectId,
      widget.logId,
    );
  }

  /// Get color for connection state
  Color _getConnectionColor(connection_svc.ConnectionState state) {
    switch (state) {
      case connection_svc.ConnectionState.online:
        return const Color(0xFF10B981);
      case connection_svc.ConnectionState.offline:
        return const Color(0xFF64748B);
      case connection_svc.ConnectionState.poor:
        return const Color(0xFFF59E0B);
      case connection_svc.ConnectionState.switching:
        return const Color(0xFF3B82F6);
    }
  }

  /// Show connection details dialog
  void _showConnectionDetails(BuildContext context, WidgetRef ref) {
    final connectionService = ref.read(connectionServiceProvider);
    final dataMode = ref.read(currentDataModeProvider);
    final connectionState = ref.read(currentConnectionStateProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Connection Status',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ConnectionDetailRow(
              label: 'Status',
              value: connectionService.getConnectionStatusText(),
              icon: connectionService.getConnectionStatusIcon(),
            ),
            const SizedBox(height: 8),
            _ConnectionDetailRow(
              label: 'Data Mode',
              value: dataMode.name.toUpperCase(),
              icon: dataMode == connection_svc.DataMode.firestore ? '☁️' : '💾',
            ),
            const SizedBox(height: 16),
            // Helpful information about current mode
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getInfoBackgroundColor(
                    connectionState, connectionService.isManualOfflineMode),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: _getInfoBorderColor(connectionState,
                        connectionService.isManualOfflineMode)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getInfoTitle(
                        connectionState, connectionService.isManualOfflineMode),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _getInfoTextColor(connectionState,
                          connectionService.isManualOfflineMode),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getInfoDescription(
                        connectionState, connectionService.isManualOfflineMode),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: _getInfoTextColor(connectionState,
                          connectionService.isManualOfflineMode),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Mode switching buttons with improved prompts
            if (connectionState == connection_svc.ConnectionState.online &&
                !connectionService.isManualOfflineMode)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _showOfflineModeConfirmation(
                        context, connectionService, ref),
                    icon: const Icon(Icons.wifi_off),
                    label: const Text('Switch to Offline Mode'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Use this when working in areas with poor connectivity',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            if (connectionService.isManualOfflineMode)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _showOnlineModeConfirmation(
                        context, connectionService, ref),
                    icon: const Icon(Icons.wifi),
                    label: const Text('Switch to Online Mode'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Data will sync to the cloud when connected',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            if (connectionState == connection_svc.ConnectionState.poor &&
                !connectionService.isManualOfflineMode)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _showOfflineModeRecommendation(
                        context, connectionService, ref),
                    icon: const Icon(Icons.signal_wifi_bad),
                    label: const Text('Use Offline Mode?'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFF59E0B),
                      side: const BorderSide(color: Color(0xFFF59E0B)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Recommended for poor connection areas',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            if (connectionState != connection_svc.ConnectionState.switching)
              TextButton.icon(
                onPressed: () {
                  connectionService.refreshConnection();
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Check Connection'),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedLogDateProvider);
    final progressData =
        ref.watch(progressDataProvider((widget.projectId, selectedDate)));
    final projectAsync = ref.watch(projectProvider(widget.projectId));

    final completedHours = progressData['completedHours'] as int;
    final totalHours = progressData['totalHours'] as int;
    final missingHours = progressData['missingHours'] as List<int>;
    final operatorName = progressData['operatorName'] as String;
    final progressPercent = totalHours > 0 ? completedHours / totalHours : 0.0;
    final stats = progressData['stats'] as DailySummaryStats;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Modern App Bar with blur effect and connection status
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white.withOpacity(0.95),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            actions: [
              // Connection Status Indicator
              Consumer(
                builder: (context, ref, child) {
                  final connectionIcon =
                      ref.watch(connectionStatusIconProvider);
                  final connectionText =
                      ref.watch(connectionStatusTextProvider);
                  final connectionState = ref.watch(connectionStateProvider);

                  return connectionState.when(
                    data: (state) => Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: GestureDetector(
                        onTap: () => _showConnectionDetails(context, ref),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getConnectionColor(state).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  _getConnectionColor(state).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                connectionIcon,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                connectionText,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _getConnectionColor(state),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: Text(
                'Operator Dashboard',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFF8FAFC),
                      Color(0xFFE2E8F0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Project Header Card
                _ProjectHeaderCard(
                  projectId: widget.projectId,
                  projectAsync: projectAsync,
                  selectedDate: selectedDate,
                ),

                const SizedBox(height: 24),

                // Progress Ring Section
                _ProgressSection(
                  progressPercent: progressPercent,
                  completedHours: completedHours,
                  totalHours: totalHours,
                  progressAnimation: _progressAnimation,
                ),

                const SizedBox(height: 24),

                // Log Type Requirements Section
                _LogTypeRequirementsCard(
                  projectId: widget.projectId,
                  stats: stats,
                ),

                const SizedBox(height: 24),

                // Hourly Status Grid
                _HourlyStatusGrid(
                  projectId: widget.projectId,
                  selectedDate: selectedDate,
                ),

                const SizedBox(height: 24),

                // Missing Logs Banner
                if (missingHours.isNotEmpty)
                  _MissingLogsBanner(missingHours: missingHours),

                if (missingHours.isNotEmpty) const SizedBox(height: 24),

                // Action Cards
                Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.schedule,
                        title: 'Start Logging',
                        subtitle: 'Hourly Data',
                        color: const Color(0xFF3B82F6),
                        onTap: _navigateToHourlyLog,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.analytics,
                        title: 'Enter System',
                        subtitle: 'Metrics',
                        color: const Color(0xFF10B981),
                        onTap: _navigateToSystemMetrics,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _ActionCard(
                  icon: Icons.list_alt,
                  title: 'Review All Entries',
                  subtitle: 'Validate logged data',
                  color: const Color(0xFF8B5CF6),
                  onTap: _navigateToReviewEntries,
                  isFullWidth: true,
                ),

                const SizedBox(height: 32),

                // Operator Info
                _OperatorInfo(operatorName: operatorName),

                const SizedBox(height: 20),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper Widgets

class _ProjectHeaderCard extends StatelessWidget {
  final String projectId;
  final AsyncValue<ProjectDocument?> projectAsync;
  final DateTime selectedDate;

  const _ProjectHeaderCard({
    required this.projectId,
    required this.projectAsync,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.work_outline,
                  color: Color(0xFF3B82F6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    projectAsync.when(
                      data: (project) => Text(
                        project?.projectName ?? 'Project $projectId',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      loading: () => Container(
                        height: 18,
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      error: (_, __) => Text(
                        'Project $projectId',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: $projectId',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Color(0xFF475569),
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(selectedDate),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressSection extends StatelessWidget {
  final double progressPercent;
  final int completedHours;
  final int totalHours;
  final Animation<double> progressAnimation;

  const _ProgressSection({
    required this.progressPercent,
    required this.completedHours,
    required this.totalHours,
    required this.progressAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Daily Progress',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 24),
          AnimatedBuilder(
            animation: progressAnimation,
            builder: (context, child) {
              return CircularPercentIndicator(
                radius: 80.0,
                lineWidth: 12.0,
                animation: false,
                percent: progressPercent * progressAnimation.value,
                center: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${(progressPercent * progressAnimation.value * 100).toInt()}%',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Complete',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                circularStrokeCap: CircularStrokeCap.round,
                progressColor: const Color(0xFF10B981),
                backgroundColor: const Color(0xFFE2E8F0),
              );
            },
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatItem(
                label: 'Completed',
                value: '$completedHours',
                color: const Color(0xFF10B981),
              ),
              Container(
                width: 1,
                height: 40,
                color: const Color(0xFFE2E8F0),
              ),
              _StatItem(
                label: 'Total Hours',
                value: '$totalHours',
                color: const Color(0xFF64748B),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}

class _ConnectionDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final String icon;

  const _ConnectionDetailRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          icon,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }
}

// Helper methods for connection dialog
Color _getInfoBackgroundColor(connection_svc.ConnectionState state, bool isManualOffline) {
  if (isManualOffline) return const Color(0xFFFEF3C7); // Amber background
  switch (state) {
    case connection_svc.ConnectionState.online:
      return const Color(0xFFD1FAE5); // Green background
    case connection_svc.ConnectionState.offline:
      return const Color(0xFFFEE2E2); // Red background
    case connection_svc.ConnectionState.poor:
      return const Color(0xFFFED7AA); // Orange background
    case connection_svc.ConnectionState.switching:
      return const Color(0xFFE0E7FF); // Blue background
  }
}

Color _getInfoBorderColor(connection_svc.ConnectionState state, bool isManualOffline) {
  if (isManualOffline) return const Color(0xFFF59E0B); // Amber border
  switch (state) {
    case connection_svc.ConnectionState.online:
      return const Color(0xFF10B981); // Green border
    case connection_svc.ConnectionState.offline:
      return const Color(0xFFEF4444); // Red border
    case connection_svc.ConnectionState.poor:
      return const Color(0xFFF97316); // Orange border
    case connection_svc.ConnectionState.switching:
      return const Color(0xFF3B82F6); // Blue border
  }
}

Color _getInfoTextColor(connection_svc.ConnectionState state, bool isManualOffline) {
  if (isManualOffline) return const Color(0xFF92400E); // Amber text
  switch (state) {
    case connection_svc.ConnectionState.online:
      return const Color(0xFF047857); // Green text
    case connection_svc.ConnectionState.offline:
      return const Color(0xFFDC2626); // Red text
    case connection_svc.ConnectionState.poor:
      return const Color(0xFFEA580C); // Orange text
    case connection_svc.ConnectionState.switching:
      return const Color(0xFF2563EB); // Blue text
  }
}

String _getInfoTitle(connection_svc.ConnectionState state, bool isManualOffline) {
  if (isManualOffline) return 'Manual Offline Mode Active';
  switch (state) {
    case connection_svc.ConnectionState.online:
      return 'Connected & Online';
    case connection_svc.ConnectionState.offline:
      return 'No Internet Connection';
    case connection_svc.ConnectionState.poor:
      return 'Poor Connection Detected';
    case connection_svc.ConnectionState.switching:
      return 'Checking Connection...';
  }
}

String _getInfoDescription(connection_svc.ConnectionState state, bool isManualOffline) {
  if (isManualOffline) {
    return 'All data is being saved locally. It will sync when you go back online.';
  }
  switch (state) {
    case connection_svc.ConnectionState.online:
      return 'Data is being saved to the cloud in real-time. All features available.';
    case connection_svc.ConnectionState.offline:
      return 'Working offline. Data is saved locally and will sync when connection returns.';
    case connection_svc.ConnectionState.poor:
      return 'Slow connection detected. Consider switching to offline mode for better performance.';
    case connection_svc.ConnectionState.switching:
      return 'Testing connection quality and determining best data mode...';
  }
}

void _showOfflineModeConfirmation(
    BuildContext context, connection_svc.ConnectionService connectionService, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        'Switch to Offline Mode?',
        style: GoogleFonts.inter(fontWeight: FontWeight.w700),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('This will:'),
          const SizedBox(height: 8),
          const Text('• Save all data locally on this device'),
          const Text('• Continue working without internet'),
          const Text('• Sync data when you go back online'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFF59E0B)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: Color(0xFF92400E), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Recommended when working in areas with unreliable internet.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            connectionService.setManualOfflineMode(true);
            Navigator.of(context).pop(); // Close confirmation
            Navigator.of(context).pop(); // Close main dialog
            _showModeChangeNotification(
                context,
                'Switched to Offline Mode',
                'All data will be saved locally and synced later.',
                Icons.wifi_off);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF59E0B),
            foregroundColor: Colors.white,
          ),
          child: const Text('Go Offline'),
        ),
      ],
    ),
  );
}

void _showOnlineModeConfirmation(
    BuildContext context, connection_svc.ConnectionService connectionService, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        'Switch to Online Mode?',
        style: GoogleFonts.inter(fontWeight: FontWeight.w700),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('This will:'),
          const SizedBox(height: 8),
          const Text('• Resume cloud synchronization'),
          const Text('• Upload any pending offline data'),
          const Text('• Enable real-time data backup'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFD1FAE5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF10B981)),
            ),
            child: Row(
              children: [
                const Icon(Icons.cloud_upload,
                    color: Color(0xFF047857), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your data will be automatically synced to the cloud.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF047857),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            connectionService.setManualOfflineMode(false);
            Navigator.of(context).pop(); // Close confirmation
            Navigator.of(context).pop(); // Close main dialog
            _showModeChangeNotification(context, 'Switched to Online Mode',
                'Data syncing to cloud resumed.', Icons.cloud_done);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
          ),
          child: const Text('Go Online'),
        ),
      ],
    ),
  );
}

void _showOfflineModeRecommendation(
    BuildContext context, connection_svc.ConnectionService connectionService, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.signal_wifi_bad, color: Color(0xFFF97316)),
          const SizedBox(width: 8),
          Text(
            'Poor Connection Detected',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
              'We recommend switching to offline mode for better performance in this area.'),
          const SizedBox(height: 12),
          const Text('Offline mode will:'),
          const SizedBox(height: 8),
          const Text('• Prevent data loss from connection timeouts'),
          const Text('• Provide faster, more reliable data entry'),
          const Text('• Automatically sync when connection improves'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Stay Online'),
        ),
        ElevatedButton(
          onPressed: () {
            connectionService.setManualOfflineMode(true);
            Navigator.of(context).pop(); // Close recommendation
            Navigator.of(context).pop(); // Close main dialog
            _showModeChangeNotification(context, 'Switched to Offline Mode',
                'Better performance in poor connection areas.', Icons.wifi_off);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF59E0B),
            foregroundColor: Colors.white,
          ),
          child: const Text('Use Offline Mode'),
        ),
      ],
    ),
  );
}

void _showModeChangeNotification(
    BuildContext context, String title, String message, IconData icon) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  message,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF1F2937),
      duration: const Duration(seconds: 4),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}

class _MissingLogsBanner extends StatelessWidget {
  final List<int> missingHours;

  const _MissingLogsBanner({required this.missingHours});

  @override
  Widget build(BuildContext context) {
    final missingHoursText = missingHours
        .map((hour) => '${hour.toString().padLeft(2, '0')}:00')
        .join(', ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFF59E0B).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.warning_outlined,
              color: Color(0xFFD97706),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Missing Logs',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFD97706),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  missingHoursText,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF92400E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool isFullWidth;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
            if (isFullWidth) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'View Details',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward,
                    color: color,
                    size: 16,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LogTypeRequirementsCard extends ConsumerWidget {
  final String projectId;
  final DailySummaryStats stats;

  const _LogTypeRequirementsCard({
    required this.projectId,
    required this.stats,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get cached project to determine log type requirements
    final cachedProjectAsync =
        ref.watch(FutureProvider<CachedProject?>((ref) async {
      return await LocalDatabaseService.getCachedProject(projectId);
    }));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.checklist,
                  color: Color(0xFF8B5CF6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Log Requirements',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          cachedProjectAsync.when(
            data: (project) {
              final logTypes = project?.metadata['logTypes'] ??
                  ['Hourly Readings', 'Daily Metrics'];
              final requiredReadings =
                  project?.metadata['requiredHourlyReadings'] ?? 24;

              return Column(
                children: [
                  _RequirementItem(
                    label: 'Log Types',
                    value: (logTypes as List).join(', '),
                    icon: Icons.category,
                  ),
                  const SizedBox(height: 12),
                  _RequirementItem(
                    label: 'Required Hourly Readings',
                    value: '$requiredReadings per day',
                    icon: Icons.schedule,
                  ),
                  const SizedBox(height: 12),
                  _RequirementItem(
                    label: 'Current Progress',
                    value:
                        '${stats.completedEntries} / $requiredReadings completed',
                    icon: Icons.trending_up,
                    color: stats.completedEntries >= requiredReadings
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B),
                  ),
                  if (stats.isFinalized) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF10B981).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.lock,
                            size: 16,
                            color: Color(0xFF059669),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Day Finalized',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
              ),
            ),
            error: (_, __) => Column(
              children: [
                _RequirementItem(
                  label: 'Log Types',
                  value: 'Hourly Readings, Daily Metrics',
                  icon: Icons.category,
                ),
                const SizedBox(height: 12),
                _RequirementItem(
                  label: 'Required Hourly Readings',
                  value: '24 per day',
                  icon: Icons.schedule,
                ),
                const SizedBox(height: 12),
                _RequirementItem(
                  label: 'Current Progress',
                  value: '${stats.completedEntries} / 24 completed',
                  icon: Icons.trending_up,
                  color: stats.completedEntries >= 24
                      ? const Color(0xFF10B981)
                      : const Color(0xFFF59E0B),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HourlyStatusGrid extends ConsumerWidget {
  final String projectId;
  final DateTime selectedDate;

  const _HourlyStatusGrid({
    required this.projectId,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logEntriesAsync = ref.watch(dailyLogEntriesProvider(selectedDate));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.grid_view,
                  color: Color(0xFF3B82F6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Hourly Status',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          logEntriesAsync.when(
            data: (entries) {
              // Create a map of hour to status
              final hourStatusMap = <int, String>{};
              for (final entry in entries) {
                final hour = int.tryParse(entry.hour) ?? -1;
                if (hour >= 0 && hour < 24) {
                  hourStatusMap[hour] = entry.status;
                }
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.2,
                ),
                itemCount: 24,
                itemBuilder: (context, index) {
                  final status = hourStatusMap[index];
                  return _HourStatusTile(
                    hour: index,
                    status: status,
                    onTap: status == null
                        ? () {
                            // Navigate to hour selector for this specific hour
                            HapticFeedback.lightImpact();
                            context.goToHourSelector(
                              projectId,
                              'log_$index', // Generate a log ID based on hour
                              extra: {
                                'selectedHour': index,
                                'selectedDate': selectedDate,
                              },
                            );
                          }
                        : null,
                  );
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
              ),
            ),
            error: (error, _) => Center(
              child: Text(
                'Error loading hourly status',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFFEF4444),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatusLegendItem(
                color: const Color(0xFF10B981),
                label: 'Completed',
              ),
              _StatusLegendItem(
                color: const Color(0xFFF59E0B),
                label: 'In Progress',
              ),
              _StatusLegendItem(
                color: const Color(0xFFE2E8F0),
                label: 'Not Started',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HourStatusTile extends StatelessWidget {
  final int hour;
  final String? status;
  final VoidCallback? onTap;

  const _HourStatusTile({
    required this.hour,
    this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    IconData? icon;

    switch (status) {
      case 'completed':
        backgroundColor = const Color(0xFF10B981);
        textColor = Colors.white;
        icon = Icons.check;
        break;
      case 'in_progress':
      case 'pending':
        backgroundColor = const Color(0xFFF59E0B);
        textColor = Colors.white;
        icon = Icons.schedule;
        break;
      default:
        backgroundColor = const Color(0xFFE2E8F0);
        textColor = const Color(0xFF64748B);
        icon = null;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: status == null
              ? Border.all(
                  color: const Color(0xFFCBD5E1),
                  width: 1,
                )
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${hour.toString().padLeft(2, '0')}:00',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            if (icon != null) ...[
              const SizedBox(height: 2),
              Icon(
                icon,
                size: 14,
                color: textColor,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusLegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _StatusLegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}

class _RequirementItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _RequirementItem({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final displayColor = color ?? const Color(0xFF64748B);

    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: displayColor,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: displayColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _OperatorInfo extends StatelessWidget {
  final String operatorName;

  const _OperatorInfo({required this.operatorName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          OperatorBadge(
            initials: operatorName.split(' ').map((n) => n[0]).join(),
            size: 40,
            isOnline: true,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Operator',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
              Text(
                operatorName,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Online',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF059669),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
