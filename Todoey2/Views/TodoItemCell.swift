import UIKit

class TodoItemCell: UITableViewCell {
    
    // MARK: - IBOutlets
    @IBOutlet private weak var checkButton: UIButton!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var containerView: UIView!
    
    // MARK: - Properties
    static let identifier = "TodoItemCell"
    var onCheckTapped: (() -> Void)?
    
    // MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    private func setupUI() {
        // Configure cell appearance
        backgroundColor = .clear
        selectionStyle = .none
        
        // Configure container view
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 10
        containerView.layer.masksToBounds = true
        
        // Configure button
        checkButton.addTarget(self, action: #selector(checkButtonTapped), for: .touchUpInside)
    }
    
    func configure(with item: Item) {
        // Configure text
        titleLabel.text = item.title
        titleLabel.textColor = UIColor(item.textColor.color)  // Ensure this is UIColor
        
        // Configure completion state
        if item.isCompleted {
            let attributeString = NSMutableAttributedString(string: item.title)
            attributeString.addAttribute(.strikethroughStyle, value: 2, range: NSRange(location: 0, length: item.title.count))
            titleLabel.attributedText = attributeString
            titleLabel.alpha = 0.7
            checkButton.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
            checkButton.tintColor = .systemGreen
        } else {
            titleLabel.attributedText = nil
            titleLabel.text = item.title
            titleLabel.alpha = 1.0
            checkButton.setImage(UIImage(systemName: "circle"), for: .normal)
            checkButton.tintColor = .systemGray3
        }
    }
    
    @objc private func checkButtonTapped() {
        onCheckTapped?()
    }
}
