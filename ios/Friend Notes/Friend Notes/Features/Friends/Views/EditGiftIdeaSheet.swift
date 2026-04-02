import SwiftUI
import SwiftData

/// Sheet for editing an existing gift idea in place.
struct EditGiftIdeaSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var idea: GiftIdea

    var body: some View {
        NavigationStack {
            ScrollView {
                let canClearTitle = !idea.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                let canClearNote = !idea.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                let canClearURL = !idea.url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        fieldLabel(L10n.text("gift.name", "Name"))
                        HStack(spacing: 8) {
                            TextField("", text: $idea.title)
                                .textFieldStyle(.plain)

                            Button {
                                idea.title = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.body)
                                    .foregroundStyle(.tertiary)
                                    .frame(width: 20, height: 20)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(L10n.text("common.clear", "Clear"))
                            .opacity(canClearTitle ? 1 : 0)
                            .disabled(!canClearTitle)
                        }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        fieldLabel(L10n.text("gift.note", "Note"))
                        HStack(alignment: .top, spacing: 8) {
                            TextField("", text: $idea.note, axis: .vertical)
                                .textFieldStyle(.plain)
                                .lineLimit(4...)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Button {
                                idea.note = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.body)
                                    .foregroundStyle(.tertiary)
                                    .frame(width: 20, height: 20)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(L10n.text("common.clear", "Clear"))
                            .opacity(canClearNote ? 1 : 0)
                            .disabled(!canClearNote)
                        }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        fieldLabel(L10n.text("gift.url", "URL"))
                        HStack(spacing: 8) {
                            TextField("", text: $idea.url)
                                .textFieldStyle(.plain)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .keyboardType(.URL)

                            Button {
                                idea.url = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.body)
                                    .foregroundStyle(.tertiary)
                                    .frame(width: 20, height: 20)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(L10n.text("common.clear", "Clear"))
                            .opacity(canClearURL ? 1 : 0)
                            .disabled(!canClearURL)
                        }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    Toggle(L10n.text("gift.already_gifted", "Already gifted"), isOn: $idea.isGifted)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(AppTheme.subtleFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .navigationTitle(L10n.text("gift.edit.title", "Edit Gift Idea"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.text("common.close", "Close")) { dismiss() }
                }
            }
        }
        .appScreenBackground()
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
    }
}
