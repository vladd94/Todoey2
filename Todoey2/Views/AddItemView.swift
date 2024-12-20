import SwiftUI

struct AddItemView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TodoListViewModel
    var editingItem: Item?
    
    @State private var newItemTitle: String
    @State private var suggestions: [String] = []
    @State private var isLoading = false
    @State private var selectedColor: Color
    @State private var originalInput = ""
    @State private var selectedSuggestionIndex: Int? = nil
    @State private var selectedDate: Date
    @State private var selectedTime: Date
    @State private var hasDueDate: Bool
    @State private var isDatePickerShown = false
    @State private var isTimePickerShown = false
    @State private var isDurationTimePickerShown = false
    @State private var hasDuration: Bool
    @State private var selectedDuration: TimeInterval
    @State private var durationHours: Int
    @State private var durationMinutes: Int

    init(viewModel: TodoListViewModel, editingItem: Item? = nil) {
        self.viewModel = viewModel
        self.editingItem = editingItem
        
        _newItemTitle = State(initialValue: editingItem?.title ?? "")
        _selectedColor = State(initialValue: editingItem?.textColor.color ?? .primary)
        _hasDueDate = State(initialValue: editingItem?.dueDate != nil)
        _selectedDate = State(initialValue: editingItem?.dueDate ?? Date())
        _selectedTime = State(initialValue: editingItem?.dueDate ?? Date())
        _hasDuration = State(initialValue: editingItem?.duration != nil)
        _selectedDuration = State(initialValue: editingItem?.duration ?? 3600)
        let initialDuration = editingItem?.duration ?? 3600.0
        let hours = Int(initialDuration) / 3600
        let minutes = Int(initialDuration) / 60 % 60
        _durationHours = State(initialValue: hours)
        _durationMinutes = State(initialValue: minutes)
    }

    private var combinedDateTime: Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)
        
        var combined = DateComponents()
        combined.year = dateComponents.year
        combined.month = dateComponents.month
        combined.day = dateComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute
        
        return calendar.date(from: combined) ?? Date()
    }

    private var formattedDateTime: String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: combinedDateTime)
        let timeFormat = combinedDateTime.formatted(date: .omitted, time: .shortened)
        
        guard let days = components.day else {
            return combinedDateTime.formatted(date: .abbreviated, time: .shortened)
        }
        
        if days == 0 {
            return "Today, " + timeFormat
        } else if days == 1 {
            return "Tomorrow, " + timeFormat
        } else {
            return combinedDateTime.formatted(date: .abbreviated, time: .shortened)
        }
    }

    private var formattedDuration: String {
        if durationHours > 0 {
            return durationMinutes > 0 ? "\(durationHours)h \(durationMinutes)m" : "\(durationHours)h"
        } else {
            return "\(durationMinutes)m"
        }
    }

    var body: some View {
        NavigationView {
            Form {
                Section("New Task") {
                    TextField("Enter task", text: $newItemTitle)
                        .onChange(of: newItemTitle) { oldValue, newValue in
                            // Clear suggestions unless the new value is one of the suggestions
                            if !suggestions.contains(newValue) {
                                suggestions = []
                                originalInput = newValue
                                selectedSuggestionIndex = nil
                            }
                        }

                    Button(action: beCreativeButtonTapped) {
                        HStack {
                            Image(systemName: "sparkles.rectangle.stack")
                                .symbolEffect(.bounce, value: isLoading)
                            Text("Be Creative")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(newItemTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?
                                    Color.gray.opacity(0.3) : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(newItemTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                }

                if !suggestions.isEmpty {
                    Section {
                        Text("AI Suggestions")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 8)

                        // Original Text Button
                        Button(action: revertToOriginal) {
                            HStack {
                                Image(systemName: "arrow.uturn.backward.circle")
                                    .foregroundColor(.orange)
                                Text("Original: \(originalInput)")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "checkmark.circle")
                                    .foregroundColor(.blue)
                                    .opacity(newItemTitle == originalInput && selectedSuggestionIndex == nil ? 1 : 0)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(newItemTitle == originalInput && selectedSuggestionIndex == nil ? Color.blue : Color.clear, lineWidth: 2)
                            )
                        }
                        .padding(.bottom, 8)

                        // AI Suggestions List
                        ForEach(suggestions.indices, id: \.self) { index in
                            Button(action: {
                                selectSuggestion(at: index)
                            }) {
                                HStack {
                                    Text(suggestions[index])
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                        .imageScale(.large)
                                        .opacity(selectedSuggestionIndex == index ? 1 : 0)
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedSuggestionIndex == index ?
                                            Color.gray.opacity(0.15) :
                                            Color(.systemBackground))
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }

                Section("Customize") {
                    ColorPicker("Text Color", selection: $selectedColor)
                    
                    Toggle("Set Due Date", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        // Date Selection
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                            Text(selectedDate.formatted(date: .abbreviated, time: .omitted))
                                .foregroundColor(.primary)
                            Spacer()
                            Button("Edit") {
                                isDatePickerShown = true
                            }
                            .foregroundColor(.blue)
                        }
                        
                        // Time Selection
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.blue)
                            Text(selectedTime.formatted(date: .omitted, time: .shortened))
                                .foregroundColor(.primary)
                            Spacer()
                            Button("Edit") {
                                isTimePickerShown = true
                            }
                            .foregroundColor(.blue)
                        }
                        
                        // Update date picker sheet
                        .sheet(isPresented: $isDatePickerShown) {
                            NavigationView {
                                DatePicker(
                                    "",
                                    selection: $selectedDate,
                                    in: Date()...,
                                    displayedComponents: [.date]
                                )
                                .datePickerStyle(.graphical)
                                .labelsHidden()
                                .padding()
                                .navigationTitle("Choose Date")
                                .navigationBarTitleDisplayMode(.inline)
                                .toolbar {
                                    ToolbarItem(placement: .cancellationAction) {
                                        Button("Cancel") {
                                            isDatePickerShown = false
                                        }
                                    }
                                    ToolbarItem(placement: .confirmationAction) {
                                        Button("Done") {
                                            isDatePickerShown = false
                                        }
                                    }
                                }
                            }
                            .presentationDetents([.medium])
                        }
                        
                        // Update time picker sheet
                        .sheet(isPresented: $isTimePickerShown) {
                            NavigationView {
                                DatePicker(
                                    "",
                                    selection: $selectedTime,
                                    displayedComponents: [.hourAndMinute]
                                )
                                .datePickerStyle(.wheel)
                                .labelsHidden()
                                .padding()
                                .navigationTitle("Choose Time")
                                .navigationBarTitleDisplayMode(.inline)
                                .toolbar {
                                    ToolbarItem(placement: .cancellationAction) {
                                        Button("Cancel") {
                                            isTimePickerShown = false
                                        }
                                    }
                                    ToolbarItem(placement: .confirmationAction) {
                                        Button("Done") {
                                            isTimePickerShown = false
                                        }
                                    }
                                }
                            }
                            .presentationDetents([.height(300)])
                        }
                    }

                    Toggle("Set Duration", isOn: $hasDuration)

                    if hasDuration {
                        HStack {
                            Image(systemName: "timer")
                                .foregroundColor(.blue)
                            Text(formattedDuration)
                                .foregroundColor(.primary)
                            Spacer()
                            Button("Edit") {
                                isDurationTimePickerShown = true
                            }
                            .foregroundColor(.blue)
                        }
                        .sheet(isPresented: $isDurationTimePickerShown) {
                            NavigationView {
                                DatePicker(
                                    "",
                                    selection: Binding(
                                        get: {
                                            let calendar = Calendar.current
                                            let midnight = calendar.startOfDay(for: Date())
                                            return midnight.addingTimeInterval(selectedDuration)
                                        },
                                        set: { newDate in
                                            let calendar = Calendar.current
                                            let components = calendar.dateComponents([.hour, .minute], from: newDate)
                                            let hours = components.hour ?? 0
                                            let minutes = components.minute ?? 0
                                            
                                            durationHours = hours
                                            durationMinutes = minutes
                                            selectedDuration = TimeInterval(hours * 3600 + minutes * 60)
                                        }
                                    ),
                                    displayedComponents: [.hourAndMinute]
                                )
                                .datePickerStyle(.wheel)
                                .labelsHidden()
                                .environment(\.calendar, Calendar(identifier: .gregorian))
                                .padding()
                                .navigationTitle("Choose Duration")
                                .navigationBarTitleDisplayMode(.inline)
                                .toolbar {
                                    ToolbarItem(placement: .cancellationAction) {
                                        Button("Cancel") {
                                            isDurationTimePickerShown = false
                                        }
                                    }
                                    ToolbarItem(placement: .confirmationAction) {
                                        Button("Done") {
                                            isDurationTimePickerShown = false
                                        }
                                    }
                                }
                            }
                            .presentationDetents([.height(300)])
                        }
                    }
                }
            }
            .navigationTitle(editingItem != nil ? "Edit Task" : "Add New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(editingItem != nil ? "Save" : "Add") {
                        addItem()
                    }
                    .disabled(newItemTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .overlay {
                if isLoading {
                    ZStack {
                        Color.black.opacity(0.2)
                            .ignoresSafeArea()

                        VStack(spacing: 15) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text(AISettings.loadingMessage)
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        .padding(20)
                        .background(.ultraThinMaterial)
                        .cornerRadius(15)
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func beCreativeButtonTapped() {
        guard !isLoading else { return }
        Task {
            await generateSuggestions()
        }
    }

    private func revertToOriginal() {
        withAnimation(.easeInOut(duration: 0.2)) {
            newItemTitle = originalInput
            selectedSuggestionIndex = nil
        }
    }

    private func selectSuggestion(at index: Int) {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedSuggestionIndex = index
            newItemTitle = suggestions[index]
        }
    }

    private func addItem() {
        let trimmedTitle = newItemTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        
        if let editingItem = editingItem {
            viewModel.updateItem(
                editingItem,
                with: trimmedTitle,
                textColor: selectedColor,
                dueDate: hasDueDate ? combinedDateTime : nil,
                duration: hasDuration ? selectedDuration : nil
            )
        } else {
            let item = Item(
                title: trimmedTitle,
                textColor: selectedColor,
                dueDate: hasDueDate ? combinedDateTime : nil,
                duration: hasDuration ? selectedDuration : nil
            )
            viewModel.items.append(item)
        }
        viewModel.saveItems()
        dismiss()
    }

    private func generateSuggestions() async {
        guard !newItemTitle.isEmpty,
              AISettings.isValidTaskLength(newItemTitle),
              !isLoading else { return }

        originalInput = newItemTitle
        selectedSuggestionIndex = nil
        isLoading = true
        do {
            let suggestionArray = try await viewModel.generateInspiringOptions(for: newItemTitle)
            // Ensure unique suggestions and limit to maxSuggestions
            suggestions = Array(Set(suggestionArray)).prefix(AISettings.maxSuggestions).map { $0 }
        } catch {
            print("Failed to generate suggestions: \(error)")
            suggestions = []
        }
        isLoading = false
    }
}

#Preview {
    @Previewable @StateObject var viewModel = TodoListViewModel()
    AddItemView(viewModel: viewModel)
}
