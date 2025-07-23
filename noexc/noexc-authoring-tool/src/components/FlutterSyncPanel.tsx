import React, { useState } from 'react';
import { syncFromFlutterProject, generateSharedConfig, FlutterSyncResult } from '../utils/flutterSync';
import { useVariableManager } from '../context/VariableManagerContext';

interface FlutterSyncPanelProps {
  isOpen: boolean;
  onClose: () => void;
}

const FlutterSyncPanel: React.FC<FlutterSyncPanelProps> = ({ isOpen, onClose }) => {
  const [syncResult, setSyncResult] = useState<FlutterSyncResult | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [flutterPath, setFlutterPath] = useState('../'); // Default to parent directory
  const variableManager = useVariableManager();

  const handleSync = async () => {
    setIsLoading(true);
    try {
      const result = await syncFromFlutterProject(flutterPath);
      setSyncResult(result);
    } catch (error) {
      setSyncResult({
        variables: [],
        errors: [`Sync failed: ${error}`],
        lastSync: new Date().toISOString(),
        sourceFiles: []
      });
    } finally {
      setIsLoading(false);
    }
  };

  const handleImportVariables = () => {
    if (!syncResult) return;

    let importedCount = 0;
    syncResult.variables.forEach(flutterVar => {
      try {
        variableManager.addVariable({
          key: flutterVar.key,
          type: flutterVar.type,
          defaultValue: flutterVar.defaultValue || '',
          description: flutterVar.description,
          category: flutterVar.category,
          readonly: flutterVar.readonly
        });
        importedCount++;
      } catch (error) {
        // Variable might already exist, skip silently
      }
    });

    alert(`Imported ${importedCount} variables from Flutter project`);
    onClose();
  };

  const downloadSharedConfig = () => {
    if (!syncResult) return;

    const config = generateSharedConfig(syncResult.variables);
    const dataStr = JSON.stringify(config, null, 2);
    const dataUri = 'data:application/json;charset=utf-8,' + encodeURIComponent(dataStr);
    
    const linkElement = document.createElement('a');
    linkElement.setAttribute('href', dataUri);
    linkElement.setAttribute('download', 'flutter-variables-config.json');
    linkElement.click();
  };

  if (!isOpen) return null;

  return (
    <div style={{
      position: 'fixed',
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      backgroundColor: 'rgba(0,0,0,0.5)',
      zIndex: 2000,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center'
    }}>
      <div style={{
        backgroundColor: 'white',
        borderRadius: '8px',
        width: '90%',
        maxWidth: '700px',
        height: '80%',
        maxHeight: '600px',
        display: 'flex',
        flexDirection: 'column',
        boxShadow: '0 8px 32px rgba(0,0,0,0.3)'
      }}>
        {/* Header */}
        <div style={{
          padding: '16px 20px',
          borderBottom: '1px solid #eee',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center'
        }}>
          <h3 style={{ margin: 0, color: '#333' }}>🔄 Flutter Project Sync</h3>
          <button
            onClick={onClose}
            style={{
              background: 'none',
              border: 'none',
              fontSize: '20px',
              cursor: 'pointer',
              color: '#666'
            }}
          >
            ×
          </button>
        </div>

        {/* Content */}
        <div style={{ padding: '20px', flex: 1, overflowY: 'auto' }}>
          
          {/* Flutter Path Input */}
          <div style={{ marginBottom: '20px' }}>
            <label style={{ display: 'block', fontSize: '14px', fontWeight: 'bold', marginBottom: '8px' }}>
              Flutter Project Path
            </label>
            <input
              type="text"
              value={flutterPath}
              onChange={(e) => setFlutterPath(e.target.value)}
              placeholder="../ (relative to authoring tool)"
              style={{
                width: '100%',
                padding: '8px 12px',
                border: '1px solid #ddd',
                borderRadius: '4px',
                fontSize: '14px'
              }}
            />
            <div style={{ fontSize: '12px', color: '#666', marginTop: '4px' }}>
              Path to your Flutter project directory (containing lib/ folder)
            </div>
          </div>

          {/* Sync Button */}
          <div style={{ marginBottom: '20px' }}>
            <button
              onClick={handleSync}
              disabled={isLoading}
              style={{
                padding: '12px 24px',
                backgroundColor: isLoading ? '#ccc' : '#2196f3',
                color: 'white',
                border: 'none',
                borderRadius: '4px',
                cursor: isLoading ? 'not-allowed' : 'pointer',
                fontSize: '14px',
                fontWeight: 'bold'
              }}
            >
              {isLoading ? '🔄 Syncing...' : '🔄 Sync from Flutter'}
            </button>
          </div>

          {/* Sync Results */}
          {syncResult && (
            <div>
              <h4 style={{ margin: '0 0 16px 0', color: '#333' }}>Sync Results</h4>
              
              {/* Summary */}
              <div style={{
                display: 'grid',
                gridTemplateColumns: 'repeat(auto-fit, minmax(120px, 1fr))',
                gap: '12px',
                marginBottom: '16px'
              }}>
                <div style={{ textAlign: 'center', padding: '12px', backgroundColor: '#e3f2fd', borderRadius: '4px' }}>
                  <div style={{ fontSize: '20px', fontWeight: 'bold', color: '#1976d2' }}>
                    {syncResult.variables.length}
                  </div>
                  <div style={{ fontSize: '12px', color: '#666' }}>Variables Found</div>
                </div>
                <div style={{ textAlign: 'center', padding: '12px', backgroundColor: '#e8f5e8', borderRadius: '4px' }}>
                  <div style={{ fontSize: '20px', fontWeight: 'bold', color: '#388e3c' }}>
                    {syncResult.sourceFiles.length}
                  </div>
                  <div style={{ fontSize: '12px', color: '#666' }}>Files Scanned</div>
                </div>
                <div style={{ textAlign: 'center', padding: '12px', backgroundColor: syncResult.errors.length > 0 ? '#ffebee' : '#e8f5e8', borderRadius: '4px' }}>
                  <div style={{ fontSize: '20px', fontWeight: 'bold', color: syncResult.errors.length > 0 ? '#d32f2f' : '#388e3c' }}>
                    {syncResult.errors.length}
                  </div>
                  <div style={{ fontSize: '12px', color: '#666' }}>Errors</div>
                </div>
              </div>

              {/* Variables by Category */}
              {syncResult.variables.length > 0 && (
                <div style={{ marginBottom: '16px' }}>
                  <h5 style={{ margin: '0 0 12px 0', color: '#333' }}>Variables by Category</h5>
                  {['user', 'session', 'system', 'achievement', 'custom'].map(category => {
                    const categoryVars = syncResult.variables.filter(v => v.category === category);
                    if (categoryVars.length === 0) return null;
                    
                    return (
                      <div key={category} style={{ marginBottom: '12px' }}>
                        <h6 style={{ 
                          margin: '0 0 6px 0', 
                          fontSize: '14px', 
                          fontWeight: 'bold',
                          color: '#666',
                          textTransform: 'capitalize'
                        }}>
                          {category} ({categoryVars.length})
                        </h6>
                        <div style={{ display: 'flex', flexWrap: 'wrap', gap: '4px' }}>
                          {categoryVars.map(variable => (
                            <span
                              key={variable.key}
                              style={{
                                padding: '2px 6px',
                                backgroundColor: '#f5f5f5',
                                color: '#333',
                                borderRadius: '8px',
                                fontSize: '11px',
                                fontFamily: 'monospace'
                              }}
                              title={`${variable.description} (${variable.source})`}
                            >
                              {variable.key}
                            </span>
                          ))}
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}

              {/* Errors */}
              {syncResult.errors.length > 0 && (
                <div style={{ marginBottom: '16px' }}>
                  <h5 style={{ margin: '0 0 8px 0', color: '#d32f2f' }}>Errors</h5>
                  {syncResult.errors.map((error, index) => (
                    <div key={index} style={{
                      padding: '8px',
                      backgroundColor: '#ffebee',
                      color: '#d32f2f',
                      borderRadius: '4px',
                      fontSize: '12px',
                      marginBottom: '4px'
                    }}>
                      {error}
                    </div>
                  ))}
                </div>
              )}

              {/* Action Buttons */}
              {syncResult.variables.length > 0 && (
                <div style={{ display: 'flex', gap: '12px' }}>
                  <button
                    onClick={handleImportVariables}
                    style={{
                      padding: '10px 20px',
                      backgroundColor: '#4caf50',
                      color: 'white',
                      border: 'none',
                      borderRadius: '4px',
                      cursor: 'pointer',
                      fontSize: '14px',
                      fontWeight: 'bold'
                    }}
                  >
                    📥 Import to Variable Manager
                  </button>
                  
                  <button
                    onClick={downloadSharedConfig}
                    style={{
                      padding: '10px 20px',
                      backgroundColor: '#ff9800',
                      color: 'white',
                      border: 'none',
                      borderRadius: '4px',
                      cursor: 'pointer',
                      fontSize: '14px',
                      fontWeight: 'bold'
                    }}
                  >
                    💾 Download Config
                  </button>
                </div>
              )}
            </div>
          )}

          {/* Help Text */}
          <div style={{
            marginTop: '20px',
            padding: '12px',
            backgroundColor: '#f8f9fa',
            borderRadius: '4px',
            fontSize: '12px',
            color: '#666'
          }}>
            <strong>How it works:</strong>
            <ul style={{ margin: '8px 0', paddingLeft: '16px' }}>
              <li>Scans Flutter project files for variable definitions</li>
              <li>Extracts constants from storage_keys.dart, app_constants.dart, etc.</li>
              <li>Parses model classes for property definitions</li>
              <li>Categorizes variables by prefix (user., session., system., etc.)</li>
              <li>Imports variables into the authoring tool's Variable Manager</li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  );
};

export default FlutterSyncPanel;