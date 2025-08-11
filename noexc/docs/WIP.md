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

1) The input in bubbles is sometimes hard to select, is there a simple way to make it a larger target?
2) Make the input text style identical to the style of the message it creates
3) There is a slim zone next to the device bottom from where bubble come from, is there a way to make the display truely fullscreen with the bubbles coming from the very edge?



I want to introduce the concept of local notifications/reminders to the
  app. Propose a plan to set it up as simply and straightforwardly as
  possible for one reminder per day for now at deadline time. Make sure to
  keep everything notification related modular



rule : 

intensity 1:
    1 at start time
    1 at deadline time
    2 total

intensity 2:
    1 at start time
    2 in between
    1 at deadline time
    4 total

intensity 3:
    1 at start time
    6 in between
    1 at deadline time
    8 total

8 9 10 11 12 13 14 15 16 17 18
1                            1

14 15 16 17 18
1           1


New notifications related triggers need to be added to the script's data action nodes capability
1) Triggers the permission prompt for notifications if not done already
2) Recalculates notification schedule
3) Disable notifications


I want to upgrade the notification system of the app in a logical and straightforward way:
1) Familiarize yourself with the current notification implementation
2) Familiarize yourself with the launch calculations
3) Familiarize yourself with the scripts triggers

4) Propose a logical, lean plan to enhance the notification system and scheduling based on :

Notification Scheduling Logic
1.	On the Day of the Task
	•	Task Start → Send encouraging message at the scheduled start time.
	•	Between Start & Deadline → Send multiple reminders based on the user’s selected reminder intensity.
	•	Deadline → Send a “completion check” notification.
2.	Snooze / Cancellation Rules
	•	Task Completed → Cancel all remaining reminders for that day. (triggered from script)
	•	Task Marked as Pending → Cancel all remaining reminders except the final one. (triggered from script)
3.	After Multiple Consecutive Unchecked Days (2 active days, when task is past end date)
	•	Send occasional “come back” reminders with gradually decreasing intensity over time.

Try to rely on existing calculations and script interactions as much as logically possible, create new concepts and calculations only when missing from existing logic or when there is a risk of clashing values. Do not code until plan approval.

Lets continue planning :

Phase 1) Add multi-stage day schedule : 
    Good plan.
Phase 2) Snooze/cancellation rules via script triggers :
    Task Completed : Is a new event necessary? since declaring completion will already reset the task.currentDate and reschedule future notifications?
    Task Marked Pending : Instead of tracking which notifications to delete, would it be logical to just cancel all reminders and reschedule from the deadline? Discuss
Phase 3) “Come back” reminders after multiple consecutive unchecked days :
    The user will most likely never open the app until the need to send a comeback notification, does the plan account for this or is it dependant on recalculations?
Phase 4) Debug and visibility : 
    Good plan.
Phase 5) Backward-compatible rollout :
    Good plan.

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

A fallback system already exists currently for notifications set to be scheduled in the past, as only a deadline notification exist the fallback reschedules the notification to the next active day. This system needs to be reevaluated in light of the current plan. Do not code until plan approval.