'use client';

import { useState, useEffect } from 'react';
import { collection, addDoc, serverTimestamp, getDocs } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { CheckCircle, AlertCircle, Loader2, Info } from 'lucide-react';

export default function TestFirestorePage() {
  const [isLoading, setIsLoading] = useState(false);
  const [result, setResult] = useState<{
    success: boolean;
    message: string;
    documentId?: string;
    error?: any;
  } | null>(null);
  const [debugInfo, setDebugInfo] = useState<any>(null);
  const [firebaseStatus, setFirebaseStatus] = useState<string>('Checking...');

  // Check Firebase status on component mount
  useEffect(() => {
    checkFirebaseStatus();
  }, []);

  const checkFirebaseStatus = async () => {
    try {
      // Check if db object exists
      if (!db) {
        setFirebaseStatus('❌ Firebase db object is undefined');
        return;
      }

      // Try to get a simple collection reference
      const testCollection = collection(db, 'test_collection');
      if (!testCollection) {
        setFirebaseStatus('❌ Cannot create collection reference');
        return;
      }

      // Check if we can access Firestore methods
      if (typeof addDoc !== 'function') {
        setFirebaseStatus('❌ addDoc function not available');
        return;
      }

      setFirebaseStatus('✅ Firebase appears to be initialized correctly');
      
      // Log debug info
      console.log('Firebase db object:', db);
      console.log('Firebase app:', db.app);
      
    } catch (error) {
      setFirebaseStatus(`❌ Firebase check failed: ${error}`);
      console.error('Firebase status check error:', error);
    }
  };

  const testFirestoreWrite = async () => {
    setIsLoading(true);
    setResult(null);
    
    try {
      console.log('🚀 Starting Firestore test...');
      console.log('Firebase db object:', db);
      
      // Test document data
      const testData = {
        timestamp: serverTimestamp(),
        testField: 'This is a test document',
        projectId: 'alien-hologram-470217-r0',
        createdAt: new Date().toISOString(),
        testType: 'project_link_test'
      };

      console.log('📝 Test data to write:', testData);

      // Write to Firestore
      const docRef = await addDoc(collection(db, 'test_project_link'), testData);
      
      console.log('✅ Document successfully written!');
      console.log('📄 Document ID:', docRef.id);
      
      setResult({
        success: true,
        message: 'Document successfully written to Firestore!',
        documentId: docRef.id
      });
      
      // Update debug info
      setDebugInfo({
        documentId: docRef.id,
        timestamp: new Date().toISOString(),
        firebaseConfig: {
          projectId: db.app.options.projectId,
          authDomain: db.app.options.authDomain
        }
      });
      
    } catch (error) {
      console.error('❌ Error writing document:', error);
      
      // Enhanced error logging
      const errorDetails = {
        message: error.message,
        code: error.code,
        stack: error.stack,
        firebaseStatus: firebaseStatus,
        dbObject: db ? 'exists' : 'undefined'
      };
      
      console.error('🔍 Detailed error info:', errorDetails);
      
      setResult({
        success: false,
        message: 'Failed to write document to Firestore',
        error: errorDetails
      });
    } finally {
      setIsLoading(false);
    }
  };

  const testFirestoreRead = async () => {
    try {
      console.log('📖 Testing Firestore read...');
      const querySnapshot = await getDocs(collection(db, 'test_project_link'));
      console.log('📚 Read successful, documents found:', querySnapshot.size);
      
      const docs = querySnapshot.docs.map(doc => ({
        id: doc.id,
        data: doc.data()
      }));
      
      console.log('📄 Documents:', docs);
      
      setResult({
        success: true,
        message: `Successfully read ${querySnapshot.size} documents from test_project_link collection`
      });
      
    } catch (error) {
      console.error('❌ Read test failed:', error);
      setResult({
        success: false,
        message: 'Failed to read from Firestore',
        error: error
      });
    }
  };

  return (
    <div className="container mx-auto p-6 max-w-4xl">
      <Card>
        <CardHeader>
          <CardTitle className="text-2xl font-bold text-center">
            Firestore Connection Test
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-6">
          
          {/* Firebase Status */}
          <Alert className="border-blue-200 bg-blue-50">
            <Info className="h-4 w-4 text-blue-600" />
            <AlertDescription className="text-blue-800">
              <strong>Firebase Status:</strong> {firebaseStatus}
            </AlertDescription>
          </Alert>

          <div className="text-center space-y-4">
            <p className="text-gray-600">
              This page tests your Firestore connection by writing a test document to the 
              <code className="bg-gray-100 px-2 py-1 rounded">test_project_link</code> collection.
            </p>
            
            <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 text-left">
              <h3 className="font-semibold text-blue-800 mb-2">Test Details:</h3>
              <ul className="text-sm text-blue-700 space-y-1">
                <li>• Collection: <code>test_project_link</code></li>
                <li>• Project ID: <code>alien-hologram-470217-r0</code></li>
                <li>• Test field with timestamp</li>
                <li>• Server timestamp for accurate timing</li>
              </ul>
            </div>
          </div>

          {/* Test Buttons */}
          <div className="flex justify-center space-x-4">
            <Button 
              onClick={testFirestoreWrite}
              disabled={isLoading}
              className="px-8 py-3 text-lg"
            >
              {isLoading ? (
                <>
                  <Loader2 className="mr-2 h-5 w-5 animate-spin" />
                  Testing Write...
                </>
              ) : (
                'Test Firestore Write'
              )}
            </Button>
            
            <Button 
              onClick={testFirestoreRead}
              variant="outline"
              className="px-8 py-3 text-lg"
            >
              Test Firestore Read
            </Button>
          </div>

          {/* Results */}
          {result && (
            <Alert className={result.success ? 'border-green-200 bg-green-50' : 'border-red-200 bg-red-50'}>
              {result.success ? (
                <CheckCircle className="h-4 w-4 text-green-600" />
              ) : (
                <AlertCircle className="h-4 w-4 text-red-600" />
              )}
              <AlertDescription className={result.success ? 'text-green-800' : 'text-red-800'}>
                <div className="font-semibold mb-2">{result.message}</div>
                {result.success && result.documentId && (
                  <div className="text-sm">
                    <strong>Document ID:</strong> <code className="bg-green-100 px-2 py-1 rounded">{result.documentId}</code>
                  </div>
                )}
                {!result.success && result.error && (
                  <div className="text-sm mt-2">
                    <strong>Error Details:</strong>
                    <pre className="bg-red-100 p-2 rounded mt-1 text-xs overflow-auto">
                      {JSON.stringify(result.error, null, 2)}
                    </pre>
                  </div>
                )}
              </AlertDescription>
            </Alert>
          )}

          {/* Debug Info */}
          {debugInfo && (
            <div className="bg-gray-50 border border-gray-200 rounded-lg p-4">
              <h3 className="font-semibold text-gray-800 mb-2">Debug Information:</h3>
              <pre className="text-sm text-gray-700 overflow-auto">
                {JSON.stringify(debugInfo, null, 2)}
              </pre>
            </div>
          )}

          {/* Troubleshooting */}
          <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
            <h3 className="font-semibold text-yellow-800 mb-2">Troubleshooting:</h3>
            <ol className="text-sm text-yellow-700 space-y-2 list-decimal list-inside">
              <li><strong>Check Console:</strong> Open Developer Tools (F12) and look for errors</li>
              <li><strong>Environment Variables:</strong> Ensure your .env.local has Firebase config</li>
              <li><strong>Firebase Rules:</strong> Check if Firestore rules allow writes</li>
              <li><strong>Network:</strong> Verify internet connection and Firebase service status</li>
            </ol>
          </div>

        </CardContent>
      </Card>
    </div>
  );
}
