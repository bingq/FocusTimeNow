# USER_FLOWS.md

## Overview
This document defines key user flows for **FocusTime Now**.  
Flows are grouped by **mode** or **scenario**, so new flows can be added easily in the future without modifying existing ones.

---

## Flow 1: Quick Mode (Default)

### Goal
Allow users to record activities with minimal effort.  

### Steps
1. **Start Activity**  
   - User taps category button (Learning, Sports, Leisure, Waste).  
   - App creates `ActivityEvent` (startAt=now, endAt=nil).  

2. **Ongoing State**  
   - Timeline shows ongoing event.  
   - Banner displays current activity with elapsed time.  

3. **Stop Activity**  
   - User taps **Stop**.  
   - App sets endAt=now, calculates duration.  
   - Timeline updates with finished activity.  

4. **Edit (Optional)**  
   - User may edit title, category, or time.  

### Outcome
- Activity is logged in timeline.  
- Included in daily/weekly summaries.  
- No efficiency ratio calculated.  

---

## Flow 2: Detailed Mode (Optional)

### Goal
Allow users to capture preparation, transition, and core activity for efficiency analysis.  

### Steps
1. **Start Group Session**  
   - User selects "Detailed" option (at start or later via edit).  
   - App creates an `ActivityGroup`.  

2. **Add Sub-Events**  
   - Travel, Running, Travel back, etc.  

3. **Stop Session**  
   - Group ends when last sub-event stops.  
   - App calculates:  
     - Total time  
     - Core activity time  
     - Efficiency ratio (core/total).  

4. **Review**  
   - Timeline shows collapsed view (total + efficiency).  
   - User may expand to see sub-events.  

### Outcome
- Both total and core activity time are visible.  
- Efficiency awareness is reinforced.  

---

## Flow 3: Post-hoc Recording

### Goal
Allow users to log activities after they happened.  

### Steps
1. User taps "Add Activity" from timeline.  
2. Input title, category, start/end times.  
3. Save → activity appears in timeline.  

### Outcome
- Activity included in summaries.  
- Can later be converted to a group if user wants to split into sub-events.  

---

## Flow 4: Summaries & Awareness

### Goal
Provide users with feedback on how time was spent.  

### Steps
1. User switches to **Summary tab**.  
2. App displays:  
   - **Daily summary**: pie chart by category.  
   - **Weekly summary**: stacked bar chart.  
   - Streak counter for goals.  

### Outcome
- User develops awareness of balance and discipline.  
- Reinforced by streaks and achievements.  

---

## Flow 5: Reminders (Future)

### Goal
Nudge users when they spend too much time on "Waste" activities.  

### Steps
1. User starts a Waste activity (e.g., Short Videos).  
2. App tracks elapsed time.  
3. After threshold (e.g., 40 min), app sends gentle notification.  

### Outcome
- User becomes aware of prolonged distraction.  
- Can stop activity or continue consciously.  

---

## Extensibility Notes
- New flows (e.g., Goals, Badges, Sync) can be added as **Flow 6, Flow 7…**  
- Each flow is independent, with **Goal / Steps / Outcome** format.  
- Keeps document modular and easy to extend.