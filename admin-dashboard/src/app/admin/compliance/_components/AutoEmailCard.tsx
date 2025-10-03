'use client';

import { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Label } from '@/components/ui/label';
import { 
  Mail, 
  Send, 
  CheckCircle, 
  AlertCircle, 
  Clock,
  Plus,
  X
} from 'lucide-react';
import { emailReport } from '../actions/emailReport';

interface AutoEmailCardProps {
  jobId?: string | null;
}

export function AutoEmailCard({ jobId }: AutoEmailCardProps) {
  const [sending, setSending] = useState(false);
  const [lastEmail, setLastEmail] = useState<{
    messageId: string;
    sentAt: Date;
    recipients: string[];
  } | null>(null);
  const [emailConfig, setEmailConfig] = useState({
    to: ['customer@example.com'],
    cc: ['compliance@company.com'],
    subject: '',
    customMessage: '',
  });
  const [newRecipient, setNewRecipient] = useState('');
  const [error, setError] = useState<string | null>(null);

  const handleSendEmail = async () => {
    if (!jobId || emailConfig.to.length === 0) return;
    
    try {
      setSending(true);
      setError(null);
      
      const [projectId, logId] = jobId.split('-');
      const today = new Date();
      const startDate = new Date(today);
      startDate.setHours(0, 0, 0, 0);
      const endDate = new Date(today);
      endDate.setHours(23, 59, 59, 999);
      
      const result = await emailReport({
        to: emailConfig.to,
        cc: emailConfig.cc.filter(email => email.trim() !== ''),
        subject: emailConfig.subject || `Thermal Log Report - ${projectId} - ${today.toLocaleDateString()}`,
        projectId,
        logId,
        startDate,
        endDate,
        customMessage: emailConfig.customMessage || undefined,
      });
      
      if (result.success) {
        setLastEmail({
          messageId: result.messageId || '',
          sentAt: new Date(),
          recipients: [...emailConfig.to, ...emailConfig.cc],
        });
      } else {
        setError(result.error || 'Failed to send email');
      }
      
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to send email');
    } finally {
      setSending(false);
    }
  };

  const addRecipient = (type: 'to' | 'cc') => {
    if (!newRecipient.trim() || !newRecipient.includes('@')) return;
    
    setEmailConfig(prev => ({
      ...prev,
      [type]: [...prev[type], newRecipient.trim()],
    }));
    setNewRecipient('');
  };

  const removeRecipient = (type: 'to' | 'cc', index: number) => {
    setEmailConfig(prev => ({
      ...prev,
      [type]: prev[type].filter((_, i) => i !== index),
    }));
  };

  const isValidEmail = (email: string) => {
    return email.includes('@') && email.includes('.');
  };

  const canSend = () => {
    return jobId && 
           emailConfig.to.length > 0 && 
           emailConfig.to.every(isValidEmail) &&
           emailConfig.cc.every(isValidEmail) &&
           !sending;
  };

  return (
    <Card className="col-span-1">
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <Mail className="h-5 w-5" />
          Auto Email
          {lastEmail && (
            <Badge variant="outline" className="text-xs">
              <CheckCircle className="h-3 w-3 mr-1" />
              Sent
            </Badge>
          )}
        </CardTitle>
      </CardHeader>
      <CardContent>
        {!jobId && (
          <div className="text-center py-8 text-muted-foreground">
            Select a job to email reports
          </div>
        )}
        
        {jobId && (
          <div className="space-y-4">
            {/* Recipients */}
            <div className="space-y-3">
              <div>
                <Label className="text-xs">To Recipients</Label>
                <div className="space-y-1">
                  {emailConfig.to.map((email, idx) => (
                    <div key={idx} className="flex items-center gap-2">
                      <Badge variant="outline" className="text-xs flex-1 justify-between">
                        {email}
                        <Button
                          size="sm"
                          variant="ghost"
                          onClick={() => removeRecipient('to', idx)}
                          className="h-4 w-4 p-0 ml-1"
                        >
                          <X className="h-2 w-2" />
                        </Button>
                      </Badge>
                    </div>
                  ))}
                  <div className="flex gap-1">
                    <Input
                      placeholder="email@example.com"
                      value={newRecipient}
                      onChange={(e) => setNewRecipient(e.target.value)}
                      className="text-xs"
                      onKeyPress={(e) => {
                        if (e.key === 'Enter') {
                          addRecipient('to');
                        }
                      }}
                    />
                    <Button
                      size="sm"
                      variant="outline"
                      onClick={() => addRecipient('to')}
                      disabled={!newRecipient.trim() || !newRecipient.includes('@')}
                    >
                      <Plus className="h-3 w-3" />
                    </Button>
                  </div>
                </div>
              </div>
              
              <div>
                <Label className="text-xs">CC Recipients (Optional)</Label>
                <div className="space-y-1">
                  {emailConfig.cc.map((email, idx) => (
                    <div key={idx} className="flex items-center gap-2">
                      <Badge variant="secondary" className="text-xs flex-1 justify-between">
                        {email}
                        <Button
                          size="sm"
                          variant="ghost"
                          onClick={() => removeRecipient('cc', idx)}
                          className="h-4 w-4 p-0 ml-1"
                        >
                          <X className="h-2 w-2" />
                        </Button>
                      </Badge>
                    </div>
                  ))}
                  <div className="flex gap-1">
                    <Input
                      placeholder="cc@example.com"
                      value={newRecipient}
                      onChange={(e) => setNewRecipient(e.target.value)}
                      className="text-xs"
                      onKeyPress={(e) => {
                        if (e.key === 'Enter') {
                          addRecipient('cc');
                        }
                      }}
                    />
                    <Button
                      size="sm"
                      variant="outline"
                      onClick={() => addRecipient('cc')}
                      disabled={!newRecipient.trim() || !newRecipient.includes('@')}
                    >
                      <Plus className="h-3 w-3" />
                    </Button>
                  </div>
                </div>
              </div>
            </div>
            
            {/* Subject */}
            <div>
              <Label htmlFor="subject" className="text-xs">Subject (Optional)</Label>
              <Input
                id="subject"
                placeholder="Auto-generated if left blank"
                value={emailConfig.subject}
                onChange={(e) => setEmailConfig(prev => ({ ...prev, subject: e.target.value }))}
                className="text-sm"
              />
            </div>
            
            {/* Custom Message */}
            <div>
              <Label htmlFor="message" className="text-xs">Custom Message (Optional)</Label>
              <Textarea
                id="message"
                placeholder="Additional message to include in email body..."
                value={emailConfig.customMessage}
                onChange={(e) => setEmailConfig(prev => ({ ...prev, customMessage: e.target.value }))}
                rows={3}
                className="text-sm"
              />
            </div>
            
            {/* Send Button */}
            <Button
              onClick={handleSendEmail}
              disabled={!canSend()}
              className="w-full"
            >
              {sending ? (
                <>
                  <Clock className="h-4 w-4 mr-2 animate-spin" />
                  Sending Email...
                </>
              ) : (
                <>
                  <Send className="h-4 w-4 mr-2" />
                  Send Report via Email
                </>
              )}
            </Button>
            
            {/* Error Display */}
            {error && (
              <div className="p-3 bg-destructive/10 border border-destructive/20 rounded-lg">
                <div className="flex items-center gap-2 text-destructive">
                  <AlertCircle className="h-4 w-4" />
                  <span className="text-sm font-medium">Email Failed</span>
                </div>
                <div className="text-xs text-destructive/80 mt-1">{error}</div>
              </div>
            )}
            
            {/* Last Sent Email */}
            {lastEmail && (
              <div className="p-3 bg-green-50 border border-green-200 rounded-lg">
                <div className="flex items-center gap-2 mb-2">
                  <CheckCircle className="h-4 w-4 text-green-600" />
                  <span className="text-sm font-medium text-green-800">Email Sent</span>
                </div>
                
                <div className="text-xs text-green-700 space-y-1">
                  <div>To: {lastEmail.recipients.join(', ')}</div>
                  <div>Sent: {lastEmail.sentAt.toLocaleString()}</div>
                  <div>Message ID: {lastEmail.messageId}</div>
                </div>
              </div>
            )}
            
            {/* Email Info */}
            <div className="text-xs text-muted-foreground space-y-1 border-t pt-3">
              <div>• Includes Excel report as attachment</div>
              <div>• Auto-generated email body with summary</div>
              <div>• Logged in communications history</div>
              <div>• SMTP delivery confirmation</div>
            </div>
          </div>
        )}
      </CardContent>
    </Card>
  );
}