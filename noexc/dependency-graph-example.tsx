// Example: Dependency Graph Component
import React, { useMemo } from 'react';
import { Node, Edge } from 'reactflow';

interface SequenceDependency {
  sequenceId: string;
  name: string;
  dependencies: string[]; // sequences this one depends on
  dependents: string[];   // sequences that depend on this one
  nodeCount: number;
  status: 'valid' | 'warning' | 'error';
  issues: string[];
}

interface DependencyGraphProps {
  sequences: SequenceDependency[];
  onSequenceClick: (sequenceId: string) => void;
}

const DependencyGraph: React.FC<DependencyGraphProps> = ({ sequences, onSequenceClick }) => {
  
  // Analyze sequences to build dependency relationships
  const analyzeSequences = (allNodes: Node[], allEdges: Edge[]) => {
    const dependencies: SequenceDependency[] = [];
    const sequenceMap = new Map<string, string[]>(); // sequenceId -> referenced sequences
    
    // Group nodes by sequence (based on parentId)
    const sequenceNodes = new Map<string, Node[]>();
    allNodes.forEach(node => {
      const sequenceId = node.parentId || 'main';
      if (!sequenceNodes.has(sequenceId)) {
        sequenceNodes.set(sequenceId, []);
      }
      sequenceNodes.get(sequenceId)!.push(node);
    });
    
    // Analyze edges for cross-sequence references
    allEdges.forEach(edge => {
      const label = edge.data?.label || '';
      if (label.startsWith('@')) {
        const targetSequence = label.substring(1);
        const sourceNode = allNodes.find(n => n.id === edge.source);
        const sourceSequence = sourceNode?.parentId || 'main';
        
        if (!sequenceMap.has(sourceSequence)) {
          sequenceMap.set(sourceSequence, []);
        }
        
        const refs = sequenceMap.get(sourceSequence)!;
        if (!refs.includes(targetSequence)) {
          refs.push(targetSequence);
        }
      }
    });
    
    // Build dependency objects
    sequenceNodes.forEach((nodes, sequenceId) => {
      const referencedSequences = sequenceMap.get(sequenceId) || [];
      const referencingSequences: string[] = [];
      
      // Find sequences that reference this one
      sequenceMap.forEach((refs, sourceSeq) => {
        if (refs.includes(sequenceId) && sourceSeq !== sequenceId) {
          referencingSequences.push(sourceSeq);
        }
      });
      
      // Validate sequence
      const issues: string[] = [];
      let status: 'valid' | 'warning' | 'error' = 'valid';
      
      // Check for missing references
      referencedSequences.forEach(refSeq => {
        if (!sequenceNodes.has(refSeq)) {
          issues.push(`References non-existent sequence: ${refSeq}`);
          status = 'error';
        }
      });
      
      // Check for circular dependencies
      const checkCircular = (current: string, visited: Set<string>): boolean => {
        if (visited.has(current)) return true;
        visited.add(current);
        
        const deps = sequenceMap.get(current) || [];
        return deps.some(dep => checkCircular(dep, new Set(visited)));
      };
      
      if (checkCircular(sequenceId, new Set())) {
        issues.push('Circular dependency detected');
        status = 'error';
      }
      
      // Check for unreachable sequences
      if (referencingSequences.length === 0 && sequenceId !== 'main') {
        issues.push('Unreachable sequence (no incoming references)');
        status = 'warning';
      }
      
      dependencies.push({
        sequenceId,
        name: sequenceId.charAt(0).toUpperCase() + sequenceId.slice(1),
        dependencies: referencedSequences,
        dependents: referencingSequences,
        nodeCount: nodes.length,
        status,
        issues
      });
    });
    
    return dependencies;
  };
  
  const getStatusColor = (status: string) => {
    switch (status) {
      case 'valid': return '#4caf50';
      case 'warning': return '#ff9800';
      case 'error': return '#f44336';
      default: return '#9e9e9e';
    }
  };
  
  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'valid': return '✅';
      case 'warning': return '⚠️';
      case 'error': return '❌';
      default: return '❓';
    }
  };
  
  // Calculate graph layout using force-directed algorithm
  const calculateLayout = (dependencies: SequenceDependency[]) => {
    const nodes: any[] = [];
    const edges: any[] = [];
    
    // Create nodes
    dependencies.forEach((dep, index) => {
      nodes.push({
        id: dep.sequenceId,
        position: { 
          x: (index % 3) * 300, 
          y: Math.floor(index / 3) * 200 
        },
        data: dep,
        type: 'sequence'
      });
    });
    
    // Create edges
    dependencies.forEach(dep => {
      dep.dependencies.forEach(targetId => {
        edges.push({
          id: `${dep.sequenceId}-${targetId}`,
          source: dep.sequenceId,
          target: targetId,
          type: 'dependency',
          animated: true,
          style: { stroke: '#666' }
        });
      });
    });
    
    return { nodes, edges };
  };
  
  const layout = useMemo(() => calculateLayout(sequences), [sequences]);
  
  return (
    <div className="dependency-graph">
      <div className="graph-header">
        <h3>Sequence Dependencies</h3>
        <div className="graph-legend">
          <div className="legend-item">
            <span className="legend-color" style={{backgroundColor: '#4caf50'}}></span>
            Valid
          </div>
          <div className="legend-item">
            <span className="legend-color" style={{backgroundColor: '#ff9800'}}></span>
            Warning
          </div>
          <div className="legend-item">
            <span className="legend-color" style={{backgroundColor: '#f44336'}}></span>
            Error
          </div>
        </div>
      </div>
      
      <div className="graph-container">
        <svg width="800" height="600" viewBox="0 0 800 600">
          {/* Render edges */}
          {layout.edges.map(edge => {
            const sourceNode = layout.nodes.find(n => n.id === edge.source);
            const targetNode = layout.nodes.find(n => n.id === edge.target);
            
            if (!sourceNode || !targetNode) return null;
            
            return (
              <line
                key={edge.id}
                x1={sourceNode.position.x + 75}
                y1={sourceNode.position.y + 40}
                x2={targetNode.position.x + 75}
                y2={targetNode.position.y + 40}
                stroke="#666"
                strokeWidth="2"
                markerEnd="url(#arrowhead)"
              />
            );
          })}
          
          {/* Arrow marker */}
          <defs>
            <marker id="arrowhead" markerWidth="10" markerHeight="7" 
                    refX="9" refY="3.5" orient="auto">
              <polygon points="0 0, 10 3.5, 0 7" fill="#666" />
            </marker>
          </defs>
          
          {/* Render nodes */}
          {layout.nodes.map(node => (
            <g key={node.id}>
              <rect
                x={node.position.x}
                y={node.position.y}
                width="150"
                height="80"
                rx="8"
                fill={getStatusColor(node.data.status)}
                fillOpacity="0.1"
                stroke={getStatusColor(node.data.status)}
                strokeWidth="2"
                onClick={() => onSequenceClick(node.id)}
                style={{ cursor: 'pointer' }}
              />
              
              <text
                x={node.position.x + 75}
                y={node.position.y + 25}
                textAnchor="middle"
                fontSize="14"
                fontWeight="bold"
                fill="#333"
              >
                {getStatusIcon(node.data.status)} {node.data.name}
              </text>
              
              <text
                x={node.position.x + 75}
                y={node.position.y + 45}
                textAnchor="middle"
                fontSize="12"
                fill="#666"
              >
                {node.data.nodeCount} nodes
              </text>
              
              <text
                x={node.position.x + 75}
                y={node.position.y + 65}
                textAnchor="middle"
                fontSize="10"
                fill="#888"
              >
                {node.data.dependencies.length} deps • {node.data.dependents.length} refs
              </text>
            </g>
          ))}
        </svg>
      </div>
      
      {/* Issues Panel */}
      <div className="issues-panel">
        <h4>Issues Found</h4>
        {sequences.filter(s => s.issues.length > 0).map(seq => (
          <div key={seq.sequenceId} className="issue-item">
            <div className="issue-header">
              {getStatusIcon(seq.status)} <strong>{seq.name}</strong>
            </div>
            <ul className="issue-list">
              {seq.issues.map((issue, index) => (
                <li key={index} className={`issue-${seq.status}`}>
                  {issue}
                </li>
              ))}
            </ul>
          </div>
        ))}
      </div>
    </div>
  );
};

export default DependencyGraph;