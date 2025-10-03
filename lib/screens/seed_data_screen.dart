import 'package:flutter/material.dart';
import '../services/screenshot_data_seeder.dart';

/// Screen to seed data for portfolio screenshots
/// Navigate to this screen before taking screenshots: /seed-data
class SeedDataScreen extends StatefulWidget {
  const SeedDataScreen({super.key});

  @override
  State<SeedDataScreen> createState() => _SeedDataScreenState();
}

class _SeedDataScreenState extends State<SeedDataScreen> {
  final _seeder = ScreenshotDataSeeder();
  bool _isSeeding = false;
  String _status = 'Ready to seed data';
  final List<String> _logs = [];

  Future<void> _seedData() async {
    setState(() {
      _isSeeding = true;
      _status = 'Seeding data...';
      _logs.clear();
    });

    try {
      _addLog('🌱 Starting data seeding...');

      await _seeder.seedProjects();
      _addLog('✅ Projects seeded');

      await _seeder.seedLogEntriesForMarathonProject();
      _addLog('✅ Marathon log entries seeded (20 complete, 3 missing)');

      await _seeder.seedPartialLogForActiveProject();
      _addLog('✅ P66 partial log seeded (15 of 24 hours)');

      await _seeder.seedHourSelectorData();
      _addLog('✅ Hour selector data seeded');

      setState(() {
        _status = 'Data seeding complete! ✅';
        _isSeeding = false;
      });

      _addLog('');
      _addLog('📸 Ready for screenshots!');
      _addLog('Date: July 15, 2025');
      _addLog('Operators: John Smith, Sarah Johnson, Mike Davis');

    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _isSeeding = false;
      });
      _addLog('❌ Error: $e');
    }
  }

  Future<void> _clearData() async {
    setState(() {
      _isSeeding = true;
      _status = 'Clearing data...';
      _logs.clear();
    });

    try {
      _addLog('🗑️  Clearing screenshot data...');
      await _seeder.clearScreenshotData();

      setState(() {
        _status = 'Data cleared! ✅';
        _isSeeding = false;
      });

      _addLog('✅ All screenshot data removed');

    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _isSeeding = false;
      });
      _addLog('❌ Error: $e');
    }
  }

  void _addLog(String message) {
    setState(() {
      _logs.add(message);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Screenshot Data Seeder'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isSeeding ? Icons.hourglass_empty : Icons.data_object,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Data Seeding Tool',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _status,
                      style: TextStyle(
                        fontSize: 16,
                        color: _isSeeding ? Colors.orange : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSeeding ? null : _seedData,
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text('Seed Data'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSeeding ? null : _clearData,
                    icon: const Icon(Icons.delete_sweep),
                    label: const Text('Clear Data'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Info Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What gets seeded:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('• 5 realistic projects (Marathon, P66, Deer Park, Valero, Shell)'),
                    const Text('• 20 complete log entries for Marathon (3 missing hours)'),
                    const Text('• 15 log entries for P66 (9 hours remaining)'),
                    const Text('• Hour selector sample data (Deer Park)'),
                    const Text('• Date: July 15, 2025'),
                    const Text('• Operators: John Smith, Sarah Johnson, Mike Davis'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Log Output
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Log Output:',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            _logs.isEmpty ? 'No logs yet...' : _logs.join('\n'),
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
