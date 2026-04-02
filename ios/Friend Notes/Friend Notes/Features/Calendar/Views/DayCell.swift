import SwiftUI

// MARK: - Day Cell

/// Single calendar day cell with selection/today state and dot indicators.
struct DayCell: View {
    /// Calendar day represented by this cell.
    let date: Date
    /// Indicates whether the user selected this day.
    let isSelected: Bool
    /// Indicates whether the cell represents the current day.
    let isToday: Bool
    /// Indicates whether at least one meeting exists on this day.
    let hasMeeting: Bool
    /// Indicates whether at least one event exists on this day.
    let hasEvent: Bool
    /// Indicates whether at least one birthday exists on this day.
    let hasBirthday: Bool

    var body: some View {
        VStack(spacing: 3) {
            Text(date, format: .dateTime.day())
                .font(.callout.weight((isToday || isSelected) ? .bold : .regular))
                .foregroundStyle((isToday || isSelected) ? AppTheme.accent : .primary)
                .frame(width: 34, height: 34)
                .background {
                    if isSelected {
                        Circle()
                            .fill(.clear)
                            .glassEffect(.regular, in: Circle())
                    }
                }
            HStack(spacing: 3) {
                if hasBirthday { Circle().fill(AppTheme.birthday).frame(width: 4, height: 4) }
                if hasMeeting  { Circle().fill(AppTheme.accent).frame(width: 4, height: 4) }
                if hasEvent  { Circle().fill(AppTheme.event).frame(width: 4, height: 4) }
            }
            .frame(height: 6)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 46)
    }
}
