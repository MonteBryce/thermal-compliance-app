'use client';

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { PlusCircle, FileText, Users, Settings, Activity, TrendingUp, Clock, CheckCircle } from 'lucide-react';

export default function AdminDashboard() {
  return (
    <div className="px-6 py-8 space-y-8">
        {/* Summary Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
          <Card className="bg-[#1E1E1E] border-gray-800">
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium text-gray-300">Total Templates</CardTitle>
              <div className="w-10 h-10 rounded-lg bg-blue-600/20 flex items-center justify-center">
                <FileText className="h-5 w-5 text-blue-400" />
              </div>
            </CardHeader>
            <CardContent>
              <div className="text-3xl font-bold text-white">12</div>
              <p className="text-xs text-green-400">+2 from last month</p>
            </CardContent>
          </Card>

          <Card className="bg-[#1E1E1E] border-gray-800">
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium text-gray-300">Active Projects</CardTitle>
              <div className="w-10 h-10 rounded-lg bg-green-600/20 flex items-center justify-center">
                <Users className="h-5 w-5 text-green-400" />
              </div>
            </CardHeader>
            <CardContent>
              <div className="text-3xl font-bold text-white">8</div>
              <p className="text-xs text-blue-400">3 new this week</p>
              <div className="mt-2 w-full bg-gray-700 rounded-full h-2">
                <div className="bg-green-500 h-2 rounded-full" style={{width: '75%'}}></div>
              </div>
            </CardContent>
          </Card>

          <Card className="bg-[#1E1E1E] border-gray-800">
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium text-gray-300">Log Entries</CardTitle>
              <div className="w-10 h-10 rounded-lg bg-amber-600/20 flex items-center justify-center">
                <Activity className="h-5 w-5 text-amber-400" />
              </div>
            </CardHeader>
            <CardContent>
              <div className="text-3xl font-bold text-white">1,247</div>
              <p className="text-xs text-green-400">+15% from last week</p>
            </CardContent>
          </Card>

          <Card className="bg-[#1E1E1E] border-gray-800">
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium text-gray-300">Operators Online</CardTitle>
              <div className="w-10 h-10 rounded-lg bg-green-600/20 flex items-center justify-center">
                <div className="w-2 h-2 bg-green-400 rounded-full animate-pulse"></div>
              </div>
            </CardHeader>
            <CardContent>
              <div className="text-3xl font-bold text-white">24</div>
              <p className="text-xs text-gray-400">Real-time count</p>
            </CardContent>
          </Card>
        </div>

        {/* Main Action Cards */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <Card className="bg-[#1E1E1E] border-gray-800">
            <CardHeader>
              <CardTitle className="flex items-center gap-3 text-white">
                <div className="w-10 h-10 rounded-lg bg-blue-600/20 flex items-center justify-center">
                  <FileText className="h-5 w-5 text-blue-400" />
                </div>
                Template Builder
              </CardTitle>
              <CardDescription className="text-gray-400">
                Create and manage thermal log templates with drag-and-drop interface
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex gap-3">
                <Button asChild className="flex-1 bg-orange-600 hover:bg-orange-700 text-white border-0">
                  <a href="/admin/templates/new">
                    <PlusCircle className="h-4 w-4 mr-2" />
                    Create Template
                  </a>
                </Button>
                <Button variant="outline" asChild className="flex-1 border-gray-600 text-gray-300 hover:bg-gray-700">
                  <a href="/admin/templates">
                    View All Templates
                  </a>
                </Button>
              </div>
              <div className="pt-2 border-t border-gray-700">
                <div className="flex justify-between text-sm">
                  <span className="text-gray-400">Recent templates</span>
                  <span className="text-blue-400">12 active</span>
                </div>
              </div>
            </CardContent>
          </Card>

          <Card className="bg-[#1E1E1E] border-gray-800">
            <CardHeader>
              <CardTitle className="flex items-center gap-3 text-white">
                <div className="w-10 h-10 rounded-lg bg-green-600/20 flex items-center justify-center">
                  <Users className="h-5 w-5 text-green-400" />
                </div>
                Project Management
              </CardTitle>
              <CardDescription className="text-gray-400">
                Assign templates to projects and track operator progress
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex gap-3">
                <Button asChild className="flex-1 bg-orange-600 hover:bg-orange-700 text-white border-0">
                  <a href="/admin/jobs">
                    <Users className="h-4 w-4 mr-2" />
                    Manage Jobs
                  </a>
                </Button>
                <Button variant="outline" asChild className="flex-1 border-gray-600 text-gray-300 hover:bg-gray-700">
                  <a href="/admin/jobs">
                    View Assignments
                  </a>
                </Button>
              </div>
              <div className="pt-2 border-t border-gray-700">
                <div className="flex justify-between text-sm">
                  <span className="text-gray-400">Active projects</span>
                  <span className="text-green-400">8 ongoing</span>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Recent Activity */}
        <Card className="bg-[#1E1E1E] border-gray-800">
          <CardHeader>
            <CardTitle className="text-white flex items-center gap-2">
              <Clock className="h-5 w-5 text-gray-400" />
              Recent Activity
            </CardTitle>
            <CardDescription className="text-gray-400">
              Latest updates from your thermal logging system
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              <div className="flex items-start gap-4 p-3 rounded-lg bg-green-600/10 border border-green-600/20">
                <div className="w-2 h-2 bg-green-500 rounded-full mt-2"></div>
                <div className="flex-1">
                  <p className="text-sm font-medium text-white">New template "Marathon GBR Thermal Log" published</p>
                  <p className="text-xs text-green-400">2 hours ago</p>
                </div>
                <CheckCircle className="h-4 w-4 text-green-500" />
              </div>
              <div className="flex items-start gap-4 p-3 rounded-lg bg-blue-600/10 border border-blue-600/20">
                <div className="w-2 h-2 bg-blue-500 rounded-full mt-2"></div>
                <div className="flex-1">
                  <p className="text-sm font-medium text-white">Project "North Sea Operations" assigned new template</p>
                  <p className="text-xs text-blue-400">4 hours ago</p>
                </div>
                <Users className="h-4 w-4 text-blue-500" />
              </div>
              <div className="flex items-start gap-4 p-3 rounded-lg bg-amber-600/10 border border-amber-600/20">
                <div className="w-2 h-2 bg-amber-500 rounded-full mt-2"></div>
                <div className="flex-1">
                  <p className="text-sm font-medium text-white">15 operators completed thermal logs today</p>
                  <p className="text-xs text-amber-400">6 hours ago</p>
                </div>
                <TrendingUp className="h-4 w-4 text-amber-500" />
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    );
}