import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/job_model.dart';
import '../services/firestore_service.dart';

final jobListProvider = FutureProvider<List<Job>>((ref) async {
  return FirestoreService.fetchJobs();
});
