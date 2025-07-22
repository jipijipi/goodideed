import React, { useState, useCallback } from 'react';
import {
  EdgeProps,
  EdgeLabelRenderer,
  getBezierPath,
  useReactFlow,
} from 'reactflow';

interface CustomEdgeData {
  label?: string;
  style?: 'solid' | 'dashed' | 'dotted';
  delay?: number;
  color?: string;
  value?: any;
  onLabelChange?: (edgeId: string, newLabel: string) => void;
  onStyleChange?: (edgeId: string, newStyle: 'solid' | 'dashed' | 'dotted') => void;
  onDelayChange?: (edgeId: string, newDelay: number) => void;
  onColorChange?: (edgeId: string, newColor: string) => void;
  onValueChange?: (edgeId: string, newValue: any) => void;
  onReset?: (edgeId: string) => void;
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
    e.stopPropagation();
    // Only start editing if there's no label and user double-clicked
    // Single clicks will be handled by React Flow for selection
  }, []);

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
  const hasDelay = data?.delay && data.delay > 0;
  const hasValue = data?.value !== undefined && data?.value !== null && data?.value !== '';
  const hasCustomizations = hasLabel || hasDelay || hasValue;
  const isCrossSequence = data?.label && data.label.startsWith('@');
  const isCondition = data?.label && (data.label.includes('==') || data.label.includes('!=') || data.label.includes('>') || data.label.includes('<'));
  
  const getStrokeDashArray = () => {
    if (isCrossSequence) return '5,3';
    switch (data?.style) {
      case 'dashed': return '8,4';
      case 'dotted': return '2,2';
      default: return 'none';
    }
  };

  const handleStyleChange = useCallback((newStyle: 'solid' | 'dashed' | 'dotted') => {
    if (data?.onStyleChange) {
      data.onStyleChange(id, newStyle);
    } else {
      setEdges((edges) =>
        edges.map((edge) => {
          if (edge.id === id) {
            return {
              ...edge,
              data: { ...edge.data, style: newStyle },
            };
          }
          return edge;
        })
      );
    }
  }, [id, data, setEdges]);

  const handleDelayChange = useCallback((newDelay: number) => {
    if (data?.onDelayChange) {
      data.onDelayChange(id, newDelay);
    } else {
      setEdges((edges) =>
        edges.map((edge) => {
          if (edge.id === id) {
            return {
              ...edge,
              data: { ...edge.data, delay: newDelay },
            };
          }
          return edge;
        })
      );
    }
  }, [id, data, setEdges]);

  const handleColorChange = useCallback((newColor: string) => {
    if (data?.onColorChange) {
      data.onColorChange(id, newColor);
    } else {
      setEdges((edges) =>
        edges.map((edge) => {
          if (edge.id === id) {
            return {
              ...edge,
              data: { ...edge.data, color: newColor },
            };
          }
          return edge;
        })
      );
    }
  }, [id, data, setEdges]);

  const handleReset = useCallback(() => {
    if (data?.onReset) {
      data.onReset(id);
    } else {
      setEdges((edges) =>
        edges.map((edge) => {
          if (edge.id === id) {
            return {
              ...edge,
              data: { 
                ...edge.data, 
                style: undefined,
                delay: undefined,
                color: undefined,
                label: undefined,
                value: undefined
              },
            };
          }
          return edge;
        })
      );
    }
  }, [id, data, setEdges]);

  return (
    <>
      <path
        id={id}
        className="react-flow__edge-path"
        d={edgePath}
        markerEnd={markerEnd}
        style={{ 
          stroke: data?.color || (isCrossSequence ? '#9c27b0' : isCondition ? '#ff9800' : '#999'), 
          strokeWidth: isCrossSequence ? 3 : 2,
          strokeDasharray: getStrokeDashArray(),
          cursor: 'pointer',
          pointerEvents: 'all'
        }}
      />
      {(hasCustomizations || isEditing) && (
        <EdgeLabelRenderer>
          <div
            style={{
              position: 'absolute',
              transform: `translate(-50%, -50%) translate(${labelX}px,${labelY}px)`,
              fontSize: 12,
              pointerEvents: 'all',
              zIndex: 1003,
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
                {data?.label || ''}
                {data?.delay && data.delay > 0 && (
                  <span style={{ fontSize: '10px', color: '#666', marginLeft: data?.label ? '4px' : '0px' }}>
                    {data?.label ? `(${data.delay}ms)` : `${data.delay}ms`}
                  </span>
                )}
                {hasValue && (
                  <span style={{ fontSize: '10px', color: '#2196f3', marginLeft: (data?.label || (data?.delay && data.delay > 0)) ? '4px' : '0px' }}>
                    {(data?.label || (data?.delay && data.delay > 0)) ? `[${JSON.stringify(data.value)}]` : `${JSON.stringify(data.value)}`}
                  </span>
                )}
              </div>
            )}
          </div>
        </EdgeLabelRenderer>
      )}

    </>
  );
};

export default CustomEdge;