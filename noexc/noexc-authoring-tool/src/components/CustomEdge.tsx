import React, { useState, useCallback } from 'react';
import {
  EdgeProps,
  EdgeLabelRenderer,
  getBezierPath,
  useReactFlow,
} from 'reactflow';

interface CustomEdgeData {
  label?: string;
  onLabelChange?: (edgeId: string, newLabel: string) => void;
}

const CustomEdge: React.FC<EdgeProps<CustomEdgeData>> = ({
  id,
  sourceX,
  sourceY,
  targetX,
  targetY,
  sourcePosition,
  targetPosition,
  data,
  markerEnd,
}) => {
  const [isEditing, setIsEditing] = useState(false);
  const [tempLabel, setTempLabel] = useState(data?.label || '');
  const { setEdges } = useReactFlow();

  const [edgePath, labelX, labelY] = getBezierPath({
    sourceX,
    sourceY,
    sourcePosition,
    targetX,
    targetY,
    targetPosition,
  });

  const handleDoubleClick = useCallback((e: React.MouseEvent) => {
    e.stopPropagation();
    setIsEditing(true);
    setTempLabel(data?.label || '');
  }, [data?.label]);

  const handleEdgeClick = useCallback((e: React.MouseEvent) => {
    if (!data?.label) {
      e.stopPropagation();
      setIsEditing(true);
      setTempLabel('');
    }
  }, [data?.label]);

  const handleSave = useCallback(() => {
    if (data?.onLabelChange) {
      data.onLabelChange(id, tempLabel);
    } else {
      // Fallback: directly update the edge if no callback provided
      setEdges((edges) =>
        edges.map((edge) => {
          if (edge.id === id) {
            return {
              ...edge,
              data: { ...edge.data, label: tempLabel },
            };
          }
          return edge;
        })
      );
    }
    setIsEditing(false);
  }, [id, tempLabel, data, setEdges]);

  const handleCancel = useCallback(() => {
    setTempLabel(data?.label || '');
    setIsEditing(false);
  }, [data?.label]);

  const handleKeyDown = useCallback((e: React.KeyboardEvent) => {
    if (e.key === 'Enter') {
      handleSave();
    } else if (e.key === 'Escape') {
      handleCancel();
    }
  }, [handleSave, handleCancel]);

  const hasLabel = data?.label && data.label.trim() !== '';
  const isCrossSequence = data?.label && data.label.startsWith('@');
  const isCondition = data?.label && (data.label.includes('==') || data.label.includes('!=') || data.label.includes('>') || data.label.includes('<'));

  return (
    <>
      <path
        id={id}
        className="react-flow__edge-path"
        d={edgePath}
        markerEnd={markerEnd}
        onClick={handleEdgeClick}
        style={{ 
          stroke: isCrossSequence ? '#9c27b0' : isCondition ? '#ff9800' : '#999', 
          strokeWidth: isCrossSequence ? 3 : 2,
          strokeDasharray: isCrossSequence ? '5,3' : 'none',
          cursor: hasLabel ? 'default' : 'pointer'
        }}
      />
      {(hasLabel || isEditing) && (
        <EdgeLabelRenderer>
          <div
            style={{
              position: 'absolute',
              transform: `translate(-50%, -50%) translate(${labelX}px,${labelY}px)`,
              fontSize: 12,
              pointerEvents: 'all',
            }}
            className="nodrag nopan"
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
                  border: '1px solid #ccc',
                  borderRadius: '4px',
                  padding: '2px 6px',
                  fontSize: '12px',
                  background: 'white',
                  minWidth: '60px',
                  textAlign: 'center',
                }}
                onClick={(e) => e.stopPropagation()}
                placeholder="@sequence_id | condition | choice::value"
                title="Format: @sequence_id for cross-sequence, condition for routes, choice::value for choices"
              />
            ) : (
              <div
                style={{
                  background: isCrossSequence ? '#f3e5f5' : 'white',
                  padding: '2px 6px',
                  borderRadius: '4px',
                  border: `1px solid ${isCrossSequence ? '#9c27b0' : '#ddd'}`,
                  cursor: 'pointer',
                  minWidth: '40px',
                  textAlign: 'center',
                  boxShadow: '0 1px 3px rgba(0,0,0,0.1)',
                  fontWeight: isCrossSequence ? 'bold' : 'normal',
                  color: isCrossSequence ? '#6a1b9a' : 'inherit'
                }}
                onDoubleClick={handleDoubleClick}
                title={isCrossSequence ? "Cross-sequence navigation - Double-click to edit" : "Double-click to edit"}
              >
                {data?.label}
              </div>
            )}
          </div>
        </EdgeLabelRenderer>
      )}
    </>
  );
};

export default CustomEdge;