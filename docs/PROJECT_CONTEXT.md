# PROJECT_CONTEXT.md

## Project Name
**FocusTime Now**

## Vision
A lightweight iPhone app that helps people stay disciplined and focused by making time usage visible, easy to track, and aligned with goals.  
Core idea: *"Stay aware of what you're doing, right now."*

## Current Stage
- **Stage 1+ (MVP + Projects)** completed with enhancements.
- Core features: ActivityEvent model, Project model, timeline view, quick Start/Stop, daily totals.
- Project selection functionality implemented but currently disabled for simplicity.
- Ready to proceed to Stage 2 (Usability & Awareness features).

## Key Documents
- **SPEC.md** → Product specification (vision, problems, solutions, models, principles).  
- **IMPLEMENTATION_PLAN.md** → Development plan by stages (MVP → advanced features).  
- **USER_FLOWS.md** → User flows (Quick Mode, Detailed Mode, example scenarios).  
- **UI_DESIGN.md** (optional) → Wireframes or layout notes.  

## Development Principles
- Keep input simple (Quick Mode default, Detailed optional).  
- Make wasted time visible.  
- Provide awareness and a sense of achievement (charts, streaks, badges).  
- Favor lightweight logging over heavy data entry.  

## Recent Issues & Fixes (2025-08-31)

### Issue #1: Project Selection Friction
**Problem:** When tapping category buttons, app showed project selection popup, adding unwanted friction.
**Expected:** Direct activity start for simple Quick Mode experience.
**Solution:** Modified TimelineView to skip project selection and start activities directly with `projectId: nil`.
**Files Changed:** `FocusTimeNow/Views/TimelineView.swift`

### Issue #2: Activities List Not Fully Scrollable  
**Problem:** Early activity records became hidden behind fixed "Today's Summary" section, making them inaccessible.
**Expected:** All activity records should be scrollable while keeping summary and buttons fixed.
**Solution:** Added `.frame(maxWidth: .infinity, maxHeight: .infinity)` to ScrollView for proper sizing and touch area.
**Files Changed:** `FocusTimeNow/Views/TimelineView.swift`
**Note:** Mac Simulator requires one-finger-hold + second-finger-swipe gesture for scrolling.

## Notes for AI Assistants
- Always refer to SPEC.md for product scope.  
- Follow IMPLEMENTATION_PLAN.md for development sequence.  
- Use USER_FLOWS.md for UI/UX decisions.  
- Keep code implementation in Swift (SwiftUI + SwiftData).