/// Admin Dashboard Sidebar Navigation
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminSidebar extends ConsumerWidget {
  const AdminSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        border: Border(
          right: BorderSide(
            color: isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Logo/Brand Section
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.dashboard,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Admin Dashboard',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : const Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
          
          // Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildNavGroup(
                  'MAIN',
                  [
                    _NavItem(
                      icon: Icons.dashboard_outlined,
                      label: 'Dashboard',
                      isActive: true,
                      onTap: () {},
                    ),
                    _NavItem(
                      icon: Icons.work_outline,
                      label: 'Projects',
                      badge: '12',
                      onTap: () {},
                    ),
                    _NavItem(
                      icon: Icons.analytics_outlined,
                      label: 'Analytics',
                      onTap: () {},
                    ),
                  ],
                  isDarkMode,
                ),
                
                const SizedBox(height: 24),
                
                _buildNavGroup(
                  'MANAGEMENT',
                  [
                    _NavItem(
                      icon: Icons.people_outline,
                      label: 'Operators',
                      onTap: () {},
                    ),
                    _NavItem(
                      icon: Icons.description_outlined,
                      label: 'Log Templates',
                      onTap: () {},
                    ),
                    _NavItem(
                      icon: Icons.file_download_outlined,
                      label: 'Export Reports',
                      onTap: () {},
                    ),
                  ],
                  isDarkMode,
                ),
                
                const SizedBox(height: 24),
                
                _buildNavGroup(
                  'SYSTEM',
                  [
                    _NavItem(
                      icon: Icons.settings_outline,
                      label: 'Settings',
                      onTap: () {},
                    ),
                    _NavItem(
                      icon: Icons.help_outline,
                      label: 'Help & Support',
                      onTap: () {},
                    ),
                  ],
                  isDarkMode,
                ),
              ],
            ),
          ),
          
          // User Profile Section
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF374151) : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF3B82F6),
                  child: Text(
                    'A',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Admin User',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? Colors.white : const Color(0xFF111827),
                        ),
                      ),
                      Text(
                        'admin@company.com',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.more_vert,
                  size: 16,
                  color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavGroup(String title, List<_NavItem> items, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...items.map((item) => _buildNavItem(item, isDarkMode)),
      ],
    );
  }

  Widget _buildNavItem(_NavItem item, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: item.isActive
                  ? const Color(0xFF3B82F6).withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: item.isActive
                  ? Border.all(color: const Color(0xFF3B82F6).withOpacity(0.2))
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 20,
                  color: item.isActive
                      ? const Color(0xFF3B82F6)
                      : isDarkMode 
                          ? const Color(0xFF9CA3AF) 
                          : const Color(0xFF6B7280),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: item.isActive ? FontWeight.w500 : FontWeight.w400,
                      color: item.isActive
                          ? const Color(0xFF3B82F6)
                          : isDarkMode 
                              ? Colors.white 
                              : const Color(0xFF111827),
                    ),
                  ),
                ),
                if (item.badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      item.badge!,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String? badge;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    this.badge,
    this.isActive = false,
    required this.onTap,
  });
}
