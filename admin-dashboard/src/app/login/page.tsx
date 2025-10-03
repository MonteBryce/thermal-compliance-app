'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/lib/contexts/AuthContext';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Loader2 } from 'lucide-react';

export default function LoginPage() {
  const router = useRouter();
  const { signIn, user, isLoading: authLoading } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  
  // Check if in development mode
  const isDevelopment = process.env.NODE_ENV === 'development';

  // Redirect if already logged in
  useEffect(() => {
    if (user && !authLoading) {
      router.push('/admin/jobs');
    }
  }, [user, authLoading, router]);

  const handleSkipLogin = () => {
    // In development, directly navigate to admin dashboard
    router.push('/admin');
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      await signIn(email, password);
      // On success, manually redirect
      router.push('/admin/jobs');
    } catch (error: any) {
      console.error('Login error:', error);
      
      // Handle specific Firebase auth errors
      switch (error.code) {
        case 'auth/user-not-found':
        case 'auth/wrong-password':
        case 'auth/invalid-credential':
          setError('Invalid email or password');
          break;
        case 'auth/too-many-requests':
          setError('Too many failed login attempts. Please try again later.');
          break;
        case 'auth/user-disabled':
          setError('This account has been disabled');
          break;
        default:
          setError('Login failed. Please try again.');
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-background">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-foreground">
            Admin Login
          </h1>
          <p className="mt-2 text-muted-foreground">
            Sign in to access the thermal logging dashboard
          </p>
        </div>

        {/* Main Content */}
        <div className="max-w-md mx-auto">
          <Card>
            <CardHeader>
              <CardTitle>Sign In</CardTitle>
              <CardDescription>
                Enter your credentials to access the admin panel
              </CardDescription>
            </CardHeader>
            <CardContent>
              <form onSubmit={handleSubmit} className="space-y-6">
                <div className="space-y-2">
                  <Label htmlFor="email">Email Address</Label>
                  <Input
                    id="email"
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="admin@example.com"
                    required
                    disabled={loading}
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="password">Password</Label>
                  <Input
                    id="password"
                    type="password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="••••••••"
                    required
                    disabled={loading}
                  />
                </div>

                {error && (
                  <Alert variant="destructive">
                    <AlertDescription>{error}</AlertDescription>
                  </Alert>
                )}

                <Button 
                  type="submit" 
                  className="w-full" 
                  disabled={loading}
                >
                  {loading ? (
                    <>
                      <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                      Signing In...
                    </>
                  ) : (
                    'Sign In'
                  )}
                </Button>

                {isDevelopment && (
                  <Button 
                    type="button" 
                    variant="secondary" 
                    className="w-full mt-3" 
                    onClick={handleSkipLogin}
                    disabled={loading}
                  >
                    🚧 Skip Login (Development)
                  </Button>
                )}
              </form>
            </CardContent>
          </Card>

          {/* Firebase Authentication Info */}
          <Card className="mt-6">
            <CardHeader>
              <CardTitle className="text-lg">Firebase Authentication</CardTitle>
              <CardDescription>
                Sign in with your Firebase user account
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="text-sm text-muted-foreground">
                <p>This login uses Firebase Authentication for your project:</p>
                <p className="font-mono text-xs mt-2 bg-muted p-2 rounded">
                  datacollection-e8170
                </p>
                <p className="mt-2">
                  Create users in Firebase Console → Authentication → Users
                </p>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}