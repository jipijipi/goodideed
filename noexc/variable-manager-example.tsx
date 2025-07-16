// Example: Variable Manager System
import React, { useState, useContext, createContext } from 'react';

interface VariableDefinition {
  key: string;
  type: 'string' | 'number' | 'boolean' | 'object' | 'array';
  defaultValue: any;
  description: string;
  category: 'user' | 'session' | 'system' | 'achievement' | 'custom';
  usage: VariableUsage[];
  readonly: boolean;
  deprecated: boolean;
}

interface VariableUsage {
  sequenceId: string;
  nodeId: string;
  action: 'read' | 'write' | 'increment' | 'decrement' | 'reset';
  context: string; // template, condition, data action, etc.
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
  trackUsage: (key: string, usage: VariableUsage) => void;
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
      usage: [],
      readonly: false,
      deprecated: false
    }],
    ['user.score', {
      key: 'user.score',
      type: 'number',
      defaultValue: 0,
      description: 'User\'s current score',
      category: 'user',
      usage: [],
      readonly: false,
      deprecated: false
    }],
    ['session.visitCount', {
      key: 'session.visitCount',
      type: 'number',
      defaultValue: 1,
      description: 'Number of times user has visited today',
      category: 'session',
      usage: [],
      readonly: true,
      deprecated: false
    }],
    ['session.totalVisitCount', {
      key: 'session.totalVisitCount',
      type: 'number',
      defaultValue: 1,
      description: 'Total number of app launches',
      category: 'session',
      usage: [],
      readonly: true,
      deprecated: false
    }],
    ['session.timeOfDay', {
      key: 'session.timeOfDay',
      type: 'number',
      defaultValue: 1,
      description: 'Time of day: 1=morning, 2=afternoon, 3=evening, 4=night',
      category: 'session',
      usage: [],
      readonly: true,
      deprecated: false
    }]
  ]));

  const addVariable = (variable: VariableDefinition) => {
    setVariables(prev => new Map(prev).set(variable.key, variable));
  };

  const updateVariable = (key: string, updates: Partial<VariableDefinition>) => {
    setVariables(prev => {
      const updated = new Map(prev);
      const existing = updated.get(key);
      if (existing) {
        updated.set(key, { ...existing, ...updates });
      }
      return updated;
    });
  };

  const removeVariable = (key: string) => {
    setVariables(prev => {
      const updated = new Map(prev);
      updated.delete(key);
      return updated;
    });
  };

  const getVariable = (key: string) => variables.get(key);

  const getVariablesByCategory = (category: string) => {
    return Array.from(variables.values()).filter(v => v.category === category);
  };

  const getVariableSuggestions = (prefix: string) => {
    return Array.from(variables.keys())
      .filter(key => key.toLowerCase().includes(prefix.toLowerCase()))
      .sort();
  };

  const validateVariable = (key: string): { valid: boolean; errors: string[] } => {
    const errors: string[] = [];
    
    if (!key.trim()) {
      errors.push('Variable key cannot be empty');
    }
    
    if (!/^[a-zA-Z][a-zA-Z0-9._]*$/.test(key)) {
      errors.push('Variable key must start with a letter and contain only letters, numbers, dots, and underscores');
    }
    
    if (key.includes('..')) {
      errors.push('Variable key cannot contain consecutive dots');
    }
    
    if (key.endsWith('.')) {
      errors.push('Variable key cannot end with a dot');
    }
    
    return { valid: errors.length === 0, errors };
  };

  const trackUsage = (key: string, usage: VariableUsage) => {
    updateVariable(key, {
      usage: [...(getVariable(key)?.usage || []), usage]
    });
  };

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
      trackUsage
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

