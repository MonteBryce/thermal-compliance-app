import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../routes/route_extensions.dart';

/// Navigation context widget that provides breadcrumbs and navigation state
class NavigationContextWidget extends StatelessWidget {
  final Widget child;
  final bool showBreadcrumbs;
  final bool showBackButton;
  final Color? backgroundColor;

  const NavigationContextWidget({
    super.key,
    required this.child,
    this.showBreadcrumbs = true,
    this.showBackButton = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showBreadcrumbs) _buildBreadcrumbs(context),
        Expanded(child: child),
      ],
    );
  }

  Widget _buildBreadcrumbs(BuildContext context) {
    final breadcrumbs = context.getCurrentBreadcrumbs();
    
    if (breadcrumbs.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: backgroundColor ?? Colors.grey[100],
      child: Row(
        children: [
          if (showBackButton && context.canPop())
            IconButton(
              icon: const Icon(Icons.arrow_back, size: 20),
              onPressed: () => context.pop(),
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
            ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _buildBreadcrumbItems(context, breadcrumbs),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBreadcrumbItems(BuildContext context, Map<String, String> breadcrumbs) {
    final items = <Widget>[];
    final entries = breadcrumbs.entries.toList();

    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final isLast = i == entries.length - 1;

      // Breadcrumb item
      items.add(
        GestureDetector(
          onTap: isLast ? null : () => context.go(entry.value),
          child: Text(
            entry.key,
            style: TextStyle(
              color: isLast ? Colors.black87 : Colors.blue[700],
              fontWeight: isLast ? FontWeight.w600 : FontWeight.normal,
              fontSize: 14,
              decoration: isLast ? null : TextDecoration.underline,
            ),
          ),
        ),
      );

      // Separator
      if (!isLast) {
        items.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              Icons.chevron_right,
              size: 16,
              color: Colors.grey[600],
            ),
          ),
        );
      }
    }

    return items;
  }
}

/// Enhanced AppBar with navigation context
class ContextualAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBreadcrumbs;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final PreferredSizeWidget? bottom;

  const ContextualAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBreadcrumbs = true,
    this.backgroundColor,
    this.foregroundColor,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final breadcrumbs = context.getCurrentBreadcrumbs();
    final hasNavigation = breadcrumbs.isNotEmpty && showBreadcrumbs;

    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              color: foregroundColor ?? Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (hasNavigation) _buildCompactBreadcrumbs(context, breadcrumbs),
        ],
      ),
      backgroundColor: backgroundColor ?? Colors.blue[800],
      foregroundColor: foregroundColor ?? Colors.white,
      actions: [
        ...?actions,
        _buildNavigationMenu(context),
      ],
      bottom: bottom,
      titleSpacing: 16,
    );
  }

  Widget _buildCompactBreadcrumbs(BuildContext context, Map<String, String> breadcrumbs) {
    final entries = breadcrumbs.entries.toList();
    if (entries.length <= 1) return const SizedBox.shrink();

    final currentEntry = entries.last;
    final parentEntry = entries[entries.length - 2];

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go(parentEntry.value),
            child: Text(
              parentEntry.key,
              style: TextStyle(
                color: (foregroundColor ?? Colors.white).withOpacity(0.7),
                fontSize: 12,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              Icons.chevron_right,
              size: 12,
              color: (foregroundColor ?? Colors.white).withOpacity(0.7),
            ),
          ),
          Flexible(
            child: Text(
              currentEntry.key,
              style: TextStyle(
                color: (foregroundColor ?? Colors.white).withOpacity(0.9),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: foregroundColor ?? Colors.white,
      ),
      onSelected: (value) => _handleMenuAction(context, value),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'home',
          child: ListTile(
            leading: Icon(Icons.home),
            title: Text('Go to Projects'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        if (context.isValidProjectRoute()) ...[
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'project_summary',
            child: ListTile(
              leading: Icon(Icons.dashboard),
              title: Text('Project Summary'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
        if (context.isValidLogRoute()) ...[
          const PopupMenuItem(
            value: 'hour_selector',
            child: ListTile(
              leading: Icon(Icons.access_time),
              title: Text('Hour Selection'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const PopupMenuItem(
            value: 'review_entries',
            child: ListTile(
              leading: Icon(Icons.rate_review),
              title: Text('Review Entries'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ],
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    final projectId = context.getCurrentProjectId();
    final logDate = context.getCurrentLogDate();

    switch (action) {
      case 'home':
        context.goToProjects();
        break;
      case 'project_summary':
        if (projectId != null) {
          context.goToProjectSummary(projectId);
        }
        break;
      case 'hour_selector':
        if (projectId != null && logDate != null) {
          context.goToHourSelector(projectId, logDate);
        }
        break;
      case 'review_entries':
        if (projectId != null && logDate != null) {
          context.goToReviewAll(projectId, logDate);
        }
        break;
    }
  }

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (bottom?.preferredSize.height ?? 0) + (showBreadcrumbs ? 20 : 0),
  );
}

/// Navigation status indicator widget
class NavigationStatusWidget extends StatelessWidget {
  final bool isOffline;
  final bool hasUnsyncedData;
  final VoidCallback? onSyncPressed;

  const NavigationStatusWidget({
    super.key,
    this.isOffline = false,
    this.hasUnsyncedData = false,
    this.onSyncPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOffline && !hasUnsyncedData) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isOffline)
            Container(
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
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          if (hasUnsyncedData) ...[
            if (isOffline) const SizedBox(width: 8),
            GestureDetector(
              onTap: onSyncPressed,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange[600],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sync_problem, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      'Unsynced',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}