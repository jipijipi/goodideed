export const NODE_CATEGORIES = [
  'bot',
  'user', 
  'choice',
  'textInput',
  'autoroute'
] as const;

export const NODE_LABELS = [
  'Welcome Message',
  'Question',
  'Response',
  'Choice Menu',
  'Text Input',
  'Conditional Route',
  'End Message',
  'Error Handler',
  'Custom'
] as const;

export type NodeCategory = typeof NODE_CATEGORIES[number];
export type NodeLabel = typeof NODE_LABELS[number];

export interface NodeData {
  label: string;
  category: NodeCategory;
  nodeLabel: NodeLabel;
  // Common fields
  nodeId: string;
  // Bot/Message specific fields
  content?: string;
  // Input specific fields
  placeholderText?: string;
  storeKey?: string;
  // Group association
  groupId?: string;
  // Callbacks
  onLabelChange: (id: string, newLabel: string) => void;
  onCategoryChange: (id: string, newCategory: NodeCategory) => void;
  onNodeLabelChange: (id: string, newNodeLabel: NodeLabel) => void;
  onNodeIdChange: (id: string, newNodeId: string) => void;
  onContentChange: (id: string, newContent: string) => void;
  onPlaceholderChange: (id: string, newPlaceholder: string) => void;
  onStoreKeyChange: (id: string, newStoreKey: string) => void;
}