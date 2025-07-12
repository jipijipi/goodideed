import React, { useState, useCallback, useRef } from 'react';
import ReactFlow, { 
  Node, 
  Edge, 
  useNodesState, 
  useEdgesState, 
  addEdge, 
  reconnectEdge,
  Connection,
  Controls,
  Background,
  useReactFlow,
  ReactFlowProvider,
  ConnectionLineType,
  EdgeTypes
} from 'reactflow';
import 'reactflow/dist/style.css';
import EditableNode from './components/EditableNode';
import CustomEdge from './components/CustomEdge';
import { NodeData, NodeCategory, NodeLabel } from './constants/nodeTypes';

const nodeTypes = {
  editable: EditableNode,
};

const edgeTypes: EdgeTypes = {
  custom: CustomEdge,
};

const initialNodes: Node<NodeData>[] = [
  {
    id: '1',
    position: { x: 0, y: 0 },
    data: { 
      label: 'Welcome',
      category: 'bot' as NodeCategory,
      nodeLabel: 'Welcome Message' as NodeLabel,
      nodeId: '1',
      content: 'Welcome to our app!',
      onLabelChange: () => {},
      onCategoryChange: () => {},
      onNodeLabelChange: () => {},
      onNodeIdChange: () => {},
      onContentChange: () => {},
      onPlaceholderChange: () => {},
      onStoreKeyChange: () => {}
    },
    type: 'editable',
  },
  {
    id: '2',
    position: { x: 200, y: 150 },
    data: { 
      label: 'User Input',
      category: 'textInput' as NodeCategory,
      nodeLabel: 'Text Input' as NodeLabel,
      nodeId: '2',
      placeholderText: 'Enter your name...',
      onLabelChange: () => {},
      onCategoryChange: () => {},
      onNodeLabelChange: () => {},
      onNodeIdChange: () => {},
      onContentChange: () => {},
      onPlaceholderChange: () => {},
      onStoreKeyChange: () => {}
    },
    type: 'editable',
  },
];

