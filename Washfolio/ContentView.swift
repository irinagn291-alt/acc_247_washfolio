import SwiftUI

struct ContentView: View {
    @StateObject private var folio: AlmanacFolio

    init() {
        _folio = StateObject(wrappedValue: AlmanacFolio(store: FolioStore()))
    }

    var body: some View {
        FolioCanvas(folio: folio, handlesLaunch: true)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    FolioCanvas()
}
