import React, { useCallback, useState } from 'react';
import { Handle, Position, NodeProps } from 'reactflow';
import { NodeData, NodeCategory, DataActionItem } from '../constants/nodeTypes';
import HelpTooltip from './HelpTooltip';
import { helpContent } from '../constants/helpContent';
import VariableInput from './VariableInput';
import { COLORS } from '../styles/styleConstants';

const getCategoryColor = (category: NodeCategory): string => {
  const colors: Record<NodeCategory, string> = {
    bot: 'var(--node-bot)',           // Green - bot speaks
    user: 'var(--node-user)',         // Orange - user speaks  
    choice: 'var(--node-choice)',     // Purple - user chooses
    textInput: 'var(--node-textInput)', // Blue - user types
    autoroute: 'var(--node-autoroute)', // Yellow - logic flow
    dataAction: 'var(--node-dataAction)', // Pink - data manipulation
    image: 'var(--node-image)',       // Teal - image display
    system: 'var(--node-system)'     // Gray - system messages
  };
  return colors[category] || 'var(--bg-secondary)';
};

const getNodeTitle = (category: NodeCategory): string => {
  const titles: Record<NodeCategory, string> = {
    bot: 'Message',
    user: 'Message',
    choice: 'Choices',
    textInput: 'Input',
    autoroute: 'Auto-Route',
    dataAction: 'Data Action',
    image: 'Image',
    system: 'System'
  };
  return titles[category] || 'Node';
};

