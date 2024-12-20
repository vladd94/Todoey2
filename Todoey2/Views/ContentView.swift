import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = TodoListViewModel()
    
    var body: some View {
        TodoListView()
            .environmentObject(viewModel)
            .preferredColorScheme(.light) // Or use .dark or nil for system setting
    }
}

#Preview {
    ContentView()
}
