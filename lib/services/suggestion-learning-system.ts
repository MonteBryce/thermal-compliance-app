import { LogField, FieldType, LogTemplate } from '@/lib/types/logbuilder';

export interface UserInteraction {
  id: string;
  timestamp: number;
  userId?: string;
  sessionId: string;
  interactionType: 'suggestion_shown' | 'suggestion_accepted' | 'suggestion_rejected' | 'field_created' | 'field_modified' | 'template_saved';
  context: {
    templateType?: string;
    industryContext?: string;
    fieldKey?: string;
    fieldLabel?: string;
    fieldType?: FieldType;
    suggestion?: {
      type: 'field_name' | 'field_type' | 'validation' | 'help_text' | 'pattern';
      value: any;
      source: 'ai' | 'pattern' | 'history';
      confidence: number;
    };
  };
  outcome?: {
    accepted: boolean;
    userModifications?: any;
    finalValue?: any;
    timeToDecision?: number; // milliseconds
  };
}

export interface LearningInsight {
  pattern: string;
  confidence: number;
  supportingEvidence: number;
  lastUpdated: number;
  effectiveness: number; // 0-1 score based on user acceptance
}

export interface SuggestionMetrics {
  totalSuggestions: number;
  acceptanceRate: number;
  rejectionRate: number;
  modificationRate: number;
  averageDecisionTime: number;
  topAcceptedPatterns: Array<{ pattern: string; acceptanceRate: number }>;
  topRejectedPatterns: Array<{ pattern: string; rejectionRate: number }>;
  improvementTrends: Array<{ date: string; acceptanceRate: number }>;
}

export class SuggestionLearningSystem {
  private static instance: SuggestionLearningSystem;
  private sessionId: string;
  private userId?: string;
  private interactions: UserInteraction[] = [];
  private insights: Map<string, LearningInsight> = new Map();
  
  private constructor() {
    this.sessionId = this.generateSessionId();
    this.loadStoredData();
    this.setupEventListeners();
  }
  
  static getInstance(): SuggestionLearningSystem {
    if (!SuggestionLearningSystem.instance) {
      SuggestionLearningSystem.instance = new SuggestionLearningSystem();
    }
    return SuggestionLearningSystem.instance;
  }
  
