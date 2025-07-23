import React, { createContext, useContext, useState, useCallback, useEffect } from 'react';
import { LocalStoragePersistence, AutoSave, PersistenceResult } from '../utils/variablePersistence';

export interface VariableDefinition {
  key: string;
  type: 'string' | 'number' | 'boolean' | 'object';
  defaultValue: any;
  description: string;
  category: 'user' | 'session' | 'system' | 'custom';
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
  // Persistence methods
  saveToLocalStorage: () => PersistenceResult;
  loadFromLocalStorage: () => PersistenceResult;
  clearLocalStorage: () => PersistenceResult;
  importVariables: (newVariables: Map<string, VariableDefinition>) => void;
  replaceAllVariables: (newVariables: Map<string, VariableDefinition>) => void;
}

const VariableManagerContext = createContext<VariableManagerContextType | null>(null);

export const VariableManagerProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [variables, setVariables] = useState<Map<string, VariableDefinition>>(new Map());

  // Default variables for fallback
  const defaultVariables: [string, VariableDefinition][] = [
    // Built-in system variables
    ['user.name', {
      key: 'user.name',
      type: 'string',
      defaultValue: '',
      description: 'User\'s display name',
      category: 'user',
      readonly: false
    }],
    ['user.userTask', {
      key: 'user.userTask',
      type: 'string',
      defaultValue: '',
      description: 'User\'s current task description',
      category: 'user',
      readonly: false
    }],
    ['user.userStreak', {
      key: 'user.userStreak',
      type: 'number',
      defaultValue: 0,
      description: 'User\'s current streak count',
      category: 'user',
      readonly: false
    }],
    ['user.isOnboarded', {
      key: 'user.isOnboarded',
      type: 'boolean',
      defaultValue: false,
      description: 'Whether user has completed onboarding',
      category: 'user',
      readonly: false
    }],
    ['user.isOnNotice', {
      key: 'user.isOnNotice',
      type: 'boolean',
      defaultValue: false,
      description: 'Whether user is on notice for task performance',
      category: 'user',
      readonly: false
    }],
    ['user.userTaskDeadline', {
      key: 'user.userTaskDeadline',
      type: 'number',
      defaultValue: 1,
      description: 'User\'s configured deadline: 1=morning, 2=afternoon, 3=evening, 4=night',
      category: 'user',
      readonly: false
    }],
    // Task namespace variables
    ['task.deadlineTime', {
      key: 'task.deadlineTime',
      type: 'number',
      defaultValue: 1,
      description: 'Task deadline time: 1=morning, 2=afternoon, 3=evening, 4=night',
      category: 'system',
      readonly: false
    }],
    ['task.currentDate', {
      key: 'task.currentDate',
      type: 'string',
      defaultValue: '',
      description: 'Current task date (YYYY-MM-DD format)',
      category: 'system',
      readonly: false
    }],
    ['task.currentStatus', {
      key: 'task.currentStatus',
      type: 'string',
      defaultValue: 'pending',
      description: 'Task status: pending, completed, failed',
      category: 'system',
      readonly: false
    }],
    ['task.previousDate', {
      key: 'task.previousDate',
      type: 'string',
      defaultValue: '',
      description: 'Previous day\'s task date for archiving',
      category: 'system',
      readonly: false
    }],
    ['task.activeDays', {
      key: 'task.activeDays',
      type: 'string',
      defaultValue: '',
      description: 'User configured active days (comma-separated)',
      category: 'system',
      readonly: false
    }],
    ['task.gracePeriodUsed', {
      key: 'task.gracePeriodUsed',
      type: 'boolean',
      defaultValue: false,
      description: 'Whether grace period has been used',
      category: 'system',
      readonly: false
    }],
    ['task.currentTime', {
      key: 'task.currentTime',
      type: 'string',
      defaultValue: '',
      description: 'Current time in HH:MM format',
      category: 'system',
      readonly: false
    }],
    ['task.currentHour', {
      key: 'task.currentHour',
      type: 'number',
      defaultValue: 0,
      description: 'Current hour (0-23)',
      category: 'system',
      readonly: false
    }],
    ['task.currentMinute', {
      key: 'task.currentMinute',
      type: 'number',
      defaultValue: 0,
      description: 'Current minute (0-59)',
      category: 'system',
      readonly: false
    }],
    ['task.isActiveDay', {
      key: 'task.isActiveDay',
      type: 'boolean',
      defaultValue: false,
      description: 'Computed: Whether today is an active day for tasks',
      category: 'system',
      readonly: true
    }],
    ['task.isPastDeadline', {
      key: 'task.isPastDeadline',
      type: 'boolean',
      defaultValue: false,
      description: 'Computed: Whether current time is past task deadline',
      category: 'system',
      readonly: true
    }],
    // Session namespace variables
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
  ];

  // Load variables from localStorage on mount
  useEffect(() => {
    const result = LocalStoragePersistence.load();
    if (result.success && result.data) {
      const loadedVariables = result.data as Map<string, VariableDefinition>;
      if (loadedVariables.size > 0) {
        setVariables(loadedVariables);
      } else {
        // No saved variables, use defaults
        setVariables(new Map(defaultVariables));
      }
    } else {
      // Failed to load or no data, use defaults
      setVariables(new Map(defaultVariables));
    }
  }, []);

  // Auto-save to localStorage when variables change
  useEffect(() => {
    if (variables.size > 0) {
      AutoSave.schedule(variables);
    }
  }, [variables]);

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

  // Persistence methods
  const saveToLocalStorage = useCallback((): PersistenceResult => {
    return LocalStoragePersistence.save(variables);
  }, [variables]);

  const loadFromLocalStorage = useCallback((): PersistenceResult => {
    const result = LocalStoragePersistence.load();
    if (result.success && result.data) {
      setVariables(result.data as Map<string, VariableDefinition>);
    }
    return result;
  }, []);

  const clearLocalStorage = useCallback((): PersistenceResult => {
    const result = LocalStoragePersistence.clear();
    if (result.success) {
      setVariables(new Map(defaultVariables));
    }
    return result;
  }, []);

  const importVariables = useCallback((newVariables: Map<string, VariableDefinition>): void => {
    const merged = new Map(variables);
    newVariables.forEach((variable, key) => {
      merged.set(key, variable);
    });
    setVariables(merged);
  }, [variables]);

  const replaceAllVariables = useCallback((newVariables: Map<string, VariableDefinition>): void => {
    setVariables(new Map(newVariables));
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
      validateVariable,
      saveToLocalStorage,
      loadFromLocalStorage,
      clearLocalStorage,
      importVariables,
      replaceAllVariables
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