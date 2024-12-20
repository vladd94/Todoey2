import SwiftUI

struct TodoItemRow: View {
    let item: Item
    let onToggle: () -> Void
    
    private var isDueSoon: Bool {
        guard let dueDate = item.dueDate else { return false }
        return Date().addingTimeInterval(3600) >= dueDate // 3600 seconds = 1 hour
    }
    
    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(item.isCompleted ? .green : .gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .foregroundColor(item.textColor.color)
                    .strikethrough(item.isCompleted)
                    .opacity(item.isCompleted ? 0.7 : 1)
                
                if let dueDate = item.dueDate {
                    HStack(spacing: 8) {
                        Text(dueDate.formatted(date: .abbreviated, time: .shortened))
                        
                        if let duration = item.duration {
                            Text("•")
                            Text("\(Int(duration) / 3600)h \(Int(duration) / 60 % 60)m")
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                } else if let duration = item.duration {
                    Text("\(Int(duration) / 3600)h \(Int(duration) / 60 % 60)m")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if isDueSoon {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.orange)
                    .imageScale(.large)
            }

        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
} 