  private generateSessionId(): string {
    return `session_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }
  
  private loadStoredData(): void {
    try {
      // Load interactions
      const storedInteractions = localStorage.getItem('suggestion-learning-interactions');
      if (storedInteractions) {
        this.interactions = JSON.parse(storedInteractions);
        // Keep only interactions from the last 30 days
        const thirtyDaysAgo = Date.now() - (30 * 24 * 60 * 60 * 1000);
        this.interactions = this.interactions.filter(i => i.timestamp > thirtyDaysAgo);
      }
      
      // Load insights
      const storedInsights = localStorage.getItem('suggestion-learning-insights');
      if (storedInsights) {
        const insightsData = JSON.parse(storedInsights);
        this.insights = new Map(insightsData);
      }
      
      // Load user ID if available
      this.userId = localStorage.getItem('user-id') || undefined;
    } catch (error) {
      console.warn('Failed to load learning data:', error);
    }
  }
  
  private saveData(): void {
    try {
      localStorage.setItem('suggestion-learning-interactions', JSON.stringify(this.interactions));
      localStorage.setItem('suggestion-learning-insights', JSON.stringify([...this.insights]));
    } catch (error) {
      console.warn('Failed to save learning data:', error);
    }
  }
  
  private setupEventListeners(): void {
    // Save data before page unload
    window.addEventListener('beforeunload', () => {
      this.saveData();
    });
    
    // Periodic saving
    setInterval(() => {
      this.saveData();
    }, 60000); // Save every minute
  }
  
  /**
   * Set user ID for personalized learning
   */
  setUserId(userId: string): void {
    this.userId = userId;
    localStorage.setItem('user-id', userId);
  }
  
  /**
   * Record when a suggestion is shown to the user
   */
  recordSuggestionShown(context: {
    templateType?: string;
    industryContext?: string;
    fieldKey?: string;
    fieldLabel?: string;
    suggestion: {
      type: 'field_name' | 'field_type' | 'validation' | 'help_text' | 'pattern';
      value: any;
      source: 'ai' | 'pattern' | 'history';
      confidence: number;
    };
  }): string {
    const interaction: UserInteraction = {
      id: this.generateInteractionId(),
      timestamp: Date.now(),
      userId: this.userId,
      sessionId: this.sessionId,
      interactionType: 'suggestion_shown',
      context
    };
    
    this.interactions.push(interaction);
    return interaction.id;
  }
  
  /**
   * Record user's response to a suggestion
   */
  recordSuggestionResponse(
    suggestionId: string,
    accepted: boolean,
    userModifications?: any,
    finalValue?: any,
    decisionTime?: number
  ): void {
    const interaction = this.interactions.find(i => i.id === suggestionId);
    if (!interaction) {
      console.warn('Suggestion interaction not found:', suggestionId);
      return;
    }
    
    interaction.outcome = {
      accepted,
      userModifications,
      finalValue,
      timeToDecision: decisionTime
    };
    
    // Update interaction type
    interaction.interactionType = accepted ? 'suggestion_accepted' : 'suggestion_rejected';
    
    // Learn from this interaction
    this.updateLearningInsights(interaction);
  }
  
  /**
   * Record field creation events
   */
  recordFieldCreated(field: LogField, context: {
    templateType?: string;
    industryContext?: string;
  }): void {
    const interaction: UserInteraction = {
      id: this.generateInteractionId(),
      timestamp: Date.now(),
      userId: this.userId,
      sessionId: this.sessionId,
      interactionType: 'field_created',
      context: {
        ...context,
        fieldKey: field.key,
        fieldLabel: field.label,
        fieldType: field.type
      }
    };
    
    this.interactions.push(interaction);
    this.updateFieldCreationInsights(field, context);
  }
  
  /**
   * Record template save events
   */
  recordTemplateSaved(template: LogTemplate): void {
    const interaction: UserInteraction = {
      id: this.generateInteractionId(),
      timestamp: Date.now(),
      userId: this.userId,
      sessionId: this.sessionId,
      interactionType: 'template_saved',
      context: {
        templateType: template.logType
      }
    };
    
    this.interactions.push(interaction);
  }
  
  /**
   * Get improved suggestions based on learning
   */
  getImprovedSuggestions(context: {
    templateType?: string;
    industryContext?: string;
    fieldKey?: string;
    suggestionType: 'field_name' | 'field_type' | 'validation' | 'help_text' | 'pattern';
  }): Array<{
    value: any;
    confidence: number;
    source: 'learned' | 'pattern' | 'ai';
    reasoning: string;
  }> {
    const suggestions: Array<{
      value: any;
      confidence: number;
      source: 'learned' | 'pattern' | 'ai';
      reasoning: string;
    }> = [];
    
    // Generate pattern key for lookup
    const patternKey = this.generatePatternKey(context);
    const relatedInsights = this.findRelatedInsights(patternKey);
    
    // Convert insights to suggestions
    for (const insight of relatedInsights) {
      if (insight.effectiveness > 0.6 && insight.supportingEvidence >= 3) {
        suggestions.push({
          value: this.extractValueFromPattern(insight.pattern),
          confidence: insight.confidence * insight.effectiveness,
          source: 'learned',
          reasoning: `Learned from ${insight.supportingEvidence} similar cases with ${Math.round(insight.effectiveness * 100)}% success rate`
        });
      }
    }
    
    return suggestions.sort((a, b) => b.confidence - a.confidence);
  }
  
  /**
   * Get performance metrics for suggestions
   */
  getSuggestionMetrics(timeRange?: { start: number; end: number }): SuggestionMetrics {
    let filteredInteractions = this.interactions;
    
    if (timeRange) {
      filteredInteractions = this.interactions.filter(i => 
        i.timestamp >= timeRange.start && i.timestamp <= timeRange.end
      );
    }
    
    const suggestionInteractions = filteredInteractions.filter(i => 
      ['suggestion_accepted', 'suggestion_rejected'].includes(i.interactionType)
    );
    
    const totalSuggestions = suggestionInteractions.length;
    const acceptedSuggestions = suggestionInteractions.filter(i => i.outcome?.accepted).length;
    const rejectedSuggestions = suggestionInteractions.filter(i => !i.outcome?.accepted).length;
    const modifiedSuggestions = suggestionInteractions.filter(i => i.outcome?.userModifications).length;
    
    // Calculate decision times
    const decisionTimes = suggestionInteractions
      .filter(i => i.outcome?.timeToDecision)
      .map(i => i.outcome!.timeToDecision!);
    const averageDecisionTime = decisionTimes.length > 0 
      ? decisionTimes.reduce((a, b) => a + b, 0) / decisionTimes.length 
      : 0;
    
    // Top patterns
    const patternStats = new Map<string, { accepted: number; total: number }>();
    
    suggestionInteractions.forEach(interaction => {
      if (interaction.context.suggestion) {
        const pattern = `${interaction.context.suggestion.type}:${interaction.context.suggestion.source}`;
        const stats = patternStats.get(pattern) || { accepted: 0, total: 0 };
        stats.total++;
        if (interaction.outcome?.accepted) {
          stats.accepted++;
        }
        patternStats.set(pattern, stats);
      }
    });
    
    const topAccepted = Array.from(patternStats.entries())
      .map(([pattern, stats]) => ({ 
        pattern, 
        acceptanceRate: stats.accepted / stats.total 
      }))
      .sort((a, b) => b.acceptanceRate - a.acceptanceRate)
      .slice(0, 10);
    
    const topRejected = Array.from(patternStats.entries())
      .map(([pattern, stats]) => ({ 
        pattern, 
        rejectionRate: (stats.total - stats.accepted) / stats.total 
      }))
      .sort((a, b) => b.rejectionRate - a.rejectionRate)
      .slice(0, 10);
    
    // Improvement trends (last 7 days)
    const improvementTrends = this.calculateImprovementTrends(7);
    
    return {
      totalSuggestions,
      acceptanceRate: totalSuggestions > 0 ? acceptedSuggestions / totalSuggestions : 0,
      rejectionRate: totalSuggestions > 0 ? rejectedSuggestions / totalSuggestions : 0,
      modificationRate: totalSuggestions > 0 ? modifiedSuggestions / totalSuggestions : 0,
      averageDecisionTime,
      topAcceptedPatterns: topAccepted,
      topRejectedPatterns: topRejected,
      improvementTrends
    };
  }
  
  /**
   * Export learning data for analysis
   */
  exportLearningData(): {
    interactions: UserInteraction[];
    insights: Array<[string, LearningInsight]>;
    metrics: SuggestionMetrics;
  } {
    return {
      interactions: this.interactions,
      insights: [...this.insights],
      metrics: this.getSuggestionMetrics()
    };
  }
  
  /**
   * Clear all learning data (for privacy/reset)
   */
  clearLearningData(): void {
    this.interactions = [];
    this.insights.clear();
    localStorage.removeItem('suggestion-learning-interactions');
    localStorage.removeItem('suggestion-learning-insights');
  }
  
  // Private helper methods
  
  private generateInteractionId(): string {
    return `interaction_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }
  
