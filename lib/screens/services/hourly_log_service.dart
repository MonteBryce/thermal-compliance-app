 import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/path_helper.dart';

class HourlyLogService {
  static Future<void> patchHourlyEntry({
    required String projectId,
    required String logId,
    required String hour,
    required Map<String, dynamic> data,
  }) async {
    final docRef = PathHelper.entryDocRef(
      FirebaseFirestore.instance,
      projectId,
      logId,
      hour,
    );

    print('📤 Writing to projects/$projectId/logs/$logId/entries/$hour → $data');

    try {
      await docRef.set(data, SetOptions(merge: true));
      print('✅ Hourly data saved to $hour.');
    } catch (e) {
      print('❌ Error writing hourly data: $e');
    }
  }

 static bool validateInputs(Map<String, dynamic> data) {
  final tempIn = data['temperatureInlet'];
  final tempOut = data['temperatureOutlet'];
  final lel = data['exhaustLEL'];
  final h2s = data['inletH2S'];

  print('🔎 Validating inputs: $data');

  if (tempIn is! num || tempIn < 100 || tempIn > 1600) {
    print('❌ temperatureInlet invalid: $tempIn');
    return false;
  }
  if (tempOut is! num || tempOut < 100 || tempOut > 1600) {
    print('❌ temperatureOutlet invalid: $tempOut');
    return false;
  }
  if (lel is! num || lel < 0 || lel > 100) {
    print('❌ exhaustLEL invalid: $lel');
    return false;
  }
  if (h2s is! num || h2s < 0) {
    print('❌ inletH2S invalid: $h2s');
    return false;
  }

  print('✅ Inputs valid!');
  return true;
  }
}