const initialEdges: Edge[] = [
  { 
    id: 'e1-2', 
    source: '1', 
    target: '2', 
    type: 'custom',
    data: {}
  },
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
  const { getNodes } = useReactFlow();
  const [nodeIdCounter, setNodeIdCounter] = useState(3);
  const edgeReconnectSuccessful = useRef(true);

  const getId = () => `${nodeIdCounter}`;
  const nodeOrigin: [number, number] = [0.5, 0];

  const onConnect = useCallback(
    (params: Connection) => {
      const newEdge = {
        ...params,
        type: 'custom',
        data: {}
      };
      setEdges((eds) => addEdge(newEdge, eds));
    },
    [setEdges]
  );

  const onReconnectStart = useCallback(() => {
    edgeReconnectSuccessful.current = false;
  }, []);

  const onReconnect = useCallback((oldEdge: Edge, newConnection: Connection) => {
    edgeReconnectSuccessful.current = true;
    setEdges((els) => reconnectEdge(oldEdge, newConnection, els));
  }, [setEdges]);

  const onReconnectEnd = useCallback((event: MouseEvent | TouchEvent, edge: Edge) => {
    if (!edgeReconnectSuccessful.current) {
      setEdges((eds) => eds.filter((e) => e.id !== edge.id));
    }
    edgeReconnectSuccessful.current = true;
  }, [setEdges]);


  const createQuickNode = useCallback((nodeType: { category: NodeCategory, label: NodeLabel, text: string }) => {
    const id = getId();
    const position = { x: 300, y: 200 + (nodes.length * 50) }; // Stagger positions
    
    // Set default values based on node type
    const getDefaultData = (category: NodeCategory) => {
      const baseData = {
        label: nodeType.text,
        category: nodeType.category,
        nodeLabel: nodeType.label,
        nodeId: id,
        onLabelChange: () => {},
        onCategoryChange: () => {},
        onNodeLabelChange: () => {},
        onNodeIdChange: () => {},
        onContentChange: () => {},
        onPlaceholderChange: () => {},
        onStoreKeyChange: () => {}
      };

      switch (category) {
        case 'bot':
        case 'user':
          return { ...baseData, content: 'Enter your message here...' };
        case 'textInput':
          return { 
            ...baseData, 
            placeholderText: 'Enter placeholder text...'
          };
        case 'choice':
          return baseData;
        case 'autoroute':
          return baseData;
        default:
          return baseData;
      }
    };
    
    const newNode: Node<NodeData> = {
      id,
      position,
      data: getDefaultData(nodeType.category),
      type: 'editable',
    };

    setNodes((nds) => nds.concat(newNode));
    setNodeIdCounter((counter) => counter + 1);
  }, [nodes.length, nodeIdCounter]);

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

  const onNodeIdChange = useCallback((nodeId: string, newNodeId: string) => {
    setNodes((nds) =>
      nds.map((node) => {
        if (node.id === nodeId) {
          return {
            ...node,
            data: {
              ...node.data,
              nodeId: newNodeId,
            },
          };
        }
        return node;
      })
    );
  }, [setNodes]);

  const onContentChange = useCallback((nodeId: string, newContent: string) => {
    setNodes((nds) =>
      nds.map((node) => {
        if (node.id === nodeId) {
          return {
            ...node,
            data: {
              ...node.data,
              content: newContent,
            },
          };
        }
        return node;
      })
    );
  }, [setNodes]);

  const onPlaceholderChange = useCallback((nodeId: string, newPlaceholder: string) => {
    setNodes((nds) =>
      nds.map((node) => {
        if (node.id === nodeId) {
          return {
            ...node,
            data: {
              ...node.data,
              placeholderText: newPlaceholder,
            },
          };
        }
        return node;
      })
    );
  }, [setNodes]);

  const onStoreKeyChange = useCallback((nodeId: string, newStoreKey: string) => {
    setNodes((nds) =>
      nds.map((node) => {
        if (node.id === nodeId) {
          return {
            ...node,
            data: {
              ...node.data,
              storeKey: newStoreKey,
            },
          };
        }
        return node;
      })
    );
  }, [setNodes]);

  const onEdgeLabelChange = useCallback((edgeId: string, newLabel: string) => {
    setEdges((eds) =>
      eds.map((edge) => {
        if (edge.id === edgeId) {
          return {
            ...edge,
            data: {
              ...edge.data,
              label: newLabel,
            },
          };
        }
        return edge;
      })
    );
  }, [setEdges]);

  // Update nodes with all callback functions
  const nodesWithCallbacks = nodes.map(node => ({
    ...node,
    data: {
      ...node.data,
      onLabelChange,
      onCategoryChange,
      onNodeLabelChange,
      onNodeIdChange,
      onContentChange,
      onPlaceholderChange,
      onStoreKeyChange,
    },
  }));

  // Update edges with callback functions
  const edgesWithCallbacks = edges.map(edge => ({
    ...edge,
    data: {
      ...edge.data,
      onLabelChange: onEdgeLabelChange,
    },
  }));

  const exportToJSON = useCallback(() => {
    const exportData = {
      nodes: nodes.map(({ data, ...node }) => ({
        ...node,
        data: { 
          label: data.label,
          category: data.category,
          nodeLabel: data.nodeLabel,
          nodeId: data.nodeId,
          content: data.content,
          placeholderText: data.placeholderText,
          storeKey: data.storeKey
        }
      })),
      edges: edges.map(edge => ({
        id: edge.id,
        source: edge.source,
        target: edge.target,
        type: edge.type || 'default',
        label: edge.data?.label
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

  const importFromJSON = useCallback(() => {
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = '.json';
    input.onchange = (event) => {
      const file = (event.target as HTMLInputElement).files?.[0];
      if (file) {
        const reader = new FileReader();
        reader.onload = (e) => {
          try {
            const content = e.target?.result as string;
            const importData = JSON.parse(content);
            
            if (importData.nodes && importData.edges) {
              // Convert imported nodes to the correct format
              const importedNodes = importData.nodes.map((node: any) => ({
                ...node,
                data: {
                  ...node.data,
                  onLabelChange: () => {},
                  onCategoryChange: () => {},
                  onNodeLabelChange: () => {},
                  onNodeIdChange: () => {},
                  onContentChange: () => {},
                  onPlaceholderChange: () => {},
                  onStoreKeyChange: () => {}
                }
              }));

              // Convert imported edges to the correct format
              const importedEdges = importData.edges.map((edge: any) => ({
                ...edge,
                type: edge.type || 'custom',
                data: { 
                  label: edge.label,
                  onLabelChange: () => {}
                }
              }));

              setNodes(importedNodes);
              setEdges(importedEdges);
              
              // Update node counter based on imported nodes
              const maxNodeId = Math.max(
                ...importedNodes
                  .map((n: any) => parseInt(n.id))
                  .filter((id: number) => !isNaN(id)),
                nodeIdCounter
              );
              setNodeIdCounter(maxNodeId + 1);
              
              alert('Flow imported successfully!');
            } else {
              alert('Invalid JSON format. Please ensure the file contains nodes and edges.');
            }
          } catch (error) {
            alert('Error parsing JSON file. Please check the file format.');
          }
        };
        reader.readAsText(file);
      }
    };
    input.click();
  }, [setNodes, setEdges, nodeIdCounter, setNodeIdCounter]);

  const nodeTemplates = [
    { category: 'bot' as NodeCategory, label: 'Welcome Message' as NodeLabel, text: 'Welcome!', icon: '💬', description: 'Bot message' },
    { category: 'user' as NodeCategory, label: 'Response' as NodeLabel, text: 'User response', icon: '👤', description: 'User message' },
    { category: 'choice' as NodeCategory, label: 'Choice Menu' as NodeLabel, text: 'Select option:', icon: '🔘', description: 'Choice buttons' },
    { category: 'textInput' as NodeCategory, label: 'Text Input' as NodeLabel, text: 'Enter text:', icon: '⌨️', description: 'Text input' },
    { category: 'autoroute' as NodeCategory, label: 'Conditional Route' as NodeLabel, text: 'Route condition', icon: '🔀', description: 'Auto-route' },
  ];


  return (
    <div style={{ width: '100vw', height: '100vh', position: 'relative' }}>
      {/* Quick Create Panel */}
      <div style={{
        position: 'absolute',
        top: 10,
        left: 10,
        zIndex: 1000,
        padding: '12px',
        background: 'white',
        borderRadius: '8px',
        boxShadow: '0 2px 8px rgba(0,0,0,0.15)',
        minWidth: '200px'
      }}>
        <div style={{ 
          fontSize: '14px', 
          fontWeight: 'bold', 
          marginBottom: '10px',
          color: '#333',
          borderBottom: '1px solid #eee',
          paddingBottom: '8px'
        }}>
          🚀 Quick Create
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: '6px' }}>
          {nodeTemplates.map((template, index) => (
            <button
              key={index}
              onClick={() => createQuickNode(template)}
              style={{
                padding: '8px 12px',
                border: '1px solid #ddd',
                borderRadius: '6px',
                background: '#fff',
                cursor: 'pointer',
                textAlign: 'left',
                fontSize: '12px',
                transition: 'all 0.2s',
                display: 'flex',
                alignItems: 'center',
                gap: '8px'
              }}
              onMouseEnter={(e) => {
                e.currentTarget.style.background = '#f8f9fa';
                e.currentTarget.style.borderColor = '#999';
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.background = '#fff';
                e.currentTarget.style.borderColor = '#ddd';
              }}
            >
              <span style={{ fontSize: '16px' }}>{template.icon}</span>
              <div>
                <div style={{ fontWeight: 'bold', color: '#333' }}>
                  {template.description}
                </div>
                <div style={{ color: '#666', fontSize: '11px' }}>
                  {template.category} • {template.label}
                </div>
              </div>
            </button>
          ))}
        </div>

        
        <div style={{ 
          fontSize: '11px', 
          color: '#888', 
          marginTop: '10px',
          fontStyle: 'italic',
          borderTop: '1px solid #eee',
          paddingTop: '8px'
        }}>
          💡 Based on comprehensive_test.json
        </div>
      </div>

      {/* Controls Panel */}
      <div style={{ 
        position: 'absolute', 
        top: 10, 
        right: 10, 
        zIndex: 1000,
        padding: '10px',
        background: 'white',
        borderRadius: '5px',
        boxShadow: '0 2px 4px rgba(0,0,0,0.1)',
        display: 'flex',
        flexDirection: 'column',
        gap: '8px'
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
            fontWeight: 'bold',
            marginBottom: '8px'
          }}
        >
          Export JSON
        </button>
        
        <button 
          onClick={importFromJSON}
          style={{
            padding: '8px 16px',
            backgroundColor: '#4caf50',
            color: 'white',
            border: 'none',
            borderRadius: '4px',
            cursor: 'pointer',
            fontWeight: 'bold'
          }}
        >
          Import JSON
        </button>
      </div>
      
      <ReactFlow
        nodes={nodesWithCallbacks}
        edges={edgesWithCallbacks}
        onNodesChange={onNodesChange}
        onEdgesChange={onEdgesChange}
        onConnect={onConnect}
        onReconnect={onReconnect}
        onReconnectStart={onReconnectStart}
        onReconnectEnd={onReconnectEnd}
        nodeTypes={nodeTypes}
        edgeTypes={edgeTypes}
        fitView
        connectionLineType={ConnectionLineType.Bezier}
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