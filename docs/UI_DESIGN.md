# UI_DESIGN.md

## Overview
This document defines the main UI layouts for **FocusTime Now**.  
The design is modular: each screen is described independently so new features can be added without breaking existing structure.  

Core design principle: **simple, convenient, and extensible.**

---

## 1. Timeline View (Home Screen)

### Purpose
- Show chronological list of activities.  
- Allow user to quickly start/stop logging.  
- Display current ongoing activity.  

### Layout (ASCII Wireframe)

    -------------------------------------
    |  Timeline (Today)                 |
    -------------------------------------
    |  07:30 – 07:50  Travel to gym [T] |
    |  07:50 – 08:30  Running      [S]  |
    |  08:30 – 08:40  Travel back  [T]  |
    |  08:40 – 09:10  Reading      [L]  |
    |  09:10 – Now    Short Videos [W]  |
    -------------------------------------
    |  Current: Short Videos [Waste]    |
    -------------------------------------
    |  [ Learning ] [ Sports ]          |
    |  [ Leisure  ] [ Waste  ]          |
    -------------------------------------

### Actions
- Tap category button → start new activity.  
- Tap ongoing banner → stop current activity.  
- Tap activity row → open Edit Activity screen.  

---

## 2. Edit Activity Screen

### Purpose
- Modify activity details after recording.  

### Layout

    -------------------------------------
    |  Edit Activity                    |
    -------------------------------------
    |  Title: Running at gym            |
    |  Category: Sports [▼]             |
    |  Start: 07:50                     |
    |  End:   08:30                     |
    |  Notes: [ Optional text area ]    |
    -------------------------------------
    |  [ Save ]      [ Cancel ]         |
    -------------------------------------

---

## 3. Summary View

### Purpose
- Provide daily and weekly insights.  
- Reinforce awareness and achievement.  

### Daily Summary Layout

    -------------------------------------
    |  Summary (Daily)                  |
    -------------------------------------
    |  Pie Chart: Time by category      |
    |                                   |
    |  Learning  2h (40%)               |
    |  Sports    1h (20%)               |
    |  Leisure   1h (20%)               |
    |  Waste     1h (20%)               |
    -------------------------------------
    |  Streaks: Learning 3-day streak   |
    -------------------------------------
    |  [ Switch to Weekly Summary ]     |
    -------------------------------------

### Weekly Summary Layout

    -------------------------------------
    |  Summary (Weekly)                 |
    -------------------------------------
    |  Bar Chart: Hours per category    |
    |                                   |
    |  Mon: [██ L][█ S][█ W]            |
    |  Tue: [███ L][██ S]               |
    |  Wed: [█ L][███ W]                |
    |  ...                              |
    -------------------------------------
    |  Goal Progress:                   |
    |   - Learning: 8h / 10h            |
    |   - Sports: 2h / 3h               |
    -------------------------------------

---

## 4. Group Session (Detailed Mode)

### Purpose
- Allow breakdown of activity into sub-events.  
- Show efficiency ratio (core vs total).  

### Layout

    -------------------------------------
    |  Gym Session (70m, 57%)           |
    -------------------------------------
    |  07:30 – 07:50  Travel [T]        |
    |  07:50 – 08:30  Running [S]       |
    |  08:30 – 08:40  Travel [T]        |
    -------------------------------------
    |  Efficiency: 40m core / 70m total |
    -------------------------------------
    |  [ Collapse / Expand Group ]      |
    -------------------------------------

---

## 5. Navigation

### Tabs
- Timeline  
- Summary  
- Settings (future expansion: goals, categories, badges)  

### Bottom Tab Layout

    -------------------------------------
    | [ Timeline ] [ Summary ] [ More ] |
    -------------------------------------

---

## Extensibility Notes
- **Charts**: More can be added (heatmap, badges) in Summary without changing Timeline.  
- **Categories**: Default 4, user can add more. UI should scroll horizontally if >4.  
- **Settings**: Placeholder for future features (custom goals, reminders, sync).