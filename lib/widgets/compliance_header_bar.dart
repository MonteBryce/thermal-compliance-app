/// Compliance Dashboard Header Bar
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ComplianceHeaderBar extends StatefulWidget {
  final VoidCallback? onRefresh;
  final VoidCallback? onNewJob;
  final VoidCallback? onExport;
  final VoidCallback? onSettings;
  final String? searchQuery;
  final Function(String)? onSearchChanged;

  const ComplianceHeaderBar({
    super.key,
    this.onRefresh,
    this.onNewJob,
    this.onExport,
    this.onSettings,
    this.searchQuery,
    this.onSearchChanged,
  });

  @override
  State<ComplianceHeaderBar> createState() => _ComplianceHeaderBarState();
}

class _ComplianceHeaderBarState extends State<ComplianceHeaderBar> {
  final _searchController = TextEditingController();
  DateTime _lastSync = DateTime.now();

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.searchQuery ?? '';
    _updateSyncTime();
  }

  void _updateSyncTime() {
    setState(() {
      _lastSync = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 96,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            border: Border(
              bottom: BorderSide(
                color: Color(0xFF2A2A2A),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Title and Sync Status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Project Dashboard',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Last sync: ${DateFormat('HH:mm').format(_lastSync)}',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Search Bar
              Container(
                width: 300,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF2A2A2A),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search projects...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF6B7280),
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF6B7280),
                      size: 18,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  onChanged: widget.onSearchChanged,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Action Buttons
              _buildActionButton(
                icon: Icons.refresh,
                tooltip: 'Refresh',
                onPressed: () {
                  widget.onRefresh?.call();
                  _updateSyncTime();
                },
              ),
              
              const SizedBox(width: 12),
              
              _buildActionButton(
                icon: Icons.add,
                tooltip: 'New Job',
                onPressed: widget.onNewJob,
                isPrimary: true,
              ),
              
              const SizedBox(width: 12),
              
              _buildActionButton(
                icon: Icons.download,
                tooltip: 'Export',
                onPressed: widget.onExport,
              ),
              
              const SizedBox(width: 16),
              
              // User Avatar
              GestureDetector(
                onTap: () {
                  // Show user menu
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF2A2A2A),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'A',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              _buildActionButton(
                icon: Icons.settings,
                tooltip: 'Settings',
                onPressed: widget.onSettings,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    VoidCallback? onPressed,
    bool isPrimary = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isPrimary 
                ? const Color(0xFF3B82F6) 
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isPrimary 
                  ? const Color(0xFF3B82F6) 
                  : const Color(0xFF2A2A2A),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isPrimary 
                ? Colors.white 
                : const Color(0xFF9CA3AF),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

