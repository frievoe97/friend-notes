import SwiftUI

/// Sheet containing a wheel date-time picker with 5-minute granularity.
struct DateTimeWheelPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate: Date

    let title: String
    let range: ClosedRange<Date>?
    let onSave: (Date) -> Void

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
                VStack(alignment: .leading, spacing: 16) {
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

                    DatePicker(
                        L10n.text("meeting.time", "Time"),
                        selection: timeSelectionBinding,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.compact)
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
                    Button(L10n.text("common.cancel", "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.text("common.save", "Save")) {
                        onSave(FiveMinuteDateTimePicker.roundedToFiveMinutes(selectedDate))
                        dismiss()
                    }
                    .fontWeight(.semibold)
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
