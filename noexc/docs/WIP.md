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

{
    "asset": "assets/animations/radial_range_test.riv",
    "zone": 4,
    "align": "center",
    "fit": "contain",
    "useDataBinding": true,
    "bindings": { "start": 0, "end":0 }
  }

  {
  "type": "trigger",
  "key": "fx",
  "event": "overlay_rive_update",
  "data": {
    "zone": 4,
    "bindings": { "start": "{task.deadlineTime}", "end":"{task.startTime}" }
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



{
  "asset": "assets/animations/radial_range_test.riv",
  "zone": 4,
  "align": "center",
  "id": "clock",
  "policy": "ignore",
  "fit": "contain",
  "useDataBinding": true,
  "bindings": {
    "start": 0,
    "end": 0
  }
}
{
  "asset": "assets/animations/throttle_test.riv",
  "zone": 4,
  "align": "center",
  "id": "throttle",
  "policy": "ignore",
  "fit": "contain",
  "useDataBinding": true,
  "bindings": {
    "level": 0
  }
}

{
  "zone": 4,
  "id": "clock",
  "bindings": {
    "start": "{task.deadlineTime}",
    "end": "{task.startTime}"
  }
}
{
  "zone": 4,
  "id": "throttle",
  "bindings": {
    "level": "{task.remindersIntensity}"
  }
}
{
  "zone": 4,
  "id": "throttle",
  "autoHideMs": 1000
}

{
  "zone": 4,
  "id": "calendar",
  "autoHideMs": 1000
}
{
  "zone": 4,
  "id": "calendar",
  "bindings": {
    "monday": "{session.mon_active}",
    "tuesday": "{session.tue_active}",
    "wednesday": "{session.wed_active}",
    "thursday": "{session.thu_active}",
    "friday": "{session.fri_active}",
    "saturday": "{session.sat_active}",
    "sunday": "{session.sun_active}"
  }
}


{
  "asset": "assets/animations/calendar.riv",
  "zone": 4,
  "align": "center",
  "id": "calendar",
  "policy": "ignore",
  "fit": "contain",
  "useDataBinding": true,
  "bindings": {
    "monday": "{session.mon_active}",
    "tuesday": "{session.tue_active}",
    "wednesday": "{session.wed_active}",
    "thursday": "{session.thu_active}",
    "friday": "{session.fri_active}",
    "saturday": "{session.sat_active}",
    "sunday": "{session.sun_active}"
  }
}

  {
    "asset": "assets/animations/tristopher_simple.riv",
    "zone": 4,
    "id": "success",
    "policy": "queue",
    "minShowMs": 1000,
    "autoHideMs": 1200
  }


  ----

  Here’s a safe, straightforward, logical refactor plan focused on clarifying resp
onsibilities, reducing branching paths, and tightening test seams. I’ve ordered
it to deliver quick wins first, then consolidate flow control, and finally consi
der bigger changes. Each step is independently testable and can land without bre
aking the app.

**Quick Wins (Low Risk)**
- Dead code trim: Remove `SequenceLoader.createUserResponseMessage` (ChatService
 already owns this). Tests: search usage, keep `ChatService.createUserResponseMe
ssage` tests green.
- Centralize text unescape: Move `_unescapeTextForMarkdown` into `FormatterServi
ce` and call it from `MessageProcessor`. Tests: unit for escaping edge cases; Me
ssageProcessor snapshot tests unchanged.
- Single entrypoints: Add `ChatService.start(sequenceId)` and `ChatService.conti
nueFrom(messageId)` that return `FlowResponse`. Keep current wrappers (`getIniti
alMessages`, `getMessagesAfter*`) delegating. Tests: service-level happy-path +
“awaiting interaction” cases.
- Renderer contract: Document and enforce that display filtering (autoroute/data
Action) happens only in `MessageRenderer`. Keep UI’s “empty text” filter for now
 but mark for review. Tests: renderer filters everything correctly; UI still gre
en.
- Asset guardrails: Strengthen validators to assert invariants already intended
by code (interactive messages have empty text, autoroute/dataAction have empty t
ext, image type rules). Tests: validation unit tests on samples.
- Observability: Add a single “flow trace” log per flow step in `FlowOrchestrato
r` (cycle count, stop reason, next action). Tests: quiet by default; assert mess
age presence via `LoggerService` in test mode.

**Flow Consolidation (Medium Risk, Clear Wins)**
- One place to continue flow: Introduce `ChatService.applyChoiceAndContinue(mess
age, choice)` and `applyTextAndContinue(message, text)` that both: store data, r
un orchestrator, handle routes/sequence transitions, and return `FlowResponse`.
Tests: service-level for both paths, including route to new sequence.
- Move sequence switching out of UI: Update `UserInteractionHandler` to call the
 new ChatService APIs and only display `FlowResponse.messages`. Remove `_switchT
oSequenceFromChoice`, `_continueWithChoice`, `_continueWithTextInput`. Tests: wi
dget tests remain green; add one asserting no duplication when sequence changes.
- Route authority: Keep all route decisions inside `RouteProcessor` and flow tra
nsitions inside `FlowOrchestrator`. UI no longer decides routing. Tests: route p
rocessor with conditional/default routes, including `sequenceId` routes.
- Clear continuation contract: Expose `FlowResponse` at UI boundaries (now and f
or future). Tests: chat service returns `requiresUserInteraction` with correct `
interactionMessageId`.
- Safety limit clarity: Surface `_maxProcessingCycles` limit via config for test
 tuning and add test asserting loop cap behavior without recursion.

**Data & Content Simplifications (Targeted, Optional if not used)**
- Variants deprecation: If sequences now rely on `contentKey`, mark `TextVariant
sService` as deprecated in `MessageProcessor` (keep fallback for now; add a feat
ure flag to disable). Tests: one path with variants on; one with contentKey; con
tentKey takes precedence.
- Choice value parsing: Extract JSON-array parsing and coercion from `MessagePro
cessor` into a small helper (or reuse `DataActionProcessor` patterns) to unify b
ehavior. Tests: choice values parsed to lists and ints correctly.

**Bigger, High-Value Changes (Breaking, Worth Doing Early)**
- Flow API as a facade: Add a thin `FlowFacade` (or promote `FlowOrchestrator` A
PI via `ChatService`) as the single UI gateway: `start`, `applyChoice`, `applyTe
xt`, `continueFrom`. Deprecate `getMessagesAfter*` once UI migrates. Tests: serv
ice integration tests only target facade.
- Stronger types for messages: Make `ChatMessage` a sealed hierarchy (`BotMessag
e`, `UserMessage`, `ChoiceMessage`, `TextInputMessage`, `AutoRouteMessage`, `Dat
aActionMessage`, `ImageMessage`). Eliminates runtime asserts and type confusion.
 Keep JSON `type` as discriminator. Tests: fromJson/toJson roundtrips; renderer/
walker filters via types.
- Route unification (optional): Eliminate the little-used `message.sequenceId` b
oundary concept entirely and rely on explicit `autoroute` with `routes[]` or cho
ice routing. Add an asset migration validator + fixer. Tests: assets validation;
 route processor remains the single sequence switch path.

**Testing Additions (Per Step)**
- Service-level: `FlowOrchestrator` cycles, stop reasons, autoroute, data action
s, sequence transitions, and “awaiting interaction”.
- Renderer-level: filter-only + multi-text expansion behavior.
- UI-level: `UserInteractionHandler` uses new service methods; AnimatedList cons
istency remains intact.
- Validation-level: asset rules for message types and fields.
- Regression: “no duplicate non-empty messages when switching sequences”, “insta
nt vs adaptive delays” unaffected.

**Why this plan**
- Safe: Each change is additive or internal first, with deprecations rather than
 removals, and backed by targeted tests.
- Straightforward: Responsibilities are clarified without introducing new concep
ts; UI stops making flow decisions.
- Logical: Flow decisions centralize in flow layer; ChatService becomes the faca
de; models and content handling become simpler and more explicit.

Would you like me to proceed with Phase 1 (Quick Wins) first and draft the minim
al tests to accompany each step?

**Phase 1 — Quick Wins**
- Centralize Unescape: Move JSON/markdown unescape into `FormatterService`; use
from `MessageProcessor`.
  - Tests: unit for escape cases; MessageProcessor snapshot unchanged.
  - Depends on: none. Obsoletes: private `_unescapeTextForMarkdown`.
- Flow Trace Logs: Add one compact trace per cycle in `FlowOrchestrator` (cycle,
 stop reason, next action).
  - Tests: assert via `LoggerService` in test mode; default quiet.
  - Depends on: none. Obsoletes: scattered debug lines.
- Renderer Contract Check: Ensure only `MessageRenderer` filters `autoroute/data
Action`; keep UI “empty text” filter (to be removed later).
  - Tests: renderer filters; UI still green.
  - Depends on: none. Obsoletes later: UI empty-text filter (Phase 5).
- Asset Guards: Strengthen validators to enforce type/text invariants (choice/te
xtInput/autoroute/dataAction must have empty text; image rules).
  - Tests: validator samples for pass/fail.
  - Depends on: none. Reduced importance later after sealed types.
- Trim Redundancy: Remove `SequenceLoader.createUserResponseMessage`; keep `Chat
Service.createUserResponseMessage`.
  - Tests: existing ChatService creation tests green.
  - Depends on: none.

**Phase 2 — Flow Consolidation**
- Start/Resume Facade: Add `ChatService.start(sequenceId)` and `continueFrom(mes
sageId)` returning `FlowResponse`.
  - Tests: happy path; awaiting interaction case.
  - Depends on: Flow orchestrator; no UI changes yet.
- Unified Apply APIs: Add `ChatService.applyChoiceAndContinue(...)` and `applyTe
xtAndContinue(...)` (store + orchestrate + return `FlowResponse`).
  - Tests: choice/text paths including sequence route.
  - Depends on: Phase 2 start/resume; makes `getMessagesAfter*` wrappers legacy.
- UI Uses Facade: Update `UserInteractionHandler` to call new apply APIs and dis
play `FlowResponse.messages`; remove `_switchToSequenceFromChoice/_continue*`.
  - Tests: no duplicates on sequence switch; AnimatedList consistency.
  - Depends on: unified apply APIs. Obsoletes: those private UI helpers.
- Cycle Limit Config: Surface `_maxProcessingCycles` via config for tests.
  - Tests: cap behavior without recursion.
  - Depends on: none.

**Phase 3 — Data & Content Simplifications**
- Variants Feature Flag: Prioritize `contentKey`; gate `TextVariantsService` wit
h a flag (default enabled for now).
  - Tests: both paths; precedence of `contentKey`.
  - Depends on: none. Enables later removal.
- Choice Value Helper: Extract choice value parse/coercion (JSON arrays, ints) i
nto shared helper (align with `DataActionProcessor` behavior).
  - Tests: parse/coerce cases.
  - Depends on: none.

**Phase 4 — Breaking Improvements (staged to avoid app breakage)**
- Sealed Message Types (Stage 1): Introduce sealed hierarchy alongside current `
ChatMessage`; add mappers to/from legacy model; keep JSON “type” as discriminato
r.
  - Tests: roundtrip JSON; adapter correctness.
  - Depends on: none. Does not break app yet.
- Sealed Types Adoption (Stage 2): Convert renderer/walker/processor to operate
on sealed types behind adapters; keep legacy boundary shims.
  - Tests: regression across flow; renderer filtering by type.
  - Depends on: Stage 1. Obsoletes: runtime asserts on `ChatMessage`.
- Route Unification (Stage 1): Validator flags use of `message.sequenceId` bound
ary; add authoring guidance to prefer `autoroute.routes`.
  - Tests: validator coverage.
  - Depends on: none.
- Route Unification (Stage 2): Migrate sequences to explicit `autoroute`; Orches
trator supports both during transition; Walker de-emphasizes sequenceId boundary
 (warn only).
  - Tests: mixed assets; ensure flow correctness.
  - Depends on: Stage 1 validator. Obsoletes later: walker’s sequenceId stop con
dition.

**Phase 5 — Cleanup**
- Deprecation Removal: Remove `getMessagesAfter*` wrappers, UI empty-text filter
, `TextVariantsService` (if flag disabled and usage removed), legacy `ChatMessag
e` path.
  - Tests: update callers to facade; ensure no regressions.
  - Depends on: Phases 2–4 adoption.
- Validator Simplification: Drop checks now enforced by sealed types; keep conte
nt-level validations.
  - Tests: updated validator suite.
  - Depends on: sealed types fully adopted.

If this looks good, I’ll start with Phase 1 (Centralize Unescape, Flow Trace Log
s, Renderer Contract Check, Asset Guards, Trim Redundancy) and draft focused tes
ts for each.