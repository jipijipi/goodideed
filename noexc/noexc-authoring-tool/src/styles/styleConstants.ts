// Centralized styling constants for the authoring tool
// Uses CSS custom properties for theme consistency

export const COLORS = {
  // Background colors
  primary: 'var(--bg-primary)',
  secondary: 'var(--bg-secondary)', 
  tertiary: 'var(--bg-tertiary)',
  panel: 'var(--bg-panel)',
  
  // Text colors
  textPrimary: 'var(--text-primary)',
  textSecondary: 'var(--text-secondary)',
  textMuted: 'var(--text-muted)',
  
  // UI colors
  accent: 'var(--accent-color)',
  accentHover: 'var(--accent-hover)',
  success: 'var(--success-color)',
  error: 'var(--error-color)',
  warning: 'var(--warning-color)',
  info: 'var(--info-color)',
  
  // Border colors
  borderPrimary: 'var(--border-primary)',
  borderSecondary: 'var(--border-secondary)',
  
  // Common hardcoded colors that need to be replaced
  white: '#ffffff',
  lightGray: '#f8f9fa',
  gray: '#e0e0e0',
  disabled: '#ccc'
};

export const BUTTON_STYLES = {
  base: {
    padding: '6px 12px',
    border: 'none',
    borderRadius: '4px',
    cursor: 'pointer',
    fontWeight: 'bold' as const,
    fontSize: '11px',
    color: 'white',
    opacity: 1,
    transition: 'all 0.2s ease'
  },
  
  // Semantic button types
  primary: {
    backgroundColor: COLORS.accent
  },
  
  success: {
    backgroundColor: COLORS.success
  },
  
  error: {
    backgroundColor: COLORS.error
  },
  
  warning: {
    backgroundColor: COLORS.warning
  },
  
  info: {
    backgroundColor: COLORS.info  
  },
  
  secondary: {
    backgroundColor: '#607d8b'
  },
  
  purple: {
    backgroundColor: '#673ab7'
  },
  
  indigo: {
    backgroundColor: '#9c27b0'
  },
  
  // States
  disabled: {
    backgroundColor: COLORS.disabled,
    cursor: 'not-allowed',
    opacity: 0.5
  }
};

export const PANEL_STYLES = {
  base: {
    padding: '12px',
    borderRadius: '6px',
    marginBottom: '20px'
  },
  
  info: {
    backgroundColor: '#f0f8ff',
    border: '1px solid #b3d9ff'
  },
  
  warning: {
    backgroundColor: '#fff3cd', 
    border: '1px solid #ffeaa7'
  },
  
  success: {
    backgroundColor: '#e8f5e8',
    border: '1px solid #c8e6c9'
  },
  
  error: {
    backgroundColor: '#ffebee',
    border: '1px solid #ffcdd2'
  },
  
  neutral: {
    backgroundColor: COLORS.lightGray,
    border: `1px solid ${COLORS.borderSecondary}`
  }
};

export const INPUT_STYLES = {
  base: {
    width: '100%',
    padding: '8px 12px',
    border: `1px solid ${COLORS.borderSecondary}`,
    borderRadius: '4px',
    fontSize: '14px',
    backgroundColor: COLORS.white,
    color: COLORS.textPrimary
  }
};

// Helper function to merge styles
export const mergeStyles = (...styles: any[]) => {
  return Object.assign({}, ...styles);
};

// Helper function to create button style
export const createButtonStyle = (type: keyof typeof BUTTON_STYLES, disabled = false) => {
  const baseStyle = BUTTON_STYLES.base;
  const typeStyle = BUTTON_STYLES[type] || {};
  const disabledStyle = disabled ? BUTTON_STYLES.disabled : {};
  
  return mergeStyles(baseStyle, typeStyle, disabledStyle);
};

// Helper function to create panel style  
export const createPanelStyle = (type: keyof typeof PANEL_STYLES) => {
  const baseStyle = PANEL_STYLES.base;
  const typeStyle = PANEL_STYLES[type] || {};
  
  return mergeStyles(baseStyle, typeStyle);
};