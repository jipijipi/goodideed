import React, { useCallback } from 'react';
import { Handle, Position, NodeProps } from 'reactflow';
import { NodeData, NodeCategory } from '../constants/nodeTypes';

const getCategoryColor = (category: NodeCategory): string => {
  const colors = {
    bot: '#e3f2fd',
    user: '#f3e5f5',
    choice: '#fff3e0',
    textInput: '#e8f5e8',
    autoroute: '#fce4ec'
  };
  return colors[category] || '#f5f5f5';
};

const getNodeTitle = (category: NodeCategory): string => {
  const titles = {
    bot: 'Message',
    user: 'Message',
    choice: 'Choices',
    textInput: 'Input',
    autoroute: 'Auto-Route'
  };
  return titles[category] || 'Node';
};

const EditableNode: React.FC<NodeProps<NodeData>> = ({ id, data, selected }) => {
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
        minWidth: '220px',
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