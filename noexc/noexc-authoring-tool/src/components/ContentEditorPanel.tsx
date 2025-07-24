import React, { useState, useEffect } from 'react';

interface ContentEditorPanelProps {
  contentKey: string | undefined;
  onContentChange: (contentKey: string, variants: string[]) => void;
  currentVariants: string[];
  isVisible: boolean;
  directoryHandle: FileSystemDirectoryHandle | null;
  onNotification: (message: string) => void;
  onError: (title: string, messages: string[]) => void;
}

const ContentEditorPanel: React.FC<ContentEditorPanelProps> = ({
  contentKey,
  onContentChange,
  currentVariants,
  isVisible,
  directoryHandle,
  onNotification,
  onError
}) => {
  const [isEditing, setIsEditing] = useState(false);
  const [editText, setEditText] = useState('');
  const [isLoadingExisting, setIsLoadingExisting] = useState(false);
  const [hasExistingContent, setHasExistingContent] = useState(false);


  const loadExistingContent = async (key: string) => {
    if (!key || !directoryHandle) {
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
  }, [contentKey, currentVariants, directoryHandle]);

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

  if (!isVisible || !contentKey) {
    return null;
  }

  return (
    <div style={{
      position: 'absolute',
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
    }}>
      <div style={{ 
        display: 'flex', 
        alignItems: 'center', 
        marginBottom: '12px',
        borderBottom: '1px solid #eee',
        paddingBottom: '8px'
      }}>
        <span style={{ fontSize: '18px', marginRight: '8px' }}>
          {isLoadingExisting ? '⏳' : hasExistingContent ? '📁' : '✨'}
        </span>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: '14px', fontWeight: 'bold', color: '#333' }}>
            {contentKey}
          </div>
          <div style={{ fontSize: '11px', color: '#666', fontFamily: 'monospace' }}>
            {getFilePathFromContentKey(contentKey)}
          </div>
          <div style={{ fontSize: '10px', color: hasExistingContent ? '#28a745' : '#6c757d', marginTop: '2px' }}>
            {isLoadingExisting ? 'Loading existing content...' :
             hasExistingContent ? 'Loaded from existing file' : 
             directoryHandle ? 'New content (will save to Flutter)' : 'New content (connect Flutter to sync)'}
          </div>
        </div>
      </div>

      {!isEditing ? (
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
      )}
    </div>
  );
};

export default ContentEditorPanel;