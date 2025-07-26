// Master Flow Persistence Utility
// Handles saving/loading master flow to/from git-tracked JSON file

import { Node, Edge } from 'reactflow';
import { NodeData } from '../constants/nodeTypes';
import { getCurrentGitInfo, GitInfo, isGitInfoCompatible, generateGitWarningMessage } from './gitInfo';

export interface MasterFlowData {
  version: string;
  lastUpdated: string;
  gitBranch: string;
  gitCommit: string;
  appVersion: string;
  nodes: Node<NodeData>[];
  edges: Edge[];
  gitInfo?: GitInfo; // Added for compatibility checking
}

export interface PersistenceResult {
  success: boolean;
  message: string;
  data?: MasterFlowData;
  warning?: string;
}

const MASTER_FLOW_PATH = './master-flow/authoring-tool-master-flow.json';

// Save master flow data to git-tracked file
export const saveMasterFlow = async (nodes: Node<NodeData>[], edges: Edge[], directoryHandle?: FileSystemDirectoryHandle): Promise<PersistenceResult> => {
  try {
    // Validate input data to prevent empty files
    if (!nodes || !Array.isArray(nodes)) {
      return {
        success: false,
        message: 'Invalid nodes data - cannot save empty or invalid flow'
      };
    }

    if (!edges || !Array.isArray(edges)) {
      return {
        success: false,
        message: 'Invalid edges data - cannot save empty or invalid flow'
      };
    }

    const gitInfo = await getCurrentGitInfo();
    
    const masterFlowData: MasterFlowData = {
      version: '1.0.0',
      lastUpdated: new Date().toISOString(),
      gitBranch: gitInfo.branch,
      gitCommit: gitInfo.commit,
      appVersion: 'flutter-chat-app',
      gitInfo,
      nodes: nodes.map(node => ({
        ...node,
        selected: false // Remove UI state from saved data
      })),
      edges: edges.map(edge => ({
        ...edge,
        selected: false
      }))
    };

    // Validate masterFlowData is not empty
    const dataStr = JSON.stringify(masterFlowData, null, 2);
    if (!dataStr || dataStr.length < 100) { // Reasonable minimum size check
      return {
        success: false,
        message: 'Generated master flow data is too small or empty'
      };
    }

    // If directoryHandle is provided, save directly to the Flutter project
    if (directoryHandle) {
      try {
        // Get or create the authoring tool directory
        const authoringToolDir = await directoryHandle.getDirectoryHandle('noexc-authoring-tool', { create: true });
        // Get or create the master-flow directory
        const masterFlowDir = await authoringToolDir.getDirectoryHandle('master-flow', { create: true });
        
        // Create/update the master flow file
        const fileHandle = await masterFlowDir.getFileHandle('authoring-tool-master-flow.json', { create: true });
        const writable = await (fileHandle as any).createWritable();
        await writable.write(dataStr);
        await writable.close();
        
        return {
          success: true,
          message: 'Master flow saved to Flutter project successfully (no reload)',
          data: masterFlowData
        };
      } catch (error: any) {
        return {
          success: false,
          message: `Failed to save to Flutter project: ${error.message}`
        };
      }
    }

    // Fallback: Use File System Access API with file picker (for browsers that support it)
    if ('showSaveFilePicker' in window) {
      try {
        const fileHandle = await (window as any).showSaveFilePicker({
          suggestedName: 'authoring-tool-master-flow.json',
          types: [{
            description: 'JSON files',
            accept: { 'application/json': ['.json'] }
          }]
        });
        
        const writable = await fileHandle.createWritable();
        await writable.write(dataStr);
        await writable.close();
        
        return {
          success: true,
          message: 'Master flow saved to selected location successfully',
          data: masterFlowData
        };
      } catch (error: any) {
        if (error.name === 'AbortError') {
          return {
            success: false,
            message: 'Save cancelled by user'
          };
        }
        throw error;
      }
    } else {
      // Final fallback: download the file
      const dataUri = 'data:application/json;charset=utf-8,' + encodeURIComponent(dataStr);
      
      const linkElement = document.createElement('a');
      linkElement.setAttribute('href', dataUri);
      linkElement.setAttribute('download', 'authoring-tool-master-flow.json');
      linkElement.click();

      return {
        success: true,
        message: 'Master flow downloaded - please replace the existing file in noexc-authoring-tool/master-flow/',
        data: masterFlowData
      };
    }
  } catch (error) {
    return {
      success: false,
      message: `Failed to save master flow: ${error instanceof Error ? error.message : 'Unknown error'}`
    };
  }
};

