# SPEC.md

# App Name
**FocusTime Now**  
*"Stay aware of what you're doing, right now."*

---

## Product Vision
This app helps people stay disciplined and focused by making their use of time visible, easy to track, and aligned with their goals.  
It provides clear daily/weekly summaries, raises awareness of wasted time, and helps users connect their current actions to their long-term goals.

---

## Problem Statement
1. People easily waste time without noticing.  
2. Goals are often forgotten in daily routines.  
3. Lack of discipline leads to unstructured days.  
4. People are not always aware of their current focus or priorities.  
5. Time can slip away quickly without conscious awareness.  
6. Existing tracking tools are often too complex or inconvenient.  

---

## Solution Overview
A lightweight iPhone app that:  
- Makes time usage visible in real-time.  
- Provides one-tap input for starting and ending activities.  
- Categorizes activities into meaningful buckets (learning, sports, leisure, waste, or custom).  
- Allows users to optionally record preparation/transition time.  
- Reminds users of their goals and current focus.  
- Generates daily and weekly charts to reinforce a sense of achievement.  
- Gently alerts users when too much time is wasted.  

---

## Core Features (MVP)
- **Quick Start/Stop**: One tap to start an activity, one tap to stop.  
- **Default Categories**: Learning, Sports, Leisure, Waste.  
- **Custom Categories**: Users may define new categories (e.g., "整理", "Development").  
- **Timeline View**: Display activities as a chronological list with start–end times, title, and category tag.  
- **Ongoing Activity**: If no end time is set, display as "Now" in timeline.  
- **Simple Summaries**: Daily totals per category, weekly overview.  

---

## Advanced Features (Future Iterations)
- **Grouped Activities (ActivityGroup)**:  
  - Example: "Gym Session" = Travel to gym + Running + Travel back.  
  - Compute *total time* vs *core activity time*.  
  - Efficiency Ratio = Core / Total.  
- **Charts for Achievement & Awareness**:  
  - Daily Pie Chart: Time by category.  
  - Weekly Bar Chart: Hours per category.  
  - Streak Counter: Number of consecutive days goals are met.  
  - Heatmap: Which hours of the day are productive vs wasted.  
  - Achievement Badges: Milestones (e.g., "10h learning", "7-day sports streak").  
- **Reminders**:  
  - Notify user if an activity runs too long (e.g., wasted > 40 minutes).  
  - Gentle nudges to stay on track with daily goals.  
- **HealthKit / Location Integration** (optional):  
  - Automatically detect transitions (e.g., travel → running → travel).  

---

## User Input Modes
- **Quick Mode (default)**:  
  - Start and stop with minimal taps.  
  - Core activity only, no details required.  
- **Detailed Mode (optional)**:  
  - User can later edit or split an activity into sub-events (e.g., "travel", "exercise").  
  - Allows efficiency calculations.  
- **Post-hoc Recording**:  
  - Users may add/edit activities after they happened (to reduce friction).  

---

## Database Model (ActivityEvent)
- id: UUID  
- title: String  
- category: String (default categories + user-defined)  
- startAt: Date  
- endAt: Date? (nil = ongoing)  
- duration: Int? (calculated at stop)  
- note: String?  
- tags: [String]?  
- sourceApp: String? (optional, for auto-classification)  

### (Optional Future) ActivityGroup
- id: UUID  
- groupTitle: String  
- events: [ActivityEvent]  
- efficiency: Double (core / total)  

---

## Design Principles
1. **Simplicity**: Minimize friction in recording activities.  
2. **Awareness**: Make wasted time visible and goals tangible.  
3. **Flexibility**: Support both quick logging and detailed breakdowns.  
4. **Achievement**: Use charts and badges to foster motivation.  
5. **Gentle Guidance**: Nudges, not punishments.  

---

## Addendum (2025-08-24)
- Default categories extended to: Learning, Sports, Leisure, **Work**, Waste.

## Updates (2025-08-31)
- Added **Life** category for personal/family activities (cyan color, heart.fill icon).
- Default categories now: Learning, Sports, Leisure, Work, **Life**, Waste.
- Optional **Projects/Goals** per category:
  - Users can create/select a Project (e.g., Learning → "Machine Learning course by Andrew Ng").
  - `ActivityEvent` gains optional `projectId: UUID?`.
  - Summaries can aggregate by category and, if present, by project.

## Implementation Notes (2025-08-31)
- **Quick Mode prioritized**: Category buttons start activities directly without project selection for minimal friction.
- **Project functionality available**: Full Project model and ProjectSelectionView implemented but not in primary flow.
- **Future enhancement**: Project selection can be re-enabled via EditActivityView or separate "detailed mode" if needed.

