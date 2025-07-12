import React, { useState, useCallback, useRef, useEffect } from 'react';
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
  ReactFlowProvider,
  ConnectionLineType,
  EdgeTypes,
  useReactFlow
} from 'reactflow';
import 'reactflow/dist/style.css';
import EditableNode from './components/EditableNode';
import CustomEdge from './components/CustomEdge';
import GroupNode from './components/GroupNode';
import { NodeData, NodeCategory, NodeLabel } from './constants/nodeTypes';

const nodeTypes = {
  editable: EditableNode,
  group: GroupNode,
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
  const [nodeIdCounter, setNodeIdCounter] = useState(3);
  const [isShiftPressed, setIsShiftPressed] = useState(false);
  const [selectedNodes, setSelectedNodes] = useState<Node<NodeData>[]>([]);
  const edgeReconnectSuccessful = useRef(true);
  const { getNodes } = useReactFlow();


  const getId = useCallback(() => `${nodeIdCounter}`, [nodeIdCounter]);

  // Create group from selected nodes
  const createGroupFromSelectedNodes = useCallback(() => {
    if (selectedNodes.length < 2) return;

    // Calculate bounding box for the group
    const selectedIds = selectedNodes.map(node => node.id);
    const minX = Math.min(...selectedNodes.map(node => node.position.x));
    const minY = Math.min(...selectedNodes.map(node => node.position.y));
    const maxX = Math.max(...selectedNodes.map(node => node.position.x + (node.width || 150)));
    const maxY = Math.max(...selectedNodes.map(node => node.position.y + (node.height || 50)));

    const groupWidth = maxX - minX + 50; // Add padding
    const groupHeight = maxY - minY + 50; // Add padding
    const groupId = getId();

    // Create group node
    const groupNode: Node<NodeData> = {
      id: groupId,
      position: { x: minX - 25, y: minY - 25 }, // Offset for padding
      data: {
        label: `Group ${groupId}`,
        category: 'bot' as NodeCategory,
        nodeLabel: 'Group' as NodeLabel,
        nodeId: groupId,
        content: 'Subflow Group',
        groupId: `group_${groupId}`,
        title: `Subflow ${groupId}`,
        description: 'A group of related nodes',
        onLabelChange: () => {},
        onCategoryChange: () => {},
        onNodeLabelChange: () => {},
        onNodeIdChange: () => {},
        onContentChange: () => {},
        onPlaceholderChange: () => {},
        onStoreKeyChange: () => {},
        onGroupIdChange: () => {},
        onTitleChange: () => {},
        onDescriptionChange: () => {}
      },
      type: 'group',
      style: {
        width: groupWidth,
        height: groupHeight
      }
    };

    // Update selected nodes to be children of the group
    const updatedNodes = nodes.map(node => {
      if (selectedIds.includes(node.id)) {
        return {
          ...node,
          parentId: groupId,
          position: {
            x: node.position.x - minX + 25,
            y: node.position.y - minY + 25
          },
          extent: 'parent' as const,
          selected: false
        };
      }
      return node;
    });

    // Add the group node to the list (parent must come before children)
    setNodes([groupNode, ...updatedNodes]);
    setNodeIdCounter(counter => counter + 1);
    setSelectedNodes([]);

    console.log(`Created group ${groupId} with ${selectedNodes.length} child nodes`);
  }, [selectedNodes, nodes, getId, setNodes, setNodeIdCounter]);

  // Ungroup selected group nodes
  const ungroupSelectedNodes = useCallback(() => {
    const groupNodes = selectedNodes.filter(node => node.type === 'group');
    if (groupNodes.length === 0) return;

    let updatedNodes = [...nodes];
    
    groupNodes.forEach(groupNode => {
      // Find child nodes of this group
      const childNodes = updatedNodes.filter(node => node.parentId === groupNode.id);
      
      // Remove the group node
      updatedNodes = updatedNodes.filter(node => node.id !== groupNode.id);
      
      // Update child nodes to remove parent relationship and restore absolute positions
      updatedNodes = updatedNodes.map(node => {
        if (node.parentId === groupNode.id) {
          return {
            ...node,
            parentId: undefined,
            position: {
              x: groupNode.position.x + node.position.x,
              y: groupNode.position.y + node.position.y
            },
            extent: undefined,
            selected: false
          };
        }
        return node;
      });
      
      console.log(`Ungrouped ${childNodes.length} nodes from group ${groupNode.id}`);
    });

    setNodes(updatedNodes);
    setSelectedNodes([]);
  }, [selectedNodes, nodes, setNodes]);

  // Enhanced keyboard event handling for shift key and ungrouping
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Shift') {
        setIsShiftPressed(true);
      }
      // Handle ungrouping with 'U' key
      if (e.key === 'u' || e.key === 'U') {
        const hasGroupSelected = selectedNodes.some(node => node.type === 'group');
        if (hasGroupSelected) {
          ungroupSelectedNodes();
        }
      }
    };

    const handleKeyUp = (e: KeyboardEvent) => {
      if (e.key === 'Shift') {
        setIsShiftPressed(false);
        // Trigger grouping when shift is released and multiple nodes are selected
        if (selectedNodes.length > 1) {
          createGroupFromSelectedNodes();
        }
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    window.addEventListener('keyup', handleKeyUp);

    return () => {
      window.removeEventListener('keydown', handleKeyDown);
      window.removeEventListener('keyup', handleKeyUp);
    };
  }, [selectedNodes, createGroupFromSelectedNodes, ungroupSelectedNodes]);

  // Track selected nodes
  const handleNodesChange = useCallback((changes: any) => {
    onNodesChange(changes);
    
    // Update selected nodes list
    const currentNodes = getNodes();
    const selected = currentNodes.filter(node => node.selected);
    setSelectedNodes(selected);
  }, [onNodesChange, getNodes]);

  // Group field editing callbacks
  const onGroupIdChange = useCallback((nodeId: string, newGroupId: string) => {
    setNodes((nds) =>
      nds.map((node) => {
        if (node.id === nodeId) {
          return {
            ...node,
            data: {
              ...node.data,
              groupId: newGroupId,
            },
          };
        }
        return node;
      })
    );
  }, [setNodes]);

  const onTitleChange = useCallback((nodeId: string, newTitle: string) => {
    setNodes((nds) =>
      nds.map((node) => {
        if (node.id === nodeId) {
          return {
            ...node,
            data: {
              ...node.data,
              title: newTitle,
            },
          };
        }
        return node;
      })
    );
  }, [setNodes]);

  const onDescriptionChange = useCallback((nodeId: string, newDescription: string) => {
    setNodes((nds) =>
      nds.map((node) => {
        if (node.id === nodeId) {
          return {
            ...node,
            data: {
              ...node.data,
              description: newDescription,
            },
          };
        }
        return node;
      })
    );
  }, [setNodes]);

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
  }, [nodes.length, getId, setNodes]);

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
      onGroupIdChange,
      onTitleChange,
      onDescriptionChange,
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

  const saveData = useCallback(() => {
    const data = {
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
    
    localStorage.setItem('react-flow-data', JSON.stringify(data));
  }, [nodes, edges]);

  const restoreData = useCallback(() => {
    const savedData = localStorage.getItem('react-flow-data');
    
    if (savedData) {
      try {
        const importData = JSON.parse(savedData);
        
        if (importData.nodes && importData.edges) {
          // Convert saved nodes to the correct format
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

          // Convert saved edges to the correct format
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
        } else {
          alert('Invalid saved data format.');
        }
      } catch (error) {
        alert('Error restoring saved data.');
      }
    } else {
      alert('No saved data found.');
    }
  }, [setNodes, setEdges, nodeIdCounter, setNodeIdCounter]);

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

  // Flutter Export Utility Functions
  const validateFlowForExport = useCallback((nodes: Node<NodeData>[], edges: Edge[]) => {
    const errors: string[] = [];
    
    // Check for required fields
    if (!nodes?.length) errors.push("No nodes found");
    if (!edges?.length) errors.push("No edges found");
    
    // Validate each node
    nodes.forEach(node => {
      if (!node.data.category) errors.push(`Node ${node.id} missing category`);
      if (!node.data.nodeId) errors.push(`Node ${node.id} missing nodeId`);
      
      switch (node.data.category) {
        case 'bot':
          if (!node.data.content?.trim()) errors.push(`Bot node ${node.id} missing content`);
          break;
        case 'textInput':
          if (!node.data.storeKey?.trim()) errors.push(`TextInput node ${node.id} missing storeKey`);
          break;
        case 'choice':
          if (!node.data.storeKey?.trim()) errors.push(`Choice node ${node.id} missing storeKey`);
          break;
      }
    });
    
    // Validate flow connectivity - find start node
    const hasStartNode = nodes.some(node => 
      !edges.some(edge => edge.target === node.id)
    );
    if (!hasStartNode) errors.push("No start node found (node with no incoming edges)");
    
    return {
      isValid: errors.length === 0,
      errors
    };
  }, []);

  const findStartNode = useCallback((nodes: Node<NodeData>[], edges: Edge[]) => {
    return nodes.find(node => 
      !edges.some(edge => edge.target === node.id)
    );
  }, []);

  const sortNodesTopologically = useCallback((nodes: Node<NodeData>[], edges: Edge[]) => {
    const startNode = findStartNode(nodes, edges);
    if (!startNode) return [];
    
    const visited = new Set<string>();
    const result: Node<NodeData>[] = [];
    
    const visit = (nodeId: string) => {
      if (visited.has(nodeId)) return;
      visited.add(nodeId);
      
      const node = nodes.find(n => n.id === nodeId);
      if (node) result.push(node);
      
      // Visit connected nodes in order
      edges
        .filter(edge => edge.source === nodeId)
        .sort((a, b) => a.target.localeCompare(b.target)) // Ensure consistent ordering
        .forEach(edge => visit(edge.target));
    };
    
    visit(startNode.id);
    return result;
  }, [findStartNode]);

  const getNextMessageId = useCallback((nodeId: string, edges: Edge[]) => {
    const edge = edges.find(e => e.source === nodeId);
    return edge ? parseInt(edge.target) : null;
  }, []);

  const extractChoicesFromEdges = useCallback((nodeId: string, edges: Edge[]) => {
    return edges
      .filter(edge => edge.source === nodeId)
      .map(edge => {
        const label = edge.data?.label || '';
        const [text, value] = label.includes('::') ? label.split('::') : [label, ''];
        
        const choice: any = { text: text.trim() || 'Choice option' };
        
        if (value && value.trim()) {
          const trimmedValue = value.trim();
          // Parse value types
          if (trimmedValue === 'true') choice.value = true;
          else if (trimmedValue === 'false') choice.value = false;
          else if (trimmedValue === 'null') choice.value = null;
          else if (!isNaN(Number(trimmedValue))) choice.value = Number(trimmedValue);
          else choice.value = trimmedValue;
        }
        
        choice.nextMessageId = parseInt(edge.target);
        return choice;
      });
  }, []);

  const extractRoutesFromEdges = useCallback((nodeId: string, edges: Edge[]) => {
    return edges
      .filter(edge => edge.source === nodeId)
      .map(edge => {
        const label = edge.data?.label || '';
        if (label.toLowerCase() === 'default' || !label.trim()) {
          return { default: true, nextMessageId: parseInt(edge.target) };
        }
        return {
          condition: label,
          nextMessageId: parseInt(edge.target)
        };
      });
  }, []);

  const convertNodesToMessages = useCallback((sortedNodes: Node<NodeData>[], edges: Edge[]) => {
    return sortedNodes.map(node => {
      const message: any = {
        id: parseInt(node.data.nodeId || node.id),
        type: node.data.category
      };
      
      
      switch (node.data.category) {
        case 'bot':
          message.text = node.data.content || 'Message content';
          const nextId = getNextMessageId(node.id, edges);
          if (nextId) message.nextMessageId = nextId;
          break;
          
        case 'textInput':
          message.storeKey = node.data.storeKey || 'user.input';
          message.placeholderText = node.data.placeholderText || 'Enter text...';
          const nextTextId = getNextMessageId(node.id, edges);
          if (nextTextId) message.nextMessageId = nextTextId;
          break;
          
        case 'choice':
          message.storeKey = node.data.storeKey || 'user.choice';
          message.choices = extractChoicesFromEdges(node.id, edges);
          break;
          
        case 'autoroute':
          message.routes = extractRoutesFromEdges(node.id, edges);
          break;
          
        case 'user':
          message.text = node.data.content || 'User message';
          const nextUserId = getNextMessageId(node.id, edges);
          if (nextUserId) message.nextMessageId = nextUserId;
          break;
      }
      
      return message;
    });
  }, [getNextMessageId, extractChoicesFromEdges, extractRoutesFromEdges]);

  const exportToFlutterSequence = useCallback(() => {
    // Get sequence metadata from user
    const sequenceId = prompt('Enter sequence ID (e.g., "my_sequence"):') || 'exported_sequence';
    const name = prompt('Enter sequence name (e.g., "My Custom Sequence"):') || 'Exported Sequence';
    const description = prompt('Enter sequence description:') || 'Sequence exported from authoring tool';
    
    try {
      // Validate flow data
      const validation = validateFlowForExport(nodes, edges);
      if (!validation.isValid) {
        alert(`Export failed:\n${validation.errors.join('\n')}`);
        return;
      }

      // Sort nodes by flow order
      const sortedNodes = sortNodesTopologically(nodes, edges);
      if (sortedNodes.length === 0) {
        alert('Export failed: Could not determine node flow order');
        return;
      }

      // Convert to Flutter format
      const messages = convertNodesToMessages(sortedNodes, edges);
      
      const flutterSequence = {
        sequenceId,
        name,
        description,
        messages
      };

      // Download as JSON file
      const dataStr = JSON.stringify(flutterSequence, null, 2);
      const dataUri = 'data:application/json;charset=utf-8,' + encodeURIComponent(dataStr);
      
      const exportFileDefaultName = `${sequenceId}.json`;
      const linkElement = document.createElement('a');
      linkElement.setAttribute('href', dataUri);
      linkElement.setAttribute('download', exportFileDefaultName);
      linkElement.click();
      
      alert(`Successfully exported ${messages.length} messages to ${exportFileDefaultName}`);
      
    } catch (error) {
      console.error('Export error:', error);
      alert(`Export failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }, [nodes, edges, validateFlowForExport, sortNodesTopologically, convertNodesToMessages]);

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
          💡 Based on comprehensive_test.json<br/>
          🔗 Hold Shift + Select multiple nodes to create subflow<br/>
          🔓 Select group node + Press 'U' to ungroup
        </div>
      </div>

      {/* Status Indicators */}
      {isShiftPressed && (
        <div style={{
          position: 'absolute',
          top: 10,
          left: '50%',
          transform: 'translateX(-50%)',
          zIndex: 1000,
          padding: '8px 16px',
          background: 'rgba(76, 175, 80, 0.9)',
          color: 'white',
          borderRadius: '20px',
          fontSize: '12px',
          fontWeight: 'bold',
          boxShadow: '0 2px 8px rgba(0,0,0,0.2)'
        }}>
          🔗 Subflow Mode: Select multiple nodes ({selectedNodes.length} selected)
        </div>
      )}
      
      {/* Ungroup Status Indicator */}
      {!isShiftPressed && selectedNodes.some(node => node.type === 'group') && (
        <div style={{
          position: 'absolute',
          top: 50,
          left: '50%',
          transform: 'translateX(-50%)',
          zIndex: 1000,
          padding: '8px 16px',
          background: 'rgba(255, 152, 0, 0.9)',
          color: 'white',
          borderRadius: '20px',
          fontSize: '12px',
          fontWeight: 'bold',
          boxShadow: '0 2px 8px rgba(0,0,0,0.2)'
        }}>
          🔓 Press 'U' to ungroup selected group ({selectedNodes.filter(node => node.type === 'group').length} group{selectedNodes.filter(node => node.type === 'group').length > 1 ? 's' : ''})
        </div>
      )}

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
          onClick={saveData}
          style={{
            padding: '8px 16px',
            backgroundColor: '#ff9800',
            color: 'white',
            border: 'none',
            borderRadius: '4px',
            cursor: 'pointer',
            fontWeight: 'bold'
          }}
        >
          Save
        </button>
        
        <button 
          onClick={restoreData}
          style={{
            padding: '8px 16px',
            backgroundColor: '#673ab7',
            color: 'white',
            border: 'none',
            borderRadius: '4px',
            cursor: 'pointer',
            fontWeight: 'bold'
          }}
        >
          Restore
        </button>
        
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
        
        <button 
          onClick={exportToFlutterSequence}
          style={{
            padding: '8px 16px',
            backgroundColor: '#e91e63',
            color: 'white',
            border: 'none',
            borderRadius: '4px',
            cursor: 'pointer',
            fontWeight: 'bold'
          }}
        >
          🚀 Export to Flutter
        </button>
        
        <button 
          onClick={ungroupSelectedNodes}
          disabled={!selectedNodes.some(node => node.type === 'group')}
          style={{
            padding: '8px 16px',
            backgroundColor: selectedNodes.some(node => node.type === 'group') ? '#ff9800' : '#ccc',
            color: 'white',
            border: 'none',
            borderRadius: '4px',
            cursor: selectedNodes.some(node => node.type === 'group') ? 'pointer' : 'not-allowed',
            fontWeight: 'bold',
            opacity: selectedNodes.some(node => node.type === 'group') ? 1 : 0.5
          }}
        >
          🔓 Ungroup
        </button>
      </div>
      
      <ReactFlow
        nodes={nodesWithCallbacks}
        edges={edgesWithCallbacks}
        onNodesChange={handleNodesChange}
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
        multiSelectionKeyCode="Shift"
        defaultEdgeOptions={{ zIndex: 1 }}
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