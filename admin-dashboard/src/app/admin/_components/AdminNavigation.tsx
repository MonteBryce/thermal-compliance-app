'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { useState } from 'react';
import { 
  LayoutDashboard, 
  FileText, 
  Users, 
  Settings, 
  BarChart3,
  Shield,
  Database,
  Wrench,
  LogOut,
  User,
  FolderOpen,
  Menu,
  X
} from 'lucide-react';
import { cn } from '@/lib/utils';
import { useAuth } from '@/lib/contexts/AuthContext';
import { Permission, Role } from '@/lib/types/permissions';
import { PermissionGuard } from '@/components/auth/PermissionGuard';

const navigation = [
  {
    name: 'Dashboard',
    href: '/admin',
    icon: LayoutDashboard,
    permission: Permission.TEMPLATE_VIEW, // Basic access permission
  },
  {
    name: 'Templates',
    href: '/admin/templates',
    icon: FileText,
    permission: Permission.TEMPLATE_VIEW,
  },
  {
    name: 'Projects',
    href: '/admin/jobs',
    icon: FolderOpen,
    permission: Permission.PROJECT_VIEW,
  },
  {
    name: 'Compliance',
    href: '/admin/compliance',
    icon: Shield,
    permission: Permission.COMPLIANCE_VIEW,
  },
  {
    name: 'Analytics',
    href: '/admin/analytics',
    icon: BarChart3,
    permission: Permission.ANALYTICS_VIEW,
  },
  {
    name: 'Users',
    href: '/admin/users',
    icon: Users,
    permission: Permission.USER_VIEW,
  },
  {
    name: 'Settings',
    href: '/admin/settings',
    icon: Settings,
    permission: Permission.SYSTEM_SETTINGS,
  },
];

