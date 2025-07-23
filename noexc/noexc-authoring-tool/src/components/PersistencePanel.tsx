import React, { useState } from 'react';
import { useVariableManager } from '../context/VariableManagerContext';
import { SharedConfigPersistence, BackupManager, PersistenceResult } from '../utils/variablePersistence';

interface PersistencePanelProps {
  isOpen: boolean;
  onClose: () => void;
}

const PersistencePanel: React.FC<PersistencePanelProps> = ({ isOpen, onClose }) => {
  const [lastResult, setLastResult] = useState<PersistenceResult | null>(null);
  const [backups, setBackups] = useState<string[]>([]);
  const variableManager = useVariableManager();

  const showResult = (result: PersistenceResult) => {
    setLastResult(result);
    setTimeout(() => setLastResult(null), 5000);
  };

  const handleExportSharedConfig = () => {
    const result = SharedConfigPersistence.downloadSharedConfig(variableManager.variables);
    showResult(result);
  };

  const handleImportSharedConfig = async () => {
    const result = await SharedConfigPersistence.uploadSharedConfig();
    if (result.success && result.data) {
      variableManager.replaceAllVariables(result.data as Map<string, any>);
    }
    showResult(result);
  };

  const handleSaveToLocalStorage = () => {
    const result = variableManager.saveToLocalStorage();
    showResult(result);
  };

  const handleLoadFromLocalStorage = () => {
    const result = variableManager.loadFromLocalStorage();
    showResult(result);
  };

  const handleClearLocalStorage = () => {
    if (window.confirm('Are you sure you want to clear all saved variables? This cannot be undone.')) {
      const result = variableManager.clearLocalStorage();
      showResult(result);
    }
  };

  const handleCreateBackup = () => {
    const result = BackupManager.createBackup(variableManager.variables);
    if (result.success) {
      setBackups(BackupManager.listBackups());
    }
    showResult(result);
  };

  const handleRestoreBackup = (backupKey: string) => {
    if (window.confirm(`Restore variables from backup: ${backupKey}?`)) {
      const result = BackupManager.restoreBackup(backupKey);
      if (result.success && result.data) {
        variableManager.replaceAllVariables(result.data as Map<string, any>);
      }
      showResult(result);
    }
  };

  const handleDeleteBackup = (backupKey: string) => {
    if (window.confirm(`Delete backup: ${backupKey}?`)) {
      const result = BackupManager.deleteBackup(backupKey);
      if (result.success) {
        setBackups(BackupManager.listBackups());
      }
      showResult(result);
    }
  };

  const refreshBackups = () => {
    setBackups(BackupManager.listBackups());
  };

  React.useEffect(() => {
    if (isOpen) {
      refreshBackups();
    }
  }, [isOpen]);

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
        maxWidth: '600px',
        height: '80%',
        maxHeight: '500px',
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
          <h3 style={{ margin: 0, color: '#333' }}>💾 Variable Persistence</h3>
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
          
          {/* Result Display */}
          {lastResult && (
            <div style={{
              padding: '12px',
              marginBottom: '20px',
              backgroundColor: lastResult.success ? '#e8f5e8' : '#ffebee',
              color: lastResult.success ? '#2e7d32' : '#c62828',
              borderRadius: '4px',
              fontSize: '14px'
            }}>
              <strong>{lastResult.success ? '✅' : '❌'}</strong> {lastResult.message}
              {lastResult.errors && lastResult.errors.length > 0 && (
                <ul style={{ margin: '8px 0 0 0', paddingLeft: '20px' }}>
                  {lastResult.errors.map((error, index) => (
                    <li key={index}>{error}</li>
                  ))}
                </ul>
              )}
            </div>
          )}

          {/* Shared Configuration */}
          <div style={{ marginBottom: '24px' }}>
            <h4 style={{ margin: '0 0 12px 0', color: '#333', borderBottom: '2px solid #e3f2fd', paddingBottom: '4px' }}>
              📄 Shared Configuration
            </h4>
            <div style={{ display: 'flex', gap: '12px', flexWrap: 'wrap' }}>
              <button
                onClick={handleExportSharedConfig}
                style={{
                  padding: '10px 16px',
                  backgroundColor: '#1976d2',
                  color: 'white',
                  border: 'none',
                  borderRadius: '4px',
                  cursor: 'pointer',
                  fontSize: '14px',
                  fontWeight: 'bold'
                }}
              >
                📤 Export to JSON
              </button>
              
              <button
                onClick={handleImportSharedConfig}
                style={{
                  padding: '10px 16px',
                  backgroundColor: '#388e3c',
                  color: 'white',
                  border: 'none',
                  borderRadius: '4px',
                  cursor: 'pointer',
                  fontSize: '14px',
                  fontWeight: 'bold'
                }}
              >
                📥 Import from JSON
              </button>
            </div>
            <div style={{ fontSize: '12px', color: '#666', marginTop: '8px' }}>
              Export/import variables to/from shared-config/variables.json for use with Flutter app
            </div>
          </div>

          {/* Local Storage */}
          <div style={{ marginBottom: '24px' }}>
            <h4 style={{ margin: '0 0 12px 0', color: '#333', borderBottom: '2px solid #fff3e0', paddingBottom: '4px' }}>
              💾 Local Storage
            </h4>
            <div style={{ display: 'flex', gap: '12px', flexWrap: 'wrap' }}>
              <button
                onClick={handleSaveToLocalStorage}
                style={{
                  padding: '10px 16px',
                  backgroundColor: '#ff9800',
                  color: 'white',
                  border: 'none',
                  borderRadius: '4px',
                  cursor: 'pointer',
                  fontSize: '14px',
                  fontWeight: 'bold'
                }}
              >
                💾 Save
              </button>
              
              <button
                onClick={handleLoadFromLocalStorage}
                style={{
                  padding: '10px 16px',
                  backgroundColor: '#673ab7',
                  color: 'white',
                  border: 'none',
                  borderRadius: '4px',
                  cursor: 'pointer',
                  fontSize: '14px',
                  fontWeight: 'bold'
                }}
              >
                📂 Load
              </button>
              
              <button
                onClick={handleClearLocalStorage}
                style={{
                  padding: '10px 16px',
                  backgroundColor: '#f44336',
                  color: 'white',
                  border: 'none',
                  borderRadius: '4px',
                  cursor: 'pointer',
                  fontSize: '14px',
                  fontWeight: 'bold'
                }}
              >
                🗑️ Clear
              </button>
            </div>
            <div style={{ fontSize: '12px', color: '#666', marginTop: '8px' }}>
              Variables are auto-saved to browser storage. Manual save/load for backup purposes.
            </div>
          </div>

          {/* Backups */}
          <div>
            <h4 style={{ margin: '0 0 12px 0', color: '#333', borderBottom: '2px solid #f3e5f5', paddingBottom: '4px' }}>
              🔄 Backups
            </h4>
            <div style={{ marginBottom: '12px' }}>
              <button
                onClick={handleCreateBackup}
                style={{
                  padding: '10px 16px',
                  backgroundColor: '#9c27b0',
                  color: 'white',
                  border: 'none',
                  borderRadius: '4px',
                  cursor: 'pointer',
                  fontSize: '14px',
                  fontWeight: 'bold',
                  marginRight: '12px'
                }}
              >
                📦 Create Backup
              </button>
              
              <button
                onClick={refreshBackups}
                style={{
                  padding: '10px 16px',
                  backgroundColor: '#607d8b',
                  color: 'white',
                  border: 'none',
                  borderRadius: '4px',
                  cursor: 'pointer',
                  fontSize: '14px',
                  fontWeight: 'bold'
                }}
              >
                🔄 Refresh
              </button>
            </div>

            {/* Backup List */}
            {backups.length > 0 ? (
              <div style={{ maxHeight: '150px', overflowY: 'auto' }}>
                {backups.map(backup => (
                  <div key={backup} style={{
                    display: 'flex',
                    justifyContent: 'space-between',
                    alignItems: 'center',
                    padding: '8px',
                    backgroundColor: '#f8f9fa',
                    borderRadius: '4px',
                    marginBottom: '4px'
                  }}>
                    <span style={{ fontSize: '12px', fontFamily: 'monospace' }}>
                      {backup.replace('backup-', '').replace(/T/, ' ').replace(/\..+/, '')}
                    </span>
                    <div style={{ display: 'flex', gap: '8px' }}>
                      <button
                        onClick={() => handleRestoreBackup(backup)}
                        style={{
                          padding: '4px 8px',
                          backgroundColor: '#4caf50',
                          color: 'white',
                          border: 'none',
                          borderRadius: '3px',
                          cursor: 'pointer',
                          fontSize: '11px'
                        }}
                      >
                        Restore
                      </button>
                      <button
                        onClick={() => handleDeleteBackup(backup)}
                        style={{
                          padding: '4px 8px',
                          backgroundColor: '#f44336',
                          color: 'white',
                          border: 'none',
                          borderRadius: '3px',
                          cursor: 'pointer',
                          fontSize: '11px'
                        }}
                      >
                        Delete
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <div style={{ 
                textAlign: 'center', 
                padding: '20px', 
                color: '#666', 
                fontStyle: 'italic',
                backgroundColor: '#f8f9fa',
                borderRadius: '4px'
              }}>
                No backups found. Create a backup to get started.
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default PersistencePanel;