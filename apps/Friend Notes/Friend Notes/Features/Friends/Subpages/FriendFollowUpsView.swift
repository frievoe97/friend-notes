import SwiftUI
import SwiftData

/// Manages follow-up tasks that belong to a single friend profile.
struct FriendFollowUpsView: View {
    /// Bound friend model that owns the shown follow-up tasks.
    @Bindable var friend: Friend
    /// SwiftData context used for inserts and deletes triggered from this screen.
    @Environment(\.modelContext) private var modelContext

    /// Controls add-sheet presentation.
    @State private var showingAddFollowUp = false
    /// Controls expansion of the completed section.
    @State private var showingCompleted = false

    /// Pending follow-up tasks sorted by due date ascending.
    private var pendingTasks: [FollowUpTask] {
        friend.followUpTasks
            .filter { !$0.isCompleted }
            .sorted { $0.dueDate < $1.dueDate }
    }

    /// Completed follow-up tasks sorted by completion timestamp descending.
    private var completedTasks: [FollowUpTask] {
        friend.followUpTasks
            .filter(\.isCompleted)
            .sorted { lhs, rhs in
                let lhsDate = lhs.completedAt ?? lhs.dueDate
                let rhsDate = rhs.completedAt ?? rhs.dueDate
                return lhsDate > rhsDate
            }
    }

    var body: some View {
        taskList
            .navigationTitle(L10n.text("friend.section.follow_ups", "To-Dos"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddFollowUp = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel(L10n.text("common.add", "Add"))
                }
            }
            .appScreenBackground()
            .sheet(isPresented: $showingAddFollowUp) {
                AddFollowUpTaskSheet { title, note, dueDate, _ in
                    addFollowUpTask(title: title, note: note, dueDate: dueDate)
                }
            }
    }

    /// Renders the grouped follow-up list with an empty-state fallback.
    private var taskList: some View {
        List {
            pendingSection
            completedSection
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .overlay {
            if pendingTasks.isEmpty && completedTasks.isEmpty {
                ContentUnavailableView {
                    Label(
                        L10n.text("friend.section.follow_ups", "To-Dos"),
                        systemImage: "checklist"
                    )
                } description: {
                    Text(L10n.text("list.detail.empty", "Tap + to add an entry."))
                }
            }
        }
    }

    @ViewBuilder
    /// Renders pending tasks.
    private var pendingSection: some View {
        if !pendingTasks.isEmpty {
            Section(L10n.text("followup.section.pending", "Pending")) {
                ForEach(pendingTasks) { task in
                    NavigationLink(destination: FollowUpTaskDetailView(task: task)) {
                        taskRow(task)
                    }
                    .listRowBackground(AppTheme.subtleFill)
                }
                .onDelete { offsets in
                    offsets.map { pendingTasks[$0] }.forEach { modelContext.delete($0) }
                }
            }
        }
    }

    @ViewBuilder
    /// Renders completed tasks in an expandable section.
    private var completedSection: some View {
        if !completedTasks.isEmpty {
            Section {
                if showingCompleted {
                    ForEach(completedTasks) { task in
                        NavigationLink(destination: FollowUpTaskDetailView(task: task)) {
                            taskRow(task)
                        }
                        .listRowBackground(AppTheme.subtleFill)
                    }
                    .onDelete { offsets in
                        offsets.map { completedTasks[$0] }.forEach { modelContext.delete($0) }
                    }
                }
            } header: {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showingCompleted.toggle()
                    }
                } label: {
                    HStack {
                        Text(L10n.text("followup.section.done", "Done"))
                        Spacer()
                        Image(systemName: showingCompleted ? "chevron.up" : "chevron.down")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(.secondary)
                    .textCase(nil)
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// Renders one follow-up row with due date and optional note preview.
    ///
    /// - Parameter task: Follow-up task displayed in the row.
    private func taskRow(_ task: FollowUpTask) -> some View {
        HStack(spacing: 12) {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(task.isCompleted ? AppTheme.followUp.opacity(0.65) : AppTheme.followUp)
                .frame(width: 24, alignment: .center)

            VStack(alignment: .leading, spacing: 3) {
                Text(task.displayTitle)
                    .font(.body)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                    .strikethrough(task.isCompleted)

                Text(task.dueDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                let trimmedNote = task.note.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedNote.isEmpty {
                    Text(trimmedNote)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 2)
    }

    /// Creates and attaches a new follow-up task to the bound friend.
    ///
    /// - Parameters:
    ///   - title: Raw title input from the add sheet.
    ///   - note: Raw optional note input.
    ///   - dueDate: Selected due date and time.
    private func addFollowUpTask(title: String, note: String, dueDate: Date) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let task = FollowUpTask(
            title: trimmed,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            dueDate: dueDate,
            isCompleted: false
        )
        task.friend = friend
        modelContext.insert(task)
        friend.followUpTasks.append(task)
    }
}
