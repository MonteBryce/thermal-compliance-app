import 'package:universal_html/html.dart' as html;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/hourly_entry_form.dart';
import '../models/thermal_reading.dart';
import '../services/thermal_reading_service.dart';
import '../routes/route_extensions.dart';
import '../providers/report_providers.dart';

enum EntryStatus { completed, missing, edited, warning }

class HourlyEntry {
  final int hour;
  final ThermalReading? data;
  final EntryStatus status;
  final String? summary;

  HourlyEntry({
    required this.hour,
    this.data,
    required this.status,
    this.summary,
  });
}

class ReviewEntriesView extends ConsumerStatefulWidget {
  final String? projectId;
  final String? logId;
  
  const ReviewEntriesView({
    super.key,
    this.projectId,
    this.logId,
  });

  @override
  ConsumerState<ReviewEntriesView> createState() => _ReviewEntriesViewState();
}

class _ReviewEntriesViewState extends ConsumerState<ReviewEntriesView> 
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  List<ThermalReading> thermalData = [];
  String? projectId;
  String? logId;
  final _thermalReadingService = ThermalReadingService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    // Use widget parameters directly
    projectId = widget.projectId;
    logId = widget.logId;
    
    // Load thermal data from Firestore
    if (projectId != null && logId != null) {
      _loadThermalData();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Only try to load from route if we don't have widget parameters
    if (projectId == null || logId == null) {
      _tryLoadFromRoute();
    }
  }

  void _tryLoadFromRoute() {
    try {
      // Get data from go_router extra parameter as fallback
      final routeState = GoRouterState.of(context);
      final args = routeState.extra as Map<String, dynamic>?;
      
      if (args != null) {
        setState(() {
          projectId = projectId ?? args['projectId'] as String?;
          logId = logId ?? args['logId'] as String?;
        });
        
        // Load thermal data from Firestore
        if (projectId != null && logId != null) {
          _loadThermalData();
        }
      }
    } catch (e) {
      // Fallback to empty state if there are any casting issues
      debugPrint('Error loading review data from route: $e');
      if (mounted) {
        setState(() {
          thermalData = [];
          projectId = null;
          logId = null;
        });
      }
    }
  }

  Future<void> _loadThermalData() async {
    if (projectId == null || logId == null) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final loadedData = await _thermalReadingService.loadThermalReadings(
        projectId: projectId!,
        logId: logId!,
      );
      
      if (mounted) {
        setState(() {
          thermalData = loadedData;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading thermal data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatHour(int hour) {
    final isPM = hour >= 12;
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:00';
  }

  String _formatHourWithPeriod(int hour) {
    final isPM = hour >= 12;
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:00 ${isPM ? 'PM' : 'AM'}';
  }

  EntryStatus _getEntryStatus(ThermalReading? entry) {
    if (entry == null) return EntryStatus.missing;

    // Check for warning conditions
    if (entry.vacuumAtTankVaporOutlet != null &&
        entry.vacuumAtTankVaporOutlet! < 2) {
      return EntryStatus.warning;
    }

    if (entry.exhaustTemperature != null &&
        (entry.exhaustTemperature! < 300 || entry.exhaustTemperature! > 1200)) {
      return EntryStatus.warning;
    }

    // Check if recently edited (within last hour)
    final now = DateTime.now();
    final entryTime = DateTime.parse(entry.timestamp);
    if (now.difference(entryTime).inHours < 1) {
      return EntryStatus.edited;
    }

    return EntryStatus.completed;
  }

  Widget _getStatusIcon(EntryStatus status) {
    switch (status) {
      case EntryStatus.completed:
        return Container(
          padding: const EdgeInsets.all(6),
          decoration: const BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            color: Colors.white,
            size: 16,
          ),
        );
      case EntryStatus.missing:
        return Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.grey.shade400,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.schedule,
            color: Colors.white,
            size: 16,
          ),
        );
      case EntryStatus.edited:
        return Container(
          padding: const EdgeInsets.all(6),
          decoration: const BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.edit,
            color: Colors.white,
            size: 16,
          ),
        );
      case EntryStatus.warning:
        return Container(
          padding: const EdgeInsets.all(6),
          decoration: const BoxDecoration(
            color: Colors.orange,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.warning,
            color: Colors.white,
            size: 16,
          ),
        );
    }
  }

  String _getSummary(ThermalReading? entry) {
    if (entry == null) return 'No data entered';
    
    final List<String> summaryParts = [];
    
    if (entry.inletReading != null) {
      summaryParts.add('Inlet: ${entry.inletReading!.toStringAsFixed(1)} PPM');
    }
    if (entry.outletReading != null) {
      summaryParts.add('Outlet: ${entry.outletReading!.toStringAsFixed(1)} PPM');
    }
    if (entry.exhaustTemperature != null) {
      summaryParts.add('Temp: ${entry.exhaustTemperature!.toStringAsFixed(0)}°F');
    }
    
    return summaryParts.isNotEmpty ? summaryParts.join(' • ') : 'Partial data';
  }

  List<HourlyEntry> _getAllHours() {
    return List.generate(24, (i) {
      final existingEntry = thermalData.firstWhere(
        (entry) => entry.hour == i,
        orElse: () => ThermalReading(hour: i, timestamp: DateTime.now().toIso8601String()),
      );

      final hasData = existingEntry.inletReading != null || 
                     existingEntry.outletReading != null ||
                     existingEntry.exhaustTemperature != null ||
                     existingEntry.vacuumAtTankVaporOutlet != null;

      return HourlyEntry(
        hour: i,
        data: hasData ? existingEntry : null,
        status: _getEntryStatus(hasData ? existingEntry : null),
        summary: _getSummary(hasData ? existingEntry : null),
      );
    });
  }

  int _getCompletedCount() {
    return _getAllHours().where((entry) => 
      entry.status == EntryStatus.completed || 
      entry.status == EntryStatus.edited ||
      entry.status == EntryStatus.warning
    ).length;
  }

  Future<void> _navigateToHourlyEntry(int hour) async {
    // Load the specific entry data for this hour if it exists
    ThermalReading? existingEntry;
    
    if (projectId != null && logId != null) {
      try {
        existingEntry = await _thermalReadingService.loadThermalReadingForHour(
          projectId: projectId!,
          logId: logId!,
          hour: hour,
        );
      } catch (e) {
        debugPrint('Error loading entry for hour $hour: $e');
      }
    }

    // If no existing entry, create a new one (but keep it null if we want to load in the form)
    // Only create empty entry if we really couldn't load anything
    if (existingEntry == null) {
      debugPrint('⚠️ No existing entry found for hour $hour, will load in form');
    }

    if (mounted) {
      // Debug logging
      debugPrint('🚀 Navigating to hour $hour');
      debugPrint('📊 Existing entry: ${existingEntry?.toJson()}');
      debugPrint('📁 Project: ${projectId ?? 'unknown'}, Log: ${logId ?? 'unknown'}');
      
      final result = await context.goToHourlyEntry(
        projectId ?? 'unknown',
        logId ?? 'unknown',
        hour,
        extra: {
          'existingData': existingEntry,
          'logType': 'thermal',
          'enteredHours': thermalData.map((e) => e.hour).toSet(),
        },
      );

      // Reload data when returning from entry form
      if (result != null) {
        await _loadThermalData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    // Show loading state while data is being fetched
    if (_isLoading) {
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
            'Review All Entries',
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.blue),
              SizedBox(height: 16),
              Text(
                'Loading thermal readings...',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }
    
    final allHours = _getAllHours();
    final completedCount = _getCompletedCount();
    final amHours = allHours.where((h) => h.hour < 12).toList();
    final pmHours = allHours.where((h) => h.hour >= 12).toList();

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
          'Review All Entries',
          style: GoogleFonts.nunito(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadThermalData,
            tooltip: 'Refresh Data',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.download, color: Colors.white),
            tooltip: 'Export Options',
            onSelected: (value) {
              if (value == 'comprehensive') {
                _exportToExcel();
              } else if (value == 'vapor') {
                _exportVaporReport();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'comprehensive',
                child: Row(
                  children: [
                    Icon(Icons.table_chart, size: 20),
                    SizedBox(width: 8),
                    Text('Comprehensive Report'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'vapor',
                child: Row(
                  children: [
                    Icon(Icons.description, size: 20),
                    SizedBox(width: 8),
                    Text('Vapor Combustor Template'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress Indicator
          Container(
            margin: EdgeInsets.all(MediaQuery.of(context).size.width > 768 ? 20 : 16),
            padding: EdgeInsets.all(MediaQuery.of(context).size.width > 768 ? 24 : 20),
            decoration: BoxDecoration(
              color: const Color(0xFF152042),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress Overview',
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontSize: MediaQuery.of(context).size.width > 768 ? 20 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: completedCount == 24 ? Colors.green.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: completedCount == 24 ? Colors.green : Colors.blue,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '$completedCount/24 hours completed',
                        style: GoogleFonts.nunito(
                          color: completedCount == 24 ? Colors.green : Colors.blue,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: completedCount / 24,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      completedCount == 24 ? Colors.green : Colors.blue,
                    ),
                    minHeight: 10,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${((completedCount / 24) * 100).toStringAsFixed(0)}% complete • ${24 - completedCount} entries remaining',
                  style: GoogleFonts.nunito(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Scrollable Content
          Expanded(
            child: CustomScrollView(
              slivers: [
                // AM Section
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SectionHeaderDelegate(
                    title: '12:00 AM – 11:00 AM',
                    backgroundColor: const Color(0xFF0B132B),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final entry = amHours[index];
                        return _buildHourTile(entry);
                      },
                      childCount: amHours.length,
                    ),
                  ),
                ),

                // PM Section
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SectionHeaderDelegate(
                    title: '12:00 PM – 11:00 PM',
                    backgroundColor: const Color(0xFF0B132B),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final entry = pmHours[index];
                        return _buildHourTile(entry);
                      },
                      childCount: pmHours.length,
                    ),
                  ),
                ),
                
                // Bottom spacing
                const SliverPadding(
                  padding: EdgeInsets.only(bottom: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourTile(HourlyEntry entry) {
    final isDesktop = MediaQuery.of(context).size.width > 768;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: const Color(0xFF152042),
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _navigateToHourlyEntry(entry.hour),
          child: Padding(
            padding: EdgeInsets.all(isDesktop ? 20 : 16),
            child: Row(
              children: [
                // Hour Label
                SizedBox(
                  width: isDesktop ? 100 : 80,
                  child: Text(
                    _formatHourWithPeriod(entry.hour),
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontSize: isDesktop ? 18 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                SizedBox(width: isDesktop ? 24 : 16),
                
                // Summary/Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.summary ?? 'No data entered',
                        style: GoogleFonts.nunito(
                          color: entry.data != null ? Colors.white70 : Colors.white54,
                          fontSize: isDesktop ? 16 : 14,
                        ),
                        maxLines: isDesktop ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (entry.data?.observations.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(
                          entry.data!.observations,
                          style: GoogleFonts.nunito(
                            color: Colors.white54,
                            fontSize: isDesktop ? 14 : 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                
                SizedBox(width: isDesktop ? 24 : 16),
                
                // Status Icon
                _getStatusIcon(entry.status),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Export thermal readings to Excel
  Future<void> _exportToExcel() async {
    if (projectId == null || logId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Missing project or log information for export'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Show loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Generating Excel report...'),
            ],
          ),
        ),
      );
    }

    try {
      // Generate the project report
      await ref.read(reportGenerationProvider.notifier).generateProjectReport(
        projectId: projectId!,
        projectName: projectId,
      );

      // Listen for completion
      ref.listen<ReportGenerationState>(reportGenerationProvider, (previous, next) {
        next.when(
          idle: () {},
          generating: () {},
          completed: (reportData, fileName) async {
            // Close loading dialog
            if (mounted) {
              Navigator.of(context).pop();
            }

            try {
              // For web platform, trigger download using universal_html
              final blob = html.Blob([reportData]);
              final url = html.Url.createObjectUrlFromBlob(blob);
              final anchor = html.AnchorElement()
                ..href = url
                ..style.display = 'none'
                ..download = fileName;
              html.document.body!.append(anchor);
              anchor.click();
              html.document.body!.children.remove(anchor);
              html.Url.revokeObjectUrl(url);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Excel report downloaded: $fileName'),
                    backgroundColor: Colors.green,
                    action: SnackBarAction(
                      label: 'OK',
                      textColor: Colors.white,
                      onPressed: () {},
                    ),
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error downloading file: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }

            // Reset the state
            ref.read(reportGenerationProvider.notifier).reset();
          },
          onError: (error) {
            // Close loading dialog
            if (mounted) {
              Navigator.of(context).pop();
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error generating report: $error'),
                  backgroundColor: Colors.red,
                ),
              );
            }

            // Reset the state
            ref.read(reportGenerationProvider.notifier).reset();
          },
        );
      });
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) {
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initiating export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Export thermal readings to Excel using vapor combustor template
  Future<void> _exportVaporReport() async {
    if (projectId == null || logId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Missing project or log information for export'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Show loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Generating vapor report...'),
            ],
          ),
        ),
      );
    }

    try {
      // Use the first thermal reading date as the report date
      final reportDate = thermalData.isNotEmpty 
          ? DateTime.parse(thermalData.first.timestamp)
          : DateTime.now();

      // Generate the vapor report
      await ref.read(reportGenerationProvider.notifier).generateVaporReport(
        projectId: projectId!,
        date: reportDate,
        projectName: projectId,
      );

      // Listen for completion
      ref.listen<ReportGenerationState>(reportGenerationProvider, (previous, next) {
        next.when(
          idle: () {},
          generating: () {},
          completed: (reportData, fileName) async {
            // Close loading dialog
            if (mounted) {
              Navigator.of(context).pop();
            }

            try {
              // For web platform, trigger download using universal_html
              final blob = html.Blob([reportData]);
              final url = html.Url.createObjectUrlFromBlob(blob);
              final anchor = html.AnchorElement()
                ..href = url
                ..style.display = 'none'
                ..download = fileName;
              html.document.body!.append(anchor);
              anchor.click();
              html.document.body!.children.remove(anchor);
              html.Url.revokeObjectUrl(url);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Vapor report downloaded: $fileName'),
                    backgroundColor: Colors.green,
                    action: SnackBarAction(
                      label: 'OK',
                      textColor: Colors.white,
                      onPressed: () {},
                    ),
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error downloading file: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }

            // Reset the state
            ref.read(reportGenerationProvider.notifier).reset();
          },
          onError: (error) {
            // Close loading dialog
            if (mounted) {
              Navigator.of(context).pop();
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error generating vapor report: $error'),
                  backgroundColor: Colors.red,
                ),
              );
            }

            // Reset the state
            ref.read(reportGenerationProvider.notifier).reset();
          },
        );
      });
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) {
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initiating vapor export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _SectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final Color backgroundColor;

  _SectionHeaderDelegate({
    required this.title,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 48;

  @override
  double get minExtent => 48;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}