// Variable Manager UI Component
const VariableManagerPanel: React.FC<{
  isOpen: boolean;
  onClose: () => void;
}> = ({ isOpen, onClose }) => {
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const [searchTerm, setSearchTerm] = useState('');
  const [showAddForm, setShowAddForm] = useState(false);
  const [newVariable, setNewVariable] = useState<Partial<VariableDefinition>>({
    key: '',
    type: 'string',
    defaultValue: '',
    description: '',
    category: 'custom',
    readonly: false,
    deprecated: false
  });

  const variableManager = useVariableManager();

  if (!isOpen) return null;

  const categories = ['all', 'user', 'session', 'system', 'achievement', 'custom'];
  
  const filteredVariables = Array.from(variableManager.variables.values())
    .filter(variable => 
      (selectedCategory === 'all' || variable.category === selectedCategory) &&
      (searchTerm === '' || 
       variable.key.toLowerCase().includes(searchTerm.toLowerCase()) ||
       variable.description.toLowerCase().includes(searchTerm.toLowerCase()))
    );

  const handleAddVariable = () => {
    if (newVariable.key && newVariable.description) {
      const validation = variableManager.validateVariable(newVariable.key);
      if (validation.valid) {
        variableManager.addVariable({
          ...newVariable,
          usage: []
        } as VariableDefinition);
        setNewVariable({
          key: '',
          type: 'string',
          defaultValue: '',
          description: '',
          category: 'custom',
          readonly: false,
          deprecated: false
        });
        setShowAddForm(false);
      } else {
        alert('Invalid variable key: ' + validation.errors.join(', '));
      }
    }
  };

  const getCategoryColor = (category: string) => {
    const colors = {
      user: '#2196f3',
      session: '#ff9800',
      system: '#4caf50',
      achievement: '#9c27b0',
      custom: '#607d8b'
    };
    return colors[category as keyof typeof colors] || '#999';
  };

  const getTypeIcon = (type: string) => {
    const icons = {
      string: '📝',
      number: '🔢',
      boolean: '✅',
      object: '🗂️',
      array: '📋'
    };
    return icons[type as keyof typeof icons] || '❓';
  };

  return (
    <div className="variable-manager-panel">
      <div className="panel-header">
        <h3>🗂️ Variable Manager</h3>
        <button onClick={onClose}>×</button>
      </div>
      
      <div className="panel-controls">
        <div className="search-box">
          <input
            type="text"
            placeholder="Search variables..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>
        
        <div className="category-filter">
          <select 
            value={selectedCategory} 
            onChange={(e) => setSelectedCategory(e.target.value)}
          >
            {categories.map(cat => (
              <option key={cat} value={cat}>
                {cat.charAt(0).toUpperCase() + cat.slice(1)}
              </option>
            ))}
          </select>
        </div>
        
        <button 
          className="add-variable-btn"
          onClick={() => setShowAddForm(true)}
        >
          + Add Variable
        </button>
      </div>

      {showAddForm && (
        <div className="add-variable-form">
          <h4>Add New Variable</h4>
          <div className="form-row">
            <input
              type="text"
              placeholder="Variable key (e.g., user.newProperty)"
              value={newVariable.key}
              onChange={(e) => setNewVariable({...newVariable, key: e.target.value})}
            />
            <select
              value={newVariable.type}
              onChange={(e) => setNewVariable({...newVariable, type: e.target.value as any})}
            >
              <option value="string">String</option>
              <option value="number">Number</option>
              <option value="boolean">Boolean</option>
              <option value="object">Object</option>
              <option value="array">Array</option>
            </select>
          </div>
          <div className="form-row">
            <input
              type="text"
              placeholder="Default value"
              value={newVariable.defaultValue}
              onChange={(e) => setNewVariable({...newVariable, defaultValue: e.target.value})}
            />
            <select
              value={newVariable.category}
              onChange={(e) => setNewVariable({...newVariable, category: e.target.value as any})}
            >
              <option value="custom">Custom</option>
              <option value="user">User</option>
              <option value="achievement">Achievement</option>
            </select>
          </div>
          <input
            type="text"
            placeholder="Description"
            value={newVariable.description}
            onChange={(e) => setNewVariable({...newVariable, description: e.target.value})}
          />
          <div className="form-actions">
            <button onClick={handleAddVariable}>Add Variable</button>
            <button onClick={() => setShowAddForm(false)}>Cancel</button>
          </div>
        </div>
      )}

      <div className="variables-list">
        {filteredVariables.map(variable => (
          <div key={variable.key} className="variable-item">
            <div className="variable-header">
              <div className="variable-info">
                <span className="variable-type">{getTypeIcon(variable.type)}</span>
                <span className="variable-key">{variable.key}</span>
                <span 
                  className="variable-category"
                  style={{ backgroundColor: getCategoryColor(variable.category) }}
                >
                  {variable.category}
                </span>
                {variable.readonly && <span className="readonly-badge">readonly</span>}
                {variable.deprecated && <span className="deprecated-badge">deprecated</span>}
              </div>
              <div className="variable-actions">
                <button className="edit-btn">✏️</button>
                <button className="delete-btn">🗑️</button>
              </div>
            </div>
            
            <div className="variable-description">
              {variable.description}
            </div>
            
            <div className="variable-details">
              <div className="default-value">
                <strong>Default:</strong> <code>{JSON.stringify(variable.defaultValue)}</code>
              </div>
              <div className="usage-count">
                <strong>Used in:</strong> {variable.usage.length} places
              </div>
            </div>
            
            {variable.usage.length > 0 && (
              <div className="usage-locations">
                <strong>Usage:</strong>
                <ul>
                  {variable.usage.slice(0, 3).map((usage, index) => (
                    <li key={index}>
                      {usage.sequenceId} (node {usage.nodeId}) - {usage.action} in {usage.context}
                    </li>
                  ))}
                  {variable.usage.length > 3 && (
                    <li>... and {variable.usage.length - 3} more</li>
                  )}
                </ul>
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
};

// Auto-complete input component
const VariableInput: React.FC<{
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
  context?: string;
}> = ({ value, onChange, placeholder, context = 'general' }) => {
  const [showSuggestions, setShowSuggestions] = useState(false);
  const [suggestions, setSuggestions] = useState<string[]>([]);
  const variableManager = useVariableManager();

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const newValue = e.target.value;
    onChange(newValue);
    
    // Extract variable references from template strings
    const matches = newValue.match(/\{([^}]*)/g);
    if (matches) {
      const lastMatch = matches[matches.length - 1];
      const variablePart = lastMatch.substring(1); // Remove the {
      const suggestions = variableManager.getVariableSuggestions(variablePart);
      setSuggestions(suggestions);
      setShowSuggestions(suggestions.length > 0);
    } else {
      setShowSuggestions(false);
    }
  };

  const handleSuggestionClick = (suggestion: string) => {
    // Replace the current variable being typed with the suggestion
    const newValue = value.replace(/\{[^}]*$/, `{${suggestion}}`);
    onChange(newValue);
    setShowSuggestions(false);
  };

  return (
    <div className="variable-input-container">
      <input
        type="text"
        value={value}
        onChange={handleInputChange}
        placeholder={placeholder}
        onFocus={() => handleInputChange({ target: { value } } as any)}
        onBlur={() => setTimeout(() => setShowSuggestions(false), 100)}
      />
      
      {showSuggestions && (
        <div className="variable-suggestions">
          {suggestions.map(suggestion => {
            const variable = variableManager.getVariable(suggestion);
            return (
              <div
                key={suggestion}
                className="suggestion-item"
                onClick={() => handleSuggestionClick(suggestion)}
              >
                <div className="suggestion-key">{suggestion}</div>
                <div className="suggestion-type">{getTypeIcon(variable?.type || 'string')}</div>
                <div className="suggestion-description">{variable?.description}</div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
};

export { VariableManagerPanel, VariableInput };