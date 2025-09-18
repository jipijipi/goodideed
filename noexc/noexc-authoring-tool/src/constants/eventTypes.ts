// Event types for trigger data actions
// Based on Flutter NotificationType enum and common app events

export interface EventCategory {
  name: string;
  description: string;
  events: EventType[];
}

export interface EventType {
  value: string;
  label: string;
  description: string;
}

// Rive overlay events - animation and visual effects
const RIVE_OVERLAY_EVENTS: EventType[] = [
  {
    value: 'overlay_rive',
    label: 'Show Rive Overlay',
    description: 'Display Rive animation overlay with specified animation'
  },
  {
    value: 'overlay_rive_update',
    label: 'Update Rive Overlay',
    description: 'Update or change the current Rive overlay animation'
  },
  {
    value: 'overlay_rive_hide',
    label: 'Hide Rive Overlay',
    description: 'Hide the currently displayed Rive overlay animation'
  }
];

// Notification management and demonstration events - implemented in ChatService
const NOTIFICATION_EVENTS: EventType[] = [
  {
    value: 'notification_request_permissions',
    label: 'Request Notification Permissions',
    description: 'Request notification permissions from the user'
  },
  {
    value: 'notification_reschedule',
    label: 'Reschedule Notifications',
    description: 'Force reschedule all pending notifications based on current user settings'
  },
  {
    value: 'notification_disable',
    label: 'Disable Notifications',
    description: 'Cancel and disable all scheduled notifications'
  },
  {
    value: 'show_test_notification',
    label: 'Show Test Notification',
    description: 'Display a demo notification to showcase how notifications appear to users'
  }
];

// Task calculation events - used by ChatService for task processing
const TASK_CALCULATION_EVENTS: EventType[] = [
  {
    value: 'refresh_task_calculations',
    label: 'Refresh Task Calculations',
    description: 'Recalculate task status, timing, and deadline information'
  },
  {
    value: 'recalculate_past_deadline',
    label: 'Recalculate Past Deadline',
    description: 'Handle scenarios when task deadline has passed'
  }
];

// Event categories grouped for dropdown organization
export const EVENT_CATEGORIES: EventCategory[] = [
  {
    name: 'Rive Overlays',
    description: 'Animation and visual overlay events',
    events: RIVE_OVERLAY_EVENTS
  },
  {
    name: 'Task Calculations',
    description: 'Task processing and calculation events',
    events: TASK_CALCULATION_EVENTS
  },
  {
    name: 'Notifications',
    description: 'Notification management and demonstration events',
    events: NOTIFICATION_EVENTS
  }
];

// Flat list of all available event types for easy access
export const ALL_EVENT_TYPES: EventType[] = EVENT_CATEGORIES.flatMap(category => category.events);

// Helper function to find event by value
export const findEventByValue = (value: string): EventType | undefined => {
  return ALL_EVENT_TYPES.find(event => event.value === value);
};

// Helper function to check if event is predefined
export const isPreDefinedEvent = (value: string): boolean => {
  return ALL_EVENT_TYPES.some(event => event.value === value);
};