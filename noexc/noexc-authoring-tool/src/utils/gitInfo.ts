// Git Information Utility
// Detects current git branch and commit for version tracking

export interface GitInfo {
  branch: string;
  commit: string;
  timestamp: string;
}

// For browser environment, we'll need to fetch git info from the parent project
// Since we can't run git commands directly in the browser, we'll create a simple
// file-based approach that can be updated by a build script
export const getCurrentGitInfo = async (): Promise<GitInfo> => {
  try {
    // In a real implementation, this could fetch from a generated git-info.json file
    // or use a build-time script to inject git information
    
    // For now, we'll use a simple detection method
    const timestamp = new Date().toISOString();
    
    // Try to read git info from a generated file (could be created by build script)
    const gitInfoPath = '../git-info.json';
    
    try {
      const response = await fetch(gitInfoPath);
      if (response.ok) {
        const gitInfo = await response.json();
        return {
          branch: gitInfo.branch || 'unknown',
          commit: gitInfo.commit || 'unknown',
          timestamp
        };
      }
    } catch {
      // Fall back to manual detection if file doesn't exist
    }
    
    // Fallback: return basic info
    return {
      branch: 'unknown',
      commit: 'unknown', 
      timestamp
    };
  } catch (error) {
    console.warn('Failed to get git info:', error);
    return {
      branch: 'unknown',
      commit: 'unknown',
      timestamp: new Date().toISOString()
    };
  }
};

// Helper to check if git info matches between saved state and current
export const isGitInfoCompatible = (savedGitInfo: GitInfo, currentGitInfo: GitInfo): boolean => {
  // Consider compatible if on same branch
  return savedGitInfo.branch === currentGitInfo.branch;
};

// Generate git info warning message
export const generateGitWarningMessage = (savedGitInfo: GitInfo, currentGitInfo: GitInfo): string => {
  if (savedGitInfo.branch !== currentGitInfo.branch) {
    return `Warning: Master flow was created on branch "${savedGitInfo.branch}" but you're currently on "${currentGitInfo.branch}". The exported sequences may not be compatible with this branch's Flutter app.`;
  }
  
  if (savedGitInfo.commit !== currentGitInfo.commit && savedGitInfo.commit !== 'unknown' && currentGitInfo.commit !== 'unknown') {
    return `Info: Master flow was created from commit "${savedGitInfo.commit.substring(0, 8)}" but current commit is "${currentGitInfo.commit.substring(0, 8)}". Consider regenerating if Flutter app schema has changed.`;
  }
  
  return '';
};