const EditableNode: React.FC<NodeProps<NodeData>> = ({ id, data, selected }) => {
  const [expandedAction, setExpandedAction] = useState<number | null>(null);

  const handleNodeIdChange = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    data.onNodeIdChange(id, e.target.value);
  }, [id, data]);

  const handleContentKeyChange = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    data.onContentKeyChange(id, e.target.value);
  }, [id, data]);

  const handlePlaceholderChange = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    data.onPlaceholderChange(id, e.target.value);
  }, [id, data]);

  const handleImagePathChange = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    if (data.onImagePathChange) {
      data.onImagePathChange(id, e.target.value);
    }
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
      case 'system':
        return (
          <>
            {/* ID Field */}
            <div style={{ marginBottom: '8px' }}>
              <label style={{ fontSize: '11px', color: '#666', display: 'flex', alignItems: 'center', marginBottom: '2px' }}>
                ID:
                <HelpTooltip content={helpContent.nodeId} />
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

            {/* Content Key Field */}
            <div style={{ marginBottom: '8px' }}>
              <label style={{ fontSize: '11px', color: '#666', display: 'flex', alignItems: 'center', marginBottom: '2px' }}>
                Content Key:
                <HelpTooltip content={helpContent.contentKey} />
              </label>
              <input
                type="text"
                value={data.contentKey || ''}
                onChange={handleContentKeyChange}
                style={{
                  width: '100%',
                  padding: '4px',
                  border: '1px solid #ccc',
                  borderRadius: '4px',
                  fontSize: '12px',
                  background: 'white',
                }}
                onClick={(e) => e.stopPropagation()}
                placeholder="e.g., welcome_message, error_response..."
              />
            </div>
            
            {/* Content Field */}
            <div style={{ marginBottom: '8px' }}>
              <label style={{ fontSize: '11px', color: '#666', display: 'flex', alignItems: 'center', marginBottom: '2px' }}>
                Content:
                <HelpTooltip content={data.category === 'bot' ? helpContent.botMessage : helpContent.userMessage} />
              </label>
              <VariableInput
                value={data.content || ''}
                onChange={(value) => data.onContentChange(id, value)}
                placeholder="Enter message content... Use {variable|fallback} for dynamic content"
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
              />
            </div>
          </>
        );
        
      case 'textInput':
        return (
          <>
            {/* ID Field */}
            <div style={{ marginBottom: '8px' }}>
              <label style={{ fontSize: '11px', color: '#666', display: 'flex', alignItems: 'center', marginBottom: '2px' }}>
                ID:
                <HelpTooltip content={helpContent.nodeId} />
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

            {/* Content Key Field */}
            <div style={{ marginBottom: '8px' }}>
              <label style={{ fontSize: '11px', color: '#666', display: 'flex', alignItems: 'center', marginBottom: '2px' }}>
                Content Key:
                <HelpTooltip content={helpContent.contentKey} />
              </label>
              <input
                type="text"
                value={data.contentKey || ''}
                onChange={handleContentKeyChange}
                style={{
                  width: '100%',
                  padding: '4px',
                  border: '1px solid #ccc',
                  borderRadius: '4px',
                  fontSize: '12px',
                  background: 'white',
                }}
                onClick={(e) => e.stopPropagation()}
                placeholder="e.g., user_name_input, age_input..."
              />
            </div>
            
            {/* Placeholder Text Field */}
            <div style={{ marginBottom: '8px' }}>
              <label style={{ fontSize: '11px', color: '#666', display: 'flex', alignItems: 'center', marginBottom: '2px' }}>
                Placeholder:
                <HelpTooltip content={helpContent.placeholder} />
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
              <label style={{ fontSize: '11px', color: '#666', display: 'flex', alignItems: 'center', marginBottom: '2px' }}>
                Store Key:
                <HelpTooltip content={helpContent.storeKey} />
              </label>
              <VariableInput
                value={data.storeKey || ''}
                onChange={(value) => data.onStoreKeyChange(id, value)}
                placeholder="e.g., user.name"
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
              <label style={{ fontSize: '11px', color: '#666', display: 'flex', alignItems: 'center', marginBottom: '2px' }}>
                ID:
                <HelpTooltip content={helpContent.nodeId} />
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

            {/* Content Key Field */}
            <div style={{ marginBottom: '8px' }}>
              <label style={{ fontSize: '11px', color: '#666', display: 'flex', alignItems: 'center', marginBottom: '2px' }}>
                Content Key:
                <HelpTooltip content={helpContent.contentKey} />
              </label>
              <input
                type="text"
                value={data.contentKey || ''}
                onChange={handleContentKeyChange}
                style={{
                  width: '100%',
                  padding: '4px',
                  border: '1px solid #ccc',
                  borderRadius: '4px',
                  fontSize: '12px',
                  background: 'white',
                }}
                onClick={(e) => e.stopPropagation()}
                placeholder="e.g., main_menu, difficulty_selection..."
              />
            </div>
            
            {/* Store Key Field */}
            <div style={{ marginBottom: '8px' }}>
              <label style={{ fontSize: '11px', color: '#666', display: 'flex', alignItems: 'center', marginBottom: '2px' }}>
                Store Key:
                <HelpTooltip content={helpContent.storeKey} />
              </label>
              <VariableInput
                value={data.storeKey || ''}
                onChange={(value) => data.onStoreKeyChange(id, value)}
                placeholder="e.g., user.name"
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
              <label style={{ fontSize: '11px', color: '#666', display: 'flex', alignItems: 'center', marginBottom: '2px' }}>
                ID:
                <HelpTooltip content={helpContent.nodeId} />
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

            {/* Content Key Field */}
            <div style={{ marginBottom: '8px' }}>
              <label style={{ fontSize: '11px', color: '#666', display: 'flex', alignItems: 'center', marginBottom: '2px' }}>
                Content Key:
                <HelpTooltip content={helpContent.contentKey} />
              </label>
              <input
                type="text"
                value={data.contentKey || ''}
                onChange={handleContentKeyChange}
                style={{
                  width: '100%',
                  padding: '4px',
                  border: '1px solid #ccc',
                  borderRadius: '4px',
                  fontSize: '12px',
                  background: 'white',
                }}
                onClick={(e) => e.stopPropagation()}
                placeholder="e.g., user_type_check, time_based_route..."
              />
            </div>
          </>
        );
        
      case 'image':
        return (
          <>
            {/* ID Field */}
            <div style={{ marginBottom: '8px' }}>
              <label style={{ fontSize: '11px', color: '#666', display: 'flex', alignItems: 'center', marginBottom: '2px' }}>
                ID:
                <HelpTooltip content={helpContent.nodeId} />
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

            {/* Content Key Field */}
            <div style={{ marginBottom: '8px' }}>
              <label style={{ fontSize: '11px', color: '#666', display: 'flex', alignItems: 'center', marginBottom: '2px' }}>
                Content Key:
                <HelpTooltip content={helpContent.contentKey} />
              </label>
              <input
                type="text"
                value={data.contentKey || ''}
                onChange={handleContentKeyChange}
                style={{
                  width: '100%',
                  padding: '4px',
                  border: '1px solid #ccc',
                  borderRadius: '4px',
                  fontSize: '12px',
                  background: 'white',
                }}
                onClick={(e) => e.stopPropagation()}
                placeholder="e.g., welcome_image, instruction_diagram..."
              />
            </div>

            {/* Image Path Field */}
            <div style={{ marginBottom: '8px' }}>
              <label style={{ fontSize: '11px', color: '#666', display: 'flex', alignItems: 'center', marginBottom: '2px' }}>
                Image Path:
              </label>
              <input
                type="text"
                value={data.imagePath || ''}
                onChange={handleImagePathChange}
                style={{
                  width: '100%',
                  padding: '4px',
                  border: '1px solid #ccc',
                  borderRadius: '4px',
                  fontSize: '12px',
                  background: 'white',
                }}
                onClick={(e) => e.stopPropagation()}
                placeholder="e.g., assets/images/sample_image.png"
              />
            </div>
          </>
        );
        
      case 'dataAction':
        return (
          <>
            {/* ID Field */}
            <div style={{ marginBottom: '8px' }}>
              <label style={{ fontSize: '11px', color: '#666', display: 'flex', alignItems: 'center', marginBottom: '2px' }}>
                ID:
                <HelpTooltip content={helpContent.nodeId} />
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

            {/* Content Key Field */}
            <div style={{ marginBottom: '8px' }}>
              <label style={{ fontSize: '11px', color: '#666', display: 'flex', alignItems: 'center', marginBottom: '2px' }}>
                Content Key:
                <HelpTooltip content={helpContent.contentKey} />
              </label>
              <input
                type="text"
                value={data.contentKey || ''}
                onChange={handleContentKeyChange}
                style={{
                  width: '100%',
                  padding: '4px',
                  border: '1px solid #ccc',
                  borderRadius: '4px',
                  fontSize: '12px',
                  background: 'white',
                }}
                onClick={(e) => e.stopPropagation()}
                placeholder="e.g., increment_streak, reset_score..."
              />
            </div>
            
            {/* Data Actions */}
            <div style={{ marginBottom: '8px' }}>
              <label style={{ fontSize: '11px', color: '#666', display: 'flex', alignItems: 'center', marginBottom: '4px' }}>
                Data Actions:
                <HelpTooltip content={helpContent.dataAction} />
              </label>
              
              {(data.dataActions || []).map((action, index) => (
                <div key={index} style={{ 
                  border: '1px solid #ddd', 
                  borderRadius: '4px', 
                  padding: '8px', 
                  marginBottom: '4px',
                  background: COLORS.lightGray
                }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '4px' }}>
                    <span style={{ fontSize: '10px', fontWeight: 'bold', color: '#555' }}>Action {index + 1}</span>
                    <div>
                      {action.type === 'trigger' && (
                        <button
                          onClick={(e) => {
                            e.stopPropagation();
                            setExpandedAction(expandedAction === index ? null : index);
                          }}
                          style={{
                            background: 'none',
                            border: 'none',
                            fontSize: '9px',
                            cursor: 'pointer',
                            color: '#666',
                            marginRight: '4px',
                            padding: '2px 4px'
                          }}
                          title={expandedAction === index ? 'Hide Data field' : 'Show Data field'}
                        >
                          {expandedAction === index ? '▼ Data' : '▶ Data'}
                        </button>
                      )}
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
                    <div style={{ display: 'flex', alignItems: 'center', marginBottom: '2px' }}>
                      <span style={{ fontSize: '9px', color: '#666' }}>Type:</span>
                      <HelpTooltip content={helpContent.dataActionType} />
                    </div>
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
                        background: COLORS.white
                      }}
                    >
                      <option value="set">Set</option>
                      <option value="increment">Increment</option>
                      <option value="decrement">Decrement</option>
                      <option value="reset">Reset</option>
                      <option value="trigger">Trigger</option>
                      <option value="append">Append</option>
                      <option value="remove">Remove</option>
                    </select>
                  </div>
                  
                  {/* Key Field */}
                  <div style={{ marginBottom: '4px' }}>
                    <div style={{ display: 'flex', alignItems: 'center', marginBottom: '2px' }}>
                      <span style={{ fontSize: '9px', color: '#666' }}>Key:</span>
                      <HelpTooltip content={helpContent.dataActionKey} />
                    </div>
                    <VariableInput
                      value={action.key}
                      onChange={(value) => {
                        updateDataAction(index, { ...action, key: value });
                      }}
                      placeholder="Key (e.g., user.score)"
                      style={{
                        width: '100%',
                        padding: '2px',
                        border: '1px solid #ccc',
                        borderRadius: '3px',
                        fontSize: '10px',
                        background: COLORS.white
                      }}
                    />
                  </div>
                  
                  {/* Value Field (for non-trigger actions) */}
                  {action.type !== 'trigger' && (
                    <div style={{ marginBottom: expandedAction === index ? '4px' : '0' }}>
                      <div style={{ display: 'flex', alignItems: 'center', marginBottom: '2px' }}>
                        <span style={{ fontSize: '9px', color: '#666' }}>Value:</span>
                        <HelpTooltip content={helpContent.dataActionValue} />
                      </div>
                      <input
                        type="text"
                        value={action.value === null ? 'null' : action.value === false ? 'false' : action.value === true ? 'true' : action.value ?? ''}
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
                          background: COLORS.white
                        }}
                      />
                    </div>
                  )}
                  
                  {/* Event Field (always visible for trigger actions) */}
                  {action.type === 'trigger' && (
                    <div style={{ marginBottom: '4px' }}>
                      <div style={{ display: 'flex', alignItems: 'center', marginBottom: '2px' }}>
                        <span style={{ fontSize: '9px', color: '#666' }}>Event:</span>
                        <HelpTooltip content={helpContent.triggerEvent} />
                      </div>
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
                          background: COLORS.white
                        }}
                      />
                    </div>
                  )}
                  
                  {/* Expanded Data field for trigger actions */}
                  {action.type === 'trigger' && expandedAction === index && (
                    <div>
                      <div style={{ display: 'flex', alignItems: 'center', marginBottom: '2px' }}>
                        <span style={{ fontSize: '9px', color: '#666' }}>Data:</span>
                        <HelpTooltip content={helpContent.triggerData} />
                      </div>
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
                          background: COLORS.white,
                          minHeight: '40px',
                          resize: 'vertical'
                        }}
                      />
                    </div>
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
                  background: COLORS.lightGray,
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
        color: 'var(--text-primary)',
        textAlign: 'center',
        borderBottom: '1px solid var(--border-secondary)',
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