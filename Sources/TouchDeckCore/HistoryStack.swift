public struct HistoryStack<Value: Equatable & Sendable>: Sendable {
    private var undoStack: [Value] = []
    private var redoStack: [Value] = []
    private let limit: Int

    public init(limit: Int = 100) {
        self.limit = limit
    }

    public var canUndo: Bool {
        !undoStack.isEmpty
    }

    public var canRedo: Bool {
        !redoStack.isEmpty
    }

    public mutating func record(_ value: Value) {
        guard undoStack.last != value else {
            return
        }

        undoStack.append(value)

        if undoStack.count > limit {
            undoStack.removeFirst(undoStack.count - limit)
        }

        redoStack.removeAll()
    }

    public mutating func undo(current: Value) -> Value? {
        guard let previous = undoStack.popLast() else {
            return nil
        }

        redoStack.append(current)
        return previous
    }

    public mutating func redo(current: Value) -> Value? {
        guard let next = redoStack.popLast() else {
            return nil
        }

        undoStack.append(current)
        return next
    }

    public mutating func reset() {
        undoStack.removeAll()
        redoStack.removeAll()
    }
}
