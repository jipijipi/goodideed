Analysis and Recommendation for Task Start Timing Choice                                        │
     │                                                                                                 │
     │ Current Flow Analysis:                                                                          │
     │ 1. settask_seq → deadline_seq → weekdays_seq → reminders_seq → sendoff_seq                      │
     │ 2. Currently, tasks automatically start on the current date when set via                        │
     │ SessionService._updateTaskInfo()                                                                │
     │ 3. No existing mechanism to defer task start to next active day                                 │
     │                                                                                                 │
     │ Optimal Placement: Between weekdays_seq and reminders_seq                                       │
     │                                                                                                 │
     │ Recommended Approach: Script-Based Implementation                                               │
     │                                                                                                 │
     │ Why Script Over Code:                                                                           │
     │                                                                                                 │
     │ 1. Consistency: Maintains the existing sequence-driven conversation flow                        │
     │ 2. Flexibility: Easy to modify messaging and logic without code changes                         │
     │ 3. User Experience: Natural conversation flow with contextual choices                           │
     │ 4. Testability: Can be tested via debug scenarios and authoring tool                            │
     │                                                                                                 │
     │ Implementation Plan:                                                                            │
     │                                                                                                 │
     │ 1. Create new sequence: task_start_timing_seq.json                                              │
     │   - Insert between weekdays_seq (message 46) and reminders_seq                                  │
     │   - Include conditional logic based on task.isActiveDay                                         │
     │   - Store choice in new field: task.startTiming ("today" | "next_active")                       │
     │ 2. Add storage key: taskStartTiming in StorageKeys.dart                                         │
     │ 3. Extend SessionService logic:                                                                 │
     │   - Check task.startTiming during task initialization                                           │
     │   - If "next_active", set task.currentDate to next active day instead of today                  │
     │   - Add helper method _getNextActiveDay() to calculate next active date                         │
     │ 4. Update sequence navigation:                                                                  │
     │   - Modify weekdays_seq message 46 to route to task_start_timing_seq                            │
     │   - Route from timing choice to reminders_seq                                                   │
     │                                                                                                 │
     │ This approach preserves the conversational UX while adding the needed functionality through the │
     │ existing, well-tested sequence system. 


I want a smarter resizing for groups
1) Suggest a way to calculate an appropriate size based on the group's children
2) Would it be possible/advisable to recalculate the parent's group size on each children node move?

The node colors and styling are mostly gone, suggest a simple way to centralize styling of the authoring tool