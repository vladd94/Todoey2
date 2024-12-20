import Foundation

@available(iOS 14.0, *)
public enum TaskCustomizationMode: Equatable {
    case create
    case edit(index: Int)
    
    // Custom implementation of Equatable
    public static func == (lhs: TaskCustomizationMode, rhs: TaskCustomizationMode) -> Bool {
        switch (lhs, rhs) {
        case (.create, .create):
            return true
        case let (.edit(index1), .edit(index2)):
            return index1 == index2
        default:
            return false
        }
    }
} 