export function AdminNavigation() {
  const pathname = usePathname();
  const { user, signOut, canAccess, roles } = useAuth();
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

  return (
    <div className="bg-[#1E1E1E] border-b border-gray-800">
      {/* Header */}
      <div className="px-4 sm:px-6 py-4 border-b border-gray-800">
        <div className="flex justify-between items-center">
          <div className="flex-1 min-w-0">
            <h1 className="text-xl sm:text-2xl font-semibold text-white truncate">Thermal Log Admin</h1>
            <p className="text-gray-400 text-xs sm:text-sm mt-1 hidden sm:block">
              Manage templates, projects, and operator assignments
            </p>
          </div>
          
          {/* Desktop Actions */}
          <div className="hidden lg:flex items-center gap-3">
            <Badge className="bg-green-600 text-white border-0 text-xs">
              System Online
            </Badge>
            {user && (
              <div className="flex items-center gap-2 text-sm text-gray-400">
                <User className="h-4 w-4" />
                <div className="flex flex-col">
                  <span className="truncate max-w-32">{user.email}</span>
                  {roles.length > 0 && (
                    <span className="text-xs text-orange-400">
                      {roles.map(role => role.replace('_', ' ').toLowerCase()).join(', ')}
                    </span>
                  )}
                </div>
              </div>
            )}
            <PermissionGuard permissions={Permission.TEMPLATE_EDIT}>
              <Button asChild variant="outline" size="sm" className="border-gray-600 text-gray-300 hover:bg-gray-700">
                <Link href="/admin/templates/builder">
                  <Wrench className="h-4 w-4 mr-2" />
                  <span className="hidden xl:inline">Template Builder</span>
                  <span className="xl:hidden">Builder</span>
                </Link>
              </Button>
            </PermissionGuard>
            <Button 
              variant="outline" 
              size="sm" 
              onClick={() => signOut()}
              className="border-red-600 text-red-400 hover:bg-red-900/20"
            >
              <LogOut className="h-4 w-4 mr-2" />
              <span className="hidden xl:inline">Sign Out</span>
            </Button>
          </div>

          {/* Mobile Actions */}
          <div className="flex lg:hidden items-center gap-2">
            <Badge className="bg-green-600 text-white border-0 text-xs">
              Online
            </Badge>
            <Button 
              variant="ghost" 
              size="sm"
              onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
              className="text-gray-300 hover:bg-gray-700 h-10 w-10 p-0"
              aria-label="Toggle navigation menu"
            >
              {isMobileMenuOpen ? <X className="h-6 w-6" /> : <Menu className="h-6 w-6" />}
            </Button>
          </div>
        </div>
      </div>

      {/* Desktop Navigation Tabs */}
      <div className="hidden lg:block px-4 sm:px-6">
        <nav className="flex space-x-8 overflow-x-auto" aria-label="Tabs">
          {navigation.map((item) => {
            const isActive = pathname === item.href || 
              (item.href !== '/admin' && pathname.startsWith(item.href));
            
            return (
              <PermissionGuard key={item.name} permissions={item.permission}>
                <Link
                  href={item.href}
                  className={cn(
                    'flex items-center gap-2 py-4 px-1 border-b-2 font-medium text-sm transition-colors whitespace-nowrap',
                    isActive
                      ? 'border-orange-500 text-orange-400'
                      : 'border-transparent text-gray-400 hover:text-gray-300 hover:border-gray-300'
                  )}
                >
                  <item.icon className="h-4 w-4" />
                  {item.name}
                </Link>
              </PermissionGuard>
            );
          })}
        </nav>
      </div>

      {/* Mobile Navigation Menu */}
      {isMobileMenuOpen && (
        <div className="lg:hidden border-t border-gray-800 bg-[#1E1E1E]">
          <nav className="px-4 py-4" aria-label="Mobile navigation">
            {navigation.map((item) => {
              const isActive = pathname === item.href || 
                (item.href !== '/admin' && pathname.startsWith(item.href));
              
              return (
                <PermissionGuard key={item.name} permissions={item.permission}>
                  <Link
                    href={item.href}
                    onClick={() => setIsMobileMenuOpen(false)}
                    className={cn(
                      'flex items-center gap-3 py-4 px-3 rounded-lg font-medium text-base transition-colors min-h-[44px] w-full',
                      isActive
                        ? 'bg-orange-500/10 text-orange-400'
                        : 'text-gray-400 hover:text-gray-300 hover:bg-gray-700/50 active:bg-gray-700'
                    )}
                  >
                    <item.icon className="h-5 w-5" />
                    {item.name}
                  </Link>
                </PermissionGuard>
              );
            })}
            
            {/* Mobile User Actions */}
            <div className="pt-4 mt-4 border-t border-gray-800 space-y-3">
              {user && (
                <div className="flex items-center gap-2 px-2 py-2 text-sm text-gray-400">
                  <User className="h-4 w-4" />
                  <div className="flex flex-col">
                    <span className="truncate">{user.email}</span>
                    {roles.length > 0 && (
                      <span className="text-xs text-orange-400">
                        {roles.map(role => role.replace('_', ' ').toLowerCase()).join(', ')}
                      </span>
                    )}
                  </div>
                </div>
              )}
              
              <PermissionGuard permissions={Permission.TEMPLATE_EDIT}>
                <Link
                  href="/admin/templates/builder"
                  onClick={() => setIsMobileMenuOpen(false)}
                  className="flex items-center gap-3 py-4 px-3 rounded-lg text-base text-gray-300 hover:bg-gray-700/50 active:bg-gray-700 min-h-[44px] w-full"
                >
                  <Wrench className="h-5 w-5" />
                  Template Builder
                </Link>
              </PermissionGuard>
              
              <button
                onClick={() => {
                  setIsMobileMenuOpen(false);
                  signOut();
                }}
                className="flex items-center gap-3 py-4 px-3 rounded-lg text-base text-red-400 hover:bg-red-900/20 active:bg-red-900/30 min-h-[44px] w-full text-left"
              >
                <LogOut className="h-5 w-5" />
                Sign Out
              </button>
            </div>
          </nav>
        </div>
      )}
    </div>
  );
}