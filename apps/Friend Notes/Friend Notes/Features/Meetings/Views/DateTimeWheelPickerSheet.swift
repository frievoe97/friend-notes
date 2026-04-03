import SwiftUI

/// Sheet containing a wheel date-time picker with 5-minute granularity.
struct DateTimeWheelPickerSheet: View {
    /// Uses environment dismissal to close after save/cancel.
    @Environment(\.dismiss) private var dismiss
    /// Local date-time draft isolated until the user confirms save.
    @State private var selectedDate: Date

    /// Navigation title shown in the sheet.
    let title: String
    /// Optional allowed date range used by the calendar picker.
    let range: ClosedRange<Date>?
    /// Callback invoked when the user confirms the selected date-time.
    ///
    /// - Important: The caller owns downstream model mutation and persistence.
    let onSave: (Date) -> Void

    /// Creates a date-time picker sheet.
    ///
    /// - Parameters:
    ///   - title: Navigation title shown in the sheet.
    ///   - initialDate: Initial date-time value shown to the user.
    ///   - range: Optional selectable date bounds.
    ///   - onSave: Callback triggered on save.
    init(
        title: String,
        initialDate: Date,
        range: ClosedRange<Date>? = nil,
        onSave: @escaping (Date) -> Void
    ) {
        self.title = title
        self.range = range
        self.onSave = onSave
        _selectedDate = State(
            initialValue: FiveMinuteDateTimePicker.roundedToFiveMinutes(initialDate)
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(title)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    DatePicker(
                        "",
                        selection: dateSelectionBinding,
                        in: dateRange,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                    FiveMinuteTimePicker(
                        selection: timeSelectionBinding,
                        preferredStyle: .wheels
                    )
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel(L10n.text("common.cancel", "Cancel"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        onSave(FiveMinuteDateTimePicker.roundedToFiveMinutes(selectedDate))
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .accessibilityLabel(L10n.text("common.save", "Save"))
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .appScreenBackground()
        .onChange(of: selectedDate) { _, newValue in
            let rounded = FiveMinuteDateTimePicker.roundedToFiveMinutes(newValue)
            if abs(newValue.timeIntervalSince(rounded)) > 0.5 {
                selectedDate = rounded
            }
        }
    }

    /// Date bounds used by the calendar picker, defaulting to an unrestricted range.
    private var dateRange: ClosedRange<Date> {
        range ?? (Date.distantPast...Date.distantFuture)
    }

    /// Binds only the date component while preserving the currently selected time component.
    private var dateSelectionBinding: Binding<Date> {
        Binding(
            get: { selectedDate },
            set: { newValue in
                let cal = Calendar.current
                let time = cal.dateComponents([.hour, .minute], from: selectedDate)
                let day = cal.dateComponents([.year, .month, .day], from: newValue)
                let merged = DateComponents(
                    year: day.year,
                    month: day.month,
                    day: day.day,
                    hour: time.hour,
                    minute: time.minute
                )
                selectedDate = cal.date(from: merged) ?? newValue
            }
        )
    }

    /// Binds only the time component while preserving the currently selected date component.
    private var timeSelectionBinding: Binding<Date> {
        Binding(
            get: { selectedDate },
            set: { newValue in
                let cal = Calendar.current
                let day = cal.dateComponents([.year, .month, .day], from: selectedDate)
                let time = cal.dateComponents([.hour, .minute], from: newValue)
                let merged = DateComponents(
                    year: day.year,
                    month: day.month,
                    day: day.day,
                    hour: time.hour,
                    minute: time.minute
                )
                selectedDate = cal.date(from: merged) ?? newValue
            }
        )
    }
}
