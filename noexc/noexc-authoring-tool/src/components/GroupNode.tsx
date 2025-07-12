import React, { useState, useCallback } from 'react';
import { NodeProps } from 'reactflow';
import { NodeData } from '../constants/nodeTypes';

const GroupNode: React.FC<NodeProps<NodeData>> = ({ id, data, selected }) => {
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

  return (
    <div
      style={{
        position: 'relative',
        width: '100%',
        height: '100%',
        pointerEvents: 'none', // Allow clicking through the group
        zIndex: -1, // Ensure group stays behind other nodes
      }}
    >
      {/* Simple editable label at top left */}
      <div 
        style={{
          position: 'absolute',
          top: '0px',
          left: '0px',
          pointerEvents: 'all', // Enable clicking on the label
          zIndex: 999, // Lower than regular nodes but higher than group background
        }}
      >
        {isEditing ? (
          <input
            type="text"
            value={tempLabel}
            onChange={(e) => setTempLabel(e.target.value)}
            onBlur={handleSave}
            onKeyDown={handleKeyDown}
            autoFocus
            style={{
              fontSize: '12px',
              fontWeight: 'bold',
              color: '#666',
              background: 'rgba(255, 255, 255, 0.9)',
              border: '1px solid #ccc',
              borderRadius: '3px',
              padding: '2px 6px',
              minWidth: '60px',
            }}
            onClick={(e) => e.stopPropagation()}
          />
        ) : (
          <div
            style={{
              fontSize: '12px',
              fontWeight: 'bold',
              color: '#666',
              background: selected ? 'rgba(25, 118, 210, 0.1)' : 'rgba(255, 255, 255, 0.9)',
              border: selected ? '1px solid #1976d2' : '1px solid #ddd',
              borderRadius: '3px',
              padding: '2px 6px',
              cursor: 'pointer',
              userSelect: 'none',
            }}
            onDoubleClick={handleDoubleClick}
            title="Double-click to edit group name"
          >
            {data.label}
          </div>
        )}
      </div>
    </div>
  );
};

export default GroupNode;