// Example: Inline Documentation System
import React, { useState, useRef, useEffect } from 'react';

interface HelpContent {
  title: string;
  description: string;
  examples?: string[];
  tips?: string[];
  relatedTopics?: string[];
}

interface TooltipProps {
  content: HelpContent;
  children: React.ReactNode;
  position?: 'top' | 'bottom' | 'left' | 'right';
  trigger?: 'hover' | 'click';
}

const Tooltip: React.FC<TooltipProps> = ({ 
  content, 
  children, 
  position = 'top', 
  trigger = 'hover' 
}) => {
  const [isVisible, setIsVisible] = useState(false);
  const [tooltipPosition, setTooltipPosition] = useState({ x: 0, y: 0 });
  const triggerRef = useRef<HTMLDivElement>(null);
  const tooltipRef = useRef<HTMLDivElement>(null);

  const showTooltip = (e: React.MouseEvent) => {
    if (!triggerRef.current) return;
    
    const rect = triggerRef.current.getBoundingClientRect();
    let x = rect.left + rect.width / 2;
    let y = rect.top - 10;
    
    switch (position) {
      case 'bottom':
        y = rect.bottom + 10;
        break;
      case 'left':
        x = rect.left - 10;
        y = rect.top + rect.height / 2;
        break;
      case 'right':
        x = rect.right + 10;
        y = rect.top + rect.height / 2;
        break;
    }
    
    setTooltipPosition({ x, y });
    setIsVisible(true);
  };

  const hideTooltip = () => {
    setIsVisible(false);
  };

  const handleClick = (e: React.MouseEvent) => {
    e.stopPropagation();
    if (trigger === 'click') {
      isVisible ? hideTooltip() : showTooltip(e);
    }
  };

  return (
    <div className="tooltip-container">
      <div
        ref={triggerRef}
        onMouseEnter={trigger === 'hover' ? showTooltip : undefined}
        onMouseLeave={trigger === 'hover' ? hideTooltip : undefined}
        onClick={handleClick}
        className="tooltip-trigger"
      >
        {children}
      </div>
      
      {isVisible && (
        <div
          ref={tooltipRef}
          className={`tooltip-content tooltip-${position}`}
          style={{
            position: 'fixed',
            left: tooltipPosition.x,
            top: tooltipPosition.y,
            zIndex: 1000,
            transform: position === 'top' ? 'translateX(-50%) translateY(-100%)' : 
                      position === 'bottom' ? 'translateX(-50%)' :
                      position === 'left' ? 'translateX(-100%) translateY(-50%)' :
                      'translateY(-50%)'
          }}
        >
          <div className="tooltip-header">
            <h4>{content.title}</h4>
            <button onClick={hideTooltip} className="tooltip-close">×</button>
          </div>
          
          <div className="tooltip-body">
            <p>{content.description}</p>
            
            {content.examples && (
              <div className="tooltip-section">
                <h5>📝 Examples:</h5>
                <ul>
                  {content.examples.map((example, index) => (
                    <li key={index}>
                      <code>{example}</code>
                    </li>
                  ))}
                </ul>
              </div>
            )}
            
            {content.tips && (
              <div className="tooltip-section">
                <h5>💡 Tips:</h5>
                <ul>
                  {content.tips.map((tip, index) => (
                    <li key={index}>{tip}</li>
                  ))}
                </ul>
              </div>
            )}
            
            {content.relatedTopics && (
              <div className="tooltip-section">
                <h5>🔗 Related:</h5>
                <div className="related-topics">
                  {content.relatedTopics.map((topic, index) => (
                    <span key={index} className="related-topic">
                      {topic}
                    </span>
                  ))}
                </div>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
};

// Help content database
const helpContent: Record<string, HelpContent> = {
  dataAction: {
    title: "Data Actions",
    description: "Data Actions modify user data and trigger events. They're invisible to users but essential for tracking progress, scores, and achievements.",
    examples: [
      'Set initial score: type="set", key="user.score", value=0',
      'Increment score: type="increment", key="user.score", value=10',
      'Achievement trigger: type="trigger", event="achievement_unlocked"'
    ],
    tips: [
      "Use 'set' to initialize values",
      "Use 'increment'/'decrement' for counters",
      "Use 'trigger' for events and achievements",
      "Always provide a nextMessageId to continue the flow"
    ],
    relatedTopics: ["Template System", "Event System", "User Data"]
  },
  
  autoroute: {
    title: "Auto-Route Conditions",
    description: "Auto-routes automatically redirect users based on conditions. They're invisible decision points that check user data and route accordingly.",
    examples: [
      'user.score >= 100',
      'session.visitCount > 1',
      'user.level == 5 && user.hasAchievement == true'
    ],
    tips: [
      "Always include a 'default' route as fallback",
      "Use && for AND conditions, || for OR conditions",
      "Check for null values: user.name != null",
      "Conditions are evaluated in order"
    ],
    relatedTopics: ["Condition Builder", "User Data", "Template System"]
  },
  
  crossSequence: {
    title: "Cross-Sequence Navigation",
    description: "Navigate between different conversation sequences using @sequence_id syntax in edge labels.",
    examples: [
      '@tutorial - Jump to tutorial sequence',
      '@onboarding - Jump to onboarding sequence',
      'Continue::next @main - Choice that jumps to main sequence'
    ],
    tips: [
      "Use @sequence_id in edge labels",
      "Group nodes to create sequences",
      "Validate all sequence references before export",
      "Cross-sequence edges are shown in purple"
    ],
    relatedTopics: ["Grouping", "Edge Labels", "Export System"]
  },
  
  templateSystem: {
    title: "Template System",
    description: "Use {key|fallback} syntax to insert dynamic values from user data into your messages.",
    examples: [
      '{user.name|User} - Shows user name or 'User' if not set',
      'Your score is {user.score|0} points!',
      'Welcome back {user.name|there}!'
    ],
    tips: [
      "Use | to provide fallback values",
      "Dot notation works: user.profile.name",
      "Templates work in all text fields",
      "Use session.* for session data"
    ],
    relatedTopics: ["User Data", "Session System", "Data Actions"]
  },
  
  eventSystem: {
    title: "Event System",
    description: "Fire custom events using trigger-type data actions. Events can show achievements, notifications, or trigger other app behaviors.",
    examples: [
      'achievement_unlocked - Show achievement popup',
      'level_up - Trigger level up animation',
      'milestone_reached - Custom milestone event'
    ],
    tips: [
      "Use meaningful event names",
      "Include relevant data in the event payload",
      "Events are handled by the Flutter app",
      "Use for achievements, notifications, and analytics"
    ],
    relatedTopics: ["Data Actions", "Achievement System", "Flutter Integration"]
  }
};

// Helper component for form fields with documentation
const DocumentedField: React.FC<{
  label: string;
  helpKey: string;
  children: React.ReactNode;
}> = ({ label, helpKey, children }) => {
  return (
    <div className="documented-field">
      <div className="field-label">
        <label>{label}</label>
        <Tooltip content={helpContent[helpKey]} position="right">
          <span className="help-icon">?</span>
        </Tooltip>
      </div>
      <div className="field-input">
        {children}
      </div>
    </div>
  );
};

// Context-aware help panel
const HelpPanel: React.FC<{
  currentContext: string;
  onClose: () => void;
}> = ({ currentContext, onClose }) => {
  const [selectedTopic, setSelectedTopic] = useState(currentContext);
  
  return (
    <div className="help-panel">
      <div className="help-header">
        <h3>📚 Help & Documentation</h3>
        <button onClick={onClose}>×</button>
      </div>
      
      <div className="help-content">
        <div className="help-sidebar">
          <h4>Topics</h4>
          <ul className="help-topics">
            {Object.keys(helpContent).map(key => (
              <li 
                key={key}
                className={selectedTopic === key ? 'active' : ''}
                onClick={() => setSelectedTopic(key)}
              >
                {helpContent[key].title}
              </li>
            ))}
          </ul>
        </div>
        
        <div className="help-main">
          {selectedTopic && helpContent[selectedTopic] && (
            <div className="help-article">
              <h2>{helpContent[selectedTopic].title}</h2>
              <p>{helpContent[selectedTopic].description}</p>
              
              {helpContent[selectedTopic].examples && (
                <div className="help-section">
                  <h3>Examples</h3>
                  <div className="examples">
                    {helpContent[selectedTopic].examples!.map((example, index) => (
                      <div key={index} className="example">
                        <code>{example}</code>
                      </div>
                    ))}
                  </div>
                </div>
              )}
              
              {helpContent[selectedTopic].tips && (
                <div className="help-section">
                  <h3>Tips</h3>
                  <ul className="tips">
                    {helpContent[selectedTopic].tips!.map((tip, index) => (
                      <li key={index}>{tip}</li>
                    ))}
                  </ul>
                </div>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

// Usage example in the main app
const ExampleUsage: React.FC = () => {
  const [showHelp, setShowHelp] = useState(false);
  
  return (
    <div className="app-with-help">
      {/* Help button in main UI */}
      <button 
        className="help-button"
        onClick={() => setShowHelp(true)}
      >
        📚 Help
      </button>
      
      {/* Example of documented form field */}
      <DocumentedField label="Data Action Type" helpKey="dataAction">
        <select>
          <option value="set">Set</option>
          <option value="increment">Increment</option>
          <option value="trigger">Trigger</option>
        </select>
      </DocumentedField>
      
      {/* Context-sensitive help */}
      <DocumentedField label="Auto-Route Condition" helpKey="autoroute">
        <input 
          type="text" 
          placeholder="user.score >= 100"
        />
      </DocumentedField>
      
      {/* Help panel */}
      {showHelp && (
        <HelpPanel 
          currentContext="dataAction"
          onClose={() => setShowHelp(false)}
        />
      )}
    </div>
  );
};

export default ExampleUsage;