# IMPLEMENTATION_PLAN.md

## Stage 1+: MVP + Projects + Charts ✅ **COMPLETED**
**Goal:** Deliver a minimal working app where users can log and review daily activities with enhanced visualization.

### Features
- App structure with SwiftUI + SwiftData.
- ActivityEvent model with fields: id, title, category, startAt, endAt, duration, projectId.
- Project model for optional activity categorization.
- Default categories: Learning, Sports, Leisure, Work, Life, Waste.
- Timeline view showing today's activities in chronological order.
- One-tap Start/Stop buttons to record activities.
- Show ongoing activity with "Now" label until stopped.
- Ability to edit title, category, and times for an activity.
- **NEW: Summary tab with interactive charts using Swift Charts**.
- **NEW: Daily pie chart showing time distribution by category**.
- **NEW: Weekly bar chart showing daily patterns across the week**.
- **NEW: Detailed breakdowns with percentages and formatted durations**.

### Deliverables
- Working iOS app buildable via Xcode.
- Core database schema and SwiftData persistence.
- **Tab-based navigation (Timeline + Summary)**.
- **Interactive charts and visual analytics**.

---

## Stage 2: Advanced Usability & Awareness 
**Goal:** Add advanced user convenience features and smart notifications.

### Features
- Support for **custom categories** (user-defined beyond the 6 defaults).
- Ability to add activities **post-hoc** (after they happened).
- ~~Daily summary view with pie chart of categories~~ ✅ **COMPLETED in Stage 1+**
- ~~Weekly summary view with stacked bar chart~~ ✅ **COMPLETED in Stage 1+**
- **NEW FOCUS:** Gentle reminders for ongoing "Waste" activity exceeding threshold (e.g., 40 minutes).
- **NEW FOCUS:** Simple streak counter for daily goals (e.g., learning ≥ 2h).
- **NEW FOCUS:** Goal setting and progress tracking.

### Deliverables  
- Custom category management UI.
- Post-hoc activity entry form.
- Notification system for gentle reminders.
- Goal setting and streak tracking features.
- Unit tests for advanced features.

---

## Stage 3: Efficiency & Achievement
**Goal:** Provide deeper insights, sense of achievement, and advanced tracking.

### Features
- **ActivityGroup model**: group sub-events (e.g., Travel → Running → Travel Back).
- Automatic calculation of Efficiency Ratio (core / total time).
- Heatmap view of productivity vs wasted time across hours of the day.
- Achievement badges (e.g., 10h learning, 7-day streak).
- Improved goal tracking with configurable daily/weekly targets.
- (Optional) HealthKit & Location integration for automatic activity detection.

### Deliverables
- Grouped activity support with efficiency metrics.
- Advanced visualization: heatmap + badges.
- Expanded goal/streak tracking.
- Tests for group efficiency calculation and achievements.

---

## Stage 4: Polish & Distribution (optional)
**Goal:** Prepare for external testing and user feedback.

### Features
- Polished UI design with consistent colors and icons for categories.
- Onboarding flow introducing app concept and categories.
- Export or sync option (CSV, Notion, iCloud).
- TestFlight distribution for beta users.

### Deliverables
- App ready for TestFlight submission.
- Documentation for testers.

---

## Plan Addendum (2025-08-24)
- Stage 1: add `Project` model + `projectId?` in `ActivityEvent`, optional project picker at Start/Edit.
- Stage 2: simple Projects list (active/archived) + per-project totals in summaries.
- Stage 3: per-project targets and progress; badges at category/project levels.

