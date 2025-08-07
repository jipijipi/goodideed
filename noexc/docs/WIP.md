Let's rethink how everything is calculated to make the following behaviors possible : 

1) IMMEDIATE
The user sets his task on Monday, active for *week days only*, starting the *SAME* day.
After setting the task, if the user *FIRST* checks in on :
    Monday before the day deadline : no previous task, current task pending
    Monday after the day deadline : no previous task, current task overdue
    Tuesday before the day deadline : previous task *overdue*, current task pending
    Tuesday after the day deadline: previous task autofailed, current task overdue
    Wednesday before the day deadline : previous task autofailed, current task pending
    Wednesday after the day deadline : previous task autofailed, current task overdue
    Thursday before the day deadline : previous task autofailed, current task pending
    Thursday after the day deadline: previous task autofailed, current task overdue
    Friday before the day deadline : previous task autofailed, current task pending
    Friday after the day deadline : previous task autofailed, current task overdue
    Saturday before the day deadline : previous task autofailed, current task set to monday
    Saturday after the day deadline: previous task autofailed, current task set to monday
    Sunday before the day deadline : previous task autofailed, current task set to monday
    Sunday after the day deadline : previous task autofailed, current task set to monday
    Next Monday before the day deadline : previous task autofailed, current task pending
    Next Monday after the day deadline : previous task autofailed, current task overdue
    ...

2) POSTPONED
The user sets his task on Monday, active for *week days only*, starting the *NEXT* active day.
After setting the task, if the user *FIRST* checks in on :
    Monday before the day deadline : no previous task, current task set to tuesday
    Monday after the day deadline : no previous task, current task set to tuesday
    Tuesday before the day deadline : no previous task, current task pending
    Tuesday after the day deadline : no previous task, current task overdue
    Wednesday before the day deadline : previous task *overdue*, current task pending
    Wednesday after the day deadline: previous task autofailed, current task overdue
    Thursday before the day deadline : previous task autofailed, current task pending
    Thursday after the day deadline : previous task autofailed, current task overdue
    Friday before the day deadline : previous task autofailed, current task pending
    Friday after the day deadline: previous task autofailed, current task overdue
    Saturday before the day deadline : previous task autofailed, current task set to monday
    Saturday after the day deadline: previous task autofailed, current task set to monday
    Sunday before the day deadline : previous task autofailed, current task set to monday
    Sunday after the day deadline : previous task autofailed, current task set to monday
    Next Monday before the day deadline : previous task autofailed, current task pending
    Next Monday after the day deadline : previous task autofailed, current task overdue
    ...
  
3) GAPED
The user sets his task on Friday, active for *week days only*, starting the *NEXT* active day.
After setting the task, if the user *FIRST* checks in on :
    Friday before the day deadline : no previous task, current task set to monday
    Friday after the day deadline : no previous task, current task set to monday
    Saturday before the day deadline : no previous task, current task set to monday
    Saturday after the day deadline: no previous task, current task set to monday
    Sunday before the day deadline : no previous task, current task set to monday
    Sunday after the day deadline : no previous task, current task set to monday
    Monday before the day deadline : no previous task, current task pending
    Monday after the day deadline : no previous task, current task overdue
    Tuesday before the day deadline : previous task *overdue*, current task pending
    Tuesday after the day deadline: previous task autofailed, current task overdue
    Wednesday before the day deadline : previous task autofailed, current task pending
    Wednesday after the day deadline : previous task autofailed, current task overdue
    ...

4) PLANNED
The user sets his task on Monday, active for *weekends only*.
After setting the task, if the user *FIRST* checks in on :
    Monday before the day deadline : no previous task, current task set to saturday
    Monday after the day deadline : no previous task, current task set to saturday
    Tuesday before the day deadline : no previous task, current task set to saturday
    Tuesday after the day deadline: no previous task, current task set to saturday
    Wednesday before the day deadline : no previous task, current task set to saturday
    Wednesday after the day deadline : no previous task, current task set to saturday
    Thursday before the day deadline : no previous task, current task set to saturday
    Thursday after the day deadline: no previous task, current task set to saturday
    Friday before the day deadline : no previous task, current task set to saturday
    Friday after the day deadline : no previous task, current task set to saturday
    Saturday before the day deadline : no previous task, current task pending
    Saturday after the day deadline: no previous task, current task overdue
    Sunday before the day deadline : previous task *overdue*, current task pending
    Sunday after the day deadline: previous task autofailed, current task overdue
    Next Monday before the day deadline : previous task autofailed, current task pending
    Next Monday after the day deadline : previous task autofailed, current task overdue


1) Variables computed at launch (SessionService:11-20)

  Session Variables:
  - session.visitCount - Daily visit counter (resets each day)
  - session.totalVisitCount - Total visits (never resets)
  - session.timeOfDay - Time period (1=morning, 2=afternoon, 3=evening,
  4=night)
  - session.lastVisitDate - Last visit date (YYYY-MM-DD format)
  - session.firstVisitDate - First app visit date
  - session.daysSinceFirstVisit - Days since first visit
  - session.isWeekend - Boolean for Saturday/Sunday

  Task Variables:
  - task.currentStatus - Task status (pending/completed/failed/overdue)
  - task.isActiveDay - Boolean if today matches scheduled task date +
  active weekdays
  - task.isBeforeStart - Boolean if current time < start time
  - task.isInTimeRange - Boolean if between start and deadline times
  - task.isPastDeadline - Boolean if current time > deadline

  2) Variables that can be computed from script triggers (DataAction)

  DataAction Types:
  - set - Set any key to a value or template function
  - increment - Add to numeric values
  - decrement - Subtract from numeric values
  - reset - Reset to default value
  - trigger - Fire events with custom data

  Template Functions Available:
  - TODAY_DATE - Current date as YYYY-MM-DD
  - NEXT_ACTIVE_DATE - Next date matching user's active days configuration
  - NEXT_ACTIVE_WEEKDAY - Weekday number of next active date

  Recalculable Variables:
  - task.isActiveDay - Via sessionService.recalculateActiveDay()
  - task.isPastDeadline - Via sessionService.recalculatePastDeadline()

  3) Templated functions available from script

  Template Syntax:
  - {key|fallback} - Basic template with fallback
  - {key:formatter|fallback} - Template with formatter and fallback

  Available Formatters:
  - timeOfDay - Format time periods (1→"morning", 2→"afternoon",
  3→"evening", 4→"night")
  - activeDays - Format weekday lists ([1,2,3,4,5]→"weekdays",
  [6,7]→"weekends")
  - intensity - Format intensity levels (0→"off", 1→"low", 2→"high",
  3→"maximum")
  - timePeriod - Format time strings ("10:00"→"morning deadline",
  "14:00"→"afternoon deadline")

  All User Storage Keys Available for Templates:
  - Session: session.visitCount, session.timeOfDay, session.isWeekend, etc.
  - User: user.name, user.task, user.streak, user.isOnboarded, etc.
  - Task: task.startTime, task.deadlineTime, task.activeDays,
  task.currentStatus, etc.

  

flutter test --machine | dart tool/test_failure_extractor.dart > failures.json

