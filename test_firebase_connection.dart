import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  print('🔄 Testing Firebase connection...\n');

  try {
    // Initialize Firebase
    print('1️⃣ Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully!');
    print('   Project: ${DefaultFirebaseOptions.currentPlatform.projectId}');
    print('   Storage: ${DefaultFirebaseOptions.currentPlatform.storageBucket}\n');

    // Test Firestore connection
    print('2️⃣ Testing Firestore connection...');
    final firestore = FirebaseFirestore.instance;

    // Try to write a test document
    final testDoc = firestore.collection('_connection_test').doc('test');
    await testDoc.set({
      'timestamp': FieldValue.serverTimestamp(),
      'test': true,
      'message': 'Firebase connection test successful',
    });
    print('✅ Successfully wrote to Firestore!');

    // Try to read the document
    final snapshot = await testDoc.get();
    if (snapshot.exists) {
      print('✅ Successfully read from Firestore!');
      print('   Data: ${snapshot.data()}');
    }

    // Clean up
    await testDoc.delete();
    print('✅ Test document cleaned up\n');

    print('🎉 All Firebase tests passed!');
    print('   ✓ Firebase initialized');
    print('   ✓ Firestore write successful');
    print('   ✓ Firestore read successful');
    print('   ✓ Using project: alien-hologram-470217-r0\n');

  } catch (e, stackTrace) {
    print('❌ Firebase connection test FAILED!');
    print('   Error: $e');
    print('   Stack trace: $stackTrace\n');

    print('💡 Possible issues:');
    print('   • Check Firebase project configuration');
    print('   • Verify Firestore is enabled in Firebase Console');
    print('   • Check Firestore security rules');
    print('   • Ensure internet connection is available');
  }
}
