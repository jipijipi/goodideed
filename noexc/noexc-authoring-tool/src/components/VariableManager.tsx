import React, { useState } from 'react';
import { useVariableManager, VariableDefinition } from '../context/VariableManagerContext';

interface VariableManagerProps {
  isOpen: boolean;
  onClose: () => void;
  nodes?: any[];
  edges?: any[];
}

const VariableManager: React.FC<VariableManagerProps> = ({ isOpen, onClose, nodes = [], edges = [] }) => {
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const [searchTerm, setSearchTerm] = useState('');
  const [showAddForm, setShowAddForm] = useState(false);
  const [showAnalysis, setShowAnalysis] = useState(false);
  const [newVariable, setNewVariable] = useState<Partial<VariableDefinition>>({
    key: '',
    type: 'string',
    defaultValue: '',
    description: '',
    category: 'custom',
    readonly: false
  });

  const variableManager = useVariableManager();

  // Variable analysis function
  const analyzeVariables = () => {
    const usedVariables = new Set<string>();
    const variableUsageCount: { [key: string]: number } = {};

    // Extract variables from template strings like {user.name} or {user.name|fallback}
    const extractVariables = (text: string) => {
      if (!text) return;
      const matches = text.match(/\{([^}|]+)(\|[^}]*)?\}/g);
      if (matches) {
        matches.forEach(match => {
          const variable = match.replace(/\{([^}|]+)(\|[^}]*)?\}/, '$1').trim();
          usedVariables.add(variable);
          variableUsageCount[variable] = (variableUsageCount[variable] || 0) + 1;
        });
      }
    };

    // Scan all nodes for variables
    nodes.forEach(node => {
      if (node.data) {
        // Check content, placeholderText, storeKey
        extractVariables(node.data.content);
        extractVariables(node.data.placeholderText);
        
        // Check storeKey (variables being set)
        if (node.data.storeKey) {
          usedVariables.add(node.data.storeKey);
          variableUsageCount[node.data.storeKey] = (variableUsageCount[node.data.storeKey] || 0) + 1;
        }

        // Check data actions
        if (node.data.dataActions) {
          node.data.dataActions.forEach((action: any) => {
            if (action.key) {
              usedVariables.add(action.key);
              variableUsageCount[action.key] = (variableUsageCount[action.key] || 0) + 1;
            }
          });
        }
      }
    });

    // Scan all edges for variables
    edges.forEach(edge => {
      if (edge.data) {
        extractVariables(edge.data.label);
        extractVariables(edge.data.contentKey);
      }
    });

    // Get defined variables
    const definedVariables = new Set(Array.from(variableManager.variables.keys()));

    // Categorize variables
    const knownVariables = Array.from(usedVariables).filter(v => definedVariables.has(v));
    const unknownVariables = Array.from(usedVariables).filter(v => !definedVariables.has(v));
    const unusedVariables = Array.from(definedVariables).filter(v => !usedVariables.has(v));

    return {
      used: Array.from(usedVariables),
      known: knownVariables,
      unknown: unknownVariables,
      unused: unusedVariables,
      usageCount: variableUsageCount,
      totalUsed: usedVariables.size,
      totalDefined: definedVariables.size
    };
  };

  const analysis = analyzeVariables();

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
            onClick={() => setShowAnalysis(!showAnalysis)}
            style={{
              padding: '8px 16px',
              backgroundColor: showAnalysis ? '#ff9800' : '#2196f3',
              color: 'white',
              border: 'none',
              borderRadius: '4px',
              cursor: 'pointer',
              fontSize: '14px',
              fontWeight: 'bold'
            }}
          >
            📊 {showAnalysis ? 'Hide Analysis' : 'Show Analysis'}
          </button>

          <button 
            onClick={() => setShowAddForm(true)}
            style={{
              padding: '8px 16px',
              backgroundColor: '#4CAF50',
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

        {/* Variable Analysis Section */}
        {showAnalysis && (
          <div style={{
            margin: '0 20px 20px 20px',
            padding: '16px',
            backgroundColor: '#f8f9fa',
            borderRadius: '8px',
            border: '1px solid #e9ecef'
          }}>
            <h3 style={{ 
              margin: '0 0 16px 0', 
              fontSize: '16px', 
              fontWeight: 'bold',
              color: '#333',
              borderBottom: '2px solid #dee2e6',
              paddingBottom: '8px'
            }}>
              📊 Variable Usage Analysis
            </h3>
            
            {/* Summary Stats */}
            <div style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fit, minmax(120px, 1fr))',
              gap: '12px',
              marginBottom: '16px'
            }}>
              <div style={{ textAlign: 'center', padding: '8px', backgroundColor: 'white', borderRadius: '4px' }}>
                <div style={{ fontSize: '20px', fontWeight: 'bold', color: '#2196f3' }}>{analysis.totalUsed}</div>
                <div style={{ fontSize: '12px', color: '#666' }}>Used in Graph</div>
              </div>
              <div style={{ textAlign: 'center', padding: '8px', backgroundColor: 'white', borderRadius: '4px' }}>
                <div style={{ fontSize: '20px', fontWeight: 'bold', color: '#4caf50' }}>{analysis.known.length}</div>
                <div style={{ fontSize: '12px', color: '#666' }}>Known</div>
              </div>
              <div style={{ textAlign: 'center', padding: '8px', backgroundColor: 'white', borderRadius: '4px' }}>
                <div style={{ fontSize: '20px', fontWeight: 'bold', color: '#f44336' }}>{analysis.unknown.length}</div>
                <div style={{ fontSize: '12px', color: '#666' }}>Unknown</div>
              </div>
              <div style={{ textAlign: 'center', padding: '8px', backgroundColor: 'white', borderRadius: '4px' }}>
                <div style={{ fontSize: '20px', fontWeight: 'bold', color: '#ff9800' }}>{analysis.unused.length}</div>
                <div style={{ fontSize: '12px', color: '#666' }}>Unused</div>
              </div>
            </div>

            {/* Known Variables */}
            {analysis.known.length > 0 && (
              <div style={{ marginBottom: '16px' }}>
                <h4 style={{ 
                  margin: '0 0 8px 0', 
                  fontSize: '14px', 
                  fontWeight: 'bold',
                  color: '#4caf50',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '6px'
                }}>
                  ✅ Known Variables ({analysis.known.length})
                </h4>
                <div style={{ display: 'flex', flexWrap: 'wrap', gap: '6px' }}>
                  {analysis.known.map(variable => (
                    <span
                      key={variable}
                      style={{
                        padding: '4px 8px',
                        backgroundColor: '#e8f5e8',
                        color: '#2e7d32',
                        borderRadius: '12px',
                        fontSize: '12px',
                        fontWeight: 'bold',
                        border: '1px solid #c8e6c9'
                      }}
                    >
                      {variable} ({analysis.usageCount[variable] || 0}×)
                    </span>
                  ))}
                </div>
              </div>
            )}

            {/* Unknown Variables */}
            {analysis.unknown.length > 0 && (
              <div style={{ marginBottom: '16px' }}>
                <h4 style={{ 
                  margin: '0 0 8px 0', 
                  fontSize: '14px', 
                  fontWeight: 'bold',
                  color: '#f44336',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '6px'
                }}>
                  ❌ Unknown Variables ({analysis.unknown.length}) - Need Definition
                </h4>
                <div style={{ display: 'flex', flexWrap: 'wrap', gap: '6px' }}>
                  {analysis.unknown.map(variable => (
                    <span
                      key={variable}
                      style={{
                        padding: '4px 8px',
                        backgroundColor: '#ffebee',
                        color: '#c62828',
                        borderRadius: '12px',
                        fontSize: '12px',
                        fontWeight: 'bold',
                        border: '1px solid #ffcdd2'
                      }}
                    >
                      {variable} ({analysis.usageCount[variable] || 0}×)
                    </span>
                  ))}
                </div>
              </div>
            )}

            {/* Unused Variables */}
            {analysis.unused.length > 0 && (
              <div>
                <h4 style={{ 
                  margin: '0 0 8px 0', 
                  fontSize: '14px', 
                  fontWeight: 'bold',
                  color: '#ff9800',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '6px'
                }}>
                  ⚪ Unused Variables ({analysis.unused.length}) - Defined but Not Used
                </h4>
                <div style={{ display: 'flex', flexWrap: 'wrap', gap: '6px' }}>
                  {analysis.unused.map(variable => (
                    <span
                      key={variable}
                      style={{
                        padding: '4px 8px',
                        backgroundColor: '#fff3e0',
                        color: '#ef6c00',
                        borderRadius: '12px',
                        fontSize: '12px',
                        fontWeight: 'bold',
                        border: '1px solid #ffcc02'
                      }}
                    >
                      {variable}
                    </span>
                  ))}
                </div>
              </div>
            )}

            {analysis.totalUsed === 0 && (
              <div style={{
                textAlign: 'center',
                padding: '20px',
                color: '#666',
                fontStyle: 'italic'
              }}>
                No variables found in the current graph. Add some template variables like {'{user.name}'} to see analysis.
              </div>
            )}
          </div>
        )}

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