import React, { useCallback, useState } from 'react';
import { Handle, Position, NodeProps } from 'reactflow';
import { NodeData, NodeCategory, DataActionItem } from '../constants/nodeTypes';

const getCategoryColor = (category: NodeCategory): string => {
  const colors: Record<NodeCategory, string> = {
    bot: '#e3f2fd',
    user: '#f3e5f5',
    choice: '#fff3e0',
    textInput: '#e8f5e8',
    autoroute: '#fce4ec',
    dataAction: '#f3e5f5'
  };
  return colors[category] || '#f5f5f5';
};

const getNodeTitle = (category: NodeCategory): string => {
  const titles: Record<NodeCategory, string> = {
    bot: 'Message',
    user: 'Message',
    choice: 'Choices',
    textInput: 'Input',
    autoroute: 'Auto-Route',
    dataAction: 'Data Action'
  };
  return titles[category] || 'Node';
};

const EditableNode: React.FC<NodeProps<NodeData>> = ({ id, data, selected }) => {
  const [expandedAction, setExpandedAction] = useState<number | null>(null);

  const handleNodeIdChange = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    data.onNodeIdChange(id, e.target.value);
  }, [id, data]);

  const handleContentChange = useCallback((e: React.ChangeEvent<HTMLTextAreaElement>) => {
    data.onContentChange(id, e.target.value);
  }, [id, data]);

  const handlePlaceholderChange = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    data.onPlaceholderChange(id, e.target.value);
  }, [id, data]);

  const handleStoreKeyChange = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    data.onStoreKeyChange(id, e.target.value);
  }, [id, data]);

  const handleDataActionsChange = useCallback((newDataActions: DataActionItem[]) => {
    if (data.onDataActionsChange) {
      data.onDataActionsChange(id, newDataActions);
    }
  }, [id, data]);

  const addDataAction = useCallback(() => {
    const currentActions = data.dataActions || [];
    const newAction: DataActionItem = {
      type: 'set',
      key: 'user.property',
      value: ''
    };
    handleDataActionsChange([...currentActions, newAction]);
  }, [data.dataActions, handleDataActionsChange]);

  const updateDataAction = useCallback((index: number, updatedAction: DataActionItem) => {
    const currentActions = data.dataActions || [];
    const newActions = [...currentActions];
    newActions[index] = updatedAction;
    handleDataActionsChange(newActions);
  }, [data.dataActions, handleDataActionsChange]);

  const removeDataAction = useCallback((index: number) => {
    const currentActions = data.dataActions || [];
    const newActions = currentActions.filter((_, i) => i !== index);
    handleDataActionsChange(newActions);
  }, [data.dataActions, handleDataActionsChange]);

  const renderFields = () => {
    switch (data.category) {
      case 'bot':
      case 'user':
        return (
          <>
            {/* ID Field */}
            <div style={{ marginBottom: '8px' }}>
              <label style={{ fontSize: '11px', color: '#666', display: 'block', marginBottom: '2px' }}>
                ID:
              </label>
              <input
                type="text"
                value={data.nodeId}
                onChange={handleNodeIdChange}
                style={{
                  width: '100%',
                  padding: '4px',
                  border: '1px solid #ccc',
                  borderRadius: '4px',
                  fontSize: '12px',
                  background: 'white',
                }}
                onClick={(e) => e.stopPropagation()}
              />
            </div>
            
            {/* Content Field */}
            <div style={{ marginBottom: '8px' }}>
              <label style={{ fontSize: '11px', color: '#666', display: 'block', marginBottom: '2px' }}>
                Content:
              </label>
              <textarea
                value={data.content || ''}
                onChange={handleContentChange}
                style={{
                  width: '100%',
                  padding: '4px',
                  border: '1px solid #ccc',
                  borderRadius: '4px',
                  fontSize: '12px',
                  background: 'white',
                  minHeight: '60px',
                  resize: 'vertical',
                }}
                onClick={(e) => e.stopPropagation()}
                placeholder="Enter message content..."
              />
            </div>
          </>
        );
        
      case 'textInput':
        return (
          <>
            {/* ID Field */}
            <div style={{ marginBottom: '8px' }}>
              <label style={{ fontSize: '11px', color: '#666', display: 'block', marginBottom: '2px' }}>
                ID:
              </label>
              <input
                type="text"
                value={data.nodeId}
                onChange={handleNodeIdChange}
                style={{
                  width: '100%',
                  padding: '4px',
                  border: '1px solid #ccc',
                  borderRadius: '4px',
                  fontSize: '12px',
                  background: 'white',
                }}
                onClick={(e) => e.stopPropagation()}
              />
            </div>
            
            {/* Placeholder Text Field */}
            <div style={{ marginBottom: '8px' }}>
              <label style={{ fontSize: '11px', color: '#666', display: 'block', marginBottom: '2px' }}>
                Placeholder:
              </label>
              <input
                type="text"
                value={data.placeholderText || ''}
                onChange={handlePlaceholderChange}
                style={{
                  width: '100%',
                  padding: '4px',
                  border: '1px solid #ccc',
                  borderRadius: '4px',
                  fontSize: '12px',
                  background: 'white',
                }}
                onClick={(e) => e.stopPropagation()}
                placeholder="Enter placeholder text..."
              />
            </div>
            
            {/* Store Key Field */}
            <div style={{ marginBottom: '8px' }}>
              <label style={{ fontSize: '11px', color: '#666', display: 'block', marginBottom: '2px' }}>
                Store Key:
              </label>
              <input
                type="text"
                value={data.storeKey || ''}
                onChange={handleStoreKeyChange}
                style={{
                  width: '100%',
                  padding: '4px',
                  border: '1px solid #ccc',
                  borderRadius: '4px',
                  fontSize: '12px',
                  background: 'white',
                }}
                onClick={(e) => e.stopPropagation()}
              />
            </div>
          </>
        );
        
      case 'choice':
        return (
          <>
            {/* ID Field */}
            <div style={{ marginBottom: '8px' }}>
              <label style={{ fontSize: '11px', color: '#666', display: 'block', marginBottom: '2px' }}>
                ID:
              </label>
              <input
                type="text"
                value={data.nodeId}
                onChange={handleNodeIdChange}
                style={{
                  width: '100%',
                  padding: '4px',
                  border: '1px solid #ccc',
                  borderRadius: '4px',
                  fontSize: '12px',
                  background: 'white',
                }}
                onClick={(e) => e.stopPropagation()}
              />
            </div>
            
            {/* Store Key Field */}
            <div style={{ marginBottom: '8px' }}>
              <label style={{ fontSize: '11px', color: '#666', display: 'block', marginBottom: '2px' }}>
                Store Key:
              </label>
              <input
                type="text"
                value={data.storeKey || ''}
                onChange={handleStoreKeyChange}
                style={{
                  width: '100%',
                  padding: '4px',
                  border: '1px solid #ccc',
                  borderRadius: '4px',
                  fontSize: '12px',
                  background: 'white',
                }}
                onClick={(e) => e.stopPropagation()}
              />
            </div>
          </>
        );
        
      case 'autoroute':
        return (
          <>
            {/* ID Field */}
            <div style={{ marginBottom: '8px' }}>
              <label style={{ fontSize: '11px', color: '#666', display: 'block', marginBottom: '2px' }}>
                ID:
              </label>
              <input
                type="text"
                value={data.nodeId}
                onChange={handleNodeIdChange}
                style={{
                  width: '100%',
                  padding: '4px',
                  border: '1px solid #ccc',
                  borderRadius: '4px',
                  fontSize: '12px',
                  background: 'white',
                }}
                onClick={(e) => e.stopPropagation()}
              />
            </div>
          </>
        );
        
      case 'dataAction':
        return (
          <>
            {/* ID Field */}
            <div style={{ marginBottom: '8px' }}>
              <label style={{ fontSize: '11px', color: '#666', display: 'block', marginBottom: '2px' }}>
                ID:
              </label>
              <input
                type="text"
                value={data.nodeId}
                onChange={handleNodeIdChange}
                style={{
                  width: '100%',
                  padding: '4px',
                  border: '1px solid #ccc',
                  borderRadius: '4px',
                  fontSize: '12px',
                  background: 'white',
                }}
                onClick={(e) => e.stopPropagation()}
              />
            </div>
            
            {/* Data Actions */}
            <div style={{ marginBottom: '8px' }}>
              <label style={{ fontSize: '11px', color: '#666', display: 'block', marginBottom: '4px' }}>
                Data Actions:
              </label>
              
              {(data.dataActions || []).map((action, index) => (
                <div key={index} style={{ 
                  border: '1px solid #ddd', 
                  borderRadius: '4px', 
                  padding: '8px', 
                  marginBottom: '4px',
                  background: '#f9f9f9'
                }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '4px' }}>
                    <span style={{ fontSize: '10px', fontWeight: 'bold', color: '#555' }}>Action {index + 1}</span>
                    <div>
                      <button
                        onClick={(e) => {
                          e.stopPropagation();
                          setExpandedAction(expandedAction === index ? null : index);
                        }}
                        style={{
                          background: 'none',
                          border: 'none',
                          fontSize: '10px',
                          cursor: 'pointer',
                          color: '#666',
                          marginRight: '4px'
                        }}
                      >
                        {expandedAction === index ? '▼' : '▶'}
                      </button>
                      <button
                        onClick={(e) => {
                          e.stopPropagation();
                          removeDataAction(index);
                        }}
                        style={{
                          background: 'none',
                          border: 'none',
                          fontSize: '10px',
                          cursor: 'pointer',
                          color: '#f44336'
                        }}
                      >
                        ✕
                      </button>
                    </div>
                  </div>
                  
                  {/* Action Type */}
                  <div style={{ marginBottom: '4px' }}>
                    <select
                      value={action.type}
                      onChange={(e) => {
                        e.stopPropagation();
                        const newType = e.target.value as DataActionItem['type'];
                        const updatedAction = { ...action, type: newType };
                        
                        // Reset fields when changing type
                        if (newType === 'trigger') {
                          updatedAction.event = updatedAction.event || '';
                          updatedAction.data = updatedAction.data || {};
                        } else {
                          delete updatedAction.event;
                          delete updatedAction.data;
                        }
                        
                        updateDataAction(index, updatedAction);
                      }}
                      style={{
                        width: '100%',
                        padding: '2px',
                        border: '1px solid #ccc',
                        borderRadius: '3px',
                        fontSize: '10px',
                        background: 'white'
                      }}
                    >
                      <option value="set">Set</option>
                      <option value="increment">Increment</option>
                      <option value="decrement">Decrement</option>
                      <option value="reset">Reset</option>
                      <option value="trigger">Trigger</option>
                    </select>
                  </div>
                  
                  {/* Key Field */}
                  <div style={{ marginBottom: '4px' }}>
                    <input
                      type="text"
                      value={action.key}
                      onChange={(e) => {
                        e.stopPropagation();
                        updateDataAction(index, { ...action, key: e.target.value });
                      }}
                      placeholder="Key (e.g., user.score)"
                      style={{
                        width: '100%',
                        padding: '2px',
                        border: '1px solid #ccc',
                        borderRadius: '3px',
                        fontSize: '10px',
                        background: 'white'
                      }}
                    />
                  </div>
                  
                  {/* Value Field (for non-trigger actions) */}
                  {action.type !== 'trigger' && (
                    <div style={{ marginBottom: expandedAction === index ? '4px' : '0' }}>
                      <input
                        type="text"
                        value={action.value || ''}
                        onChange={(e) => {
                          e.stopPropagation();
                          let value: any = e.target.value;
                          
                          // Try to parse as number for increment/decrement
                          if ((action.type === 'increment' || action.type === 'decrement') && !isNaN(Number(value))) {
                            value = Number(value);
                          }
                          // Try to parse as boolean
                          else if (value === 'true') value = true;
                          else if (value === 'false') value = false;
                          else if (value === 'null') value = null;
                          
                          updateDataAction(index, { ...action, value });
                        }}
                        placeholder="Value"
                        style={{
                          width: '100%',
                          padding: '2px',
                          border: '1px solid #ccc',
                          borderRadius: '3px',
                          fontSize: '10px',
                          background: 'white'
                        }}
                      />
                    </div>
                  )}
                  
                  {/* Expanded fields for trigger actions */}
                  {action.type === 'trigger' && expandedAction === index && (
                    <>
                      <div style={{ marginBottom: '4px' }}>
                        <input
                          type="text"
                          value={action.event || ''}
                          onChange={(e) => {
                            e.stopPropagation();
                            updateDataAction(index, { ...action, event: e.target.value });
                          }}
                          placeholder="Event type (e.g., achievement_unlocked)"
                          style={{
                            width: '100%',
                            padding: '2px',
                            border: '1px solid #ccc',
                            borderRadius: '3px',
                            fontSize: '10px',
                            background: 'white'
                          }}
                        />
                      </div>
                      <div>
                        <textarea
                          value={typeof action.data === 'object' ? JSON.stringify(action.data, null, 2) : (action.data || '')}
                          onChange={(e) => {
                            e.stopPropagation();
                            try {
                              const parsedData = JSON.parse(e.target.value);
                              updateDataAction(index, { ...action, data: parsedData });
                            } catch {
                              // Keep raw string if JSON parsing fails
                              updateDataAction(index, { ...action, data: e.target.value });
                            }
                          }}
                          placeholder='{"key": "value"}'
                          style={{
                            width: '100%',
                            padding: '2px',
                            border: '1px solid #ccc',
                            borderRadius: '3px',
                            fontSize: '10px',
                            background: 'white',
                            minHeight: '40px',
                            resize: 'vertical'
                          }}
                        />
                      </div>
                    </>
                  )}
                </div>
              ))}
              
              <button
                onClick={(e) => {
                  e.stopPropagation();
                  addDataAction();
                }}
                style={{
                  width: '100%',
                  padding: '6px',
                  border: '1px dashed #ccc',
                  borderRadius: '4px',
                  background: '#f9f9f9',
                  cursor: 'pointer',
                  fontSize: '10px',
                  color: '#666'
                }}
              >
                + Add Data Action
              </button>
            </div>
          </>
        );
        
      default:
        return null;
    }
  };

  return (
    <div
      style={{
        padding: '12px',
        border: selected ? '3px solid #1976d2' : '2px solid #ddd',
        borderRadius: '8px',
        background: getCategoryColor(data.category),
        minWidth: data.category === 'dataAction' ? '280px' : '220px',
        textAlign: 'left',
        boxShadow: selected 
          ? '0 4px 12px rgba(25, 118, 210, 0.3)' 
          : '0 2px 4px rgba(0,0,0,0.1)',
        transform: selected ? 'scale(1.02)' : 'scale(1)',
        transition: 'all 0.2s ease',
      }}
    >
      <Handle type="target" position={Position.Top} />
      
      {/* Node Title */}
      <div style={{ 
        fontSize: '14px', 
        fontWeight: 'bold', 
        marginBottom: '10px',
        color: '#333',
        textAlign: 'center',
        borderBottom: '1px solid #ddd',
        paddingBottom: '6px'
      }}>
        {getNodeTitle(data.category)}
      </div>
      
      {/* Dynamic Fields */}
      {renderFields()}
      
      <Handle type="source" position={Position.Bottom} />
    </div>
  );
};

export default EditableNode;