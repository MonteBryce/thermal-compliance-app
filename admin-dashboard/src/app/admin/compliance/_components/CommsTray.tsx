'use client';

import { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { 
  MessageSquare, 
  Send, 
  Phone, 
  Mail, 
  Clock,
  CheckCircle,
  AlertTriangle
} from 'lucide-react';

interface Message {
  id: string;
  type: 'reminder' | 'confirmation' | 'alert';
  recipient: string;
  subject: string;
  content: string;
  sentAt: Date;
  status: 'sent' | 'delivered' | 'failed';
}

interface CommsTrayProps {
  jobId?: string | null;
}

export function CommsTray({ jobId }: CommsTrayProps) {
  const [activeTab, setActiveTab] = useState<'send' | 'history'>('send');
  const [messageType, setMessageType] = useState<'reminder' | 'confirmation'>('reminder');
  const [recipient, setRecipient] = useState('');
  const [message, setMessage] = useState('');
  const [sending, setSending] = useState(false);
  const [recentMessages, setRecentMessages] = useState<Message[]>([
    {
      id: '1',
      type: 'reminder',
      recipient: 'operator@company.com',
      subject: 'Missing hourly readings reminder',
      content: 'Please submit missing hourly readings for hours 10-12.',
      sentAt: new Date(Date.now() - 30 * 60 * 1000),
      status: 'delivered',
    },
    {
      id: '2',
      type: 'confirmation',
      recipient: 'customer@client.com',
      subject: 'Daily compliance confirmation',
      content: 'All readings for today are within permit limits.',
      sentAt: new Date(Date.now() - 2 * 60 * 60 * 1000),
      status: 'sent',
    },
  ]);

  const messageTemplates = {
    reminder: {
      operator: 'Please submit the missing hourly readings for the current monitoring period. Ensure all required measurements are recorded.',
      customer: 'Reminder: Daily monitoring report is pending review. Please confirm receipt of compliance data.',
    },
    confirmation: {
      operator: 'All monitoring targets have been met for the current period. Continue standard operating procedures.',
      customer: 'Daily compliance targets achieved. All measurements are within permitted limits.',
    },
  };

  const handleSendMessage = async () => {
    if (!recipient || !message.trim()) return;
    
    setSending(true);
    
    // Simulate sending delay
    setTimeout(() => {
      const newMessage: Message = {
        id: Date.now().toString(),
        type: messageType,
        recipient,
        subject: messageType === 'reminder' 
          ? 'Monitoring Reminder' 
          : 'Compliance Confirmation',
        content: message.trim(),
        sentAt: new Date(),
        status: 'sent',
      };
      
      setRecentMessages(prev => [newMessage, ...prev.slice(0, 9)]);
      setMessage('');
      setSending(false);
      
      // Auto-switch to history tab to show sent message
      setTimeout(() => setActiveTab('history'), 500);
    }, 1000);
  };

  const useTemplate = (recipientType: 'operator' | 'customer') => {
    setMessage(messageTemplates[messageType][recipientType]);
  };

  const getStatusIcon = (status: Message['status']) => {
    switch (status) {
      case 'sent':
        return <Clock className="h-3 w-3 text-blue-500" />;
      case 'delivered':
        return <CheckCircle className="h-3 w-3 text-green-500" />;
      case 'failed':
        return <AlertTriangle className="h-3 w-3 text-destructive" />;
    }
  };

  const getTypeColor = (type: Message['type']) => {
    switch (type) {
      case 'reminder':
        return 'bg-amber-100 text-amber-800';
      case 'confirmation':
        return 'bg-green-100 text-green-800';
      case 'alert':
        return 'bg-red-100 text-red-800';
    }
  };

  return (
    <Card className="col-span-1">
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <MessageSquare className="h-5 w-5" />
          Communications Tray
          {recentMessages.length > 0 && (
            <Badge variant="secondary">{recentMessages.length}</Badge>
          )}
        </CardTitle>
      </CardHeader>
      <CardContent>
        {!jobId && (
          <div className="text-center py-8 text-muted-foreground">
            Select a job to send communications
          </div>
        )}
        
        {jobId && (
          <div className="space-y-4">
            {/* Tab Navigation */}
            <div className="flex gap-1 p-1 bg-muted rounded-lg">
              <Button
                size="sm"
                variant={activeTab === 'send' ? 'default' : 'ghost'}
                onClick={() => setActiveTab('send')}
                className="flex-1"
              >
                <Send className="h-3 w-3 mr-1" />
                Send
              </Button>
              <Button
                size="sm"
                variant={activeTab === 'history' ? 'default' : 'ghost'}
                onClick={() => setActiveTab('history')}
                className="flex-1"
              >
                <Clock className="h-3 w-3 mr-1" />
                History
              </Button>
            </div>
            
            {/* Send Tab */}
            {activeTab === 'send' && (
              <div className="space-y-4">
                {/* Message Type */}
                <div className="flex gap-1">
                  <Button
                    size="sm"
                    variant={messageType === 'reminder' ? 'default' : 'outline'}
                    onClick={() => setMessageType('reminder')}
                    className="flex-1"
                  >
                    Reminder
                  </Button>
                  <Button
                    size="sm"
                    variant={messageType === 'confirmation' ? 'default' : 'outline'}
                    onClick={() => setMessageType('confirmation')}
                    className="flex-1"
                  >
                    Confirmation
                  </Button>
                </div>
                
                {/* Recipient */}
                <div>
                  <label className="text-xs font-medium">Recipient</label>
                  <Input
                    placeholder="email@example.com"
                    value={recipient}
                    onChange={(e) => setRecipient(e.target.value)}
                    className="text-sm"
                  />
                </div>
                
                {/* Quick Templates */}
                <div className="flex gap-1">
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={() => useTemplate('operator')}
                    className="text-xs flex-1"
                  >
                    Operator Template
                  </Button>
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={() => useTemplate('customer')}
                    className="text-xs flex-1"
                  >
                    Customer Template
                  </Button>
                </div>
                
                {/* Message Content */}
                <div>
                  <label className="text-xs font-medium">Message</label>
                  <Textarea
                    placeholder="Type your message here..."
                    value={message}
                    onChange={(e) => setMessage(e.target.value)}
                    rows={4}
                    className="text-sm"
                  />
                </div>
                
                {/* Send Button */}
                <Button
                  onClick={handleSendMessage}
                  disabled={!recipient || !message.trim() || sending}
                  className="w-full"
                >
                  {sending ? (
                    <>
                      <Clock className="h-4 w-4 mr-2 animate-spin" />
                      Sending...
                    </>
                  ) : (
                    <>
                      <Send className="h-4 w-4 mr-2" />
                      Send Message
                    </>
                  )}
                </Button>
              </div>
            )}
            
            {/* History Tab */}
            {activeTab === 'history' && (
              <div className="space-y-3">
                {recentMessages.length === 0 ? (
                  <div className="text-center py-8 text-muted-foreground text-sm">
                    No messages sent yet
                  </div>
                ) : (
                  recentMessages.map(msg => (
                    <div key={msg.id} className="p-3 border rounded-lg space-y-2">
                      <div className="flex items-center justify-between">
                        <Badge className={getTypeColor(msg.type)}>
                          {msg.type}
                        </Badge>
                        <div className="flex items-center gap-1 text-xs text-muted-foreground">
                          {getStatusIcon(msg.status)}
                          {msg.status}
                        </div>
                      </div>
                      
                      <div className="text-sm">
                        <div className="font-medium">{msg.subject}</div>
                        <div className="text-xs text-muted-foreground">
                          To: {msg.recipient}
                        </div>
                      </div>
                      
                      <div className="text-xs text-muted-foreground bg-muted p-2 rounded">
                        {msg.content}
                      </div>
                      
                      <div className="text-xs text-muted-foreground">
                        {msg.sentAt.toLocaleString()}
                      </div>
                    </div>
                  ))
                )}
              </div>
            )}
            
            {/* Quick Actions */}
            {activeTab === 'send' && (
              <div className="border-t pt-3">
                <div className="text-xs font-medium mb-2">Quick Actions</div>
                <div className="grid grid-cols-2 gap-2">
                  <Button size="sm" variant="outline" className="text-xs">
                    <Phone className="h-3 w-3 mr-1" />
                    Call Operator
                  </Button>
                  <Button size="sm" variant="outline" className="text-xs">
                    <Mail className="h-3 w-3 mr-1" />
                    Email Customer
                  </Button>
                </div>
              </div>
            )}
          </div>
        )}
      </CardContent>
    </Card>
  );
}