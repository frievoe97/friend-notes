import SwiftUI
import UIKit

// MARK: - Date Time Picker

/// UIKit-backed date-time picker constrained to 5-minute increments.
struct FiveMinuteDateTimePicker: UIViewRepresentable {
    /// Bound date value.
    @Binding var selection: Date
    /// Optional lower bound for selectable values.
    var minimumDate: Date?
    /// Optional upper bound for selectable values.
    var maximumDate: Date?
    /// Visual picker style (`.compact` by default, `.wheels` for sheet pickers).
    var preferredStyle: UIDatePickerStyle = .compact

    func makeUIView(context: Context) -> UIDatePicker {
        let picker = UIDatePicker()
        picker.datePickerMode = .dateAndTime
        picker.preferredDatePickerStyle = preferredStyle
        picker.locale = .current
        picker.minuteInterval = 5
        picker.setContentCompressionResistancePriority(.required, for: .horizontal)
        picker.setContentCompressionResistancePriority(.required, for: .vertical)
        picker.setContentHuggingPriority(.required, for: .horizontal)
        picker.setContentHuggingPriority(.required, for: .vertical)
        picker.addTarget(context.coordinator, action: #selector(Coordinator.valueChanged(_:)), for: .valueChanged)
        return picker
    }

    func updateUIView(_ uiView: UIDatePicker, context: Context) {
        uiView.minimumDate = minimumDate
        uiView.maximumDate = maximumDate
        uiView.minuteInterval = 5
        let roundedSelection = Self.roundedToFiveMinutes(selection)
        if abs(uiView.date.timeIntervalSince(roundedSelection)) > 0.5 {
            uiView.date = roundedSelection
        }
        if abs(selection.timeIntervalSince(roundedSelection)) > 0.5 {
            DispatchQueue.main.async {
                selection = roundedSelection
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(selection: $selection)
    }

    /// Rounds a date to the nearest 5-minute mark.
    ///
    /// - Parameter date: Source date.
    /// - Returns: Rounded date using current calendar context.
    static func roundedToFiveMinutes(_ date: Date) -> Date {
        let interval = date.timeIntervalSinceReferenceDate
        let rounded = (interval / 300.0).rounded() * 300.0
        return Date(timeIntervalSinceReferenceDate: rounded)
    }

    final class Coordinator: NSObject {
        @Binding private var selection: Date

        init(selection: Binding<Date>) {
            _selection = selection
        }

        @objc func valueChanged(_ sender: UIDatePicker) {
            let rounded = FiveMinuteDateTimePicker.roundedToFiveMinutes(sender.date)
            sender.setDate(rounded, animated: false)
            selection = rounded
        }
    }
}

/// UIKit-backed time-only picker constrained to 5-minute increments.
struct FiveMinuteTimePicker: UIViewRepresentable {
    /// Bound time value (date component is ignored by the picker UI).
    @Binding var selection: Date
    /// Visual picker style (`.compact` by default, `.wheels` for sheet pickers).
    var preferredStyle: UIDatePickerStyle = .compact

    func makeUIView(context: Context) -> UIDatePicker {
        let picker = UIDatePicker()
        picker.datePickerMode = .time
        picker.preferredDatePickerStyle = preferredStyle
        picker.locale = .current
        picker.minuteInterval = 5
        picker.setContentCompressionResistancePriority(.required, for: .horizontal)
        picker.setContentCompressionResistancePriority(.required, for: .vertical)
        picker.setContentHuggingPriority(.required, for: .horizontal)
        picker.setContentHuggingPriority(.required, for: .vertical)
        picker.addTarget(context.coordinator, action: #selector(Coordinator.valueChanged(_:)), for: .valueChanged)
        return picker
    }

    func updateUIView(_ uiView: UIDatePicker, context: Context) {
        uiView.minuteInterval = 5
        let roundedSelection = FiveMinuteDateTimePicker.roundedToFiveMinutes(selection)
        if abs(uiView.date.timeIntervalSince(roundedSelection)) > 0.5 {
            uiView.date = roundedSelection
        }
        if abs(selection.timeIntervalSince(roundedSelection)) > 0.5 {
            DispatchQueue.main.async {
                selection = roundedSelection
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(selection: $selection)
    }

    final class Coordinator: NSObject {
        @Binding private var selection: Date

        init(selection: Binding<Date>) {
            _selection = selection
        }

        @objc func valueChanged(_ sender: UIDatePicker) {
            let rounded = FiveMinuteDateTimePicker.roundedToFiveMinutes(sender.date)
            sender.setDate(rounded, animated: false)
            selection = rounded
        }
    }
}
