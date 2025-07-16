import React, { useState, useRef, useEffect } from 'react';
import { useVariableManager } from '../context/VariableManagerContext';

interface VariableInputProps {
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
  style?: React.CSSProperties;
  onClick?: (e: React.MouseEvent) => void;
}

const VariableInput: React.FC<VariableInputProps> = ({ 
  value, 
  onChange, 
  placeholder, 
  style,
  onClick 
}) => {
  const [showSuggestions, setShowSuggestions] = useState(false);
  const [suggestions, setSuggestions] = useState<string[]>([]);
  const [selectedSuggestion, setSelectedSuggestion] = useState(-1);
  const inputRef = useRef<HTMLInputElement>(null);
  const suggestionsRef = useRef<HTMLDivElement>(null);
  const variableManager = useVariableManager();

  // Extract the current template variable being typed
  const getCurrentVariable = (text: string, cursorPos: number) => {
    const beforeCursor = text.substring(0, cursorPos);
    const afterCursor = text.substring(cursorPos);
    
    // Find the last opening brace before cursor
    const lastOpenBrace = beforeCursor.lastIndexOf('{');
    if (lastOpenBrace === -1) return null;
    
    // Find the first closing brace after cursor
    const nextCloseBrace = afterCursor.indexOf('}');
    const beforeCloseBrace = beforeCursor.substring(lastOpenBrace + 1);
    
    // Check if we're inside a template variable
    if (beforeCloseBrace.includes('}')) return null;
    
    return {
      start: lastOpenBrace + 1,
      end: nextCloseBrace !== -1 ? cursorPos + nextCloseBrace : cursorPos,
      text: beforeCloseBrace
    };
  };

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const newValue = e.target.value;
    const cursorPos = e.target.selectionStart || 0;
    
    onChange(newValue);
    
    // Check if we're typing inside a template variable
    const currentVar = getCurrentVariable(newValue, cursorPos);
    if (currentVar) {
      // Get the variable key part (before |)
      const varKey = currentVar.text.split('|')[0];
      if (varKey) {
        const matchingSuggestions = variableManager.getVariableSuggestions(varKey);
        setSuggestions(matchingSuggestions);
        setShowSuggestions(matchingSuggestions.length > 0);
        setSelectedSuggestion(-1);
      } else {
        setShowSuggestions(false);
      }
    } else {
      setShowSuggestions(false);
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (!showSuggestions) return;
    
    switch (e.key) {
      case 'ArrowDown':
        e.preventDefault();
        setSelectedSuggestion(prev => 
          prev < suggestions.length - 1 ? prev + 1 : prev
        );
        break;
      case 'ArrowUp':
        e.preventDefault();
        setSelectedSuggestion(prev => prev > 0 ? prev - 1 : prev);
        break;
      case 'Enter':
      case 'Tab':
        e.preventDefault();
        if (selectedSuggestion >= 0 && suggestions[selectedSuggestion]) {
          applySuggestion(suggestions[selectedSuggestion]);
        } else if (suggestions.length > 0) {
          applySuggestion(suggestions[0]);
        }
        break;
      case 'Escape':
        setShowSuggestions(false);
        setSelectedSuggestion(-1);
        break;
    }
  };

  const applySuggestion = (suggestion: string) => {
    const cursorPos = inputRef.current?.selectionStart || 0;
    const currentVar = getCurrentVariable(value, cursorPos);
    
    if (currentVar) {
      const beforeVar = value.substring(0, currentVar.start);
      const afterVar = value.substring(currentVar.end);
      
      // Preserve any fallback value that was already typed
      const existingParts = currentVar.text.split('|');
      const fallback = existingParts.length > 1 ? `|${existingParts[1]}` : '';
      
      const newValue = `${beforeVar}${suggestion}${fallback}${afterVar}`;
      onChange(newValue);
      
      // Set cursor position after the variable
      setTimeout(() => {
        const newCursorPos = beforeVar.length + suggestion.length + fallback.length;
        inputRef.current?.setSelectionRange(newCursorPos, newCursorPos);
      }, 0);
    }
    
    setShowSuggestions(false);
    setSelectedSuggestion(-1);
  };

  // Hide suggestions when clicking outside
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (suggestionsRef.current && !suggestionsRef.current.contains(event.target as Node) &&
          inputRef.current && !inputRef.current.contains(event.target as Node)) {
        setShowSuggestions(false);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const getTypeIcon = (type: string) => {
    const icons = {
      string: '📝',
      number: '🔢',
      boolean: '✅',
      object: '🗂️'
    };
    return icons[type as keyof typeof icons] || '❓';
  };

  return (
    <div style={{ position: 'relative', display: 'inline-block', width: '100%' }}>
      <input
        ref={inputRef}
        type="text"
        value={value}
        onChange={handleInputChange}
        onKeyDown={handleKeyDown}
        placeholder={placeholder}
        style={style}
        onClick={onClick}
      />
      
      {showSuggestions && (
        <div
          ref={suggestionsRef}
          style={{
            position: 'absolute',
            top: '100%',
            left: 0,
            right: 0,
            zIndex: 1000,
            backgroundColor: 'white',
            border: '1px solid #ddd',
            borderRadius: '4px',
            maxHeight: '200px',
            overflowY: 'auto',
            boxShadow: '0 2px 8px rgba(0,0,0,0.15)'
          }}
        >
          {suggestions.map((suggestion, index) => {
            const variable = variableManager.getVariable(suggestion);
            return (
              <div
                key={suggestion}
                onClick={() => applySuggestion(suggestion)}
                style={{
                  padding: '8px 12px',
                  cursor: 'pointer',
                  backgroundColor: index === selectedSuggestion ? '#e3f2fd' : 'transparent',
                  borderBottom: index < suggestions.length - 1 ? '1px solid #f0f0f0' : 'none'
                }}
                onMouseEnter={() => setSelectedSuggestion(index)}
              >
                <div style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '8px'
                }}>
                  <span style={{ fontSize: '14px' }}>
                    {getTypeIcon(variable?.type || 'string')}
                  </span>
                  <div style={{ flex: 1 }}>
                    <div style={{ fontSize: '13px', fontWeight: 'bold' }}>
                      {suggestion}
                    </div>
                    {variable?.description && (
                      <div style={{ fontSize: '11px', color: '#666' }}>
                        {variable.description}
                      </div>
                    )}
                  </div>
                  <div style={{
                    fontSize: '10px',
                    padding: '2px 4px',
                    borderRadius: '2px',
                    backgroundColor: '#f0f0f0',
                    color: '#666'
                  }}>
                    {variable?.type || 'string'}
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
};

export default VariableInput;