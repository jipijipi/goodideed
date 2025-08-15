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



In effect, here is what a week of notifications would look like for a user (using intensity 1 for simplicity) setting a task on Monday at 11am with Start time at 10:00 and Deadline time at 18:00. His active days are monday to friday : 

Assuming the user never checks in afterward and therefore does not trigger a rescheduling:

User asks to start the NEXT ACTIVE DAY so currentDate points to tuesday in this case :

Monday/present day : No reminders
Tuesday/next active day : Start time encouragements, reminder around 14:00, completion check at deadline time
Wednesday/following active day : Start time encouragements, reminder around 14:00, completion check at deadline time
Thursday/first active day past end date : First comeback notification/reminder
Friday/and following active days past end date : Possibly second comeback notification / all subsequent comeback notifications will depend on what rule we decide
Saturday : Not an active day, no notifications
Sunday : Not an active day, no notifications

User asks to start TODAY so currentDate points to the same day :

Monday/present day : SKIP Start time encouragements (in the past), reminder around 14:00, completion check at deadline time
Tuesday/next active day : Start time encouragements, reminder around 14:00, completion check at deadline time
Wednesday/first active day past end date : First comeback notification/reminder
Thursday/and following active days past end date : Possibly second comeback notification / all subsequent comeback notifications will depend on what rule we decide
Friday/and following active days past end date : Possibly third comeback notification / all subsequent comeback notifications will depend on what rule we decide
Saturday : Not an active day, no notifications
Sunday : Not an active day, no notifications

I want to trigger rive animations in different zones of the screen depending on context. 
1) Rive animations are already used inline in chat bubbles. Start by reviewing how they are implemented, check that they use the correct API as the new version is a major prerelease (rive: ^0.14.0-dev.5)
2) The second of 4 zones for rive animations will be overlaid on top of everything. This zone will be used to display animations like achievements / trophies. These animations will be triggered directly from the script. Explain the best and most straightforward way to achieve it.

Do not code until plan validation

{ "asset": "assets/animations/test-spere.riv", "zone": 3, "align": "center", "fit": "contain", "bindings": { "posx": 100, "posy": 200 } } 

{ "asset": "assets/animations/intro_logo_animated.riv", "autoHideMs": 1800, "align": "center", "fit": "contain", "zone": 2 }
{ "asset": "assets/animations/test-spere.riv", "autoHideMs": 1800, "align": "center", "fit": "contain", "zone": 2 }


The last zone will be very similar to the background zone (3), except that it will sit above the message bubbles but beneath any panel or UI. Animations here will react mostly to actions performed by the user (changing parameters for example). One example would be an animated clock reacting to the user adjusting a slider. Discuss how to best implement it by reusing whats already in place as much as possible. Propose refactoring as you feel necessary. Do not code until plan approval.


{
  "asset": "assets/animations/arm_rig_test.riv",
  "zone": 4,
  "align": "center",
  "fit": "contain",
  "useDataBinding": true,
  "bindings": {
    "hand_x": 300,
    "hand_y": 300
  }
}

{
  "zone": 4,
  "bindings": {
    "hand_x": 250,
    "hand_y": 250
  }
}

TASK SUMMARY
  --------
task : {user.task}
days : {task.activeDays}
start : {task.startTime}
deadline : {task.deadlineTime}
reminders : {task.remindersIntensity}

TASK SUMMARY\n\n--------\n\ntask : {user.task}\n\ndays : {task.activeDays}\n\nstart : {task.startTime}\n\ndeadline : {task.deadlineTime}\n\nreminders : {task.remindersIntensity}