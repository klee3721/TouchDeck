import CoreTransferable
import Foundation
import UniformTypeIdentifiers

enum TouchDeckDragPayload: Codable, Equatable, Transferable {
    case library(templateID: String)
    case touchBarItem(id: UUID)

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .touchDeckDragPayload)
    }
}

extension UTType {
    static let touchDeckDragPayload = UTType(exportedAs: "app.touchdeck.drag-payload")
}
