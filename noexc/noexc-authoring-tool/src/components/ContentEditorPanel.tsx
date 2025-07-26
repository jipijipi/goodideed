import React, { useState, useEffect } from 'react';

interface ContentEditorPanelProps {
  contentKey: string | undefined;
  onContentChange: (contentKey: string, variants: string[]) => void;
  currentVariants: string[];
  isVisible: boolean;
  directoryHandle: FileSystemDirectoryHandle | null;
  onNotification: (message: string) => void;
  onError: (title: string, messages: string[]) => void;
  nodeCategory?: string;
  isEdge?: boolean;
  inline?: boolean;
}

const ContentEditorPanel: React.FC<ContentEditorPanelProps> = ({
  contentKey,
  onContentChange,
  currentVariants,
  isVisible,
  directoryHandle,
  onNotification,
  onError,
  nodeCategory,
  isEdge,
  inline = false
}) => {
  const [isEditing, setIsEditing] = useState(false);
  const [editText, setEditText] = useState('');
  const [isLoadingExisting, setIsLoadingExisting] = useState(false);
  const [hasExistingContent, setHasExistingContent] = useState(false);

  const shouldLoadContent = (key: string, category?: string, edge?: boolean): boolean => {
    if (!key) return false;
    
    // Edges (choice options) can always have content
    if (edge) return true;
    
    // Only bot/user nodes can have text content
    return category === 'bot' || category === 'user';
  };

  const getContentMessage = (category?: string, edge?: boolean): { canEdit: boolean; message: string; icon: string } => {
    if (edge) {
      return { canEdit: true, message: 'Choice option text variants', icon: '🔘' };
    }
    
    switch (category) {
      case 'bot':
      case 'user':
        return { canEdit: true, message: 'Message text variants', icon: '💬' };
      case 'choice':
        return { canEdit: false, message: 'Choice options have individual content (select edges to edit)', icon: '🔘' };
      case 'textInput':
        return { canEdit: false, message: 'Text input uses placeholder text, not content variants', icon: '⌨️' };
      case 'autoroute':
        return { canEdit: false, message: 'Autoroute uses conditions, not text content', icon: '🔀' };
      case 'dataAction':
        return { canEdit: false, message: 'Data actions use operations, not text content', icon: '⚙️' };
      default:
        return { canEdit: false, message: 'Content variants not applicable for this node type', icon: '❓' };
    }
  };


  const loadExistingContent = async (key: string) => {
    if (!key || !directoryHandle) {
      setHasExistingContent(false);
      return;
    }
    
    // Only load content for supported node/edge types
    if (!shouldLoadContent(key, nodeCategory, isEdge)) {
      setHasExistingContent(false);
      return;
    }
    
    setIsLoadingExisting(true);
    try {
      // Parse semantic key: bot.request.excuse.direct
      const parts = key.split('.');
      if (parts.length < 3) {
        setHasExistingContent(false);
        return;
      }
      
      const [actor, action, ...rest] = parts;
      const fileName = `${rest.join('_')}.txt`;
      
      // Navigate to file: assets/content/actor/action/filename.txt
      const assetsDir = await directoryHandle.getDirectoryHandle('assets');
      const contentDir = await assetsDir.getDirectoryHandle('content');
      const actorDir = await contentDir.getDirectoryHandle(actor);
      const actionDir = await actorDir.getDirectoryHandle(action);
      const fileHandle = await actionDir.getFileHandle(fileName);
      
      const file = await fileHandle.getFile();
      const content = await file.text();
      const variants = content.split('\n').map(line => line.trim()).filter(line => line.length > 0);
      
      if (variants.length > 0) {
        onContentChange(key, variants);
        setHasExistingContent(true);
        onNotification(`Loaded ${fileName} from Flutter project`);
      } else {
        setHasExistingContent(false);
      }
    } catch (error) {
      // File doesn't exist - that's fine for new content
      setHasExistingContent(false);
    } finally {
      setIsLoadingExisting(false);
    }
  };

  useEffect(() => {
    if (contentKey && currentVariants.length > 0) {
      setEditText(currentVariants.join('\n'));
      setHasExistingContent(true);
    } else if (contentKey) {
      // Try to load existing content from filesystem
      loadExistingContent(contentKey);
      setEditText('');
      setHasExistingContent(false);
    } else {
      setEditText('');
      setHasExistingContent(false);
    }
  }, [contentKey, currentVariants, directoryHandle, nodeCategory, isEdge]);

  const saveToFileSystem = async (key: string, variants: string[]) => {
    if (!directoryHandle || !key) return false;
    
    try {
      const parts = key.split('.');
      if (parts.length < 3) return false;
      
      const [actor, action, ...rest] = parts;
      const fileName = `${rest.join('_')}.txt`;
      
      // Navigate/create directory structure
      const assetsDir = await directoryHandle.getDirectoryHandle('assets', { create: true });
      const contentDir = await assetsDir.getDirectoryHandle('content', { create: true });
      const actorDir = await contentDir.getDirectoryHandle(actor, { create: true });
      const actionDir = await actorDir.getDirectoryHandle(action, { create: true });
      
      // Create/update file
      const fileHandle = await actionDir.getFileHandle(fileName, { create: true });
      const writable = await (fileHandle as any).createWritable();
      await writable.write(variants.join('\n'));
      await writable.close();
      
      onNotification(`Saved ${fileName} to Flutter project`);
      return true;
    } catch (error: any) {
      onError('File save failed', [error.message]);
      return false;
    }
  };

  const handleSave = async () => {
    if (!contentKey) return;
    
    const variants = editText
      .split('\n')
      .map(line => line.trim())
      .filter(line => line.length > 0);
    
    // Save to state
    onContentChange(contentKey, variants);
    setIsEditing(false);
    
    // Save to filesystem if connected
    if (directoryHandle) {
      await saveToFileSystem(contentKey, variants);
    }
  };

  const handleCancel = () => {
    setEditText(currentVariants.join('\n'));
    setIsEditing(false);
  };

  const getFilePathFromContentKey = (key: string): string => {
    if (!key) return '';
    const parts = key.split('.');
    if (parts.length < 3) return key;
    
    const [actor, action, ...rest] = parts;
    const fileName = rest.join('_') + '.txt';
    return `content/${actor}/${action}/${fileName}`;
  };

  const contentInfo = getContentMessage(nodeCategory, isEdge);

  if (!isVisible || !contentKey) {
    return null;
  }

  const containerStyle = inline ? {
    // Inline mode - integrate into config panel
    marginBottom: '20px',
    border: 'none',
    borderRadius: '0',
    padding: '0',
    background: 'transparent',
    width: '100%',
    maxHeight: 'none'
  } : {
    // Floating mode - original positioning
    position: 'absolute' as const,
    top: '10px',
    right: '530px',
    background: 'white',
    border: '1px solid #ddd',
    borderRadius: '8px',
    padding: '16px',
    width: '300px',
    maxHeight: '400px',
    boxShadow: '0 4px 12px rgba(0,0,0,0.1)',
    zIndex: 1000
  };

  return (
    <div style={containerStyle}>
      {/* Header Section */}
      {inline ? (
        <div style={{ marginBottom: '16px' }}>
          <h3 style={{ fontSize: '16px', fontWeight: 'bold', color: '#333', margin: '0 0 12px 0', borderBottom: '2px solid #e3f2fd', paddingBottom: '8px' }}>
            🎨 Content Variants
          </h3>
          <div style={{ fontSize: '11px', color: '#666', fontFamily: 'monospace', marginBottom: '8px' }}>
            {contentKey && getFilePathFromContentKey(contentKey)}
          </div>
        </div>
      ) : (
        <div style={{ 
          display: 'flex', 
          alignItems: 'center', 
          marginBottom: '12px',
          borderBottom: '1px solid #eee',
          paddingBottom: '8px'
        }}>
          <span style={{ fontSize: '18px', marginRight: '8px' }}>
            {isLoadingExisting ? '⏳' : hasExistingContent ? '📁' : contentInfo.icon}
          </span>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: '14px', fontWeight: 'bold', color: '#333' }}>
              {contentKey}
            </div>
            <div style={{ fontSize: '11px', color: '#666', fontFamily: 'monospace' }}>
              {getFilePathFromContentKey(contentKey)}
            </div>
            <div style={{ fontSize: '10px', color: hasExistingContent ? '#28a745' : contentInfo.canEdit ? '#6c757d' : '#ffc107', marginTop: '2px' }}>
              {isLoadingExisting ? 'Loading existing content...' :
               hasExistingContent ? 'Loaded from existing file' : 
               contentInfo.canEdit ? 
                 (directoryHandle ? 'New content (will save to Flutter)' : 'New content (connect Flutter to sync)') :
                 contentInfo.message}
            </div>
          </div>
        </div>
      )}

      {contentInfo.canEdit ? (
        !isEditing ? (
          <div>
            <div style={{
              backgroundColor: '#f8f9fa',
              border: '1px solid #e9ecef',
              borderRadius: '4px',
              padding: '8px',
              marginBottom: '12px',
              maxHeight: '200px',
              overflowY: 'auto',
              fontSize: '13px',
              lineHeight: '1.4'
            }}>
              {currentVariants.length > 0 ? (
                currentVariants.map((variant, index) => (
                  <div key={index} style={{ 
                    marginBottom: index < currentVariants.length - 1 ? '4px' : '0',
                    color: '#495057'
                  }}>
                    {variant}
                  </div>
                ))
              ) : (
                <div style={{ color: '#6c757d', fontStyle: 'italic' }}>
                  No variants defined
                </div>
              )}
            </div>
            
            <button
              onClick={() => setIsEditing(true)}
              style={{
                backgroundColor: '#007bff',
                color: 'white',
                border: 'none',
                padding: '6px 12px',
                borderRadius: '4px',
                fontSize: '12px',
                cursor: 'pointer',
                width: '100%'
              }}
            >
              ✏️ Edit Variants
            </button>
            
            <div style={{ 
              fontSize: '11px', 
              color: '#6c757d', 
              marginTop: '8px',
              textAlign: 'center'
            }}>
              {currentVariants.length > 0 
                ? `${currentVariants.length} variant${currentVariants.length === 1 ? '' : 's'} defined`
                : 'Click to add variants'
              }
            </div>
          </div>
        ) : (
          <div>
            <textarea
              value={editText}
              onChange={(e) => setEditText(e.target.value)}
              placeholder="Enter variants, one per line..."
              style={{
                width: '100%',
                height: '150px',
                border: '1px solid #ddd',
                borderRadius: '4px',
                padding: '8px',
                fontSize: '13px',
                resize: 'vertical',
                fontFamily: 'inherit'
              }}
            />
            
            <div style={{ 
              display: 'flex', 
              gap: '8px', 
              marginTop: '12px' 
            }}>
              <button
                onClick={handleSave}
                style={{
                  backgroundColor: '#28a745',
                  color: 'white',
                  border: 'none',
                  padding: '6px 12px',
                  borderRadius: '4px',
                  fontSize: '12px',
                  cursor: 'pointer',
                  flex: 1
                }}
              >
                💾 Save
              </button>
              <button
                onClick={handleCancel}
                style={{
                  backgroundColor: '#6c757d',
                  color: 'white',
                  border: 'none',
                  padding: '6px 12px',
                  borderRadius: '4px',
                  fontSize: '12px',
                  cursor: 'pointer',
                  flex: 1
                }}
              >
                ❌ Cancel
              </button>
            </div>
            
            <div style={{ 
              fontSize: '11px', 
              color: '#6c757d', 
              marginTop: '8px',
              textAlign: 'center'
            }}>
              Tip: One variant per line
            </div>
          </div>
        )
      ) : (
        <div style={{
          backgroundColor: '#fff3cd',
          border: '1px solid #ffeaa7',
          borderRadius: '4px',
          padding: '12px',
          textAlign: 'center',
          fontSize: '13px',
          color: '#856404'
        }}>
          {contentInfo.message}
        </div>
      )}
    </div>
  );
};

export default ContentEditorPanel;