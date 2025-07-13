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
  onLabelChange?: (edgeId: string, newLabel: string) => void;
  onStyleChange?: (edgeId: string, newStyle: 'solid' | 'dashed' | 'dotted') => void;
  onDelayChange?: (edgeId: string, newDelay: number) => void;
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
  const [showStylePicker, setShowStylePicker] = useState(false);
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
    setShowStylePicker(false);
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
          strokeDasharray: getStrokeDashArray(),
          cursor: hasLabel ? 'default' : 'pointer'
        }}
        onContextMenu={(e) => {
          e.preventDefault();
          setShowStylePicker(true);
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
                {data?.label}
                {data?.delay && data.delay > 0 && (
                  <span style={{ fontSize: '10px', color: '#666', marginLeft: '4px' }}>
                    ({data.delay}ms)
                  </span>
                )}
              </div>
            )}
          </div>
        </EdgeLabelRenderer>
      )}

      {/* Style Picker */}
      {showStylePicker && (
        <EdgeLabelRenderer>
          <div
            style={{
              position: 'absolute',
              transform: `translate(-50%, -50%) translate(${labelX}px,${labelY + 30}px)`,
              background: 'white',
              border: '1px solid #ccc',
              borderRadius: '4px',
              padding: '8px',
              boxShadow: '0 2px 8px rgba(0,0,0,0.15)',
              zIndex: 1004,
              minWidth: '120px'
            }}
            className="nodrag nopan"
          >
            <div style={{ fontSize: '12px', fontWeight: 'bold', marginBottom: '4px' }}>Edge Style</div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
              <button
                onClick={() => handleStyleChange('solid')}
                style={{
                  padding: '4px 8px',
                  border: '1px solid #ddd',
                  borderRadius: '3px',
                  background: (data?.style === 'solid' || !data?.style) ? '#e3f2fd' : 'white',
                  cursor: 'pointer',
                  fontSize: '11px'
                }}
              >
                --- Solid
              </button>
              <button
                onClick={() => handleStyleChange('dashed')}
                style={{
                  padding: '4px 8px',
                  border: '1px solid #ddd',
                  borderRadius: '3px',
                  background: data?.style === 'dashed' ? '#e3f2fd' : 'white',
                  cursor: 'pointer',
                  fontSize: '11px'
                }}
              >
                - - - Dashed
              </button>
              <button
                onClick={() => handleStyleChange('dotted')}
                style={{
                  padding: '4px 8px',
                  border: '1px solid #ddd',
                  borderRadius: '3px',
                  background: data?.style === 'dotted' ? '#e3f2fd' : 'white',
                  cursor: 'pointer',
                  fontSize: '11px'
                }}
              >
                . . . Dotted
              </button>
            </div>
            
            <div style={{ fontSize: '12px', fontWeight: 'bold', marginTop: '8px', marginBottom: '4px' }}>Delay (ms)</div>
            <input
              type="number"
              value={data?.delay || 0}
              onChange={(e) => handleDelayChange(parseInt(e.target.value) || 0)}
              style={{
                width: '100%',
                padding: '4px',
                border: '1px solid #ddd',
                borderRadius: '3px',
                fontSize: '11px'
              }}
              placeholder="0"
              min="0"
              step="100"
            />
            
            <button
              onClick={() => setShowStylePicker(false)}
              style={{
                marginTop: '8px',
                padding: '4px 8px',
                border: '1px solid #ddd',
                borderRadius: '3px',
                background: '#f5f5f5',
                cursor: 'pointer',
                fontSize: '11px',
                width: '100%'
              }}
            >
              Close
            </button>
          </div>
        </EdgeLabelRenderer>
      )}
    </>
  );
};

export default CustomEdge;