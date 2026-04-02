import Foundation

/// Encodes and decodes the globally defined friend tags stored in app preferences.
enum AppTagStore {
    /// The `UserDefaults` key used to persist the encoded tags array.
    static let key = "definedFriendTags"

    /// Decodes a JSON string into an array of tags.
    ///
    /// - Parameter rawValue: The raw JSON string persisted in app storage.
    /// - Returns: A decoded tag list, or an empty array when the input is invalid JSON or not UTF-8.
    static func decode(_ rawValue: String) -> [String] {
        guard let data = rawValue.data(using: .utf8),
              let tags = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return tags
    }

    /// Encodes a tag array into a JSON string for persistence.
    ///
    /// - Parameter tags: The list of tags to encode.
    /// - Returns: A JSON string representation, or `"[]"` if encoding fails.
    static func encode(_ tags: [String]) -> String {
        guard let data = try? JSONEncoder().encode(tags),
              let encoded = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return encoded
    }
}
