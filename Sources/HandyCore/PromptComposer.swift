public enum PromptComposer {
    public static func compose(goal: String, intent: String, selectedItems: [ContextItem]) -> String {
        let trimmedGoal = goal.trimmingCharacters(in: .whitespacesAndNewlines)
        let context = selectedItems.enumerated().map { index, item in
            "\(index + 1). [\(item.type.rawValue)] \(item.title) - \(item.preview) (\(item.source), \(item.detail))"
        }.joined(separator: "\n")

        return """
        Intent: \(intent)

        Context:
        \(context)

        Request:
        \(trimmedGoal)
        """
    }
}