  private updateLearningInsights(interaction: UserInteraction): void {
    if (!interaction.context.suggestion) return;
    
    const patternKey = this.generatePatternKey({
      templateType: interaction.context.templateType,
      industryContext: interaction.context.industryContext,
      fieldKey: interaction.context.fieldKey,
      suggestionType: interaction.context.suggestion.type
    });
    
    const existing = this.insights.get(patternKey);
    const isAccepted = interaction.outcome?.accepted || false;
    
    if (existing) {
      existing.supportingEvidence++;
      existing.effectiveness = this.calculateEffectiveness(patternKey);
      existing.lastUpdated = Date.now();
    } else {
      this.insights.set(patternKey, {
        pattern: patternKey,
        confidence: interaction.context.suggestion.confidence,
        supportingEvidence: 1,
        lastUpdated: Date.now(),
        effectiveness: isAccepted ? 1.0 : 0.0
      });
    }
  }
  
  private updateFieldCreationInsights(field: LogField, context: any): void {
    // Learn from user-created fields to improve future suggestions
    const patterns = [
      `field_type:${context.templateType}:${field.type}`,
      `field_name:${field.key}:${field.type}`,
      `field_label:${field.label}:${field.type}`
    ];
    
    patterns.forEach(pattern => {
      const existing = this.insights.get(pattern);
      if (existing) {
        existing.supportingEvidence++;
        existing.lastUpdated = Date.now();
      } else {
        this.insights.set(pattern, {
          pattern,
          confidence: 0.8,
          supportingEvidence: 1,
          lastUpdated: Date.now(),
          effectiveness: 0.8 // Assume user-created fields are good examples
        });
      }
    });
  }
  
