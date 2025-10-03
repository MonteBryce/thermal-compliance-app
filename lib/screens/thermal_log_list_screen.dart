import 'package:flutter/material.dart';
import '../models/thermal_log.dart';
import '../services/thermal_log_service.dart';
import '../services/thermal_log_firestore_service.dart';
import '../services/auth_service.dart';
import 'thermal_log_entry_screen.dart';

class ThermalLogListScreen extends StatefulWidget {
  final String projectId;

  const ThermalLogListScreen({
    super.key,
    required this.projectId,
  });

  @override
  State<ThermalLogListScreen> createState() => _ThermalLogListScreenState();
}

class _ThermalLogListScreenState extends State<ThermalLogListScreen> {
  bool _isLoading = true;
  List<ThermalLog> _thermalLogs = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadThermalLogs();
  }

  Future<void> _loadThermalLogs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Load from local storage first (always available)
      final localLogs = await ThermalLogService.getAll();
      final projectLogs = localLogs
          .where((log) => log.projectId == widget.projectId)
          .toList();

      setState(() {
        _thermalLogs = projectLogs;
        _isLoading = false;
      });

      // Try to sync from Firestore if authenticated
      if (AuthService.isAuthenticated) {
        try {
          final cloudLogs = await ThermalLogFirestoreService.getByProjectId(widget.projectId);
          setState(() {
            _thermalLogs = cloudLogs;
          });
        } catch (e) {
          print('Failed to load from Firestore (offline?): $e');
          // Continue with local data
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading thermal logs: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteThermalLog(ThermalLog log) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Thermal Log'),
        content: Text(
          'Are you sure you want to delete the thermal log from ${log.timestamp.toLocal().toString().split('.')[0]}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Delete from local storage
        await ThermalLogService.delete(log.id);

        // Delete from Firestore if authenticated
        if (AuthService.isAuthenticated) {
          try {
            await ThermalLogFirestoreService.delete(log.id);
          } catch (e) {
            print('Failed to delete from Firestore: $e');
          }
        }

        // Reload the list
        await _loadThermalLogs();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thermal log deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting thermal log: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _editThermalLog(ThermalLog log) async {
    final result = await Navigator.of(context).push<ThermalLog>(
      MaterialPageRoute(
        builder: (context) => ThermalLogEntryScreen(
          projectId: widget.projectId,
          existingLog: log,
        ),
      ),
    );

    if (result != null) {
      // Reload the list to show updated data
      await _loadThermalLogs();
    }
  }

  Future<void> _addNewThermalLog() async {
    final result = await Navigator.of(context).push<ThermalLog>(
      MaterialPageRoute(
        builder: (context) => ThermalLogEntryScreen(
          projectId: widget.projectId,
        ),
      ),
    );

    if (result != null) {
      // Reload the list to show new data
      await _loadThermalLogs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thermal Logs'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadThermalLogs,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewThermalLog,
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Project Info Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Project: ${widget.projectId}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${_thermalLogs.length} thermal log${_thermalLogs.length != 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadThermalLogs,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _thermalLogs.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.thermostat_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No thermal logs yet',
                                    style: Theme.of(context).textTheme.headlineSmall,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap the + button to add your first thermal log',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadThermalLogs,
                            child: ListView.builder(
                              itemCount: _thermalLogs.length,
                              itemBuilder: (context, index) {
                                final log = _thermalLogs[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.orange,
                                      child: Text(
                                        '${log.temperature.toInt()}°',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      '${log.temperature}°F',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          log.timestamp.toLocal().toString().split('.')[0],
                                        ),
                                        if (log.notes.isNotEmpty)
                                          Text(
                                            log.notes,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                      ],
                                    ),
                                    trailing: PopupMenuButton<String>(
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          _editThermalLog(log);
                                        } else if (value == 'delete') {
                                          _deleteThermalLog(log);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: ListTile(
                                            leading: Icon(Icons.edit),
                                            title: Text('Edit'),
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: ListTile(
                                            leading: Icon(Icons.delete, color: Colors.red),
                                            title: Text('Delete'),
                                          ),
                                        ),
                                      ],
                                    ),
                                    onTap: () => _editThermalLog(log),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}