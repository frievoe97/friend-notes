import SwiftUI

// MARK: - Event Row: Birthday

/// Row used to display a birthday in the selected-day event list.
struct BirthdayEventRow: View {
    let friend: Friend
    let displayYear: Int

    /// Calculates displayed age for the selected year when birth year exists.
    ///
    /// - Returns: Age value for `displayYear`, or `nil` when birthday is unavailable.
    private var age: Int? {
        guard let bday = friend.birthday else { return nil }
        return displayYear - Calendar.current.component(.year, from: bday)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "birthday.cake.fill")
                .foregroundStyle(AppTheme.birthday)
                .frame(width: 36, height: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(friend.displayName)
                    .font(.body.weight(.medium))
                if let age, age > 0 {
                    Text(L10n.text("calendar.birthday.turns", "Turns %d", age))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}