  private generatePatternKey(context: any): string {
    return [
      context.suggestionType || 'unknown',
      context.templateType || 'generic',
      context.industryContext || 'general',
      context.fieldKey || 'any'
    ].join(':');
  }
  
  private findRelatedInsights(patternKey: string): LearningInsight[] {
    const parts = patternKey.split(':');
    const related: LearningInsight[] = [];
    
    // Find exact matches first
    const exact = this.insights.get(patternKey);
    if (exact) related.push(exact);
    
    // Find partial matches
    for (const [key, insight] of this.insights) {
      const keyParts = key.split(':');
      let matchScore = 0;
      
      for (let i = 0; i < Math.min(parts.length, keyParts.length); i++) {
        if (parts[i] === keyParts[i]) {
          matchScore += 1 / parts.length;
        }
      }
      
      if (matchScore >= 0.5 && key !== patternKey) {
        related.push(insight);
      }
    }
    
    return related.sort((a, b) => b.effectiveness - a.effectiveness);
  }
  
  private calculateEffectiveness(patternKey: string): number {
    const relatedInteractions = this.interactions.filter(i => {
      if (!i.context.suggestion || !i.outcome) return false;
      const key = this.generatePatternKey({
        suggestionType: i.context.suggestion.type,
        templateType: i.context.templateType,
        industryContext: i.context.industryContext,
        fieldKey: i.context.fieldKey
      });
      return key === patternKey;
    });
    
    if (relatedInteractions.length === 0) return 0.5;
    
    const accepted = relatedInteractions.filter(i => i.outcome?.accepted).length;
    return accepted / relatedInteractions.length;
  }
  
  private extractValueFromPattern(pattern: string): any {
    // This would extract the actual suggestion value from the pattern
    // Implementation would depend on how patterns are structured
    const parts = pattern.split(':');
    return parts[parts.length - 1] || pattern;
  }
  
  private calculateImprovementTrends(days: number): Array<{ date: string; acceptanceRate: number }> {
    const trends: Array<{ date: string; acceptanceRate: number }> = [];
    const now = Date.now();
    const dayMs = 24 * 60 * 60 * 1000;
    
    for (let i = days - 1; i >= 0; i--) {
      const dayStart = now - (i * dayMs);
      const dayEnd = dayStart + dayMs;
      
      const dayInteractions = this.interactions.filter(interaction => 
        interaction.timestamp >= dayStart && 
        interaction.timestamp < dayEnd &&
        ['suggestion_accepted', 'suggestion_rejected'].includes(interaction.interactionType)
      );
      
      const accepted = dayInteractions.filter(i => i.outcome?.accepted).length;
      const total = dayInteractions.length;
      const acceptanceRate = total > 0 ? accepted / total : 0;
      
      trends.push({
        date: new Date(dayStart).toISOString().split('T')[0],
        acceptanceRate
      });
    }
    
    return trends;
  }
}