import Testing
import Foundation
@testable import CVRtracker

/// Tests for date manipulation and formatting utilities.
@Suite("Date Extensions Tests")
struct DateExtensionsTests {
    
    @Test("Date components can be extracted")
    func dateComponentExtraction() {
        let calendar = Calendar.current
        let components = DateComponents(year: 2026, month: 1, day: 10, hour: 14, minute: 30)
        let date = calendar.date(from: components)!
        
        let extractedComponents = calendar.dateComponents([.year, .month, .day], from: date)
        
        #expect(extractedComponents.year == 2026)
        #expect(extractedComponents.month == 1)
        #expect(extractedComponents.day == 10)
    }
    
    @Test("Can calculate days between dates")
    func calculateDaysBetweenDates() {
        let calendar = Calendar.current
        let today = Date()
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        let components = calendar.dateComponents([.day], from: today, to: tomorrow)
        
        #expect(components.day == 1, "Should be 1 day difference")
    }
    
    @Test("Start of day calculation")
    func startOfDayCalculation() {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        
        let components = calendar.dateComponents([.hour, .minute, .second], from: startOfDay)
        
        #expect(components.hour == 0)
        #expect(components.minute == 0)
        #expect(components.second == 0)
    }
    
    @Test("Date formatting for display")
    func dateFormattingForDisplay() {
        let calendar = Calendar.current
        let components = DateComponents(year: 2026, month: 1, day: 10)
        let date = calendar.date(from: components)!
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        let formatted = formatter.string(from: date)
        
        #expect(!formatted.isEmpty, "Formatted date should not be empty")
        #expect(formatted.contains("2026") || formatted.contains("26"), "Should contain year")
    }
    
    @Test("Can create date ranges")
    func createDateRanges() throws {
        let calendar = Calendar.current
        let today = Date()
        
        let weekAgo = try #require(calendar.date(byAdding: .weekOfYear, value: -1, to: today))
        let monthAgo = try #require(calendar.date(byAdding: .month, value: -1, to: today))
        
        #expect(weekAgo < today)
        #expect(monthAgo < weekAgo)
        #expect(monthAgo < today)
    }
}
