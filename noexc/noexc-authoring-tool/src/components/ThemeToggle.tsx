import React from 'react';
import { useTheme } from '../context/ThemeContext';

const ThemeToggle: React.FC = () => {
  const { theme, toggleTheme } = useTheme();

  return (
    <button
      onClick={toggleTheme}
      style={{
        position: 'absolute',
        top: '10px',
        right: '10px',
        zIndex: 1000,
        background: 'var(--bg-panel)',
        color: 'var(--text-primary)',
        border: '2px solid var(--border-primary)',
        borderRadius: '0',
        padding: '8px 12px',
        cursor: 'pointer',
        fontFamily: 'Courier New, monospace',
        fontWeight: 'bold',
        fontSize: '12px',
        boxShadow: '3px 3px 0px var(--border-primary)',
        transition: 'all 0.2s ease'
      }}
      onMouseEnter={(e) => {
        e.currentTarget.style.transform = 'translate(-2px, -2px)';
        e.currentTarget.style.boxShadow = '5px 5px 0px var(--border-primary)';
      }}
      onMouseLeave={(e) => {
        e.currentTarget.style.transform = 'translate(0, 0)';
        e.currentTarget.style.boxShadow = '3px 3px 0px var(--border-primary)';
      }}
    >
      {theme === 'light' ? '🌙 Dark' : '☀️ Light'}
    </button>
  );
};

export default ThemeToggle;