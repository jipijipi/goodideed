// Variable Persistence Utility
// Handles localStorage and shared JSON file persistence

import { VariableDefinition } from '../context/VariableManagerContext';

export interface SharedVariableConfig {
  version: string;
  lastUpdated: string;
  source: string;
  environments: {
    [key: string]: {
      name: string;
      description: string;
    };
  };
  variables: {
    [key: string]: {
      type: 'string' | 'number' | 'boolean' | 'object';
      defaultValue?: any;
      description: string;
      category: 'user' | 'session' | 'system' | 'achievement' | 'custom';
      readonly: boolean;
      environments: string[];
      source: string;
    };
  };
}

export interface PersistenceResult {
  success: boolean;
  message: string;
  data?: any;
  errors?: string[];
}

const STORAGE_KEY = 'authoring-tool-variables';
const BACKUP_KEY = 'authoring-tool-variables-backup';

// localStorage persistence
export class LocalStoragePersistence {
  static save(variables: Map<string, VariableDefinition>): PersistenceResult {
    try {
      // Create backup before saving
      const existing = localStorage.getItem(STORAGE_KEY);
      if (existing) {
        localStorage.setItem(BACKUP_KEY, existing);
      }

      const variableArray = Array.from(variables.entries()).map(([key, variable]) => ({
        ...variable,
        key
      }));

      const data = {
        version: '1.0.0',
        lastSaved: new Date().toISOString(),
        variables: variableArray
      };

      localStorage.setItem(STORAGE_KEY, JSON.stringify(data));
      
      return {
        success: true,
        message: `Saved ${variableArray.length} variables to local storage`,
        data: variableArray.length
      };
    } catch (error) {
      return {
        success: false,
        message: 'Failed to save to local storage',
        errors: [error instanceof Error ? error.message : 'Unknown error']
      };
    }
  }

  static load(): PersistenceResult {
    try {
      const data = localStorage.getItem(STORAGE_KEY);
      if (!data) {
        return {
          success: true,
          message: 'No saved variables found in local storage',
          data: new Map()
        };
      }

      const parsed = JSON.parse(data);
      const variableMap = new Map<string, VariableDefinition>();

      if (parsed.variables && Array.isArray(parsed.variables)) {
        parsed.variables.forEach((variable: any) => {
          if (variable.key) {
            const { key, ...variableData } = variable;
            variableMap.set(key, variableData);
          }
        });
      }

      return {
        success: true,
        message: `Loaded ${variableMap.size} variables from local storage`,
        data: variableMap
      };
    } catch (error) {
      return {
        success: false,
        message: 'Failed to load from local storage',
        errors: [error instanceof Error ? error.message : 'Unknown error']
      };
    }
  }

  static clear(): PersistenceResult {
    try {
      localStorage.removeItem(STORAGE_KEY);
      localStorage.removeItem(BACKUP_KEY);
      return {
        success: true,
        message: 'Cleared local storage'
      };
    } catch (error) {
      return {
        success: false,
        message: 'Failed to clear local storage',
        errors: [error instanceof Error ? error.message : 'Unknown error']
      };
    }
  }

  static restore(): PersistenceResult {
    try {
      const backup = localStorage.getItem(BACKUP_KEY);
      if (!backup) {
        return {
          success: false,
          message: 'No backup found in local storage'
        };
      }

      localStorage.setItem(STORAGE_KEY, backup);
      return {
        success: true,
        message: 'Restored variables from backup'
      };
    } catch (error) {
      return {
        success: false,
        message: 'Failed to restore from backup',
        errors: [error instanceof Error ? error.message : 'Unknown error']
      };
    }
  }
}

// Shared JSON file persistence
export class SharedConfigPersistence {
  static exportToSharedConfig(variables: Map<string, VariableDefinition>): SharedVariableConfig {
    const config: SharedVariableConfig = {
      version: '1.0.0',
      lastUpdated: new Date().toISOString(),
      source: 'Authoring Tool Variable Manager',
      environments: {
        development: {
          name: 'Development',
          description: 'Local development environment'
        },
        staging: {
          name: 'Staging',
          description: 'Testing environment'
        },
        production: {
          name: 'Production',
          description: 'Live production environment'
        }
      },
      variables: {}
    };

    variables.forEach((variable, key) => {
      config.variables[key] = {
        type: variable.type,
        defaultValue: variable.defaultValue,
        description: variable.description,
        category: variable.category,
        readonly: variable.readonly,
        environments: ['development', 'staging', 'production'],
        source: 'Authoring Tool'
      };
    });

    return config;
  }

  static importFromSharedConfig(config: SharedVariableConfig): PersistenceResult {
    try {
      const variableMap = new Map<string, VariableDefinition>();

      Object.entries(config.variables).forEach(([key, variable]) => {
        variableMap.set(key, {
          key,
          type: variable.type,
          defaultValue: variable.defaultValue || '',
          description: variable.description,
          category: variable.category,
          readonly: variable.readonly
        });
      });

      return {
        success: true,
        message: `Imported ${variableMap.size} variables from shared config`,
        data: variableMap
      };
    } catch (error) {
      return {
        success: false,
        message: 'Failed to import from shared config',
        errors: [error instanceof Error ? error.message : 'Unknown error']
      };
    }
  }

