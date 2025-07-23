// Flutter Project Sync Utility
// Reads Flutter Dart files and extracts variable definitions

export interface FlutterVariable {
  key: string;
  type: 'string' | 'number' | 'boolean' | 'object';
  defaultValue?: any;
  description: string;
  category: 'user' | 'session' | 'system' | 'achievement' | 'custom';
  readonly: boolean;
  source: string; // Which Flutter file it came from
}

export interface FlutterSyncResult {
  variables: FlutterVariable[];
  errors: string[];
  lastSync: string;
  sourceFiles: string[];
}

// Parse Dart constant declarations
const parseDartConstants = (content: string, filename: string): FlutterVariable[] => {
  const variables: FlutterVariable[] = [];
  const lines = content.split('\n');
  
  // Patterns to match Dart constants
  const patterns = [
    // static const String USER_NAME = 'user.name';
    /static\s+const\s+String\s+(\w+)\s*=\s*['"]([\w.]+)['"];?\s*(?:\/\/\s*(.*))?/,
    // static const String userNameKey = 'user.name';
    /static\s+const\s+String\s+(\w+Key)\s*=\s*['"]([\w.]+)['"];?\s*(?:\/\/\s*(.*))?/,
    // const String USER_SCORE = 'user.score';
    /const\s+String\s+(\w+)\s*=\s*['"]([\w.]+)['"];?\s*(?:\/\/\s*(.*))?/,
  ];

  lines.forEach((line, index) => {
    patterns.forEach(pattern => {
      const match = line.trim().match(pattern);
      if (match) {
        const [, constantName, variableKey, comment] = match;
        
        // Determine category from key prefix
        let category: FlutterVariable['category'] = 'custom';
        if (variableKey.startsWith('user.')) category = 'user';
        else if (variableKey.startsWith('session.')) category = 'session';
        else if (variableKey.startsWith('system.')) category = 'system';
        else if (variableKey.startsWith('achievement.')) category = 'achievement';

        // Determine type from key suffix or context
        let type: FlutterVariable['type'] = 'string';
        if (variableKey.includes('count') || variableKey.includes('score') || variableKey.includes('level')) {
          type = 'number';
        } else if (variableKey.includes('is') || variableKey.includes('has') || variableKey.includes('can')) {
          type = 'boolean';
        }

        variables.push({
          key: variableKey,
          type,
          description: comment || `${constantName} from ${filename}`,
          category,
          readonly: true, // Flutter constants are readonly
          source: `${filename}:${index + 1}`
        });
      }
    });
  });

  return variables;
};

// Parse Flutter model classes for properties
const parseModelClasses = (content: string, filename: string): FlutterVariable[] => {
  const variables: FlutterVariable[] = [];
  const lines = content.split('\n');
  
  let currentClass = '';
  let inClass = false;
  
  lines.forEach((line, index) => {
    const trimmed = line.trim();
    
    // Detect class declarations
    const classMatch = trimmed.match(/class\s+(\w+)\s*{?/);
    if (classMatch) {
      currentClass = classMatch[1];
      inClass = true;
      return;
    }
    
    // End of class
    if (trimmed === '}' && inClass) {
      inClass = false;
      currentClass = '';
      return;
    }
    
    if (inClass && currentClass) {
      // Match property declarations
      const propertyPatterns = [
        // String? name;
        /(\w+)\?\s+(\w+);?\s*(?:\/\/\s*(.*))?/,
        // final String name;
        /final\s+(\w+)\s+(\w+);?\s*(?:\/\/\s*(.*))?/,
        // late String name;
        /late\s+(\w+)\s+(\w+);?\s*(?:\/\/\s*(.*))?/,
      ];

      propertyPatterns.forEach(pattern => {
        const match = trimmed.match(pattern);
        if (match) {
          const [, dartType, propertyName, comment] = match;
          
          // Convert Dart types to our types
          let type: FlutterVariable['type'] = 'string';
          if (dartType.toLowerCase().includes('int') || dartType.toLowerCase().includes('double')) {
            type = 'number';
          } else if (dartType.toLowerCase().includes('bool')) {
            type = 'boolean';
          } else if (dartType.toLowerCase().includes('map') || dartType.toLowerCase().includes('list')) {
            type = 'object';
          }

          // Generate key based on class and property
          const key = `${currentClass.toLowerCase()}.${propertyName}`;
          
          // Determine category
          let category: FlutterVariable['category'] = 'custom';
          if (currentClass.toLowerCase().includes('user')) category = 'user';
          else if (currentClass.toLowerCase().includes('session')) category = 'session';
          else if (currentClass.toLowerCase().includes('system')) category = 'system';

          variables.push({
            key,
            type,
            description: comment || `${propertyName} property from ${currentClass} class`,
            category,
            readonly: false,
            source: `${filename}:${index + 1}`
          });
        }
      });
    }
  });

  return variables;
};

// Main sync function - reads Flutter files and extracts variables
export const syncFromFlutterProject = async (flutterProjectPath: string): Promise<FlutterSyncResult> => {
  const result: FlutterSyncResult = {
    variables: [],
    errors: [],
    lastSync: new Date().toISOString(),
    sourceFiles: []
  };

  try {
    // Define Flutter files to scan
    const filesToScan = [
      'lib/constants/storage_keys.dart',
      'lib/constants/app_constants.dart', 
      'lib/constants/session_constants.dart',
      'lib/constants/data_action_constants.dart',
      'lib/models/chat_message.dart',
      'lib/models/choice.dart',
      'lib/models/data_action.dart',
      'lib/services/user_data_service.dart',
      'lib/services/session_service.dart'
    ];

    for (const filePath of filesToScan) {
      try {
        const fullPath = `${flutterProjectPath}/${filePath}`;
        
        // In a real implementation, you'd use Node.js fs to read files
        // For now, we'll simulate with predefined content
        const content = await readFlutterFile(fullPath);
        
        if (content) {
          result.sourceFiles.push(filePath);
          
          // Parse constants
          const constants = parseDartConstants(content, filePath);
          result.variables.push(...constants);
          
          // Parse model classes if it's a model file
          if (filePath.includes('/models/')) {
            const modelVars = parseModelClasses(content, filePath);
            result.variables.push(...modelVars);
          }
        }
      } catch (error) {
        result.errors.push(`Failed to read ${filePath}: ${error}`);
      }
    }

    // Remove duplicates based on key
    const uniqueVariables = new Map<string, FlutterVariable>();
    result.variables.forEach(variable => {
      if (!uniqueVariables.has(variable.key)) {
        uniqueVariables.set(variable.key, variable);
      }
    });
    result.variables = Array.from(uniqueVariables.values());

  } catch (error) {
    result.errors.push(`Sync failed: ${error}`);
  }

  return result;
};

// Simulated file reader - in real implementation, use Node.js fs
const readFlutterFile = async (filePath: string): Promise<string | null> => {
  // This would be replaced with actual file reading in a Node.js environment
  // For browser-based demo, we'll return predefined content
  
  const mockFiles: { [key: string]: string } = {
    'lib/constants/storage_keys.dart': `
// Storage Keys for SharedPreferences
class StorageKeys {
  // User data keys
  static const String USER_NAME = 'user.name';
  static const String USER_SCORE = 'user.score'; // User's current score
  static const String USER_LEVEL = 'user.level'; // Current level
  static const String USER_STREAK = 'user.streak'; // Daily streak count
  static const String USER_IS_ONBOARDED = 'user.isOnboarded'; // Has completed onboarding
  
  // Session data keys  
  static const String SESSION_VISIT_COUNT = 'session.visitCount'; // Daily visits
  static const String SESSION_TOTAL_VISITS = 'session.totalVisitCount'; // All-time visits
  static const String SESSION_FIRST_VISIT = 'session.firstVisit'; // First visit date
  static const String SESSION_LAST_VISIT = 'session.lastVisit'; // Last visit date
  
  // Task management
  static const String TASK_CURRENT = 'task.current'; // Current daily task
  static const String TASK_DEADLINE = 'task.deadline'; // Task deadline
  static const String TASK_IS_COMPLETED = 'task.isCompleted'; // Task completion status
  static const String TASK_COMPLETION_DATE = 'task.completionDate'; // When task was completed
}`,
    
    'lib/constants/session_constants.dart': `
// Session-related constants
class SessionConstants {
  // Time of day detection
  static const String TIME_OF_DAY = 'session.timeOfDay'; // morning, afternoon, evening, night
  static const String IS_WEEKEND = 'session.isWeekend'; // Weekend detection
  static const String CURRENT_DATE = 'session.currentDate'; // Current date string
  
  // Achievement tracking
  static const String ACHIEVEMENT_POINTS = 'achievement.points'; // Total achievement points
  static const String ACHIEVEMENT_BADGES = 'achievement.badges'; // Earned badges
  static const String ACHIEVEMENT_MILESTONES = 'achievement.milestones'; // Reached milestones
}`,

    'lib/models/chat_message.dart': `
// Chat message model
class ChatMessage {
  final String? text; // Message text content
  final String sender; // 'bot' or 'user'
  final String? storeKey; // Key for storing user input
  final List<Choice>? choices; // Available choices
  final bool? isCompleted; // Message completion status
  final DateTime? timestamp; // Message timestamp
}`,

    'lib/services/user_data_service.dart': `
// User data management service
class UserDataService {
  // System variables
  static const String SYSTEM_VERSION = 'system.version'; // App version
  static const String SYSTEM_PLATFORM = 'system.platform'; // Platform info
  static const String SYSTEM_LOCALE = 'system.locale'; // User locale
  
  // User preferences
  static const String USER_THEME = 'user.theme'; // UI theme preference
  static const String USER_NOTIFICATIONS = 'user.notifications'; // Notification settings
  static const String USER_SOUND_ENABLED = 'user.soundEnabled'; // Sound preference
}`
  };

  // Extract filename from path for lookup
  const filename = filePath.split('/').pop() || '';
  const key = Object.keys(mockFiles).find(k => k.includes(filename));
  
  return key ? mockFiles[key] : null;
};

// Export shared configuration format
export const generateSharedConfig = (variables: FlutterVariable[]) => {
  const config = {
    version: '1.0.0',
    lastUpdated: new Date().toISOString(),
    source: 'Flutter Project Sync',
    variables: variables.reduce((acc, variable) => {
      acc[variable.key] = {
        type: variable.type,
        defaultValue: variable.defaultValue,
        description: variable.description,
        category: variable.category,
        readonly: variable.readonly,
        source: variable.source
      };
      return acc;
    }, {} as Record<string, any>)
  };

  return config;
};