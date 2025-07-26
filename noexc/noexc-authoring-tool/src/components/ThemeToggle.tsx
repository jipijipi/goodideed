import React from 'react';
import { useTheme } from '../context/ThemeContext';

const ThemeToggle: React.FC = () => {
  const { theme, toggleTheme } = useTheme();

  return (
    <button
      onClick={toggleTheme}
      style={{
        position: 'absolute',
        bottom: '20px',
        right: '20px',
        zIndex: 1000,
        background: 'var(--bg-secondary)',
        color: 'var(--text-secondary)',
        border: '1px solid var(--border-secondary)',
        borderRadius: '4px',
        padding: '6px 10px',
        cursor: 'pointer',
        fontFamily: '-apple-system, BlinkMacSystemFont, sans-serif',
        fontWeight: 'normal',
        fontSize: '11px',
        boxShadow: '0 2px 4px rgba(0,0,0,0.1)',
        transition: 'all 0.2s ease',
        opacity: 0.7
      }}
      onMouseEnter={(e) => {
        e.currentTarget.style.opacity = '1';
        e.currentTarget.style.boxShadow = '0 4px 8px rgba(0,0,0,0.15)';
      }}
      onMouseLeave={(e) => {
        e.currentTarget.style.opacity = '0.7';
        e.currentTarget.style.boxShadow = '0 2px 4px rgba(0,0,0,0.1)';
      }}
    >
      {theme === 'light' ? '🌙 Dark' : '☀️ Light'}
    </button>
  );
};

export default ThemeToggle;