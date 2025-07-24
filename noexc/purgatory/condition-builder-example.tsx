// Example: Visual Condition Builder Component
import React, { useState } from 'react';

interface ConditionRule {
  id: string;
  variable: string;
  operator: '==' | '!=' | '>' | '<' | '>=' | '<=' | 'exists' | 'not_exists';
  value: string | number | boolean;
  type: 'string' | 'number' | 'boolean';
}

interface ConditionGroup {
  id: string;
  logic: 'AND' | 'OR';
  rules: ConditionRule[];
  groups: ConditionGroup[];
}

const ConditionBuilder: React.FC<{
  condition: ConditionGroup;
  onChange: (condition: ConditionGroup) => void;
  availableVariables: string[];
}> = ({ condition, onChange, availableVariables }) => {
  
  const addRule = () => {
    const newRule: ConditionRule = {
      id: Date.now().toString(),
      variable: availableVariables[0] || 'user.score',
      operator: '==',
      value: '',
      type: 'string'
    };
    
    onChange({
      ...condition,
      rules: [...condition.rules, newRule]
    });
  };

  const addGroup = () => {
    const newGroup: ConditionGroup = {
      id: Date.now().toString(),
      logic: 'AND',
      rules: [],
      groups: []
    };
    
    onChange({
      ...condition,
      groups: [...condition.groups, newGroup]
    });
  };

  const updateRule = (ruleId: string, updates: Partial<ConditionRule>) => {
    const updatedRules = condition.rules.map(rule => 
      rule.id === ruleId ? { ...rule, ...updates } : rule
    );
    onChange({ ...condition, rules: updatedRules });
  };

  const removeRule = (ruleId: string) => {
    onChange({
      ...condition,
      rules: condition.rules.filter(rule => rule.id !== ruleId)
    });
  };

  const generateConditionString = (group: ConditionGroup): string => {
    const ruleStrings = group.rules.map(rule => {
      const { variable, operator, value, type } = rule;
      
      if (operator === 'exists') return `${variable} != null`;
      if (operator === 'not_exists') return `${variable} == null`;
      
      const formattedValue = type === 'string' 
        ? `"${value}"` 
        : value;
      
      return `${variable} ${operator} ${formattedValue}`;
    });
    
    const groupStrings = group.groups.map(subGroup => 
      `(${generateConditionString(subGroup)})`
    );
    
    const allConditions = [...ruleStrings, ...groupStrings];
    const logicOperator = group.logic === 'AND' ? ' && ' : ' || ';
    
    return allConditions.join(logicOperator);
  };

  return (
    <div className="condition-builder">
      <div className="logic-selector">
        <label>Logic: </label>
        <select 
          value={condition.logic} 
          onChange={(e) => onChange({...condition, logic: e.target.value as 'AND' | 'OR'})}
        >
          <option value="AND">AND (all must be true)</option>
          <option value="OR">OR (any can be true)</option>
        </select>
      </div>

      {/* Render Rules */}
      {condition.rules.map((rule) => (
        <div key={rule.id} className="condition-rule">
          <select 
            value={rule.variable}
            onChange={(e) => updateRule(rule.id, { variable: e.target.value })}
          >
            {availableVariables.map(variable => (
              <option key={variable} value={variable}>{variable}</option>
            ))}
          </select>
          
          <select 
            value={rule.operator}
            onChange={(e) => updateRule(rule.id, { operator: e.target.value as any })}
          >
            <option value="==">=</option>
            <option value="!=">≠</option>
            <option value=">">&gt;</option>
            <option value="<">&lt;</option>
            <option value=">=">&gt;=</option>
            <option value="<=">&lt;=</option>
            <option value="exists">exists</option>
            <option value="not_exists">not exists</option>
          </select>
          
          {!['exists', 'not_exists'].includes(rule.operator) && (
            <input 
              type={rule.type === 'number' ? 'number' : 'text'}
              value={rule.value}
              onChange={(e) => updateRule(rule.id, { 
                value: rule.type === 'number' ? Number(e.target.value) : e.target.value 
              })}
              placeholder="Value"
            />
          )}
          
          <button onClick={() => removeRule(rule.id)}>×</button>
        </div>
      ))}

      {/* Render Nested Groups */}
      {condition.groups.map((group) => (
        <div key={group.id} className="condition-group nested">
          <ConditionBuilder 
            condition={group}
            onChange={(updatedGroup) => {
              const updatedGroups = condition.groups.map(g => 
                g.id === group.id ? updatedGroup : g
              );
              onChange({ ...condition, groups: updatedGroups });
            }}
            availableVariables={availableVariables}
          />
        </div>
      ))}

      <div className="condition-actions">
        <button onClick={addRule}>+ Add Rule</button>
        <button onClick={addGroup}>+ Add Group</button>
      </div>

      {/* Preview */}
      <div className="condition-preview">
        <strong>Generated Condition:</strong>
        <code>{generateConditionString(condition)}</code>
      </div>
    </div>
  );
};

export default ConditionBuilder;