# IMPLEMENTATION_PLAN.md

## Stage 1: MVP – Core Activity Tracking
**Goal:** Deliver a minimal working app where users can log and review daily activities.

### Features
- App structure with SwiftUI + SwiftData.
- ActivityEvent model with fields: id, title, category, startAt, endAt, duration.
- Default categories: Learning, Sports, Leisure, Waste.
- Timeline view showing today's activities in chronological order.
- One-tap Start/Stop buttons to record activities.
- Show ongoing activity with "Now" label until stopped.
- Ability to edit title, category, and times for an activity.
- Daily totals per category (text summary only).

### Deliverables
- Working iOS app buildable via Xcode.
- Core database schema and SwiftData persistence.
- Minimal UI (Timeline + Start/Stop + Edit).
- Basic unit tests for ActivityEvent model.

---

## Stage 2: Usability & Awareness
**Goal:** Improve user convenience and awareness of how time is spent.

### Features
- Support for **custom categories** (user-defined).
- Ability to add activities **post-hoc** (after they happened).
- Daily summary view with pie chart of categories.
- Weekly summary view with stacked bar chart.
- Gentle reminders for ongoing "Waste" activity exceeding threshold (e.g., 40 minutes).
- Simple streak counter for daily goals (e.g., learning ≥ 2h).

### Deliverables
- Enhanced UI with Daily and Weekly views.
- Chart visualizations (using Swift Charts).
- Notification system for gentle reminders.
- Unit tests for summary calculations.

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

