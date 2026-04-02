import Foundation

/// Lightweight localization helper for resolved strings and formatted variants.
enum L10n {
    private static let tableName = "Localizable"
    private static let englishBundle: Bundle? = {
        guard
            let path = Bundle.main.path(forResource: "en", ofType: "lproj"),
            let bundle = Bundle(path: path)
        else {
            return nil
        }
        return bundle
    }()

    /// Resolves a localized value for `key` from the given bundle.
    ///
    /// - Parameters:
    ///   - key: The localization key in `Localizable.strings`.
    ///   - bundle: Bundle to resolve from.
    /// - Returns: Localized value, or `nil` when the key does not exist in that bundle.
    private static func localizedValue(for key: String, in bundle: Bundle) -> String? {
        let value = bundle.localizedString(forKey: key, value: nil, table: tableName)
        return value == key ? nil : value
    }

    /// Resolves a localized string for the given key with an English-first fallback chain.
    ///
    /// - Parameters:
    ///   - key: The localization key in `Localizable.strings`.
    ///   - fallback: Last-resort default used when key is unavailable in current and English localizations.
    /// - Returns: Current locale string, otherwise English string, otherwise `fallback`.
    static func text(_ key: String, _ fallback: String) -> String {
        if let value = localizedValue(for: key, in: .main) {
            return value
        }
        if let englishBundle, let value = localizedValue(for: key, in: englishBundle) {
            return value
        }
        return fallback
    }

    /// Resolves and formats a localized string using locale-aware interpolation.
    ///
    /// - Parameters:
    ///   - key: The localization key in `Localizable.strings`.
    ///   - fallback: Last-resort default format when key is unavailable in current and English localizations.
    ///   - arguments: Values injected into the format string.
    /// - Returns: A formatted localized string.
    ///
    /// - Note: Argument types must match the format specifiers in the localized string (e.g. `%@`, `%d`).
    static func text(_ key: String, _ fallback: String, _ arguments: CVarArg...) -> String {
        String(format: text(key, fallback), locale: Locale.current, arguments: arguments)
    }
}