  static downloadSharedConfig(variables: Map<string, VariableDefinition>, filename = 'variables.json'): PersistenceResult {
    try {
      const config = this.exportToSharedConfig(variables);
      const dataStr = JSON.stringify(config, null, 2);
      const dataUri = 'data:application/json;charset=utf-8,' + encodeURIComponent(dataStr);
      
      const linkElement = document.createElement('a');
      linkElement.setAttribute('href', dataUri);
      linkElement.setAttribute('download', filename);
      linkElement.click();

      return {
        success: true,
        message: `Downloaded shared config as ${filename}`
      };
    } catch (error) {
      return {
        success: false,
        message: 'Failed to download shared config',
        errors: [error instanceof Error ? error.message : 'Unknown error']
      };
    }
  }

  static uploadSharedConfig(): Promise<PersistenceResult> {
    return new Promise((resolve) => {
      const input = document.createElement('input');
      input.type = 'file';
      input.accept = '.json';
      
      input.onchange = (event) => {
        const file = (event.target as HTMLInputElement).files?.[0];
        if (!file) {
          resolve({
            success: false,
            message: 'No file selected'
          });
          return;
        }

        const reader = new FileReader();
        reader.onload = (e) => {
          try {
            const content = e.target?.result as string;
            const config: SharedVariableConfig = JSON.parse(content);
            
            // Validate config structure
            if (!config.variables || typeof config.variables !== 'object') {
              resolve({
                success: false,
                message: 'Invalid shared config format: missing variables object'
              });
              return;
            }

            const result = this.importFromSharedConfig(config);
            resolve(result);
          } catch (error) {
            resolve({
              success: false,
              message: 'Failed to parse shared config file',
              errors: [error instanceof Error ? error.message : 'Unknown error']
            });
          }
        };

        reader.onerror = () => {
          resolve({
            success: false,
            message: 'Failed to read file'
          });
        };

        reader.readAsText(file);
      };

      input.click();
    });
  }
}

// Auto-save functionality
export class AutoSave {
  private static timeout: NodeJS.Timeout | null = null;
  private static readonly DELAY = 2000; // 2 seconds

  static schedule(variables: Map<string, VariableDefinition>, callback?: (result: PersistenceResult) => void) {
    // Clear existing timeout
    if (this.timeout) {
      clearTimeout(this.timeout);
    }

    // Schedule new save
    this.timeout = setTimeout(() => {
      const result = LocalStoragePersistence.save(variables);
      if (callback) {
        callback(result);
      }
    }, this.DELAY);
  }

  static cancel() {
    if (this.timeout) {
      clearTimeout(this.timeout);
      this.timeout = null;
    }
  }
}

// Backup management
export class BackupManager {
  static createBackup(variables: Map<string, VariableDefinition>): PersistenceResult {
    try {
      const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
      const config = SharedConfigPersistence.exportToSharedConfig(variables);
      
      // In a real implementation, this would save to the shared-config/backups/ directory
      // For now, we'll use localStorage with a timestamped key
      const backupKey = `backup-${timestamp}`;
      localStorage.setItem(backupKey, JSON.stringify(config));

      return {
        success: true,
        message: `Created backup: ${backupKey}`,
        data: backupKey
      };
    } catch (error) {
      return {
        success: false,
        message: 'Failed to create backup',
        errors: [error instanceof Error ? error.message : 'Unknown error']
      };
    }
  }

  static listBackups(): string[] {
    const backups: string[] = [];
    for (let i = 0; i < localStorage.length; i++) {
      const key = localStorage.key(i);
      if (key && key.startsWith('backup-')) {
        backups.push(key);
      }
    }
    return backups.sort().reverse(); // Most recent first
  }

  static restoreBackup(backupKey: string): PersistenceResult {
    try {
      const backupData = localStorage.getItem(backupKey);
      if (!backupData) {
        return {
          success: false,
          message: `Backup not found: ${backupKey}`
        };
      }

      const config: SharedVariableConfig = JSON.parse(backupData);
      return SharedConfigPersistence.importFromSharedConfig(config);
    } catch (error) {
      return {
        success: false,
        message: 'Failed to restore backup',
        errors: [error instanceof Error ? error.message : 'Unknown error']
      };
    }
  }

  static deleteBackup(backupKey: string): PersistenceResult {
    try {
      localStorage.removeItem(backupKey);
      return {
        success: true,
        message: `Deleted backup: ${backupKey}`
      };
    } catch (error) {
      return {
        success: false,
        message: 'Failed to delete backup',
        errors: [error instanceof Error ? error.message : 'Unknown error']
      };
    }
  }
}