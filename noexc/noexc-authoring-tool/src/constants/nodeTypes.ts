export const NODE_CATEGORIES = [
  'bot',
  'user', 
  'choice',
  'textInput',
  'autoroute',
  'dataAction',
  'image',
  'system'
] as const;

export const NODE_LABELS = [
  'Welcome Message',
  'Question',
  'Response',
  'Choice Menu',
  'Text Input',
  'Conditional Route',
  'Data Action',
  'System Message',
  'End Message',
  'Error Handler',
  'Custom'
] as const;

// Node type constants
export const NODE_TYPES = {
  EDITABLE: 'editable',
  GROUP: 'group'
} as const;

export type NodeCategory = typeof NODE_CATEGORIES[number];
export type NodeLabel = typeof NODE_LABELS[number];

export interface DataActionItem {
  type: 'set' | 'increment' | 'decrement' | 'reset' | 'trigger' | 'append' | 'remove';
  key: string;
  value?: any;
  event?: string;
  data?: any;
}

export interface NodeData {
  label: string;
  category: NodeCategory;
  nodeLabel: NodeLabel;
  // Common fields
  nodeId: string;
  contentKey?: string;
  // Bot/Message specific fields
  content?: string;
  // Input specific fields
  placeholderText?: string;
  storeKey?: string;
  // Image specific fields
  imagePath?: string;
  // DataAction specific fields
  dataActions?: DataActionItem[];
  // Group specific fields
  groupId?: string;
  title?: string;
  description?: string;
  color?: string;
  // Callbacks
  onLabelChange: (id: string, newLabel: string) => void;
  onCategoryChange: (id: string, newCategory: NodeCategory) => void;
  onNodeLabelChange: (id: string, newNodeLabel: NodeLabel) => void;
  onNodeIdChange: (id: string, newNodeId: string) => void;
  onContentKeyChange: (id: string, newContentKey: string) => void;
  onContentChange: (id: string, newContent: string) => void;
  onPlaceholderChange: (id: string, newPlaceholder: string) => void;
  onStoreKeyChange: (id: string, newStoreKey: string) => void;
  onImagePathChange?: (id: string, newImagePath: string) => void;
  onDataActionsChange?: (id: string, newDataActions: DataActionItem[]) => void;
  onGroupIdChange?: (id: string, newGroupId: string) => void;
  onTitleChange?: (id: string, newTitle: string) => void;
  onDescriptionChange?: (id: string, newDescription: string) => void;
  onColorChange?: (id: string, newColor: string) => void;
}