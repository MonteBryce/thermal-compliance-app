/// Admin Dashboard Header with dark mode toggle and sync info
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/admin_dashboard_providers.dart';

class AdminHeader extends ConsumerWidget {
  const AdminHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDarkMode = ref.watch(darkModeProvider);
    final summary = ref.watch(dashboardSummaryProvider).value;
    
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            // Page Title and Breadcrumb
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dashboard',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Monitor and manage all thermal logging projects',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            
            // Last Sync Info
            if (summary != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF374151) : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDarkMode ? const Color(0xFF4B5563) : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.sync,
                      size: 16,
                      color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Last sync: ${_formatLastSync(summary.lastSync)}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
            ],
            
            // Refresh Button
            IconButton(
              onPressed: () {
                // Trigger refresh
                ref.invalidate(dashboardSummaryProvider);
                ref.invalidate(adminJobsProvider);
              },
              icon: Icon(
                Icons.refresh,
                color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              ),
              tooltip: 'Refresh Data',
            ),
            
            const SizedBox(width: 8),
            
            // Dark Mode Toggle
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDarkMode ? const Color(0xFF4B5563) : const Color(0xFFE5E7EB),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildThemeToggleButton(
                    icon: Icons.light_mode,
                    isActive: !isDarkMode,
                    onTap: () => ref.read(darkModeProvider.notifier).state = false,
                    isDarkMode: isDarkMode,
                  ),
                  _buildThemeToggleButton(
                    icon: Icons.dark_mode,
                    isActive: isDarkMode,
                    onTap: () => ref.read(darkModeProvider.notifier).state = true,
                    isDarkMode: isDarkMode,
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Notifications
            IconButton(
              onPressed: () {
                // Show notifications
              },
              icon: Badge(
                smallSize: 8,
                backgroundColor: const Color(0xFFEF4444),
                child: Icon(
                  Icons.notifications_outlined,
                  color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                ),
              ),
              tooltip: 'Notifications',
            ),
            
            const SizedBox(width: 8),
            
            // User Menu
            PopupMenuButton<String>(
              offset: const Offset(0, 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDarkMode ? const Color(0xFF4B5563) : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFF3B82F6),
                      child: Text(
                        'A',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 16,
                      color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                    ),
                  ],
                ),
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline, size: 16),
                      const SizedBox(width: 8),
                      Text('Profile', style: GoogleFonts.inter(fontSize: 14)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      const Icon(Icons.settings_outline, size: 16),
                      const SizedBox(width: 8),
                      Text('Settings', style: GoogleFonts.inter(fontSize: 14)),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      const Icon(Icons.logout, size: 16, color: Color(0xFFEF4444)),
                      const SizedBox(width: 8),
                      Text('Logout', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFFEF4444))),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'logout':
                    // Handle logout
                    break;
                  case 'profile':
                    // Handle profile
                    break;
                  case 'settings':
                    // Handle settings
                    break;
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeToggleButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF3B82F6)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isActive
              ? Colors.white
              : isDarkMode 
                  ? const Color(0xFF9CA3AF) 
                  : const Color(0xFF6B7280),
        ),
      ),
    );
  }

  String _formatLastSync(DateTime lastSync) {
    final now = DateTime.now();
    final difference = now.difference(lastSync);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('MMM d, HH:mm').format(lastSync);
    }
  }
}
