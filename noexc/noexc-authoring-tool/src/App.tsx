import React, { useState, useCallback, useRef } from 'react';
import ReactFlow, { 
  Node, 
  Edge, 
  useNodesState, 
  useEdgesState, 
  addEdge, 
  Connection,
  Controls,
  Background,
  useReactFlow,
  ReactFlowProvider,
  OnConnectStartParams,
  OnConnectEnd,
  ConnectionLineType
} from 'reactflow';
import 'reactflow/dist/style.css';
import EditableNode from './components/EditableNode';
import { NodeData, NodeCategory, NodeLabel } from './constants/nodeTypes';

const nodeTypes = {
  editable: EditableNode,
};

const initialNodes: Node<NodeData>[] = [
  {
    id: '1',
    position: { x: 0, y: 0 },
    data: { 
      label: 'Welcome',
      category: 'bot' as NodeCategory,
      nodeLabel: 'Welcome Message' as NodeLabel,
      onLabelChange: () => {},
      onCategoryChange: () => {},
      onNodeLabelChange: () => {}
    },
    type: 'editable',
  },
  {
    id: '2',
    position: { x: 200, y: 150 },
    data: { 
      label: 'User Response',
      category: 'user' as NodeCategory,
      nodeLabel: 'Response' as NodeLabel,
      onLabelChange: () => {},
      onCategoryChange: () => {},
      onNodeLabelChange: () => {}
    },
    type: 'editable',
  },
];

const initialEdges: Edge[] = [
  { id: 'e1-2', source: '1', target: '2', type: 'default' },
];

const FlowWithProvider = () => {
  return (
    <ReactFlowProvider>
      <Flow />
    </ReactFlowProvider>
  );
};

