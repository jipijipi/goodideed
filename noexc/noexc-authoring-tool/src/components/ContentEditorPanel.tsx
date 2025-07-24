import React, { useState, useEffect } from 'react';

interface ContentEditorPanelProps {
  contentKey: string | undefined;
  onContentChange: (contentKey: string, variants: string[]) => void;
  currentVariants: string[];
  isVisible: boolean;
}

const ContentEditorPanel: React.FC<ContentEditorPanelProps> = ({
  contentKey,
  onContentChange,
  currentVariants,
  isVisible
}) => {
  const [isEditing, setIsEditing] = useState(false);
  const [editText, setEditText] = useState('');
  const [isLoadingExisting, setIsLoadingExisting] = useState(false);
  const [hasExistingContent, setHasExistingContent] = useState(false);

  const convertSemanticKeyToFilePath = (key: string): string => {
    if (!key) return '';
    const parts = key.split('.');
    if (parts.length < 3) return '';
    
    const [actor, action, ...rest] = parts;
    const fileName = rest.join('_') + '.txt';
    return `../assets/content/${actor}/${action}/${fileName}`;
  };

  const loadExistingContent = async (key: string) => {
    if (!key) return;
    
    setIsLoadingExisting(true);
    try {
      const filePath = convertSemanticKeyToFilePath(key);
      // Try to fetch the existing content file
      const response = await fetch(filePath);
      if (response.ok) {
        const content = await response.text();
        const variants = content.split('\n').map(line => line.trim()).filter(line => line.length > 0);
        if (variants.length > 0) {
          onContentChange(key, variants);
          setHasExistingContent(true);
        }
      }
    } catch (error) {
      // File doesn't exist or can't be loaded - this is fine for new content
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
      // Try to load existing content
      loadExistingContent(contentKey);
      setEditText('');
      setHasExistingContent(false);
    } else {
      setEditText('');
      setHasExistingContent(false);
    }
  }, [contentKey, currentVariants]);

  const handleSave = () => {
    if (!contentKey) return;
    
    const variants = editText
      .split('\n')
      .map(line => line.trim())
      .filter(line => line.length > 0);
    
    onContentChange(contentKey, variants);
    setIsEditing(false);
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
      right: '220px',
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
             hasExistingContent ? 'Loaded from existing file' : 'New content'}
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