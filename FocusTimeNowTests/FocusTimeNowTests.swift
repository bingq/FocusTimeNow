import XCTest
@testable import FocusTimeNow

final class FocusTimeNowTests: XCTestCase {

    override func setUpWithError() throws {
    }

    override func tearDownWithError() throws {
    }

    func testActivityEventInitialization() throws {
        let activity = ActivityEvent(title: "Reading", category: "Learning")
        
        XCTAssertNotNil(activity.id)
        XCTAssertEqual(activity.title, "Reading")
        XCTAssertEqual(activity.category, "Learning")
        XCTAssertNotNil(activity.startAt)
        XCTAssertNil(activity.endAt)
        XCTAssertNil(activity.duration)
        XCTAssertTrue(activity.isOngoing)
    }
    
    func testActivityEventWithEmptyTitle() throws {
        let activity = ActivityEvent(category: "Sports")
        
        XCTAssertEqual(activity.title, "")
        XCTAssertEqual(activity.category, "Sports")
    }
    
    func testStopActivity() throws {
        let activity = ActivityEvent(title: "Running", category: "Sports")
        
        XCTAssertTrue(activity.isOngoing)
        XCTAssertNil(activity.endAt)
        XCTAssertNil(activity.duration)
        
        Thread.sleep(forTimeInterval: 0.1)
        activity.stop()
        
        XCTAssertFalse(activity.isOngoing)
        XCTAssertNotNil(activity.endAt)
        XCTAssertNotNil(activity.duration)
        XCTAssertGreaterThan(activity.duration!, 0)
    }
    
    func testDurationCalculation() throws {
        let startDate = Date()
        let endDate = Date(timeInterval: 3600, since: startDate)
        
        let activity = ActivityEvent(
            title: "Study Session",
            category: "Learning",
            startAt: startDate,
            endAt: endDate
        )
        
        XCTAssertEqual(activity.duration, 3600)
        XCTAssertFalse(activity.isOngoing)
    }
    
    func testFormattedDuration() throws {
        let startDate = Date()
        
        let shortActivity = ActivityEvent(
            title: "Quick Break",
            category: "Leisure",
            startAt: startDate,
            endAt: Date(timeInterval: 1800, since: startDate)
        )
        XCTAssertEqual(shortActivity.formattedDuration, "30m")
        
        let longActivity = ActivityEvent(
            title: "Work Session",
            category: "Learning",
            startAt: startDate,
            endAt: Date(timeInterval: 5400, since: startDate)
        )
        XCTAssertEqual(longActivity.formattedDuration, "1h 30m")
        
        let ongoingActivity = ActivityEvent(title: "Ongoing", category: "Sports")
        XCTAssertEqual(ongoingActivity.formattedDuration, "Now")
    }
    
    func testTimeRange() throws {
        let calendar = Calendar.current
        let components = DateComponents(year: 2024, month: 8, day: 24, hour: 9, minute: 30)
        let startDate = calendar.date(from: components)!
        let endDate = calendar.date(byAdding: .minute, value: 90, to: startDate)!
        
        let activity = ActivityEvent(
            title: "Meeting",
            category: "Learning",
            startAt: startDate,
            endAt: endDate
        )
        
        XCTAssertEqual(activity.timeRange, "09:30 – 11:00")
        
        let ongoingActivity = ActivityEvent(
            title: "Current Task",
            category: "Learning",
            startAt: startDate
        )
        
        XCTAssertEqual(ongoingActivity.timeRange, "09:30 – Now")
    }
    
    func testActivityWithNotes() throws {
        let activity = ActivityEvent(
            title: "Research",
            category: "Learning",
            note: "Reading about SwiftUI architecture"
        )
        
        XCTAssertEqual(activity.note, "Reading about SwiftUI architecture")
    }
    
    func testActivityWithTags() throws {
        let activity = ActivityEvent(
            title: "Workout",
            category: "Sports",
            tags: ["gym", "cardio", "morning"]
        )
        
        XCTAssertEqual(activity.tags?.count, 3)
        XCTAssertTrue(activity.tags?.contains("gym") ?? false)
    }
    
    func testActivityCrossDay() throws {
        let calendar = Calendar.current
        let startComponents = DateComponents(year: 2024, month: 8, day: 24, hour: 23, minute: 30)
        let startDate = calendar.date(from: startComponents)!
        let endDate = calendar.date(byAdding: .hour, value: 2, to: startDate)!
        
        let activity = ActivityEvent(
            title: "Night Study",
            category: "Learning",
            startAt: startDate,
            endAt: endDate
        )
        
        XCTAssertEqual(activity.duration, 7200)
        XCTAssertEqual(activity.timeRange, "23:30 – 01:30")
    }
    
    func testStartStopSequence() throws {
        let activity1 = ActivityEvent(title: "Task 1", category: "Learning")
        XCTAssertTrue(activity1.isOngoing)
        
        Thread.sleep(forTimeInterval: 0.05)
        activity1.stop()
        
        let activity2 = ActivityEvent(title: "Task 2", category: "Sports")
        XCTAssertTrue(activity2.isOngoing)
        XCTAssertFalse(activity1.isOngoing)
        
        XCTAssertNotNil(activity1.duration)
        XCTAssertGreaterThan(activity1.duration!, 0)
    }
}