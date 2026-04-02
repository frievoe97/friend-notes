import XCTest
@testable import Friend_Notes

final class FiveMinuteDateTimePickerTests: XCTestCase {
    func testRoundedToFiveMinutesKeepsExactFiveMinuteValue() {
        let date = Date(timeIntervalSinceReferenceDate: 1_500)

        let rounded = FiveMinuteDateTimePicker.roundedToFiveMinutes(date)

        XCTAssertEqual(rounded.timeIntervalSinceReferenceDate, 1_500)
    }

    func testRoundedToFiveMinutesRoundsDownWhenBelowHalfStep() {
        let date = Date(timeIntervalSinceReferenceDate: 149)

        let rounded = FiveMinuteDateTimePicker.roundedToFiveMinutes(date)

        XCTAssertEqual(rounded.timeIntervalSinceReferenceDate, 0)
    }

    func testRoundedToFiveMinutesRoundsUpAtHalfStep() {
        let date = Date(timeIntervalSinceReferenceDate: 150)

        let rounded = FiveMinuteDateTimePicker.roundedToFiveMinutes(date)

        XCTAssertEqual(rounded.timeIntervalSinceReferenceDate, 300)
    }

    func testRoundedToFiveMinutesRoundsUpWhenAboveHalfStep() {
        let date = Date(timeIntervalSinceReferenceDate: 451)

        let rounded = FiveMinuteDateTimePicker.roundedToFiveMinutes(date)

        XCTAssertEqual(rounded.timeIntervalSinceReferenceDate, 600)
    }

    func testRoundedToFiveMinutesHandlesNegativeReferenceDates() {
        let date = Date(timeIntervalSinceReferenceDate: -149)

        let rounded = FiveMinuteDateTimePicker.roundedToFiveMinutes(date)

        XCTAssertEqual(rounded.timeIntervalSinceReferenceDate, 0)
    }
}
