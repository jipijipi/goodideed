import React, { useState, useCallback } from 'react';
import { Handle, Position, NodeProps } from 'reactflow';
import { NodeData, NODE_CATEGORIES, NODE_LABELS, NodeCategory, NodeLabel } from '../constants/nodeTypes';

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

const EditableNode: React.FC<NodeProps<NodeData>> = ({ id, data }) => {
  const [isEditing, setIsEditing] = useState(false);
  const [tempLabel, setTempLabel] = useState(data.label);

  const handleDoubleClick = useCallback(() => {
    setIsEditing(true);
    setTempLabel(data.label);
  }, [data.label]);

  const handleSave = useCallback(() => {
    data.onLabelChange(id, tempLabel);
    setIsEditing(false);
  }, [id, tempLabel, data]);

  const handleCancel = useCallback(() => {
    setTempLabel(data.label);
    setIsEditing(false);
  }, [data.label]);

  const handleKeyDown = useCallback((e: React.KeyboardEvent) => {
    if (e.key === 'Enter') {
      handleSave();
    } else if (e.key === 'Escape') {
      handleCancel();
    }
  }, [handleSave, handleCancel]);

  const handleCategoryChange = useCallback((e: React.ChangeEvent<HTMLSelectElement>) => {
    data.onCategoryChange(id, e.target.value as NodeCategory);
  }, [id, data]);

  const handleNodeLabelChange = useCallback((e: React.ChangeEvent<HTMLSelectElement>) => {
    data.onNodeLabelChange(id, e.target.value as NodeLabel);
  }, [id, data]);

  return (
    <div
      style={{
        padding: '12px',
        border: '2px solid #ddd',
        borderRadius: '8px',
        background: getCategoryColor(data.category),
        minWidth: '180px',
        textAlign: 'center',
        cursor: isEditing ? 'text' : 'pointer',
        boxShadow: '0 2px 4px rgba(0,0,0,0.1)',
      }}
    >
      <Handle type="target" position={Position.Top} />
      
      {/* Category Dropdown */}
      <div style={{ marginBottom: '8px' }}>
        <select
          value={data.category}
          onChange={handleCategoryChange}
          style={{
            width: '100%',
            padding: '4px',
            border: '1px solid #ccc',
            borderRadius: '4px',
            fontSize: '12px',
            background: 'white',
          }}
          onClick={(e) => e.stopPropagation()}
        >
          {NODE_CATEGORIES.map(category => (
            <option key={category} value={category}>
              {category}
            </option>
          ))}
        </select>
      </div>

      {/* Node Label Dropdown */}
      <div style={{ marginBottom: '8px' }}>
        <select
          value={data.nodeLabel}
          onChange={handleNodeLabelChange}
          style={{
            width: '100%',
            padding: '4px',
            border: '1px solid #ccc',
            borderRadius: '4px',
            fontSize: '12px',
            background: 'white',
          }}
          onClick={(e) => e.stopPropagation()}
        >
          {NODE_LABELS.map(label => (
            <option key={label} value={label}>
              {label}
            </option>
          ))}
        </select>
      </div>

      {/* Editable Text */}
      <div onDoubleClick={handleDoubleClick}>
        {isEditing ? (
          <input
            type="text"
            value={tempLabel}
            onChange={(e) => setTempLabel(e.target.value)}
            onBlur={handleSave}
            onKeyDown={handleKeyDown}
            autoFocus
            style={{
              border: 'none',
              outline: 'none',
              background: 'transparent',
              textAlign: 'center',
              width: '100%',
              fontWeight: 'bold',
            }}
            onClick={(e) => e.stopPropagation()}
          />
        ) : (
          <div 
            title="Double-click to edit text"
            style={{ fontWeight: 'bold', fontSize: '14px' }}
          >
            {data.label}
          </div>
        )}
      </div>
      
      <Handle type="source" position={Position.Bottom} />
    </div>
  );
};

export default EditableNode;