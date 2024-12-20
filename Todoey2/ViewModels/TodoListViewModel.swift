import SwiftUI

class TodoListViewModel: ObservableObject {
    @Published var items: [Item] = []
    private let openAIService = OpenAIService()
    
    init() {
        loadItems()
    }
    
    var areAllCompleted: Bool {
        !items.isEmpty && items.allSatisfy { $0.isCompleted }
    }
    
    func loadItems() {
        if let data = UserDefaults.standard.data(forKey: "TodoListItems"),
           let savedItems = try? JSONDecoder().decode([Item].self, from: data) {
            items = savedItems
        } else {
            items = [
                Item(title: "Buy Eggos"),
                Item(title: "Destroy Demogorgon"),
                Item(title: "Find Mike")
            ]
        }
    }
    
    func saveItems() {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: "TodoListItems")
        }
    }
    
    func toggleCompletion(for item: Item) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].isCompleted.toggle()
            saveItems()
        }
    }
    
    func deleteItem(_ item: Item) {
        items.removeAll { $0.id == item.id }
        saveItems()
    }
    
    func deleteAllItems() {
        items.removeAll()
        saveItems()
    }
    
    func toggleAllCompletion() {
        let newState = !areAllCompleted
        items.indices.forEach { items[$0].isCompleted = newState }
        saveItems()
    }
    
    @MainActor
    func generateInspiringOptions(for text: String) async throws -> [String] {
        try await openAIService.generateInspiringOptions(text: text)
    }
    
    func updateItem(_ item: Item, with title: String, textColor: Color, dueDate: Date?, duration: TimeInterval?) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].title = title
            items[index].textColor = CodableColor(color: textColor)
            items[index].dueDate = dueDate
            items[index].duration = duration
            saveItems()
        }
    }
} 