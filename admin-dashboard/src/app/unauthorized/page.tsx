import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { ShieldX, ArrowLeft } from 'lucide-react';
import Link from 'next/link';

export default function UnauthorizedPage() {
  return (
    <div className="min-h-screen bg-background">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Header */}
        <div className="mb-8">
          <div className="flex justify-center mb-6">
            <ShieldX className="h-16 w-16 text-destructive" />
          </div>
          <div className="text-center">
            <h1 className="text-3xl font-bold text-foreground">Access Denied</h1>
            <p className="mt-2 text-muted-foreground">
              You don't have permission to access this resource
            </p>
          </div>
        </div>

        {/* Main Content */}
        <div className="max-w-md mx-auto">
          <Card>
            <CardHeader>
              <CardTitle>Insufficient Permissions</CardTitle>
              <CardDescription>
                Administrator access is required to view this page
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              <p className="text-sm text-muted-foreground">
                If you believe you should have access to this resource, please contact your system administrator.
              </p>
              
              <div className="space-y-3">
                <Button asChild className="w-full">
                  <Link href="/login">
                    <ArrowLeft className="mr-2 h-4 w-4" />
                    Return to Login
                  </Link>
                </Button>
                
                <Button asChild variant="outline" className="w-full">
                  <Link href="/">
                    Go to Home Page
                  </Link>
                </Button>
              </div>
            </CardContent>
          </Card>

          {/* Error Info Card */}
          <Card className="mt-6">
            <CardContent className="p-4">
              <div className="text-center text-sm text-muted-foreground">
                <p>Error Code: 403 - Forbidden</p>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}