// Load master flow data from git-tracked file
export const loadMasterFlow = async (directoryHandle?: FileSystemDirectoryHandle): Promise<PersistenceResult> => {
  try {
    let masterFlowData: MasterFlowData;
    
    // If directoryHandle is provided, use File System Access API
    if (directoryHandle) {
      try {
        // Get the authoring tool directory
        const authoringToolDir = await directoryHandle.getDirectoryHandle('noexc-authoring-tool', { create: false });
        // Get the master-flow directory
        const masterFlowDir = await authoringToolDir.getDirectoryHandle('master-flow', { create: false });
        
        // Read the master flow file
        const fileHandle = await masterFlowDir.getFileHandle('authoring-tool-master-flow.json', { create: false });
        const file = await fileHandle.getFile();
        const text = await file.text();
        masterFlowData = JSON.parse(text);
        
      } catch (error: any) {
        return {
          success: false,
          message: `Failed to read master flow from Flutter project: ${error.message}`
        };
      }
    } else {
      // Fallback: Try to fetch the master flow file from the repo root
      const response = await fetch(MASTER_FLOW_PATH);
      
      if (!response.ok) {
        if (response.status === 404) {
          return {
            success: false,
            message: 'No master flow file found. Using default flow.'
          };
        }
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }
      
      masterFlowData = await response.json();
    }
    
    const currentGitInfo = await getCurrentGitInfo();
    
    let warning = '';
    if (masterFlowData.gitInfo) {
      if (!isGitInfoCompatible(masterFlowData.gitInfo, currentGitInfo)) {
        warning = generateGitWarningMessage(masterFlowData.gitInfo, currentGitInfo);
      }
    }
    
    const loadMethod = directoryHandle ? 'Flutter project' : 'fetch';
    return {
      success: true,
      message: `Master flow loaded successfully from ${masterFlowData.gitBranch} branch (${loadMethod})`,
      data: masterFlowData,
      warning
    };
  } catch (error) {
    return {
      success: false,
      message: `Failed to load master flow: ${error instanceof Error ? error.message : 'Unknown error'}`
    };
  }
};

// Import master flow from uploaded file
export const importMasterFlow = async (): Promise<PersistenceResult> => {
  return new Promise((resolve) => {
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = '.json';
    
    input.onchange = async (event) => {
      const file = (event.target as HTMLInputElement).files?.[0];
      if (!file) {
        resolve({
          success: false,
          message: 'No file selected'
        });
        return;
      }

      const reader = new FileReader();
      reader.onload = async (e) => {
        try {
          const content = e.target?.result as string;
          const masterFlowData: MasterFlowData = JSON.parse(content);
          
          // Validate basic structure
          if (!masterFlowData.nodes || !Array.isArray(masterFlowData.nodes)) {
            resolve({
              success: false,
              message: 'Invalid master flow format: missing nodes array'
            });
            return;
          }
          
          if (!masterFlowData.edges || !Array.isArray(masterFlowData.edges)) {
            resolve({
              success: false,
              message: 'Invalid master flow format: missing edges array'
            });
            return;
          }
          
          const currentGitInfo = await getCurrentGitInfo();
          let warning = '';
          
          if (masterFlowData.gitInfo) {
            if (!isGitInfoCompatible(masterFlowData.gitInfo, currentGitInfo)) {
              warning = generateGitWarningMessage(masterFlowData.gitInfo, currentGitInfo);
            }
          }
          
          resolve({
            success: true,
            message: `Master flow imported successfully (${masterFlowData.nodes.length} nodes, ${masterFlowData.edges.length} edges)`,
            data: masterFlowData,
            warning
          });
        } catch (error) {
          resolve({
            success: false,
            message: 'Failed to parse master flow file',
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
};

// Export master flow for sharing
export const exportMasterFlow = async (nodes: Node<NodeData>[], edges: Edge[]): Promise<PersistenceResult> => {
  try {
    const gitInfo = await getCurrentGitInfo();
    
    const masterFlowData: MasterFlowData = {
      version: '1.0.0',
      lastUpdated: new Date().toISOString(),
      gitBranch: gitInfo.branch,
      gitCommit: gitInfo.commit,
      appVersion: 'flutter-chat-app',
      gitInfo,
      nodes: nodes.map(node => ({
        ...node,
        selected: false
      })),
      edges: edges.map(edge => ({
        ...edge,
        selected: false
      }))
    };

    const dataStr = JSON.stringify(masterFlowData, null, 2);
    const dataUri = 'data:application/json;charset=utf-8,' + encodeURIComponent(dataStr);
    
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const filename = `master-flow-${gitInfo.branch}-${timestamp}.json`;
    
    const linkElement = document.createElement('a');
    linkElement.setAttribute('href', dataUri);
    linkElement.setAttribute('download', filename);
    linkElement.click();

    return {
      success: true,
      message: `Master flow exported as ${filename}`
    };
  } catch (error) {
    return {
      success: false,
      message: `Failed to export master flow: ${error instanceof Error ? error.message : 'Unknown error'}`
    };
  }
};