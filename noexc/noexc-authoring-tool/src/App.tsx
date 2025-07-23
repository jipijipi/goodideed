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
  useReactFlow,
  useViewport
} from 'reactflow';
import 'reactflow/dist/style.css';
import EditableNode from './components/EditableNode';
import CustomEdge from './components/CustomEdge';
import GroupNode from './components/GroupNode';
import { NodeData, NodeCategory, NodeLabel, DataActionItem, NODE_TYPES } from './constants/nodeTypes';
import { VariableManagerProvider } from './context/VariableManagerContext';
import VariableManager from './components/VariableManager';
import HelpTooltip from './components/HelpTooltip';
import { helpContent } from './constants/helpContent';

const nodeTypes = {
  [NODE_TYPES.EDITABLE]: EditableNode,
  [NODE_TYPES.GROUP]: GroupNode,
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
      onContentKeyChange: () => {},
      onContentChange: () => {},
      onPlaceholderChange: () => {},
      onStoreKeyChange: () => {},
      onDataActionsChange: () => {}
    },
    type: NODE_TYPES.EDITABLE,
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
      onContentKeyChange: () => {},
      onContentChange: () => {},
      onPlaceholderChange: () => {},
      onStoreKeyChange: () => {},
      onDataActionsChange: () => {}
    },
    type: NODE_TYPES.EDITABLE,
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
  const [selectedEdge, setSelectedEdge] = useState<Edge | null>(null);
  const [notification, setNotification] = useState<string | null>(null);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [showVariableManager, setShowVariableManager] = useState(false);
  const edgeReconnectSuccessful = useRef(true);
  const { getNodes, zoomTo, fitView } = useReactFlow();
  const { x: viewportX, y: viewportY, zoom } = useViewport();

  // Show notification briefly
  const showNotification = useCallback((message: string) => {
    setNotification(message);
    setTimeout(() => setNotification(null), 3000);
  }, []);

  // Show error with detailed information
  const showError = useCallback((title: string, errors: string[]) => {
    const errorDetails = errors.length > 0 ? `\n\nDetails:\n${errors.map(e => `• ${e}`).join('\n')}` : '';
    setErrorMessage(`${title}${errorDetails}`);
    setTimeout(() => setErrorMessage(null), 8000); // Longer display for errors
  }, []);


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
        onContentKeyChange: () => {},
        onContentChange: () => {},
        onPlaceholderChange: () => {},
        onStoreKeyChange: () => {},
        onGroupIdChange: () => {},
        onTitleChange: () => {},
        onDescriptionChange: () => {}
      },
      type: NODE_TYPES.GROUP,
      style: {
        width: groupWidth,
        height: groupHeight,
        zIndex: 999
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
    // Sort nodes to ensure parents come before children
    const sortedNodes = [groupNode, ...updatedNodes].sort((a, b) => {
      // Groups (parents) come first
      if (a.type === 'group' && b.type !== 'group') return -1;
      if (a.type !== 'group' && b.type === 'group') return 1;
      // Among groups, sort by ID
      if (a.type === 'group' && b.type === 'group') return a.id.localeCompare(b.id);
      // Among children, sort by parent then by ID
      if (a.parentId && b.parentId) {
        if (a.parentId !== b.parentId) return a.parentId.localeCompare(b.parentId);
        return a.id.localeCompare(b.id);
      }
      // Nodes with parents come after nodes without parents
      if (a.parentId && !b.parentId) return 1;
      if (!a.parentId && b.parentId) return -1;
      // Regular nodes sort by ID
      return a.id.localeCompare(b.id);
    });
    setNodes(sortedNodes);
    setNodeIdCounter(counter => counter + 1);
    setSelectedNodes([]);

    showNotification(`Created group ${groupId} with ${selectedNodes.length} child nodes`);
  }, [selectedNodes, nodes, getId, setNodes, setNodeIdCounter]);

  // Resize all groups to fit their children with generous padding
  const resizeAllGroups = useCallback(() => {
    const groupNodes = nodes.filter(node => node.type === NODE_TYPES.GROUP);
    if (groupNodes.length === 0) {
      showError('No groups found', ['Create some groups first to resize them']);
      return;
    }

    let resizedCount = 0;
    const updatedNodes = nodes.map(node => {
      if (node.type === NODE_TYPES.GROUP) {
        // Find all child nodes of this group
        const childNodes = nodes.filter(child => child.parentId === node.id);
        
        if (childNodes.length === 0) {
          // Empty group - keep current size or set minimum size
          return node;
        }

        // Calculate bounding box of all children
        const minX = Math.min(...childNodes.map(child => child.position.x));
        const minY = Math.min(...childNodes.map(child => child.position.y));
        const maxX = Math.max(...childNodes.map(child => child.position.x + (child.width || 150)));
        const maxY = Math.max(...childNodes.map(child => child.position.y + (child.height || 50)));

        // Add generous padding (50px on all sides)
        const padding = 50;
        const newWidth = maxX - minX + (padding * 2);
        const newHeight = maxY - minY + (padding * 2);

        // Only resize if the new size is different
        const currentWidth = node.style?.width || 200;
        const currentHeight = node.style?.height || 100;
        
        if (Math.abs(newWidth - Number(currentWidth)) > 5 || Math.abs(newHeight - Number(currentHeight)) > 5) {
          resizedCount++;
          return {
            ...node,
            style: {
              ...node.style,
              width: newWidth,
              height: newHeight,
            }
          };
        }
      }
      return node;
    });

    if (resizedCount > 0) {
      setNodes(updatedNodes);
      showNotification(`Resized ${resizedCount} group${resizedCount === 1 ? '' : 's'} to fit their children`);
    } else {
      showNotification('All groups are already properly sized');
    }
  }, [nodes, setNodes, showNotification, showError]);

  // Zoom out significantly to see the entire canvas
  const zoomOutLot = useCallback(() => {
    zoomTo(0.01, { duration: 800 });
    showNotification('Zoomed out to 1% for maximum canvas overview');
  }, [zoomTo, showNotification]);

  // Ungroup selected group nodes
  const ungroupSelectedNodes = useCallback(() => {
    const groupNodes = selectedNodes.filter(node => node.type === NODE_TYPES.GROUP);
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
      
      showNotification(`Ungrouped ${childNodes.length} nodes from group ${groupNode.id}`);
    });

    setNodes(updatedNodes);
    setSelectedNodes([]);
  }, [selectedNodes, nodes, setNodes]);

  // Add selected nodes to an existing group
  const addNodesToGroup = useCallback((targetGroupId: string) => {
    const regularNodes = selectedNodes.filter(node => node.type !== NODE_TYPES.GROUP && !node.parentId);
    if (regularNodes.length === 0) {
      showError('No ungrouped nodes selected', ['Select nodes that are not already in a group']);
      return;
    }

    const targetGroup = nodes.find(node => node.id === targetGroupId && node.type === NODE_TYPES.GROUP);
    if (!targetGroup) {
      showError('Target group not found', ['Please select a valid group']);
      return;
    }

    const updatedNodes = nodes.map(node => {
      if (regularNodes.some(selected => selected.id === node.id)) {
        return {
          ...node,
          parentId: targetGroupId,
          position: {
            x: node.position.x - targetGroup.position.x + 25,
            y: node.position.y - targetGroup.position.y + 25
          },
          extent: 'parent' as const,
          selected: false
        };
      }
      return node;
    });

    // Sort nodes to ensure parents come before children
    const sortedNodes = updatedNodes.sort((a, b) => {
      if (a.type === 'group' && b.type !== 'group') return -1;
      if (a.type !== 'group' && b.type === 'group') return 1;
      if (a.type === 'group' && b.type === 'group') return a.id.localeCompare(b.id);
      if (a.parentId && b.parentId) {
        if (a.parentId !== b.parentId) return a.parentId.localeCompare(b.parentId);
        return a.id.localeCompare(b.id);
      }
      if (a.parentId && !b.parentId) return 1;
      if (!a.parentId && b.parentId) return -1;
      return a.id.localeCompare(b.id);
    });
    setNodes(sortedNodes);
    setSelectedNodes([]);
    showNotification(`Added ${regularNodes.length} node${regularNodes.length === 1 ? '' : 's'} to group ${targetGroupId}`);
  }, [selectedNodes, nodes, setNodes, showNotification, showError]);

  // Remove selected nodes from their groups
  const removeNodesFromGroup = useCallback(() => {
    const groupedNodes = selectedNodes.filter(node => node.parentId && node.type !== NODE_TYPES.GROUP);
    if (groupedNodes.length === 0) {
      showError('No grouped nodes selected', ['Select nodes that are currently in a group']);
      return;
    }

    const updatedNodes = nodes.map(node => {
      if (groupedNodes.some(selected => selected.id === node.id)) {
        const parentGroup = nodes.find(n => n.id === node.parentId);
        return {
          ...node,
          parentId: undefined,
          position: {
            x: (parentGroup?.position.x || 0) + node.position.x,
            y: (parentGroup?.position.y || 0) + node.position.y
          },
          extent: undefined,
          selected: false
        };
      }
      return node;
    });

    setNodes(updatedNodes);
    setSelectedNodes([]);
    showNotification(`Removed ${groupedNodes.length} node${groupedNodes.length === 1 ? '' : 's'} from their group${groupedNodes.length === 1 ? '' : 's'}`);
  }, [selectedNodes, nodes, setNodes, showNotification, showError]);

  // Enhanced keyboard event handling for shift key and ungrouping
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      // Check if user is typing in an input field
      const target = e.target as HTMLElement;
      const isTyping = target.tagName === 'INPUT' || target.tagName === 'TEXTAREA' || target.isContentEditable;
      
      if (e.key === 'Shift') {
        setIsShiftPressed(true);
      }
      
      // Only handle shortcuts if not typing in an input field
      if (!isTyping) {
        // Handle grouping with 'G' key
        if (e.key === 'g' || e.key === 'G') {
          const regularNodes = selectedNodes.filter(node => node.type !== NODE_TYPES.GROUP);
          if (regularNodes.length > 1) {
            createGroupFromSelectedNodes();
          }
        }
        // Handle ungrouping with 'U' key
        if (e.key === 'u' || e.key === 'U') {
          const hasGroupSelected = selectedNodes.some(node => node.type === NODE_TYPES.GROUP);
          if (hasGroupSelected) {
            ungroupSelectedNodes();
          }
        }
        // Handle removing nodes from group with 'R' key
        if (e.key === 'r' || e.key === 'R') {
          const hasGroupedNodesSelected = selectedNodes.some(node => node.parentId && node.type !== NODE_TYPES.GROUP);
          if (hasGroupedNodesSelected) {
            removeNodesFromGroup();
          }
        }
      }
    };

    const handleKeyUp = (e: KeyboardEvent) => {
      if (e.key === 'Shift') {
        setIsShiftPressed(false);
        // Don't auto-group on shift release - use explicit 'G' key instead
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    window.addEventListener('keyup', handleKeyUp);

    return () => {
      window.removeEventListener('keydown', handleKeyDown);
      window.removeEventListener('keyup', handleKeyUp);
    };
  }, [selectedNodes, createGroupFromSelectedNodes, ungroupSelectedNodes, removeNodesFromGroup]);

  // Track selected nodes and edges
  const handleNodesChange = useCallback((changes: any) => {
    onNodesChange(changes);
    
    // Update selected nodes list
    const currentNodes = getNodes();
    const selected = currentNodes.filter(node => node.selected);
    setSelectedNodes(selected);
  }, [onNodesChange, getNodes]);

  const handleEdgesChange = useCallback((changes: any) => {
    onEdgesChange(changes);
    
    // Update selected edge
    const currentEdges = edges;
    const selectedEdges = currentEdges.filter(edge => edge.selected);
    setSelectedEdge(selectedEdges.length === 1 ? selectedEdges[0] : null);
  }, [onEdgesChange, edges]);

  const onSelectionChange = useCallback(({ nodes, edges }: { nodes: Node[]; edges: Edge[] }) => {
    setSelectedNodes(nodes);
    setSelectedEdge(edges.length === 1 ? edges[0] : null);
  }, []);

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

  const onPaneClick = useCallback(() => {
    // Deselect all nodes and edges when clicking on empty space
    setNodes((nds) => nds.map(node => ({ ...node, selected: false })));
    setEdges((eds) => eds.map(edge => ({ ...edge, selected: false })));
    setSelectedEdge(null);
  }, [setNodes, setEdges]);

  const onReconnectStart = useCallback(() => {
    edgeReconnectSuccessful.current = false;
  }, []);

  const onReconnect = useCallback((oldEdge: Edge, newConnection: Connection) => {
    edgeReconnectSuccessful.current = true;
    setEdges((els) => reconnectEdge(oldEdge, newConnection, els));
  }, [setEdges]);

  const onReconnectEnd = useCallback((event: MouseEvent | TouchEvent, edge: Edge) => {
    // Disabled delete on drop functionality
    // if (!edgeReconnectSuccessful.current) {
    //   setEdges((eds) => eds.filter((e) => e.id !== edge.id));
    // }
    edgeReconnectSuccessful.current = true;
  }, []);


  const createQuickNode = useCallback((nodeType: { category: NodeCategory, label: NodeLabel, text: string }) => {
    const id = getId();
    
    // Calculate center of viewport with small random offset to avoid overlapping
    const viewportCenterX = (-viewportX + window.innerWidth / 2) / zoom;
    const viewportCenterY = (-viewportY + window.innerHeight / 2) / zoom;
    const randomOffsetX = (Math.random() - 0.5) * 100; // ±50px
    const randomOffsetY = (Math.random() - 0.5) * 100; // ±50px
    
    const position = { 
      x: viewportCenterX + randomOffsetX, 
      y: viewportCenterY + randomOffsetY 
    };
    
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
        onContentKeyChange: () => {},
        onContentChange: () => {},
        onPlaceholderChange: () => {},
        onStoreKeyChange: () => {},
        onDataActionsChange: () => {}
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
        case 'dataAction':
          return {
            ...baseData,
            dataActions: [{
              type: 'set' as const,
              key: 'user.property',
              value: ''
            }]
          };
        default:
          return baseData;
      }
    };
    
    const newNode: Node<NodeData> = {
      id,
      position,
      data: getDefaultData(nodeType.category),
      type: NODE_TYPES.EDITABLE,
    };

    setNodes((nds) => nds.concat(newNode));
    setNodeIdCounter((counter) => counter + 1);
  }, [getId, setNodes, viewportX, viewportY, zoom]);

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

  const onContentKeyChange = useCallback((nodeId: string, newContentKey: string) => {
    setNodes((nds) =>
      nds.map((node) => {
        if (node.id === nodeId) {
          return {
            ...node,
            data: {
              ...node.data,
              contentKey: newContentKey,
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

  const onDataActionsChange = useCallback((nodeId: string, newDataActions: DataActionItem[]) => {
    setNodes((nds) =>
      nds.map((node) => {
        if (node.id === nodeId) {
          return {
            ...node,
            data: {
              ...node.data,
              dataActions: newDataActions,
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

  const onEdgeStyleChange = useCallback((edgeId: string, newStyle: 'solid' | 'dashed' | 'dotted') => {
    setEdges((eds) =>
      eds.map((edge) => {
        if (edge.id === edgeId) {
          return {
            ...edge,
            data: {
              ...edge.data,
              style: newStyle,
            },
          };
        }
        return edge;
      })
    );
  }, [setEdges]);

  const onEdgeDelayChange = useCallback((edgeId: string, newDelay: number) => {
    setEdges((eds) =>
      eds.map((edge) => {
        if (edge.id === edgeId) {
          return {
            ...edge,
            data: {
              ...edge.data,
              delay: newDelay,
            },
          };
        }
        return edge;
      })
    );
  }, [setEdges]);

  const onEdgeColorChange = useCallback((edgeId: string, newColor: string) => {
    setEdges((eds) =>
      eds.map((edge) => {
        if (edge.id === edgeId) {
          return {
            ...edge,
            data: {
              ...edge.data,
              color: newColor,
            },
          };
        }
        return edge;
      })
    );
  }, [setEdges]);

  const onEdgeValueChange = useCallback((edgeId: string, newValue: any) => {
    setEdges((eds) =>
      eds.map((edge) => {
        if (edge.id === edgeId) {
          return {
            ...edge,
            data: {
              ...edge.data,
              value: newValue,
            },
          };
        }
        return edge;
      })
    );
  }, [setEdges]);

  const onEdgeContentKeyChange = useCallback((edgeId: string, newContentKey: string) => {
    setEdges((eds) =>
      eds.map((edge) => {
        if (edge.id === edgeId) {
          return {
            ...edge,
            data: {
              ...edge.data,
              contentKey: newContentKey,
            },
          };
        }
        return edge;
      })
    );
  }, [setEdges]);

  const onEdgeReset = useCallback((edgeId: string) => {
    setEdges((eds) =>
      eds.map((edge) => {
        if (edge.id === edgeId) {
          const resetEdge = {
            ...edge,
            data: {
              ...edge.data,
              style: undefined,
              color: undefined,
              // Keep the label and delay - only reset visual styling
            },
          };
          // Update selected edge if it's the one being reset
          if (selectedEdge?.id === edgeId) {
            setSelectedEdge(resetEdge);
          }
          return resetEdge;
        }
        return edge;
      })
    );
  }, [setEdges, selectedEdge]);

  // Update nodes with all callback functions
  const nodesWithCallbacks = nodes.map(node => ({
    ...node,
    data: {
      ...node.data,
      onLabelChange,
      onCategoryChange,
      onNodeLabelChange,
      onNodeIdChange,
      onContentKeyChange,
      onContentChange,
      onPlaceholderChange,
      onStoreKeyChange,
      onDataActionsChange,
      onGroupIdChange,
      onTitleChange,
      onDescriptionChange,
    },
  }));

  // Update edges with callback functions and visual selection
  const edgesWithCallbacks = edges.map(edge => ({
    ...edge,
    selected: selectedEdge?.id === edge.id,
    style: {
      ...edge.style,
      // Make selected edge stand out visually
      strokeWidth: selectedEdge?.id === edge.id ? 4 : 2,
      stroke: selectedEdge?.id === edge.id 
        ? '#ff6b35' // Orange highlight for selected edge
        : edge.data?.color || (edge.data?.label && (edge.data.label.includes('==') || edge.data.label.includes('!=') || edge.data.label.includes('>') || edge.data.label.includes('<')) ? '#ff9800' : '#999'),
      filter: selectedEdge?.id === edge.id ? 'drop-shadow(0 0 6px rgba(255, 107, 53, 0.6))' : 'none',
    },
    data: {
      ...edge.data,
      onLabelChange: (edgeId: string, newLabel: string) => {
        onEdgeLabelChange(edgeId, newLabel);
        // Update selected edge if it's the one being changed
        if (selectedEdge?.id === edgeId) {
          setSelectedEdge(prev => prev ? { ...prev, data: { ...prev.data, label: newLabel } } : null);
        }
      },
      onStyleChange: (edgeId: string, newStyle: 'solid' | 'dashed' | 'dotted') => {
        onEdgeStyleChange(edgeId, newStyle);
        if (selectedEdge?.id === edgeId) {
          setSelectedEdge(prev => prev ? { ...prev, data: { ...prev.data, style: newStyle } } : null);
        }
      },
      onDelayChange: (edgeId: string, newDelay: number) => {
        onEdgeDelayChange(edgeId, newDelay);
        if (selectedEdge?.id === edgeId) {
          setSelectedEdge(prev => prev ? { ...prev, data: { ...prev.data, delay: newDelay } } : null);
        }
      },
      onColorChange: (edgeId: string, newColor: string) => {
        onEdgeColorChange(edgeId, newColor);
        if (selectedEdge?.id === edgeId) {
          setSelectedEdge(prev => prev ? { ...prev, data: { ...prev.data, color: newColor } } : null);
        }
      },
      onValueChange: (edgeId: string, newValue: any) => {
        onEdgeValueChange(edgeId, newValue);
        if (selectedEdge?.id === edgeId) {
          setSelectedEdge(prev => prev ? { ...prev, data: { ...prev.data, value: newValue } } : null);
        }
      },
      onContentKeyChange: (edgeId: string, newContentKey: string) => {
        onEdgeContentKeyChange(edgeId, newContentKey);
        if (selectedEdge?.id === edgeId) {
          setSelectedEdge(prev => prev ? { ...prev, data: { ...prev.data, contentKey: newContentKey } } : null);
        }
      },
      onReset: onEdgeReset,
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
          contentKey: data.contentKey,
          content: data.content,
          placeholderText: data.placeholderText,
          storeKey: data.storeKey,
          dataActions: data.dataActions,
          groupId: data.groupId,
          title: data.title,
          description: data.description
        }
      })),
      edges: edges.map(edge => ({
        id: edge.id,
        source: edge.source,
        target: edge.target,
        type: edge.type || 'default',
        label: edge.data?.label,
        style: edge.data?.style,
        delay: edge.data?.delay,
        color: edge.data?.color,
        value: edge.data?.value,
        contentKey: edge.data?.contentKey
      }))
    };

    const dataStr = JSON.stringify(exportData, null, 2);
    const dataUri = 'data:application/json;charset=utf-8,'+ encodeURIComponent(dataStr);
    
    const exportFileDefaultName = 'sequence-flow.json';
    const linkElement = document.createElement('a');
    linkElement.setAttribute('href', dataUri);
    linkElement.setAttribute('download', exportFileDefaultName);
    linkElement.click();
    showNotification('JSON file exported successfully');
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
          contentKey: data.contentKey,
          content: data.content,
          placeholderText: data.placeholderText,
          storeKey: data.storeKey,
          dataActions: data.dataActions,
          groupId: data.groupId,
          title: data.title,
          description: data.description
        }
      })),
      edges: edges.map(edge => ({
        id: edge.id,
        source: edge.source,
        target: edge.target,
        type: edge.type || 'default',
        label: edge.data?.label,
        style: edge.data?.style,
        delay: edge.data?.delay,
        color: edge.data?.color,
        value: edge.data?.value,
        contentKey: edge.data?.contentKey
      }))
    };
    
    localStorage.setItem('react-flow-data', JSON.stringify(data));
    showNotification('Data saved to browser storage');
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
              // Only add group metadata if this was actually a group node
              ...(node.type === NODE_TYPES.GROUP ? {
                groupId: node.data.groupId || node.data.nodeId,
                title: node.data.title || node.data.label,
                description: node.data.description || 'Imported group',
              } : {}),
              onLabelChange: () => {},
              onCategoryChange: () => {},
              onNodeLabelChange: () => {},
              onNodeIdChange: () => {},
              onContentKeyChange: () => {},
              onContentChange: () => {},
              onPlaceholderChange: () => {},
              onStoreKeyChange: () => {},
              onDataActionsChange: () => {},
              onGroupIdChange: () => {},
              onTitleChange: () => {},
              onDescriptionChange: () => {}
            }
          }));

          // Convert saved edges to the correct format
          const importedEdges = importData.edges.map((edge: any) => ({
            ...edge,
            type: edge.type || 'custom',
            data: { 
              label: edge.label,
              style: edge.style,
              delay: edge.delay,
              color: edge.color,
              value: edge.value,
              contentKey: edge.contentKey,
              onLabelChange: () => {},
              onStyleChange: () => {},
              onDelayChange: () => {},
              onColorChange: () => {},
              onValueChange: () => {},
              onReset: () => {}
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
          showNotification('Data restored from browser storage');
        } else {
          showError('Invalid saved data format', ['Please check the saved data structure']);
        }
      } catch (error) {
        showError('Error restoring saved data', [error instanceof Error ? error.message : 'Unknown error']);
      }
    } else {
      showError('No saved data found', ['Save some data first before trying to restore']);
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
                  // Only add group metadata if this was actually a group node
                  ...(node.type === NODE_TYPES.GROUP ? {
                    groupId: node.data.groupId || node.data.nodeId,
                    title: node.data.title || node.data.label,
                    description: node.data.description || 'Imported group',
                  } : {}),
                  onLabelChange: () => {},
                  onCategoryChange: () => {},
                  onNodeLabelChange: () => {},
                  onNodeIdChange: () => {},
                  onContentKeyChange: () => {},
                  onContentChange: () => {},
                  onPlaceholderChange: () => {},
                  onStoreKeyChange: () => {},
                  onGroupIdChange: () => {},
                  onTitleChange: () => {},
                  onDescriptionChange: () => {}
                }
              }));

              // Convert imported edges to the correct format
              const importedEdges = importData.edges.map((edge: any) => ({
                ...edge,
                type: edge.type || 'custom',
                data: { 
                  label: edge.label,
                  style: edge.style,
                  delay: edge.delay,
                  color: edge.color,
                  value: edge.value,
                  contentKey: edge.contentKey,
                  onLabelChange: () => {},
                  onStyleChange: () => {},
                  onDelayChange: () => {},
                  onColorChange: () => {},
                  onValueChange: () => {},
                  onReset: () => {}
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
              showNotification('JSON file imported successfully');
            } else {
              showError('Invalid JSON format', ['Please ensure the file contains nodes and edges']);
            }
          } catch (error) {
            showError('Error parsing JSON file', [error instanceof Error ? error.message : 'Please check the file format']);
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
    
    // Get node IDs for this group
    const nodeIds = new Set(nodes.map(n => n.id));
    
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
          // Check if any choice edges have parsable values (contain '::')
          const choiceEdges = edges.filter(edge => edge.source === node.id);
          const hasChoiceValues = choiceEdges.some(edge => {
            const label = edge.data?.label || '';
            const hasValueSyntax = label.includes('::');
            if (hasValueSyntax) {
              const [, value] = label.split('::');
              return value && value.trim() !== '';
            }
            return false;
          });
          
          // Only require storeKey if choices have values
          if (hasChoiceValues && !node.data.storeKey?.trim()) {
            errors.push(`Choice node ${node.id} missing storeKey (required when choices have values)`);
          }
          break;
      }
    });
    
    // Validate flow connectivity - find start node (only check internal edges)
    const internalEdges = edges.filter(edge => nodeIds.has(edge.target));
    const hasStartNode = nodes.some(node => 
      !internalEdges.some(edge => edge.target === node.id)
    );
    if (!hasStartNode) errors.push("No start node found (node with no incoming internal edges)");
    
    return {
      isValid: errors.length === 0,
      errors
    };
  }, []);

  const findStartNode = useCallback((nodes: Node<NodeData>[], edges: Edge[]) => {
    const nodeIds = new Set(nodes.map(n => n.id));
    const internalEdges = edges.filter(edge => nodeIds.has(edge.target));
    return nodes.find(node => 
      !internalEdges.some(edge => edge.target === node.id)
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
      
      // Visit connected nodes in order (only within the same group)
      edges
        .filter(edge => edge.source === nodeId)
        .filter(edge => nodes.some(n => n.id === edge.target)) // Only visit targets that exist in this group
        .sort((a, b) => a.target.localeCompare(b.target)) // Ensure consistent ordering
        .forEach(edge => visit(edge.target));
    };
    
    visit(startNode.id);
    return result;
  }, [findStartNode]);

  const getNextMessageId = useCallback((nodeId: string, edges: Edge[], groupNodes?: Node<NodeData>[]) => {
    const edge = edges.find(e => e.source === nodeId);
    if (!edge) return null;
    
    // Check if this is cross-sequence navigation
    const sourceNode = nodes.find(n => n.id === nodeId);
    const targetNode = nodes.find(n => n.id === edge.target);
    
    if (sourceNode && targetNode && groupNodes) {
      const sourceGroupId = sourceNode.parentId;
      const targetGroupId = targetNode.parentId;
      
      // If target is in a different group, return an object with sequence info
      if (sourceGroupId !== targetGroupId) {
        if (targetGroupId) {
          const targetGroup = groupNodes.find(g => g.id === targetGroupId);
          if (targetGroup && targetGroup.data.groupId) {
            return {
              sequenceId: targetGroup.data.groupId,
              messageId: parseInt(targetNode.data.nodeId || targetNode.id)
            };
          }
        } else {
          // Target is ungrouped
          return {
            sequenceId: 'main',
            messageId: parseInt(targetNode.data.nodeId || targetNode.id)
          };
        }
      }
    }
    
    // FIX: Use target node's editable nodeId instead of internal React Flow ID
    return parseInt(targetNode?.data.nodeId || edge.target);
  }, [nodes]);

  const extractChoicesFromEdges = useCallback((nodeId: string, edges: Edge[], groupNodes?: Node<NodeData>[], allNodes?: Node<NodeData>[]) => {
    return edges
      .filter(edge => edge.source === nodeId)
      .map(edge => {
        const label = edge.data?.label || '';
        // Use label as text, but remove any legacy :: parsing
        const text = label.includes('::') ? label.split('::')[0].trim() : label.trim();
        
        const choice: any = { text: text || 'Choice option' };
        
        // Add contentKey if available
        if (edge.data?.contentKey) {
          choice.contentKey = edge.data.contentKey;
        }
        
        // Use dedicated value field if available, otherwise fallback to legacy parsing for backward compatibility
        if (edge.data && edge.data.value !== undefined) {
          choice.value = edge.data.value;
        } else if (label.includes('::')) {
          // Legacy fallback - parse from label for backward compatibility
          const legacyValue = label.split('::')[1];
          if (legacyValue && legacyValue.trim()) {
            const trimmedValue = legacyValue.trim();
            // Parse value types
            if (trimmedValue === 'true') choice.value = true;
            else if (trimmedValue === 'false') choice.value = false;
            else if (trimmedValue === 'null') choice.value = null;
            else if (!isNaN(Number(trimmedValue))) choice.value = Number(trimmedValue);
            else choice.value = trimmedValue;
          }
        }
        
        // Only use inferred cross-sequence navigation (no explicit @sequence syntax)
        {
          // Check if target is in a different group (auto-detect cross-sequence navigation)
          const nodesToSearch = allNodes || nodes;
          const targetNode = nodesToSearch.find(n => n.id === edge.target);
          const sourceNode = nodesToSearch.find(n => n.id === nodeId);
          
          if (targetNode && sourceNode) {
            const sourceGroupId = sourceNode.parentId;
            const targetGroupId = targetNode.parentId;
            
            // If target is in a different group or ungrouped, set up cross-sequence navigation
            if (sourceGroupId !== targetGroupId) {
              if (targetGroupId && groupNodes) {
                // Target is in another group - find the group's sequenceId
                const targetGroup = groupNodes.find(g => g.id === targetGroupId);
                if (targetGroup && targetGroup.data.groupId) {
                  choice.sequenceId = targetGroup.data.groupId;
                  // Note: Delay will be applied to target sequence's first message during export
                  // Don't set nextMessageId when sequenceId is present - Flutter app assumes first node
                }
              } else {
                // Target is ungrouped - use a special marker for main sequence
                choice.sequenceId = 'main';
                // Note: Delay will be applied to target sequence's first message during export
                // Don't set nextMessageId when sequenceId is present - Flutter app assumes first node
              }
            } else {
              // Same group - normal internal navigation
              // FIX: Use target node's editable nodeId instead of internal React Flow ID
              choice.nextMessageId = parseInt(targetNode.data.nodeId || edge.target);
            }
          } else {
            // Fallback to original behavior
            // FIX: Use target node's editable nodeId instead of internal React Flow ID
            choice.nextMessageId = parseInt(targetNode?.data.nodeId || edge.target);
          }
        }
        
        return choice;
      });
  }, [nodes]);

  const extractRoutesFromEdges = useCallback((nodeId: string, edges: Edge[], groupNodes?: Node<NodeData>[], allNodes?: Node<NodeData>[]) => {
    return edges
      .filter(edge => edge.source === nodeId)
      .map(edge => {
        const label = edge.data?.label || '';
        const isDefault = label.toLowerCase() === 'default' || !label.trim();
        
        // Check if target is in a different group (cross-sequence navigation)
        const nodesToSearch = allNodes || nodes;
        const targetNode = nodesToSearch.find(n => n.id === edge.target);
        const sourceNode = nodesToSearch.find(n => n.id === nodeId);
        
        let route: any = isDefault 
          ? { default: true }
          : { condition: label };
        
        // Only use inferred cross-sequence navigation (no explicit @sequence syntax)
        {
          // Auto-detect cross-sequence navigation based on group membership
          if (targetNode && sourceNode) {
            const sourceGroupId = sourceNode.parentId;
            const targetGroupId = targetNode.parentId;
            
            // If target is in a different group or ungrouped, set up cross-sequence navigation
            if (sourceGroupId !== targetGroupId) {
              if (targetGroupId && groupNodes) {
                // Target is in another group - find the group's sequenceId
                const targetGroup = groupNodes.find(g => g.id === targetGroupId);
                if (targetGroup && targetGroup.data.groupId) {
                  route.sequenceId = targetGroup.data.groupId;
                  // Note: Delay will be applied to target sequence's first message during export
                  // Don't set nextMessageId when sequenceId is present - Flutter app assumes first node
                }
              } else {
                // Target is ungrouped - use a special marker for main sequence
                route.sequenceId = 'main';
                // Note: Delay will be applied to target sequence's first message during export
                // Don't set nextMessageId when sequenceId is present - Flutter app assumes first node
              }
            } else {
              // Same group - normal internal navigation
              // FIX: Use target node's editable nodeId instead of internal React Flow ID
              route.nextMessageId = parseInt(targetNode.data.nodeId || edge.target);
            }
          } else {
            // Fallback to original behavior
            // FIX: Use target node's editable nodeId instead of internal React Flow ID
            route.nextMessageId = parseInt(targetNode?.data.nodeId || edge.target);
          }
        }
        
        return route;
      });
  }, [nodes]);

  const convertNodesToMessages = useCallback((sortedNodes: Node<NodeData>[], edges: Edge[], groupNodes?: Node<NodeData>[], allNodes?: Node<NodeData>[]) => {
    // Create a map of edge delays by target node
    const edgeDelayMap: { [nodeId: string]: number } = {};
    edges.forEach(edge => {
      if (edge.data?.delay && edge.data.delay > 0) {
        edgeDelayMap[edge.target] = edge.data.delay;
      }
    });

    return sortedNodes.map(node => {
      const message: any = {
        id: parseInt(node.data.nodeId || node.id)
      };
      
      // Only add type if it's not the default 'bot' type
      if (node.data.category !== 'bot') {
        message.type = node.data.category;
      }
      
      // Add contentKey if provided
      if (node.data.contentKey) {
        message.contentKey = node.data.contentKey;
      }
      
      // Add delay from incoming edge (if any)
      if (edgeDelayMap[node.id]) {
        message.delay = edgeDelayMap[node.id];
      }
      
      switch (node.data.category) {
        case 'bot':
          if (node.data.content) {
            message.text = node.data.content;
          }
          const nextId = getNextMessageId(node.id, edges, groupNodes);
          if (nextId) {
            if (typeof nextId === 'object') {
              // Cross-sequence navigation - don't set nextMessageId, Flutter app assumes first node
              message.sequenceId = nextId.sequenceId;
            } else {
              // Same sequence navigation
              message.nextMessageId = nextId;
            }
          }
          break;
          
        case 'textInput':
          if (node.data.storeKey) {
            message.storeKey = node.data.storeKey;
          }
          if (node.data.placeholderText) {
            message.placeholderText = node.data.placeholderText;
          }
          const nextTextId = getNextMessageId(node.id, edges, groupNodes);
          if (nextTextId) {
            if (typeof nextTextId === 'object') {
              // Cross-sequence navigation - don't set nextMessageId, Flutter app assumes first node
              message.sequenceId = nextTextId.sequenceId;
            } else {
              // Same sequence navigation
              message.nextMessageId = nextTextId;
            }
          }
          break;
          
        case 'choice':
          if (node.data.storeKey) {
            message.storeKey = node.data.storeKey;
          }
          const choices = extractChoicesFromEdges(node.id, edges, groupNodes, allNodes);
          if (choices.length > 0) {
            message.choices = choices;
          }
          break;
          
        case 'autoroute':
          const routes = extractRoutesFromEdges(node.id, edges, groupNodes, allNodes);
          if (routes.length > 0) {
            message.routes = routes;
          }
          break;
          
        case 'user':
          if (node.data.content) {
            message.text = node.data.content;
          }
          const nextUserId = getNextMessageId(node.id, edges, groupNodes);
          if (nextUserId) {
            if (typeof nextUserId === 'object') {
              // Cross-sequence navigation - don't set nextMessageId, Flutter app assumes first node
              message.sequenceId = nextUserId.sequenceId;
            } else {
              // Same sequence navigation
              message.nextMessageId = nextUserId;
            }
          }
          break;
          
        case 'dataAction':
          if (node.data.dataActions && node.data.dataActions.length > 0) {
            message.dataActions = node.data.dataActions.map(action => ({
              type: action.type,
              key: action.key,
              ...(action.value !== undefined && { value: action.value }),
              ...(action.event && { event: action.event }),
              ...(action.data && { data: action.data })
            }));
          }
          const nextDataActionId = getNextMessageId(node.id, edges, groupNodes);
          if (nextDataActionId) {
            if (typeof nextDataActionId === 'object') {
              // Cross-sequence navigation - don't set nextMessageId, Flutter app assumes first node
              message.sequenceId = nextDataActionId.sequenceId;
            } else {
              // Same sequence navigation
              message.nextMessageId = nextDataActionId;
            }
          }
          break;
      }
      
      return message;
    });
  }, [getNextMessageId, extractChoicesFromEdges, extractRoutesFromEdges]);

  const exportToFlutter = useCallback(() => {
    try {
      // Find all group nodes
      const groupNodes = nodes.filter(node => node.type === NODE_TYPES.GROUP);
      
      if (groupNodes.length === 0) {
        showError('No groups found', ['Create groups by selecting multiple nodes with Shift+click first']);
        return;
      }

      // Filter out ungrouped nodes (nodes without parentId)
      const groupedNodes = nodes.filter(node => 
        node.parentId || node.type === NODE_TYPES.GROUP
      );

      if (groupedNodes.length === 0) {
        showError('No grouped nodes found', ['Add nodes to groups before exporting']);
        return;
      }

      // Collect cross-sequence delays that need to be applied to target sequences
      const crossSequenceDelays: { [sequenceId: string]: number } = {};
      
      // Scan all edges for cross-sequence navigation with delays
      edges.forEach(edge => {
        if (edge.data?.delay && edge.data.delay > 0) {
          const sourceNode = nodes.find(n => n.id === edge.source);
          const targetNode = nodes.find(n => n.id === edge.target);
          
          if (sourceNode && targetNode && sourceNode.parentId !== targetNode.parentId) {
            // This is cross-sequence navigation with delay
            const targetGroup = groupNodes.find(g => g.id === targetNode.parentId);
            if (targetGroup && targetGroup.data.groupId) {
              const targetSequenceId = targetGroup.data.groupId;
              // Store the maximum delay for this sequence (in case multiple edges point to it)
              crossSequenceDelays[targetSequenceId] = Math.max(
                crossSequenceDelays[targetSequenceId] || 0,
                edge.data.delay
              );
            }
          }
        }
      });

      const exportedSequences: any[] = [];

      // Process each group
      groupNodes.forEach(groupNode => {
        // Get nodes that belong to this group
        const groupChildren = nodes.filter(node => node.parentId === groupNode.id);
        
        if (groupChildren.length === 0) {
          showError(`Group ${groupNode.id} has no children`, ['Add nodes to the group before exporting']);
          return;
        }

        // Get edges that originate from nodes in this group (including cross-sequence edges)
        const groupChildrenIds = new Set(groupChildren.map(n => n.id));
        const groupEdges = edges.filter(edge => 
          groupChildrenIds.has(edge.source)
        );

        // Validate this group's flow
        const validation = validateFlowForExport(groupChildren, groupEdges);
        if (!validation.isValid) {
          showError(`Group ${groupNode.id} validation failed`, validation.errors);
          return;
        }

        // Sort nodes in this group topologically
        const sortedGroupNodes = sortNodesTopologically(groupChildren, groupEdges);
        if (sortedGroupNodes.length === 0) {
          showError(`Group ${groupNode.id} could not be sorted topologically`, ['Check for circular dependencies in the flow']);
          return;
        }

        // Convert to Flutter format (pass all nodes for cross-sequence navigation detection)
        const messages = convertNodesToMessages(sortedGroupNodes, groupEdges, groupNodes, nodes);
        
        // Use group metadata or fallback values
        const sequenceId = groupNode.data.groupId || `group_${groupNode.id}`;
        const name = groupNode.data.title || `Group ${groupNode.id}`;
        const description = groupNode.data.description || `Sequence exported from group ${groupNode.id}`;

        // Apply cross-sequence delay to the first message if this sequence is a target
        if (crossSequenceDelays[sequenceId] && messages.length > 0) {
          messages[0] = {
            ...messages[0],
            delay: crossSequenceDelays[sequenceId]
          };
        }

        const flutterSequence = {
          sequenceId,
          name,
          description,
          messages
        };

        exportedSequences.push(flutterSequence);
      });

      if (exportedSequences.length === 0) {
        showError('No valid groups could be exported', [
          'Make sure groups have connected nodes with proper flow',
          'Check validation errors in console for details'
        ]);
        return;
      }

      // Export each sequence as a separate file with delays to prevent browser throttling
      for (let i = 0; i < exportedSequences.length; i++) {
        const sequence = exportedSequences[i];
        
        setTimeout(() => {
          const dataStr = JSON.stringify(sequence, null, 2);
          const dataUri = 'data:application/json;charset=utf-8,' + encodeURIComponent(dataStr);
          
          const exportFileDefaultName = `${sequence.sequenceId}.json`;
          const linkElement = document.createElement('a');
          linkElement.setAttribute('href', dataUri);
          linkElement.setAttribute('download', exportFileDefaultName);
          linkElement.click();
          
          // Show progress notification for each file
          if (i === exportedSequences.length - 1) {
            // Final notification when all downloads are triggered
            setTimeout(() => {
              showNotification(`All ${exportedSequences.length} sequence${exportedSequences.length === 1 ? '' : 's'} exported to Flutter`);
            }, 100);
          }
        }, i * 500); // 500ms delay between downloads
      }

      // Show initial notification immediately
      showNotification(`Exporting ${exportedSequences.length} sequence${exportedSequences.length === 1 ? '' : 's'} to Flutter...`);
      
    } catch (error) {
      console.error('Export error:', error);
      showError('Export failed', [error instanceof Error ? error.message : 'Unknown error']);
    }
  }, [nodes, edges, validateFlowForExport, sortNodesTopologically, convertNodesToMessages, showError, showNotification]);

  const nodeTemplates = [
    { category: 'bot' as NodeCategory, label: 'Welcome Message' as NodeLabel, text: 'Welcome!', icon: '💬', description: 'Bot message' },
    { category: 'user' as NodeCategory, label: 'Response' as NodeLabel, text: 'User response', icon: '👤', description: 'User message' },
    { category: 'choice' as NodeCategory, label: 'Choice Menu' as NodeLabel, text: 'Select option:', icon: '🔘', description: 'Choice buttons' },
    { category: 'textInput' as NodeCategory, label: 'Text Input' as NodeLabel, text: 'Enter text:', icon: '⌨️', description: 'Text input' },
    { category: 'autoroute' as NodeCategory, label: 'Conditional Route' as NodeLabel, text: 'Route condition', icon: '🔀', description: 'Auto-route' },
    { category: 'dataAction' as NodeCategory, label: 'Data Action' as NodeLabel, text: 'Data action', icon: '⚙️', description: 'Data action' },
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
          🔗 Hold Shift + Select multiple nodes, then Press 'G' to group<br/>
          🔓 Select group node + Press 'U' to ungroup<br/>
          ➖ Select grouped nodes + Press 'R' to remove from group<br/>
          ➕ Select ungrouped nodes + Use dropdown to add to group<br/>
          🎨 Click edges to open style panel for color, delay, and styling options
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
          🔗 Subflow Mode: Select multiple nodes ({selectedNodes.length} selected) - Press 'G' to group
        </div>
      )}
      
      {/* Group Creation Status Indicator */}
      {!isShiftPressed && selectedNodes.filter(node => node.type !== 'group').length > 1 && (
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
          🔗 Press 'G' to group selected nodes ({selectedNodes.filter(node => node.type !== 'group').length} selected)
        </div>
      )}
      
      {/* Ungroup Status Indicator */}
      {!isShiftPressed && selectedNodes.some(node => node.type === NODE_TYPES.GROUP) && (
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
          🔓 Press 'U' to ungroup selected group ({selectedNodes.filter(node => node.type === NODE_TYPES.GROUP).length} group{selectedNodes.filter(node => node.type === NODE_TYPES.GROUP).length > 1 ? 's' : ''})
        </div>
      )}

      {/* Remove from Group Status Indicator */}
      {!isShiftPressed && selectedNodes.some(node => node.parentId && node.type !== 'group') && (
        <div style={{
          position: 'absolute',
          top: 90,
          left: '50%',
          transform: 'translateX(-50%)',
          zIndex: 1000,
          padding: '8px 16px',
          background: 'rgba(156, 39, 176, 0.9)',
          color: 'white',
          borderRadius: '20px',
          fontSize: '12px',
          fontWeight: 'bold',
          boxShadow: '0 2px 8px rgba(0,0,0,0.2)'
        }}>
          ➖ Press 'R' to remove from group ({selectedNodes.filter(node => node.parentId && node.type !== 'group').length} node{selectedNodes.filter(node => node.parentId && node.type !== 'group').length > 1 ? 's' : ''})
        </div>
      )}

      {/* Add to Group Status Indicator */}
      {!isShiftPressed && selectedNodes.some(node => node.type !== NODE_TYPES.GROUP && !node.parentId) && nodes.some(node => node.type === NODE_TYPES.GROUP) && (
        <div style={{
          position: 'absolute',
          top: 130,
          left: '50%',
          transform: 'translateX(-50%)',
          zIndex: 1000,
          padding: '8px 16px',
          background: 'rgba(33, 150, 243, 0.9)',
          color: 'white',
          borderRadius: '20px',
          fontSize: '12px',
          fontWeight: 'bold',
          boxShadow: '0 2px 8px rgba(0,0,0,0.2)'
        }}>
          ➕ Use dropdown to add to group ({selectedNodes.filter(node => node.type !== 'group' && !node.parentId).length} node{selectedNodes.filter(node => node.type !== 'group' && !node.parentId).length > 1 ? 's' : ''})
        </div>
      )}

      {/* Controls Panel */}
      <div style={{
        position: 'absolute',
        top: 10,
        right: 10,
        zIndex: 1000,
        display: 'flex',
        flexDirection: 'column',
        gap: '12px',
        maxWidth: '200px'
      }}>
        

        {/* File Operations */}
        <div style={{
          display: 'flex',
          flexDirection: 'column',
          gap: '6px',
          padding: '10px',
          backgroundColor: 'rgba(255, 255, 255, 0.95)',
          borderRadius: '8px',
          boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
          border: '1px solid #e0e0e0'
        }}>
          <div style={{
            fontSize: '11px',
            fontWeight: 'bold',
            color: '#666',
            textAlign: 'center',
            marginBottom: '4px',
            borderBottom: '1px solid #ddd',
            paddingBottom: '4px'
          }}>
            💾 FILES
          </div>
          
          <button 
            onClick={saveData}
            style={{
              padding: '6px 12px',
              backgroundColor: '#ff9800',
              color: 'white',
              border: 'none',
              borderRadius: '4px',
              cursor: 'pointer',
              fontWeight: 'bold',
              fontSize: '11px'
            }}
          >
            💾 Save
          </button>
          
          <button 
            onClick={restoreData}
            style={{
              padding: '6px 12px',
              backgroundColor: '#673ab7',
              color: 'white',
              border: 'none',
              borderRadius: '4px',
              cursor: 'pointer',
              fontWeight: 'bold',
              fontSize: '11px'
            }}
          >
            📂 Restore
          </button>
          
          <button 
            onClick={exportToJSON}
            style={{
              padding: '6px 12px',
              backgroundColor: '#1976d2',
              color: 'white',
              border: 'none',
              borderRadius: '4px',
              cursor: 'pointer',
              fontWeight: 'bold',
              fontSize: '11px'
            }}
          >
            📄 Export JSON
          </button>
          
          <button 
            onClick={importFromJSON}
            style={{
              padding: '6px 12px',
              backgroundColor: '#4caf50',
              color: 'white',
              border: 'none',
              borderRadius: '4px',
              cursor: 'pointer',
              fontWeight: 'bold',
              fontSize: '11px'
            }}
          >
            📥 Import JSON
          </button>
        </div>

        {/* Export & Tools */}
        <div style={{
          display: 'flex',
          flexDirection: 'column',
          gap: '6px',
          padding: '10px',
          backgroundColor: 'rgba(255, 255, 255, 0.95)',
          borderRadius: '8px',
          boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
          border: '1px solid #e0e0e0'
        }}>
          <div style={{
            fontSize: '11px',
            fontWeight: 'bold',
            color: '#666',
            textAlign: 'center',
            marginBottom: '4px',
            borderBottom: '1px solid #ddd',
            paddingBottom: '4px'
          }}>
            🛠️ TOOLS
          </div>
          
          <button 
            onClick={exportToFlutter}
            style={{
              padding: '6px 12px',
              backgroundColor: '#e91e63',
              color: 'white',
              border: 'none',
              borderRadius: '4px',
              cursor: 'pointer',
              fontWeight: 'bold',
              fontSize: '11px'
            }}
          >
            🚀 Export Flutter
          </button>
          
          <button 
            onClick={() => setShowVariableManager(true)}
            style={{
              padding: '6px 12px',
              backgroundColor: '#607d8b',
              color: 'white',
              border: 'none',
              borderRadius: '4px',
              cursor: 'pointer',
              fontWeight: 'bold',
              fontSize: '11px'
            }}
          >
            🗂️ Variables
          </button>
        </div>

        {/* Group Management */}
        <div style={{
          display: 'flex',
          flexDirection: 'column',
          gap: '4px',
          padding: '8px',
          backgroundColor: 'rgba(255, 255, 255, 0.95)',
          borderRadius: '6px',
          boxShadow: '0 2px 6px rgba(0,0,0,0.1)',
          border: '1px solid #e0e0e0'
        }}>
          <div style={{
            fontSize: '10px',
            fontWeight: 'bold',
            color: '#666',
            textAlign: 'center',
            marginBottom: '2px',
            borderBottom: '1px solid #ddd',
            paddingBottom: '2px'
          }}>
            📦 GROUPS
          </div>
          
          <button 
            onClick={createGroupFromSelectedNodes}
            disabled={selectedNodes.filter(node => node.type !== NODE_TYPES.GROUP).length < 2}
            style={{
              padding: '6px 12px',
              backgroundColor: selectedNodes.filter(node => node.type !== NODE_TYPES.GROUP).length >= 2 ? '#4caf50' : '#ccc',
              color: 'white',
              border: 'none',
              borderRadius: '4px',
              cursor: selectedNodes.filter(node => node.type !== NODE_TYPES.GROUP).length >= 2 ? 'pointer' : 'not-allowed',
              fontWeight: 'bold',
              opacity: selectedNodes.filter(node => node.type !== NODE_TYPES.GROUP).length >= 2 ? 1 : 0.5,
              fontSize: '11px'
            }}
          >
            🔗 Group
          </button>
          
          <button 
            onClick={ungroupSelectedNodes}
            disabled={!selectedNodes.some(node => node.type === NODE_TYPES.GROUP)}
            style={{
              padding: '6px 12px',
              backgroundColor: selectedNodes.some(node => node.type === NODE_TYPES.GROUP) ? '#ff9800' : '#ccc',
              color: 'white',
              border: 'none',
              borderRadius: '4px',
              cursor: selectedNodes.some(node => node.type === NODE_TYPES.GROUP) ? 'pointer' : 'not-allowed',
              fontWeight: 'bold',
              opacity: selectedNodes.some(node => node.type === NODE_TYPES.GROUP) ? 1 : 0.5,
              fontSize: '11px'
            }}
          >
            🔓 Ungroup
          </button>
          
          <button 
            onClick={removeNodesFromGroup}
            disabled={!selectedNodes.some(node => node.parentId && node.type !== NODE_TYPES.GROUP)}
            style={{
              padding: '6px 12px',
              backgroundColor: selectedNodes.some(node => node.parentId && node.type !== NODE_TYPES.GROUP) ? '#9c27b0' : '#ccc',
              color: 'white',
              border: 'none',
              borderRadius: '4px',
              cursor: selectedNodes.some(node => node.parentId && node.type !== NODE_TYPES.GROUP) ? 'pointer' : 'not-allowed',
              fontWeight: 'bold',
              opacity: selectedNodes.some(node => node.parentId && node.type !== NODE_TYPES.GROUP) ? 1 : 0.5,
              fontSize: '11px'
            }}
          >
            ➖ Remove
          </button>
          
          <button 
            onClick={resizeAllGroups}
            style={{
              padding: '6px 12px',
              backgroundColor: '#673ab7',
              color: 'white',
              border: 'none',
              borderRadius: '4px',
              cursor: 'pointer',
              fontWeight: 'bold',
              fontSize: '11px'
            }}
          >
            📏 Resize
          </button>
          
          {/* Add to Group dropdown - only show when ungrouped nodes are selected */}
          {selectedNodes.some(node => node.type !== NODE_TYPES.GROUP && !node.parentId) && (
            <select 
              onChange={(e) => {
                if (e.target.value) {
                  addNodesToGroup(e.target.value);
                  e.target.value = ''; // Reset selection
                }
              }}
              style={{
                padding: '6px 12px',
                backgroundColor: '#2196f3',
                color: 'white',
                border: 'none',
                borderRadius: '4px',
                cursor: 'pointer',
                fontWeight: 'bold',
                fontSize: '11px'
              }}
              defaultValue=""
            >
              <option value="" disabled>➕ Add to Group</option>
              {nodes.filter(node => node.type === NODE_TYPES.GROUP).map(group => (
                <option key={group.id} value={group.id}>
                  {group.data.title || group.data.label || `Group ${group.id}`}
                </option>
              ))}
            </select>
          )}
        </div>

      </div>
      
      <ReactFlow
        nodes={nodesWithCallbacks}
        edges={edgesWithCallbacks}
        onNodesChange={handleNodesChange}
        onEdgesChange={handleEdgesChange}
        onSelectionChange={onSelectionChange}
        onConnect={onConnect}
        onReconnect={onReconnect}
        onReconnectStart={onReconnectStart}
        onReconnectEnd={onReconnectEnd}
        onPaneClick={onPaneClick}
        nodeTypes={nodeTypes}
        edgeTypes={edgeTypes}
        fitView
        connectionLineType={ConnectionLineType.Bezier}
        connectionRadius={30}
        multiSelectionKeyCode="Shift"
        defaultEdgeOptions={{ zIndex: 1001 }}
        elementsSelectable={true}
      >
        <Controls 
          showZoom={true}
          showFitView={true}
          showInteractive={true}
          fitViewOptions={{ 
            padding: 0.1,
            minZoom: 0.0005,
            maxZoom: 4
          }}
        />
        <Background />
      </ReactFlow>
      
      {/* Success Notification */}
      {notification && (
        <div style={{
          position: 'fixed',
          top: '20px',
          right: '20px',
          backgroundColor: '#4caf50',
          color: 'white',
          padding: '12px 20px',
          borderRadius: '6px',
          boxShadow: '0 4px 12px rgba(0,0,0,0.15)',
          zIndex: 2000,
          fontSize: '14px',
          fontWeight: '500',
          animation: 'slideIn 0.3s ease-out'
        }}>
          ✓ {notification}
        </div>
      )}

      {/* Error Notification */}
      {errorMessage && (
        <div style={{
          position: 'fixed',
          top: '20px',
          left: '50%',
          transform: 'translateX(-50%)',
          backgroundColor: '#f44336',
          color: 'white',
          padding: '16px 24px',
          borderRadius: '8px',
          boxShadow: '0 6px 16px rgba(0,0,0,0.2)',
          zIndex: 2001,
          fontSize: '14px',
          fontWeight: '500',
          maxWidth: '600px',
          whiteSpace: 'pre-line',
          border: '2px solid #d32f2f',
          animation: 'slideInCenter 0.3s ease-out'
        }}>
          <div style={{ display: 'flex', alignItems: 'flex-start', gap: '8px' }}>
            <span style={{ fontSize: '18px', flexShrink: 0 }}>⚠️</span>
            <div>{errorMessage}</div>
          </div>
        </div>
      )}

      {/* Edge Properties Side Panel */}
      {selectedEdge && (
        <div style={{
          position: 'fixed',
          top: 0,
          right: 0,
          width: '300px',
          height: '100vh',
          backgroundColor: 'white',
          borderLeft: '1px solid #ddd',
          boxShadow: '-2px 0 8px rgba(0,0,0,0.1)',
          zIndex: 1500,
          padding: '20px',
          overflowY: 'auto',
          animation: 'slideInFromRight 0.3s ease-out'
        }}>
          <div style={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            marginBottom: '20px',
            paddingBottom: '10px',
            borderBottom: '2px solid #f0f0f0'
          }}>
            <h3 style={{ margin: 0, color: '#333', fontSize: '18px' }}>🎨 Edge Properties</h3>
            <button
              onClick={() => setSelectedEdge(null)}
              style={{
                background: 'none',
                border: 'none',
                fontSize: '20px',
                cursor: 'pointer',
                color: '#666',
                padding: '4px'
              }}
            >
              ✕
            </button>
          </div>

          {/* Edge Info */}
          <div style={{ marginBottom: '20px', padding: '12px', backgroundColor: '#f8f9fa', borderRadius: '6px' }}>
            <div style={{ fontSize: '12px', color: '#666', marginBottom: '4px' }}>Edge ID</div>
            <div style={{ fontSize: '14px', fontFamily: 'monospace', color: '#333' }}>{selectedEdge.id}</div>
          </div>

          {/* Data Properties Header */}
          <div style={{ marginBottom: '16px' }}>
            <h3 style={{ fontSize: '16px', fontWeight: 'bold', color: '#333', margin: '0 0 12px 0', borderBottom: '2px solid #e3f2fd', paddingBottom: '8px' }}>
              📊 Data Properties
            </h3>
          </div>

          {/* Label Section */}
          <div style={{ marginBottom: '20px' }}>
            <label style={{ display: 'block', fontSize: '14px', fontWeight: 'bold', marginBottom: '8px', color: '#333' }}>
              📝 Label
            </label>
            <input
              type="text"
              value={selectedEdge.data?.label || ''}
              onChange={(e) => {
                const newLabel = e.target.value;
                onEdgeLabelChange(selectedEdge.id, newLabel);
                setSelectedEdge(prev => prev ? { ...prev, data: { ...prev.data, label: newLabel } } : null);
              }}
              placeholder="condition | choice text"
              style={{
                width: '100%',
                padding: '8px 12px',
                border: '1px solid #ddd',
                borderRadius: '4px',
                fontSize: '14px'
              }}
            />
            <div style={{ fontSize: '11px', color: '#666', marginTop: '4px' }}>
              Format: condition for routes, choice text for choices
            </div>
          </div>

          {/* Value Section */}
          <div style={{ marginBottom: '20px' }}>
            <label style={{ display: 'block', fontSize: '14px', fontWeight: 'bold', marginBottom: '8px', color: '#333' }}>
              🏷️ Choice Value
            </label>
            <input
              type="text"
              value={selectedEdge.data?.value !== undefined ? String(selectedEdge.data.value) : ''}
              onChange={(e) => {
                let newValue: any = e.target.value;
                
                // Parse value types similar to the current parsing
                if (newValue === '') {
                  newValue = undefined;
                } else if (newValue === 'true') {
                  newValue = true;
                } else if (newValue === 'false') {
                  newValue = false;
                } else if (newValue === 'null') {
                  newValue = null;
                } else if (!isNaN(Number(newValue)) && newValue.trim() !== '') {
                  newValue = Number(newValue);
                }
                // newValue is already a string at this point
                
                onEdgeValueChange(selectedEdge.id, newValue);
                setSelectedEdge(prev => prev ? { ...prev, data: { ...prev.data, value: newValue } } : null);
              }}
              placeholder="Enter value (text, number, true, false, null)"
              style={{
                width: '100%',
                padding: '8px 12px',
                border: '1px solid #ddd',
                borderRadius: '4px',
                fontSize: '14px'
              }}
            />
            <div style={{ fontSize: '11px', color: '#666', marginTop: '4px' }}>
              Value stored when this choice is selected (optional)
            </div>
          </div>

          {/* Content Key Section */}
          <div style={{ marginBottom: '20px' }}>
            <label style={{ display: 'block', fontSize: '14px', fontWeight: 'bold', marginBottom: '8px', color: '#333' }}>
              🔑 Content Key
              <HelpTooltip content={helpContent.edgeContentKey} />
            </label>
            <input
              type="text"
              value={selectedEdge.data?.contentKey || ''}
              onChange={(e) => {
                const newContentKey = e.target.value;
                onEdgeContentKeyChange(selectedEdge.id, newContentKey);
                setSelectedEdge(prev => prev ? { ...prev, data: { ...prev.data, contentKey: newContentKey } } : null);
              }}
              placeholder="e.g., main_menu_option, difficulty_choice..."
              style={{
                width: '100%',
                padding: '8px 12px',
                border: '1px solid #ddd',
                borderRadius: '4px',
                fontSize: '14px'
              }}
            />
            <div style={{ fontSize: '11px', color: '#666', marginTop: '4px' }}>
              Semantic identifier for this choice/condition (optional)
            </div>
          </div>

          {/* Delay Section */}
          <div style={{ marginBottom: '20px' }}>
            <label style={{ display: 'block', fontSize: '14px', fontWeight: 'bold', marginBottom: '8px', color: '#333' }}>
              ⏱️ Delay (ms)
            </label>
            <input
              type="number"
              value={selectedEdge.data?.delay || 0}
              onChange={(e) => {
                const newDelay = parseInt(e.target.value) || 0;
                onEdgeDelayChange(selectedEdge.id, newDelay);
                setSelectedEdge(prev => prev ? { ...prev, data: { ...prev.data, delay: newDelay } } : null);
              }}
              min="0"
              step="100"
              style={{
                width: '100%',
                padding: '8px 12px',
                border: '1px solid #ddd',
                borderRadius: '4px',
                fontSize: '14px'
              }}
            />
            <div style={{ fontSize: '11px', color: '#666', marginTop: '4px' }}>
              Delay before showing next message
            </div>
          </div>

          {/* Style Properties Header */}
          <div style={{ marginTop: '32px', marginBottom: '16px', paddingTop: '24px', borderTop: '1px solid #ddd' }}>
            <h3 style={{ fontSize: '16px', fontWeight: 'bold', color: '#333', margin: '0 0 12px 0', borderBottom: '2px solid #fff3e0', paddingBottom: '8px' }}>
              🎨 Style Properties
            </h3>
          </div>

          {/* Style Section */}
          <div style={{ marginBottom: '20px' }}>
            <label style={{ display: 'block', fontSize: '14px', fontWeight: 'bold', marginBottom: '8px', color: '#333' }}>
              ✏️ Style
            </label>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
              {['solid', 'dashed', 'dotted'].map(style => (
                <button
                  key={style}
                  onClick={() => {
                    onEdgeStyleChange(selectedEdge.id, style as any);
                    setSelectedEdge(prev => prev ? { ...prev, data: { ...prev.data, style } } : null);
                  }}
                  style={{
                    padding: '10px 12px',
                    border: '2px solid',
                    borderColor: selectedEdge.data?.style === style ? '#2196f3' : '#ddd',
                    borderRadius: '6px',
                    background: selectedEdge.data?.style === style ? '#e3f2fd' : 'white',
                    cursor: 'pointer',
                    fontSize: '12px',
                    fontWeight: selectedEdge.data?.style === style ? 'bold' : 'normal',
                    textAlign: 'left'
                  }}
                >
                  {style === 'solid' && '--- Solid'}
                  {style === 'dashed' && '- - - Dashed'}
                  {style === 'dotted' && '. . . Dotted'}
                </button>
              ))}
            </div>
          </div>

          {/* Color Section */}
          <div style={{ marginBottom: '20px' }}>
            <label style={{ display: 'block', fontSize: '14px', fontWeight: 'bold', marginBottom: '8px', color: '#333' }}>
              🎨 Color
            </label>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
              {[
                { color: '#4caf50', name: 'Green' },
                { color: '#2196f3', name: 'Blue' },
                { color: '#f44336', name: 'Red' }
              ].map(({ color, name }) => (
                <button
                  key={color}
                  onClick={() => {
                    onEdgeColorChange(selectedEdge.id, color);
                    setSelectedEdge(prev => prev ? { ...prev, data: { ...prev.data, color } } : null);
                  }}
                  style={{
                    padding: '10px 12px',
                    border: '2px solid',
                    borderColor: selectedEdge.data?.color === color ? color : '#ddd',
                    borderRadius: '6px',
                    background: selectedEdge.data?.color === color ? `${color}15` : 'white',
                    cursor: 'pointer',
                    fontSize: '12px',
                    fontWeight: selectedEdge.data?.color === color ? 'bold' : 'normal',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '8px'
                  }}
                >
                  <div style={{
                    width: '16px',
                    height: '16px',
                    backgroundColor: color,
                    borderRadius: '3px',
                    border: '1px solid #ddd'
                  }}></div>
                  {name}
                </button>
              ))}
            </div>
          </div>

          {/* Reset Section */}
          <div style={{ marginTop: '30px', paddingTop: '20px', borderTop: '1px solid #eee' }}>
            <button
              onClick={() => {
                onEdgeReset(selectedEdge.id);
                setSelectedEdge(null);
              }}
              style={{
                width: '100%',
                padding: '12px',
                border: '2px solid #f44336',
                borderRadius: '6px',
                background: '#ffebee',
                color: '#d32f2f',
                cursor: 'pointer',
                fontSize: '14px',
                fontWeight: 'bold'
              }}
            >
              🎨 Reset Styling
            </button>
          </div>
          <div style={{ height: '40px' }} />
        </div>
      )}
      
      {/* Variable Manager */}
      <VariableManager 
        isOpen={showVariableManager}
        onClose={() => setShowVariableManager(false)}
      />
    </div>
  );
}

function App() {
  return (
    <VariableManagerProvider>
      <FlowWithProvider />
    </VariableManagerProvider>
  );
}

export default App;