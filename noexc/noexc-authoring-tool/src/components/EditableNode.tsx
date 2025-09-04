import React, { useCallback } from 'react';
import { Handle, Position, NodeProps } from 'reactflow';
import { NodeData, NodeCategory, DataActionItem } from '../constants/nodeTypes';
import HelpTooltip from './HelpTooltip';
import { helpContent } from '../constants/helpContent';
import VariableInput from './VariableInput';

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

const getActionTypeEmoji = (type: DataActionItem['type']): string => {
  const emojis: Record<DataActionItem['type'], string> = {
    set: '📝',
    increment: '➕',
    decrement: '➖',
    reset: '🔄',
    trigger: '⚡',
    append: '➕📝',
    remove: '➖📝'
  };
  return emojis[type] || '⚙️';
};

const formatDataActionValue = (value: any): string => {
  if (value === null) return 'null';
  if (value === true) return 'true';
  if (value === false) return 'false';
  if (typeof value === 'object') {
    const str = JSON.stringify(value);
    return str.length > 20 ? str.substring(0, 20) + '...' : str;
  }
  const str = String(value);
  return str.length > 15 ? str.substring(0, 15) + '...' : str;
};

const createDataActionSummary = (action: DataActionItem): string => {
  const emoji = getActionTypeEmoji(action.type);
  const key = action.key || 'undefined';
  
  switch (action.type) {
    case 'set':
      return `${emoji} set ${key} → ${formatDataActionValue(action.value)}`;
    case 'increment':
    case 'decrement':
      const amount = action.value ? formatDataActionValue(action.value) : '1';
      return `${emoji} ${action.type} ${key} → ${amount}`;
    case 'reset':
      return `${emoji} reset ${key}`;
    case 'trigger':
      const event = action.event || 'event';
      return `${emoji} trigger ${event} → ${key}`;
    case 'append':
    case 'remove':
      return `${emoji} ${action.type} ${key} → ${formatDataActionValue(action.value)}`;
    default:
      return `${emoji} ${action.type} ${key}`;
  }
};

const EditableNode: React.FC<NodeProps<NodeData>> = ({ id, data, selected }) => {

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
        const dataActions = data.dataActions || [];
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

            {/* Compact Data Actions Summary */}
            <div style={{ marginBottom: '8px' }}>
              <label style={{ fontSize: '11px', color: '#666', display: 'flex', alignItems: 'center', marginBottom: '4px' }}>
                Data Actions ({dataActions.length}):
                <HelpTooltip content={helpContent.dataAction} />
              </label>
              
              {dataActions.length === 0 ? (
                <div style={{
                  padding: '8px',
                  backgroundColor: '#f8f9fa',
                  border: '1px dashed #ddd',
                  borderRadius: '4px',
                  textAlign: 'center',
                  fontSize: '10px',
                  color: '#666'
                }}>
                  No data actions configured
                </div>
              ) : (
                <div style={{
                  border: '1px solid #ddd',
                  borderRadius: '4px',
                  backgroundColor: '#fafafa',
                  maxHeight: '100px',
                  overflowY: 'auto'
                }}>
                  {dataActions.map((action, index) => (
                    <div
                      key={index}
                      style={{
                        padding: '4px 8px',
                        fontSize: '10px',
                        borderBottom: index < dataActions.length - 1 ? '1px solid #eee' : 'none',
                        fontFamily: 'monospace',
                        lineHeight: '1.3',
                        color: '#333'
                      }}
                      title={`Action ${index + 1}: ${action.type} operation`}
                    >
                      {createDataActionSummary(action)}
                    </div>
                  ))}
                </div>
              )}

              <div style={{
                marginTop: '4px',
                padding: '4px',
                backgroundColor: '#e3f2fd',
                borderRadius: '3px',
                fontSize: '9px',
                color: '#1976d2',
                textAlign: 'center'
              }}>
                💡 Edit data actions in Properties Panel →
              </div>
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