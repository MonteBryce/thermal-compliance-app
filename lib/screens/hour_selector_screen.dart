import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:go_router/go_router.dart';
import '../routes/route_extensions.dart';
import '../services/path_helper.dart';
import 'daily_summary_screen.dart';

class HourSelectorScreen extends ConsumerStatefulWidget {
  final String projectNumber; // ✅ updated from projectId
  final String logId;
  final String logType; // ✅ added if needed for downstream use

  const HourSelectorScreen({
    super.key,
    required this.projectNumber,
    required this.logId,
    required this.logType,
  });

  @override
  ConsumerState<HourSelectorScreen> createState() => _HourSelectorScreenState();
}

class _HourSelectorScreenState extends ConsumerState<HourSelectorScreen> {
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isOffline = connectivityResult == ConnectivityResult.none;
    });
    
    // Listen for connectivity changes
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (mounted) {
        setState(() {
          _isOffline = result == ConnectivityResult.none;
        });
      }
    });
  }

  IconData _getStatusIcon(bool isLogged, bool needsReview) {
    if (isLogged && needsReview) return Icons.refresh;
    if (isLogged) return Icons.check_circle;
    return Icons.hourglass_empty;
  }

  Color _getStatusColor(bool isLogged, bool needsReview) {
    if (isLogged && needsReview) return Colors.orange;
    if (isLogged) return Colors.green;
    return Colors.grey;
  }

  String _getStatusText(bool isLogged, bool needsReview) {
    if (isLogged && needsReview) return 'Needs Review';
    if (isLogged) return 'Completed';
    return 'Not Started';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entriesRef = PathHelper.entriesCollectionRef(
      FirebaseFirestore.instance,
      widget.projectNumber,
      widget.logId,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Hourly Log Selection',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          if (_isOffline)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red[600],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off, size: 14, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    'Offline',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          try {
            print('🚀 Navigating to Daily Summary Test...');
            
            // Direct push navigation to test screen
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => DailySummaryScreen(
                  projectId: widget.projectNumber,
                  logId: widget.logId,
                  selectedDate: DateTime.now(),
                ),
              ),
            );
          } catch (e) {
            print('❌ Navigation error: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Navigation failed: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        icon: const Icon(Icons.dashboard),
        label: const Text('Daily Summary'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: entriesRef.snapshots(),
        builder: (context, snapshot) {
          final entryDocs = snapshot.data?.docs ?? [];

          final Map<String, Map<String, dynamic>> hourToEntryData = {
            for (var doc in entryDocs)
              if ((doc.data() as Map<String, dynamic>).containsKey('hour'))
                ((doc.data() as Map<String, dynamic>)['hour'])
                    .toString()
                    .padLeft(2, '0'): {
                  'docId': doc.id,
                  'data': doc.data() as Map<String, dynamic>,
                }
          };

          // Group hours by AM/PM
          final amHours = List.generate(12, (i) => i); // 0-11
          final pmHours = List.generate(12, (i) => i + 12); // 12-23

          return CustomScrollView(
            slivers: [
              // AM Section
              SliverPersistentHeader(
                pinned: true,
                delegate: _SectionHeaderDelegate(
                  title: 'AM Hours (12:00 AM - 11:59 AM)',
                  theme: theme,
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildHourTile(
                    context,
                    amHours[index],
                    hourToEntryData,
                    theme,
                  ),
                  childCount: amHours.length,
                ),
              ),
              
              // PM Section
              SliverPersistentHeader(
                pinned: true,
                delegate: _SectionHeaderDelegate(
                  title: 'PM Hours (12:00 PM - 11:59 PM)',
                  theme: theme,
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildHourTile(
                    context,
                    pmHours[index],
                    hourToEntryData,
                    theme,
                  ),
                  childCount: pmHours.length,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHourTile(
    BuildContext context,
    int hour,
    Map<String, Map<String, dynamic>> hourToEntryData,
    ThemeData theme,
  ) {
    final hourStr = hour.toString().padLeft(2, '0');
    final entryData = hourToEntryData[hourStr];
    final isLogged = entryData != null;
    final needsReview = isLogged && (entryData['data']['validated'] == false);
    
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final amPm = hour < 12 ? 'AM' : 'PM';
    final timeRange = '$displayHour:00 - $displayHour:59 $amPm';
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 2,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minVerticalPadding: 16,
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getStatusColor(isLogged, needsReview).withAlpha(25),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _getStatusColor(isLogged, needsReview),
                width: 2,
              ),
            ),
            child: Icon(
              _getStatusIcon(isLogged, needsReview),
              color: _getStatusColor(isLogged, needsReview),
              size: 24,
            ),
          ),
          title: Text(
            timeRange,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            _getStatusText(isLogged, needsReview),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: _getStatusColor(isLogged, needsReview),
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.blue,
              size: 20,
            ),
          ),
          onTap: () {
            context.goToHourlyEntry(
              widget.projectNumber,
              widget.logId,
              hour,
              extra: {
                'logType': widget.logType,
                'existingData': entryData?['data'],
                'enteredHours': hourToEntryData.keys.map((h) => int.parse(h)).toSet(),
              },
            );
          },
        ),
      ),
    );
  }
}

class _SectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final ThemeData theme;

  _SectionHeaderDelegate({required this.title, required this.theme});

  @override
  double get minExtent => 56.0; // Increased to account for padding

  @override
  double get maxExtent => 56.0; // Same as minExtent for non-collapsing header

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      height: maxExtent, // Explicitly set height to match extent
      color: Colors.grey[100],
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(
            Icons.access_time,
            color: Colors.blue[700],
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SectionHeaderDelegate oldDelegate) {
    return title != oldDelegate.title;
  }
}