function Flow() {
  const [nodes, setNodes, onNodesChange] = useNodesState(initialNodes);
  const [edges, setEdges, onEdgesChange] = useEdgesState(initialEdges);
  const connectingNodeId = useRef<string | null>(null);
  const { screenToFlowPosition, getNodes } = useReactFlow();
  const [nodeIdCounter, setNodeIdCounter] = useState(3);

  const onConnect = useCallback(
    (params: Connection) => setEdges((eds) => addEdge(params, eds)),
    [setEdges]
  );

  const onConnectStart = useCallback((event: React.MouseEvent | React.TouchEvent, { nodeId }: OnConnectStartParams) => {
    connectingNodeId.current = nodeId;
  }, []);

  const onConnectEnd = useCallback(
    (event: MouseEvent | TouchEvent) => {
      if (!connectingNodeId.current) return;

      const targetIsPane = (event.target as Element)?.classList?.contains('react-flow__pane');

      if (targetIsPane) {
        // Create new node at drop position
        const position = screenToFlowPosition({
          x: (event as MouseEvent).clientX,
          y: (event as MouseEvent).clientY,
        });

        const newNode: Node<NodeData> = {
          id: `${nodeIdCounter}`,
          position,
          data: {
            label: `New Node`,
            category: 'bot' as NodeCategory,
            nodeLabel: 'Custom' as NodeLabel,
            onLabelChange: () => {},
            onCategoryChange: () => {},
            onNodeLabelChange: () => {}
          },
          type: 'editable',
        };

        setNodes((nds) => nds.concat(newNode));
        setEdges((eds) =>
          eds.concat({
            id: `e${connectingNodeId.current}-${nodeIdCounter}`,
            source: connectingNodeId.current!,
            target: `${nodeIdCounter}`,
            type: 'default'
          })
        );
        setNodeIdCounter((id) => id + 1);
      }

      connectingNodeId.current = null;
    },
    [screenToFlowPosition, setNodes, setEdges, nodeIdCounter]
  );

  // Enhanced onConnect with proximity detection
  const onConnectWithProximity = useCallback(
    (params: Connection) => {
      const sourceNode = getNodes().find(n => n.id === params.source);
      const targetNode = getNodes().find(n => n.id === params.target);
      
      if (sourceNode && targetNode) {
        const distance = Math.sqrt(
          Math.pow(targetNode.position.x - sourceNode.position.x, 2) +
          Math.pow(targetNode.position.y - sourceNode.position.y, 2)
        );
        
        // Auto-connect if nodes are within 150px
        if (distance <= 150) {
          setEdges((eds) => addEdge(params, eds));
        } else {
          // For distant connections, ask for confirmation
          if (window.confirm(`Connect distant nodes? Distance: ${Math.round(distance)}px`)) {
            setEdges((eds) => addEdge(params, eds));
          }
        }
      } else {
        setEdges((eds) => addEdge(params, eds));
      }
    },
    [setEdges, getNodes]
  );

  const onLabelChange = useCallback((nodeId: string, newLabel: string) => {
    setNodes((nds) =>
      nds.map((node) => {
        if (node.id === nodeId) {
          return {
            ...node,
            data: {
              ...node.data,
              label: newLabel,
            },
          };
        }
        return node;
      })
    );
  }, [setNodes]);

  const onCategoryChange = useCallback((nodeId: string, newCategory: NodeCategory) => {
    setNodes((nds) =>
      nds.map((node) => {
        if (node.id === nodeId) {
          return {
            ...node,
            data: {
              ...node.data,
              category: newCategory,
            },
          };
        }
        return node;
      })
    );
  }, [setNodes]);

  const onNodeLabelChange = useCallback((nodeId: string, newNodeLabel: NodeLabel) => {
    setNodes((nds) =>
      nds.map((node) => {
        if (node.id === nodeId) {
          return {
            ...node,
            data: {
              ...node.data,
              nodeLabel: newNodeLabel,
            },
          };
        }
        return node;
      })
    );
  }, [setNodes]);

  // Update nodes with all callback functions
  const nodesWithCallbacks = nodes.map(node => ({
    ...node,
    data: {
      ...node.data,
      onLabelChange,
      onCategoryChange,
      onNodeLabelChange,
    },
  }));

  const exportToJSON = useCallback(() => {
    const exportData = {
      nodes: nodes.map(({ data, ...node }) => ({
        ...node,
        data: { 
          label: data.label,
          category: data.category,
          nodeLabel: data.nodeLabel
        }
      })),
      edges: edges.map(edge => ({
        id: edge.id,
        source: edge.source,
        target: edge.target,
        type: edge.type || 'default'
      }))
    };

    const dataStr = JSON.stringify(exportData, null, 2);
    const dataUri = 'data:application/json;charset=utf-8,'+ encodeURIComponent(dataStr);
    
    const exportFileDefaultName = 'sequence-flow.json';
    const linkElement = document.createElement('a');
    linkElement.setAttribute('href', dataUri);
    linkElement.setAttribute('download', exportFileDefaultName);
    linkElement.click();
  }, [nodes, edges]);

  return (
    <div style={{ width: '100vw', height: '100vh', position: 'relative' }}>
      <div style={{ 
        position: 'absolute', 
        top: 10, 
        right: 10, 
        zIndex: 1000,
        padding: '10px',
        background: 'white',
        borderRadius: '5px',
        boxShadow: '0 2px 4px rgba(0,0,0,0.1)'
      }}>
        <button 
          onClick={exportToJSON}
          style={{
            padding: '8px 16px',
            backgroundColor: '#1976d2',
            color: 'white',
            border: 'none',
            borderRadius: '4px',
            cursor: 'pointer',
            fontWeight: 'bold'
          }}
        >
          Export JSON
        </button>
      </div>
      
      <ReactFlow
        nodes={nodesWithCallbacks}
        edges={edges}
        onNodesChange={onNodesChange}
        onEdgesChange={onEdgesChange}
        onConnect={onConnectWithProximity}
        onConnectStart={onConnectStart}
        onConnectEnd={onConnectEnd}
        nodeTypes={nodeTypes}
        fitView
        connectionLineType={ConnectionLineType.SmoothStep}
        connectionRadius={30}
      >
        <Controls />
        <Background />
      </ReactFlow>
    </div>
  );
}

function App() {
  return <FlowWithProvider />;
}

export default App;