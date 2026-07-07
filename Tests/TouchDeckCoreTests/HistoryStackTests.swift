import Testing
import TouchDeckCore

@Test func historyStackCanUndoAndRedo() {
    var history = HistoryStack<Int>()

    history.record(1)
    history.record(2)

    #expect(history.canUndo)
    #expect(history.undo(current: 3) == 2)
    #expect(history.undo(current: 2) == 1)
    #expect(!history.canUndo)
    #expect(history.redo(current: 1) == 2)
    #expect(history.redo(current: 2) == 3)
    #expect(!history.canRedo)
}

@Test func historyStackClearsRedoWhenNewValueIsRecorded() {
    var history = HistoryStack<Int>()

    history.record(1)
    _ = history.undo(current: 2)
    history.record(3)

    #expect(!history.canRedo)
    #expect(history.undo(current: 4) == 3)
}

@Test func historyStackRespectsLimit() {
    var history = HistoryStack<Int>(limit: 2)

    history.record(1)
    history.record(2)
    history.record(3)

    #expect(history.undo(current: 4) == 3)
    #expect(history.undo(current: 3) == 2)
    #expect(history.undo(current: 2) == nil)
}
