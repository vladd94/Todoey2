import UIKit
import SwiftUICore

protocol TaskCustomizationDelegate: AnyObject {
    func didSaveTask(_ task: Item)
    func didUpdateTask(_ task: Item, at index: Int)
}

@available(iOS 14.0, *)
class TaskCustomizationViewController: UIViewController {
    
    // MARK: - Properties
    private let originalText: String
    private let aiSuggestions: [String]
    private var selectedText: String
    weak var delegate: TaskCustomizationDelegate?
    
    // Make mode property public with explicit type
    public var mode: TaskCustomizationMode = .create {
        didSet {
            if isViewLoaded {
                title = mode == .create ? "Create Task" : "Edit Task"
            }
        }
    }
    
    // Add property for current color
    public var currentColor: UIColor = .label {
        didSet {
            if isViewLoaded {
                colorPicker.selectedColor = currentColor
            }
        }
    }
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let textField: UITextField = {
        let field = UITextField()
        field.borderStyle = .roundedRect
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()
    
    private let colorPicker: UIColorWell = {
        let picker = UIColorWell()
        picker.supportsAlpha = false
        picker.selectedColor = .label
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }()
    
    // MARK: - Initialization
    init(originalText: String, aiSuggestions: [String]) {
        self.originalText = originalText
        self.aiSuggestions = aiSuggestions
        self.selectedText = aiSuggestions.first ?? originalText
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        colorPicker.selectedColor = currentColor
        setupUI()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Navigation items
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .save,
            target: self,
            action: #selector(saveTapped)
        )
        
        // Add main stack view
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        
        // Show AI suggestions for both create and edit modes
        let suggestionsLabel = UILabel()
        suggestionsLabel.text = "AI Suggestions:"
        suggestionsLabel.font = .boldSystemFont(ofSize: 16)
        stackView.addArrangedSubview(suggestionsLabel)
        
        // Add buttons for each suggestion
        for suggestion in aiSuggestions {
            let button = UIButton(type: .system)
            button.setTitle(suggestion, for: .normal)
            button.contentHorizontalAlignment = .left
            button.addTarget(self, action: #selector(suggestionTapped(_:)), for: .touchUpInside)
            stackView.addArrangedSubview(button)
        }
        
        // Add original text option
        let originalButton = UIButton(type: .system)
        originalButton.setTitle("Original: \(originalText)", for: .normal)
        originalButton.contentHorizontalAlignment = .left
        originalButton.addTarget(self, action: #selector(suggestionTapped(_:)), for: .touchUpInside)
        stackView.addArrangedSubview(originalButton)
        
        let separator = UIView()
        separator.backgroundColor = .separator
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        stackView.addArrangedSubview(separator)
        
        // Add text field
        let customLabel = UILabel()
        customLabel.text = mode == .create ? "Custom Text:" : "Edit Text:"
        customLabel.font = .boldSystemFont(ofSize: 16)
        stackView.addArrangedSubview(customLabel)
        
        textField.text = selectedText
        stackView.addArrangedSubview(textField)
        
        // Add color picker
        let colorLabel = UILabel()
        colorLabel.text = "Text Color:"
        colorLabel.font = .boldSystemFont(ofSize: 16)
        stackView.addArrangedSubview(colorLabel)
        
        stackView.addArrangedSubview(colorPicker)
    }
    
    // MARK: - Actions
    @objc private func suggestionTapped(_ sender: UIButton) {
        guard let text = sender.title(for: .normal) else { return }
        let cleanText = text.hasPrefix("Original: ") ? String(text.dropFirst(10)) : text
        textField.text = cleanText
        selectedText = cleanText
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func saveTapped() {
        guard let text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else { return }
        
        let uiColor = colorPicker.selectedColor ?? .label
        let swiftUIColor = Color(uiColor: uiColor) // Convert UIColor to Color
        
        let item = Item(title: text, textColor: swiftUIColor)
        
        if case .edit(let index) = mode {
            delegate?.didUpdateTask(item, at: index)
        } else {
            delegate?.didSaveTask(item)
        }
        
        dismiss(animated: true)
    }
}
