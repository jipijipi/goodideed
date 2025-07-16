import React, { useState } from 'react';

interface HelpContent {
  title: string;
  description: string;
  examples?: string[];
  tips?: string[];
}

interface HelpTooltipProps {
  content: HelpContent;
  children?: React.ReactNode;
}

const HelpTooltip: React.FC<HelpTooltipProps> = ({ content, children }) => {
  const [isVisible, setIsVisible] = useState(false);

  return (
    <div style={{ position: 'relative', display: 'inline-block' }}>
      <span
        onMouseEnter={() => setIsVisible(true)}
        onMouseLeave={() => setIsVisible(false)}
        onClick={() => setIsVisible(!isVisible)}
        style={{
          display: 'inline-block',
          width: '16px',
          height: '16px',
          backgroundColor: '#2196f3',
          color: 'white',
          borderRadius: '50%',
          textAlign: 'center',
          fontSize: '12px',
          lineHeight: '16px',
          cursor: 'pointer',
          marginLeft: '4px',
          userSelect: 'none'
        }}
      >
        ?
      </span>
      
      {isVisible && (
        <div
          style={{
            position: 'absolute',
            top: '20px',
            left: '0',
            zIndex: 1000,
            backgroundColor: 'white',
            border: '1px solid #ddd',
            borderRadius: '6px',
            boxShadow: '0 4px 12px rgba(0,0,0,0.15)',
            padding: '12px',
            minWidth: '280px',
            maxWidth: '400px',
            fontSize: '13px'
          }}
        >
          <div style={{ fontWeight: 'bold', marginBottom: '8px', color: '#333' }}>
            {content.title}
          </div>
          
          <div style={{ marginBottom: '8px', color: '#666', lineHeight: '1.4' }}>
            {content.description}
          </div>
          
          {content.examples && (
            <div style={{ marginBottom: '8px' }}>
              <div style={{ fontWeight: 'bold', marginBottom: '4px', color: '#333' }}>
                Examples:
              </div>
              {content.examples.map((example, index) => (
                <div key={index} style={{ 
                  fontFamily: 'monospace', 
                  fontSize: '12px', 
                  backgroundColor: '#f5f5f5',
                  padding: '2px 4px',
                  borderRadius: '3px',
                  marginBottom: '2px'
                }}>
                  {example}
                </div>
              ))}
            </div>
          )}
          
          {content.tips && (
            <div>
              <div style={{ fontWeight: 'bold', marginBottom: '4px', color: '#333' }}>
                Tips:
              </div>
              <ul style={{ margin: '0', paddingLeft: '16px', color: '#666' }}>
                {content.tips.map((tip, index) => (
                  <li key={index} style={{ marginBottom: '2px' }}>
                    {tip}
                  </li>
                ))}
              </ul>
            </div>
          )}
        </div>
      )}
    </div>
  );
};

export default HelpTooltip;