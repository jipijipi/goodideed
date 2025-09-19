# Task Calculation System

## Overview

The task calculation system determines task status based on user's active days, start/deadline times, and current date/time. This system handles four main scheduling scenarios.

## Task Scheduling Scenarios

### 1. IMMEDIATE Start
User sets task on Monday, active for weekdays only, starting the SAME day.

**Behavior Matrix:**
- **Monday before deadline**: no previous task, current task pending
- **Monday after deadline**: no previous task, current task overdue
- **Tuesday before deadline**: previous task overdue, current task pending
- **Tuesday after deadline**: previous task autofailed, current task overdue
- **Wednesday before deadline**: previous task autofailed, current task pending
- **Wednesday after deadline**: previous task autofailed, current task overdue
- **Thursday before deadline**: previous task autofailed, current task pending
- **Thursday after deadline**: previous task autofailed, current task overdue
- **Friday before deadline**: previous task autofailed, current task pending
- **Friday after deadline**: previous task autofailed, current task overdue
- **Saturday/Sunday (any time)**: previous task autofailed, current task set to Monday
- **Next Monday before deadline**: previous task autofailed, current task pending
- **Next Monday after deadline**: previous task autofailed, current task overdue

### 2. POSTPONED Start
User sets task on Monday, active for weekdays only, starting the NEXT active day.

**Behavior Matrix:**
- **Monday (any time)**: no previous task, current task set to Tuesday
- **Tuesday before deadline**: no previous task, current task pending
- **Tuesday after deadline**: no previous task, current task overdue
- **Wednesday before deadline**: previous task overdue, current task pending
- **Wednesday after deadline**: previous task autofailed, current task overdue
- **Thursday before deadline**: previous task autofailed, current task pending
- **Thursday after deadline**: previous task autofailed, current task overdue
- **Friday before deadline**: previous task autofailed, current task pending
- **Friday after deadline**: previous task autofailed, current task overdue
- **Saturday/Sunday (any time)**: previous task autofailed, current task set to Monday
- **Next Monday before deadline**: previous task autofailed, current task pending
- **Next Monday after deadline**: previous task autofailed, current task overdue

### 3. GAPED Start
User sets task on Friday, active for weekdays only, starting the NEXT active day.

**Behavior Matrix:**
- **Friday through Sunday (any time)**: no previous task, current task set to Monday
- **Monday before deadline**: no previous task, current task pending
- **Monday after deadline**: no previous task, current task overdue
- **Tuesday before deadline**: previous task overdue, current task pending
- **Tuesday after deadline**: previous task autofailed, current task overdue
- **Wednesday before deadline**: previous task autofailed, current task pending
- **Wednesday after deadline**: previous task autofailed, current task overdue

### 4. PLANNED Start (Weekend Example)
User sets task on Monday, active for weekends only.

**Behavior Matrix:**
- **Monday through Friday (any time)**: no previous task, current task set to Saturday
- **Saturday before deadline**: no previous task, current task pending
- **Saturday after deadline**: no previous task, current task overdue
- **Sunday before deadline**: previous task overdue, current task pending
- **Sunday after deadline**: previous task autofailed, current task overdue
- **Next Monday before deadline**: previous task autofailed, current task pending
- **Next Monday after deadline**: previous task autofailed, current task overdue

## Session Variables

Computed at launch by SessionService:

### Session Tracking
- `session.visitCount` - Daily visit counter (resets each day)
- `session.totalVisitCount` - Total visits (never resets)
- `session.timeOfDay` - Time period (1=morning, 2=afternoon, 3=evening, 4=night)
- `session.lastVisitDate` - Last visit date (YYYY-MM-DD format)
- `session.firstVisitDate` - First app visit date
- `session.daysSinceFirstVisit` - Days since first visit
- `session.isWeekend` - Boolean for Saturday/Sunday

### Task Status Variables
- `task.currentStatus` - Task status (pending/completed/failed/overdue)
- `task.isActiveDay` - Boolean if today matches scheduled task date + active weekdays
- `task.isBeforeStart` - Boolean if current time < start time
- `task.isInTimeRange` - Boolean if between start and deadline times
- `task.isPastDeadline` - Boolean if current time > deadline

## Data Actions

Variables can be modified through DataAction types:

- **set** - Set any key to a value or template function
- **increment** - Add to numeric values
- **decrement** - Subtract from numeric values
- **reset** - Reset to default value
- **trigger** - Fire events with custom data

## Template Functions

Available for dynamic calculations:

- `TODAY_DATE` - Current date as YYYY-MM-DD
- `NEXT_ACTIVE_DATE` - Next date matching user's active days configuration
- `NEXT_ACTIVE_WEEKDAY` - Weekday number of next active date

## Recalculable Variables

These can be recalculated via SessionService:

- `task.isActiveDay` - Via `sessionService.recalculateActiveDay()`
- `task.isPastDeadline` - Via `sessionService.recalculatePastDeadline()`

## Template Syntax

All user storage keys are available for templates:

### Basic Syntax
- `{key|fallback}` - Basic template with fallback
- `{key:formatter|fallback}` - Template with formatter and fallback

### Available Formatters
- **timeOfDay** - Format time periods (1→"morning", 2→"afternoon", 3→"evening", 4→"night")
- **activeDays** - Format weekday lists ([1,2,3,4,5]→"weekdays", [6,7]→"weekends")
- **intensity** - Format intensity levels (0→"off", 1→"low", 2→"high", 3→"maximum")
- **timePeriod** - Format time strings ("10:00"→"morning deadline", "14:00"→"afternoon deadline")

### Available Storage Keys
- **Session**: session.visitCount, session.timeOfDay, session.isWeekend, etc.
- **User**: user.name, user.task, user.streak, user.isOnboarded, etc.
- **Task**: task.startTime, task.deadlineTime, task.activeDays, task.currentStatus, etc.

## Implementation Notes

See `SessionService` implementation for the core calculation logic. Task status transitions follow the behavior matrices above based on current time relative to user's configured active days and time windows.