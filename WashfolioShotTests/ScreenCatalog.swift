import SwiftUI
@testable import Washfolio

enum ScreenCatalog {
    @MainActor
    static var shots: [(String, AnyView)] {
        [
            ("foliocanvas", AnyView(FolioCanvas())),
            ("foliosettings", AnyView(FolioSettings())),
            ("root", AnyView(ContentView()))
        ]
    }
}
