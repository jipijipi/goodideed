import React, { useState } from 'react';
import { useVariableManager, VariableDefinition } from '../context/VariableManagerContext';

interface VariableManagerProps {
  isOpen: boolean;
  onClose: () => void;
}

const VariableManager: React.FC<VariableManagerProps> = ({ isOpen, onClose }) => {
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const [searchTerm, setSearchTerm] = useState('');
  const [showAddForm, setShowAddForm] = useState(false);
  const [newVariable, setNewVariable] = useState<Partial<VariableDefinition>>({
    key: '',
    type: 'string',
    defaultValue: '',
    description: '',
    category: 'custom',
    readonly: false
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
    if (newVariable.key && newVariable.description && newVariable.type) {
      const validation = variableManager.validateVariable(newVariable.key);
      if (validation.valid) {
        variableManager.addVariable(newVariable as VariableDefinition);
        setNewVariable({
          key: '',
          type: 'string',
          defaultValue: '',
          description: '',
          category: 'custom',
          readonly: false
        });
        setShowAddForm(false);
      } else {
        alert('Invalid variable key: ' + validation.errors.join(', '));
      }
    } else {
      alert('Please fill in all required fields');
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
      object: '🗂️'
    };
    return icons[type as keyof typeof icons] || '❓';
  };

  return (
    <div style={{
      position: 'fixed',
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      backgroundColor: 'rgba(0,0,0,0.5)',
      zIndex: 2000,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center'
    }}>
      <div style={{
        backgroundColor: 'white',
        borderRadius: '8px',
        width: '90%',
        maxWidth: '800px',
        height: '80%',
        maxHeight: '600px',
        display: 'flex',
        flexDirection: 'column',
        boxShadow: '0 8px 32px rgba(0,0,0,0.3)'
      }}>
        {/* Header */}
        <div style={{
          padding: '16px 20px',
          borderBottom: '1px solid #eee',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center'
        }}>
          <h3 style={{ margin: 0, color: '#333' }}>🗂️ Variable Manager</h3>
          <button
            onClick={onClose}
            style={{
              background: 'none',
              border: 'none',
              fontSize: '20px',
              cursor: 'pointer',
              color: '#666'
            }}
          >
            ×
          </button>
        </div>

        {/* Controls */}
        <div style={{
          padding: '16px 20px',
          borderBottom: '1px solid #eee',
          display: 'flex',
          gap: '12px',
          alignItems: 'center'
        }}>
          <input
            type="text"
            placeholder="Search variables..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            style={{
              flex: 1,
              padding: '8px 12px',
              border: '1px solid #ddd',
              borderRadius: '4px',
              fontSize: '14px'
            }}
          />
          
          <select 
            value={selectedCategory} 
            onChange={(e) => setSelectedCategory(e.target.value)}
            style={{
              padding: '8px 12px',
              border: '1px solid #ddd',
              borderRadius: '4px',
              fontSize: '14px'
            }}
          >
            {categories.map(cat => (
              <option key={cat} value={cat}>
                {cat === 'all' ? 'All Categories' : cat.charAt(0).toUpperCase() + cat.slice(1)}
              </option>
            ))}
          </select>
          
          <button 
            onClick={() => setShowAddForm(true)}
            style={{
              padding: '8px 16px',
              backgroundColor: '#2196f3',
              color: 'white',
              border: 'none',
              borderRadius: '4px',
              cursor: 'pointer',
              fontSize: '14px'
            }}
          >
            + Add Variable
          </button>
        </div>

        {/* Add Variable Form */}
        {showAddForm && (
          <div style={{
            padding: '16px 20px',
            borderBottom: '1px solid #eee',
            backgroundColor: '#f8f9fa'
          }}>
            <h4 style={{ margin: '0 0 12px 0', color: '#333' }}>Add New Variable</h4>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginBottom: '12px' }}>
              <input
                type="text"
                placeholder="Variable key (e.g., user.newProperty)"
                value={newVariable.key}
                onChange={(e) => setNewVariable({...newVariable, key: e.target.value})}
                style={{
                  padding: '8px',
                  border: '1px solid #ddd',
                  borderRadius: '4px',
                  fontSize: '14px'
                }}
              />
              <select
                value={newVariable.type}
                onChange={(e) => setNewVariable({...newVariable, type: e.target.value as any})}
                style={{
                  padding: '8px',
                  border: '1px solid #ddd',
                  borderRadius: '4px',
                  fontSize: '14px'
                }}
              >
                <option value="string">String</option>
                <option value="number">Number</option>
                <option value="boolean">Boolean</option>
                <option value="object">Object</option>
              </select>
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginBottom: '12px' }}>
              <input
                type="text"
                placeholder="Default value"
                value={newVariable.defaultValue}
                onChange={(e) => setNewVariable({...newVariable, defaultValue: e.target.value})}
                style={{
                  padding: '8px',
                  border: '1px solid #ddd',
                  borderRadius: '4px',
                  fontSize: '14px'
                }}
              />
              <select
                value={newVariable.category}
                onChange={(e) => setNewVariable({...newVariable, category: e.target.value as any})}
                style={{
                  padding: '8px',
                  border: '1px solid #ddd',
                  borderRadius: '4px',
                  fontSize: '14px'
                }}
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
              style={{
                width: '100%',
                padding: '8px',
                border: '1px solid #ddd',
                borderRadius: '4px',
                fontSize: '14px',
                marginBottom: '12px'
              }}
            />
            <div style={{ display: 'flex', gap: '8px' }}>
              <button
                onClick={handleAddVariable}
                style={{
                  padding: '8px 16px',
                  backgroundColor: '#4caf50',
                  color: 'white',
                  border: 'none',
                  borderRadius: '4px',
                  cursor: 'pointer',
                  fontSize: '14px'
                }}
              >
                Add Variable
              </button>
              <button
                onClick={() => setShowAddForm(false)}
                style={{
                  padding: '8px 16px',
                  backgroundColor: '#f44336',
                  color: 'white',
                  border: 'none',
                  borderRadius: '4px',
                  cursor: 'pointer',
                  fontSize: '14px'
                }}
              >
                Cancel
              </button>
            </div>
          </div>
        )}

        {/* Variables List */}
        <div style={{
          flex: 1,
          overflowY: 'auto',
          padding: '16px 20px'
        }}>
          {filteredVariables.length === 0 ? (
            <div style={{
              textAlign: 'center',
              color: '#666',
              padding: '40px 0'
            }}>
              {searchTerm ? 'No variables found matching your search.' : 'No variables in this category.'}
            </div>
          ) : (
            filteredVariables.map(variable => (
              <div key={variable.key} style={{
                border: '1px solid #eee',
                borderRadius: '6px',
                padding: '12px',
                marginBottom: '8px',
                backgroundColor: variable.readonly ? '#f8f9fa' : 'white'
              }}>
                <div style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'flex-start',
                  marginBottom: '8px'
                }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                    <span style={{ fontSize: '16px' }}>{getTypeIcon(variable.type)}</span>
                    <span style={{ fontWeight: 'bold', fontSize: '14px' }}>{variable.key}</span>
                    <span style={{
                      fontSize: '11px',
                      padding: '2px 6px',
                      borderRadius: '3px',
                      color: 'white',
                      backgroundColor: getCategoryColor(variable.category)
                    }}>
                      {variable.category}
                    </span>
                    {variable.readonly && (
                      <span style={{
                        fontSize: '11px',
                        padding: '2px 6px',
                        borderRadius: '3px',
                        color: '#666',
                        backgroundColor: '#e0e0e0'
                      }}>
                        readonly
                      </span>
                    )}
                  </div>
                  {!variable.readonly && (
                    <button
                      onClick={() => variableManager.removeVariable(variable.key)}
                      style={{
                        background: 'none',
                        border: 'none',
                        color: '#f44336',
                        cursor: 'pointer',
                        fontSize: '14px'
                      }}
                    >
                      🗑️
                    </button>
                  )}
                </div>
                
                <div style={{
                  fontSize: '13px',
                  color: '#666',
                  marginBottom: '8px'
                }}>
                  {variable.description}
                </div>
                
                <div style={{
                  display: 'flex',
                  gap: '16px',
                  fontSize: '12px',
                  color: '#888'
                }}>
                  <div>
                    <strong>Type:</strong> {variable.type}
                  </div>
                  <div>
                    <strong>Default:</strong> <code>{JSON.stringify(variable.defaultValue)}</code>
                  </div>
                </div>
              </div>
            ))
          )}
        </div>
      </div>
    </div>
  );
};

export default VariableManager;