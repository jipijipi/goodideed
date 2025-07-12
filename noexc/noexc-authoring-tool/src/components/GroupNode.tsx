import React, { memo, useCallback, useState } from 'react';
import { Handle, Position } from 'reactflow';
import { NodeData } from '../constants/nodeTypes';

interface GroupNodeProps {
  data: NodeData & {
    groupId?: string;
    title?: string;
    description?: string;
    onGroupIdChange?: (nodeId: string, newGroupId: string) => void;
    onTitleChange?: (nodeId: string, newTitle: string) => void;
    onDescriptionChange?: (nodeId: string, newDescription: string) => void;
  };
  selected: boolean;
  id: string;
}

const GroupNode = ({ data, selected, id }: GroupNodeProps) => {
  const [isEditing, setIsEditing] = useState(false);
  const [editField, setEditField] = useState<'groupId' | 'title' | 'description' | null>(null);

  const handleDoubleClick = useCallback((field: 'groupId' | 'title' | 'description') => {
    setIsEditing(true);
    setEditField(field);
  }, []);

  const handleKeyDown = useCallback((e: React.KeyboardEvent, field: 'groupId' | 'title' | 'description') => {
    if (e.key === 'Enter') {
      setIsEditing(false);
      setEditField(null);
    } else if (e.key === 'Escape') {
      setIsEditing(false);
      setEditField(null);
    }
  }, []);

  const handleBlur = useCallback(() => {
    setIsEditing(false);
    setEditField(null);
  }, []);

  const handleChange = useCallback((e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>, field: 'groupId' | 'title' | 'description') => {
    const value = e.target.value;
    switch (field) {
      case 'groupId':
        data.onGroupIdChange?.(id, value);
        break;
      case 'title':
        data.onTitleChange?.(id, value);
        break;
      case 'description':
        data.onDescriptionChange?.(id, value);
        break;
    }
  }, [data, id]);

  return (
    <>
      {/* Handles for connections */}
      <Handle type="target" position={Position.Top} style={{ opacity: 0 }} />
      <Handle type="source" position={Position.Bottom} style={{ opacity: 0 }} />
      <Handle type="target" position={Position.Left} style={{ opacity: 0 }} />
      <Handle type="source" position={Position.Right} style={{ opacity: 0 }} />
      
      {/* Group Info Panel - Top Left */}
      <div style={{
        position: 'absolute',
        top: '8px',
        left: '8px',
        backgroundColor: 'rgba(255, 255, 255, 0.9)',
        border: '1px solid #ccc',
        borderRadius: '6px',
        padding: '8px',
        fontSize: '11px',
        color: '#333',
        maxWidth: '200px',
        zIndex: 10,
        boxShadow: '0 2px 4px rgba(0,0,0,0.1)'
      }}>
        {/* Group ID Field */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '6px', marginBottom: '4px' }}>
          <strong style={{ minWidth: '30px', color: '#666', fontSize: '10px' }}>ID:</strong>
          {isEditing && editField === 'groupId' ? (
            <input
              type="text"
              value={data.groupId || ''}
              onChange={(e) => handleChange(e, 'groupId')}
              onKeyDown={(e) => handleKeyDown(e, 'groupId')}
              onBlur={handleBlur}
              autoFocus
              style={{
                flex: 1,
                padding: '1px 3px',
                border: '1px solid #ccc',
                borderRadius: '2px',
                fontSize: '10px'
              }}
            />
          ) : (
            <span 
              onDoubleClick={() => handleDoubleClick('groupId')}
              style={{ 
                flex: 1, 
                cursor: 'pointer',
                padding: '1px 3px',
                backgroundColor: 'rgba(255, 255, 255, 0.7)',
                borderRadius: '2px',
                fontSize: '10px'
              }}
            >
              {data.groupId || 'group_id'}
            </span>
          )}
        </div>

        {/* Title Field */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '6px', marginBottom: '4px' }}>
          <strong style={{ minWidth: '30px', color: '#666', fontSize: '10px' }}>Title:</strong>
          {isEditing && editField === 'title' ? (
            <input
              type="text"
              value={data.title || ''}
              onChange={(e) => handleChange(e, 'title')}
              onKeyDown={(e) => handleKeyDown(e, 'title')}
              onBlur={handleBlur}
              autoFocus
              style={{
                flex: 1,
                padding: '1px 3px',
                border: '1px solid #ccc',
                borderRadius: '2px',
                fontSize: '10px'
              }}
            />
          ) : (
            <span 
              onDoubleClick={() => handleDoubleClick('title')}
              style={{ 
                flex: 1, 
                cursor: 'pointer',
                padding: '1px 3px',
                backgroundColor: 'rgba(255, 255, 255, 0.7)',
                borderRadius: '2px',
                fontSize: '10px',
                fontWeight: 'bold'
              }}
            >
              {data.title || 'Group Title'}
            </span>
          )}
        </div>

        {/* Description Field */}
        <div style={{ fontSize: '10px' }}>
          <strong style={{ color: '#666' }}>Desc:</strong>
          {isEditing && editField === 'description' ? (
            <textarea
              value={data.description || ''}
              onChange={(e) => handleChange(e, 'description')}
              onKeyDown={(e) => handleKeyDown(e, 'description')}
              onBlur={handleBlur}
              autoFocus
              rows={2}
              style={{
                width: '100%',
                padding: '2px',
                border: '1px solid #ccc',
                borderRadius: '2px',
                fontSize: '9px',
                resize: 'none',
                marginTop: '2px'
              }}
            />
          ) : (
            <div 
              onDoubleClick={() => handleDoubleClick('description')}
              style={{ 
                cursor: 'pointer',
                padding: '2px',
                backgroundColor: 'rgba(255, 255, 255, 0.7)',
                borderRadius: '2px',
                fontSize: '9px',
                marginTop: '2px',
                maxHeight: '30px',
                overflow: 'hidden'
              }}
            >
              {data.description || 'Description...'}
            </div>
          )}
        </div>
      </div>
      
      {/* Main Group Container */}
      <div style={{
        width: '100%',
        height: '100%',
        backgroundColor: 'rgba(245, 245, 245, 0.15)',
        border: '1px dashed #bbb',
        borderRadius: '8px',
        position: 'relative'
      }}>
      </div>
    </>
  );
};

export default memo(GroupNode);