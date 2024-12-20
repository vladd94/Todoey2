import SwiftUI

struct TodoListView: View {
    @EnvironmentObject var viewModel: TodoListViewModel
    @State private var showingAddSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingEditSheet = false
    @State private var itemToEdit: Item? = nil
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.items) { item in
                    TodoItemRow(item: item) {
                        // Show edit sheet when tapped
                        itemToEdit = item
                        showingEditSheet = true
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            withAnimation {
                                viewModel.toggleCompletion(for: item)
                            }
                        } label: {
                            Label(item.isCompleted ? "Uncomplete" : "Complete", 
                                  systemImage: item.isCompleted ? "xmark.circle.fill" : "checkmark.circle.fill")
                        }
                        .tint(item.isCompleted ? .gray : .green)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            viewModel.deleteItem(item)
                        } label: {
                            Label("Delete", systemImage: "trash.circle.fill")
                        }
                    }
                }
            }
            .navigationTitle("Todoey ✓")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        withAnimation {
                            viewModel.toggleAllCompletion()
                        }
                    } label: {
                        Image(systemName: viewModel.areAllCompleted ? "checkmark.circle" : "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddItemView(viewModel: viewModel)
        }
        .sheet(item: $itemToEdit) { item in
            // Pass the item to AddItemView for editing
            AddItemView(viewModel: viewModel, editingItem: item)
        }
        .alert("Delete All Items?", isPresented: $showingDeleteAlert) {
            Button("Delete All", role: .destructive) {
                withAnimation {
                    viewModel.deleteAllItems()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }
} 