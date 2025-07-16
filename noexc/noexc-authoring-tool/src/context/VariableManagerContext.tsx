import React, { createContext, useContext, useState, useCallback } from 'react';

export interface VariableDefinition {
  key: string;
  type: 'string' | 'number' | 'boolean' | 'object';
  defaultValue: any;
  description: string;
  category: 'user' | 'session' | 'system' | 'achievement' | 'custom';
  readonly: boolean;
}

interface VariableManagerContextType {
  variables: Map<string, VariableDefinition>;
  addVariable: (variable: VariableDefinition) => void;
  updateVariable: (key: string, updates: Partial<VariableDefinition>) => void;
  removeVariable: (key: string) => void;
  getVariable: (key: string) => VariableDefinition | undefined;
  getVariablesByCategory: (category: string) => VariableDefinition[];
  getVariableSuggestions: (prefix: string) => string[];
  validateVariable: (key: string) => { valid: boolean; errors: string[] };
}

const VariableManagerContext = createContext<VariableManagerContextType | null>(null);

export const VariableManagerProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [variables, setVariables] = useState<Map<string, VariableDefinition>>(new Map([
    // Built-in system variables
    ['user.name', {
      key: 'user.name',
      type: 'string',
      defaultValue: '',
      description: 'User\'s display name',
      category: 'user',
      readonly: false
    }],
    ['user.score', {
      key: 'user.score',
      type: 'number',
      defaultValue: 0,
      description: 'User\'s current score points',
      category: 'user',
      readonly: false
    }],
    ['user.level', {
      key: 'user.level',
      type: 'number',
      defaultValue: 1,
      description: 'User\'s current level',
      category: 'user',
      readonly: false
    }],
    ['user.streak', {
      key: 'user.streak',
      type: 'number',
      defaultValue: 0,
      description: 'User\'s current streak count',
      category: 'user',
      readonly: false
    }],
    ['user.achievements', {
      key: 'user.achievements',
      type: 'number',
      defaultValue: 0,
      description: 'Total number of achievements unlocked',
      category: 'achievement',
      readonly: false
    }],
    ['session.visitCount', {
      key: 'session.visitCount',
      type: 'number',
      defaultValue: 1,
      description: 'Number of times user visited today (resets daily)',
      category: 'session',
      readonly: true
    }],
    ['session.totalVisitCount', {
      key: 'session.totalVisitCount',
      type: 'number',
      defaultValue: 1,
      description: 'Total number of app launches (never resets)',
      category: 'session',
      readonly: true
    }],
    ['session.timeOfDay', {
      key: 'session.timeOfDay',
      type: 'number',
      defaultValue: 1,
      description: 'Time of day: 1=morning, 2=afternoon, 3=evening, 4=night',
      category: 'session',
      readonly: true
    }],
    ['session.isWeekend', {
      key: 'session.isWeekend',
      type: 'boolean',
      defaultValue: false,
      description: 'Whether current day is weekend (Saturday/Sunday)',
      category: 'session',
      readonly: true
    }],
    ['session.daysSinceFirstVisit', {
      key: 'session.daysSinceFirstVisit',
      type: 'number',
      defaultValue: 0,
      description: 'Number of days since first app launch',
      category: 'session',
      readonly: true
    }]
  ]));

  const addVariable = useCallback((variable: VariableDefinition) => {
    setVariables(prev => new Map(prev).set(variable.key, variable));
  }, []);

  const updateVariable = useCallback((key: string, updates: Partial<VariableDefinition>) => {
    setVariables(prev => {
      const updated = new Map(prev);
      const existing = updated.get(key);
      if (existing) {
        updated.set(key, { ...existing, ...updates });
      }
      return updated;
    });
  }, []);

  const removeVariable = useCallback((key: string) => {
    setVariables(prev => {
      const updated = new Map(prev);
      updated.delete(key);
      return updated;
    });
  }, []);

  const getVariable = useCallback((key: string) => variables.get(key), [variables]);

  const getVariablesByCategory = useCallback((category: string) => {
    return Array.from(variables.values()).filter(v => v.category === category);
  }, [variables]);

  const getVariableSuggestions = useCallback((prefix: string) => {
    return Array.from(variables.keys())
      .filter(key => key.toLowerCase().includes(prefix.toLowerCase()))
      .sort();
  }, [variables]);

  const validateVariable = useCallback((key: string): { valid: boolean; errors: string[] } => {
    const errors: string[] = [];
    
    if (!key.trim()) {
      errors.push('Variable key cannot be empty');
    }
    
    if (!/^[a-zA-Z][a-zA-Z0-9._]*$/.test(key)) {
      errors.push('Key must start with a letter and contain only letters, numbers, dots, and underscores');
    }
    
    if (key.includes('..')) {
      errors.push('Key cannot contain consecutive dots');
    }
    
    if (key.endsWith('.')) {
      errors.push('Key cannot end with a dot');
    }
    
    return { valid: errors.length === 0, errors };
  }, []);

  return (
    <VariableManagerContext.Provider value={{
      variables,
      addVariable,
      updateVariable,
      removeVariable,
      getVariable,
      getVariablesByCategory,
      getVariableSuggestions,
      validateVariable
    }}>
      {children}
    </VariableManagerContext.Provider>
  );
};

export const useVariableManager = () => {
  const context = useContext(VariableManagerContext);
  if (!context) {
    throw new Error('useVariableManager must be used within a VariableManagerProvider');
  }
  return context;
};