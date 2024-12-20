import SwiftUI

struct Item: Identifiable, Codable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var dateCreated: Date
    var textColor: CodableColor
    var dueDate: Date?
    var duration: TimeInterval? // Duration in seconds
    
    init(
        id: UUID = UUID(),
        title: String,
        isCompleted: Bool = false,
        textColor: Color = .primary,
        dueDate: Date? = nil,
        duration: TimeInterval? = nil
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.dateCreated = Date()
        self.textColor = CodableColor(color: textColor)
        self.dueDate = dueDate
        self.duration = duration
    }
}

import SwiftUI

struct CodableColor: Codable {
    var color: Color
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Extract RGBA components from the Color
        #if os(iOS)
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #elseif os(macOS)
        let nsColor = NSColor(color)
        guard let rgbColor = nsColor.usingColorSpace(.deviceRGB) else {
            throw EncodingError.invalidValue(nsColor, .init(codingPath: container.codingPath, debugDescription: "Cannot convert color to RGB space."))
        }
        let red = rgbColor.redComponent
        let green = rgbColor.greenComponent
        let blue = rgbColor.blueComponent
        let alpha = rgbColor.alphaComponent
        #endif

        try container.encode(Double(red), forKey: .red)
        try container.encode(Double(green), forKey: .green)
        try container.encode(Double(blue), forKey: .blue)
        try container.encode(Double(alpha), forKey: .alpha)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let red = try container.decode(Double.self, forKey: .red)
        let green = try container.decode(Double.self, forKey: .green)
        let blue = try container.decode(Double.self, forKey: .blue)
        let alpha = try container.decode(Double.self, forKey: .alpha)
        self.color = Color(red: red, green: green, blue: blue, opacity: alpha)
    }
    
    init(color: Color) {
        self.color = color
    }
    
    private enum CodingKeys: String, CodingKey {
        case red, green, blue, alpha
    }
}
