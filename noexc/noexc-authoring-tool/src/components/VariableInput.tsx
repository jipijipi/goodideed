import React from 'react';

interface VariableInputProps {
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
  style?: React.CSSProperties;
  onClick?: (e: React.MouseEvent) => void;
}

const VariableInput: React.FC<VariableInputProps> = ({ 
  value, 
  onChange, 
  placeholder, 
  style,
  onClick 
}) => {
  return (
    <input
      type="text"
      value={value}
      onChange={(e) => onChange(e.target.value)}
      onClick={onClick}
      placeholder={placeholder}
      style={{
        width: '100%',
        padding: '8px 12px',
        border: '1px solid #ddd',
        borderRadius: '4px',
        fontSize: '14px',
        outline: 'none',
        ...style
      }}
    />
  );
};

export default VariableInput;