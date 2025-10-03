/**
 * Mock Authentication for Demo/Development
 * Use this when Firebase is not configured
 */

export interface MockUser {
  uid: string;
  email: string;
  displayName: string;
  customClaims: {
    admin: boolean;
    operator?: boolean;
    viewer?: boolean;
  };
}

const DEMO_USER: MockUser = {
  uid: 'demo-admin-123',
  email: 'admin@demo.com',
  displayName: 'Demo Admin',
  customClaims: {
    admin: true,
    operator: false,
    viewer: false,
  }
};

// Mock auth state
let currentUser: MockUser | null = null;
const authStateListeners: Array<(user: MockUser | null) => void> = [];

export const mockAuth = {
  currentUser: null as MockUser | null,
  
  signInWithEmailAndPassword: async (email: string, password: string): Promise<MockUser> => {
    // Demo credentials check
    if (email === 'admin@demo.com' && password === 'admin123') {
      currentUser = DEMO_USER;
      mockAuth.currentUser = currentUser;
      
      // Notify listeners
      authStateListeners.forEach(listener => listener(currentUser));
      
      return DEMO_USER;
    }
    
    throw new Error('Invalid email or password');
  },
  
  signOut: async (): Promise<void> => {
    currentUser = null;
    mockAuth.currentUser = null;
    authStateListeners.forEach(listener => listener(null));
  },
  
  onAuthStateChanged: (callback: (user: MockUser | null) => void) => {
    authStateListeners.push(callback);
    
    // Call immediately with current state
    setTimeout(() => callback(currentUser), 0);
    
    // Return unsubscribe function
    return () => {
      const index = authStateListeners.indexOf(callback);
      if (index > -1) {
        authStateListeners.splice(index, 1);
      }
    };
  },
  
  getIdTokenResult: async () => ({
    claims: currentUser?.customClaims || {},
  }),
};

export default mockAuth;