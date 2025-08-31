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

## 3. Summary View ✅ **IMPLEMENTED**

### Purpose
- Provide daily and weekly insights with interactive charts.
- Reinforce awareness and achievement through visualizations.

### Features Implemented
- **Segmented picker** to switch between Daily/Weekly views
- **Daily pie chart** (donut style) with color-coded categories
- **Weekly stacked bar chart** showing daily patterns across 7 days  
- **Detailed breakdowns** with hours, percentages, and category icons
- **Legend and color consistency** across all visualizations
- **Empty state handling** for periods with no data
- **Swift Charts integration** for native iOS chart experience

### Current Layout (Implemented)

    -------------------------------------
    |  Summary                          |
    |  [ Daily | Weekly ]               |
    -------------------------------------
    |  Interactive Pie/Bar Chart        |
    |  with Legend                      |
    -------------------------------------
    |  Detailed Breakdown:              |
    |  📘 Learning  2h 15m (40%)        |
    |  🏃 Sports    1h 30m (27%)        |
    |  🎮 Leisure   1h (18%)            |
    |  💼 Work      45m (15%)           |
    -------------------------------------

### Future Enhancements (Stage 2+)
- Streak counters and goal tracking
- Achievement badges
- Trend analysis and insights

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

### Bottom Tab Layout ✅ **IMPLEMENTED**

    -------------------------------------
    | [ Timeline ] [ Summary ]           |
    -------------------------------------

---

## Extensibility Notes
- **Charts**: More can be added (heatmap, badges) in Summary without changing Timeline.  
- **Categories**: Default 4, user can add more. UI should scroll horizontally if >4.  
- **Settings**: Placeholder for future features (custom goals, reminders, sync).