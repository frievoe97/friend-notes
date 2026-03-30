import Foundation

/// Lightweight localization helper for resolved strings and formatted variants.
enum L10n {
    /// Resolves a localized string for the given key with a fallback value.
    ///
    /// - Parameters:
    ///   - key: The localization key in `Localizable.strings`.
    ///   - fallback: The default value used when the key is missing.
    /// - Returns: The localized string for the current locale, or `fallback` when unavailable.
    static func text(_ key: String, _ fallback: String) -> String {
        NSLocalizedString(key, tableName: "Localizable", bundle: .main, value: fallback, comment: "")
    }

    /// Resolves and formats a localized string using locale-aware interpolation.
    ///
    /// - Parameters:
    ///   - key: The localization key in `Localizable.strings`.
    ///   - fallback: The default format string used when the key is missing.
    ///   - arguments: Values injected into the format string.
    /// - Returns: A formatted localized string.
    ///
    /// - Note: Argument types must match the format specifiers in the localized string (e.g. `%@`, `%d`).
    static func text(_ key: String, _ fallback: String, _ arguments: CVarArg...) -> String {
        String(format: text(key, fallback), locale: Locale.current, arguments: arguments)
    }
}
