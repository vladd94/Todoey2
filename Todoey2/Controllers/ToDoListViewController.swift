//
//  ViewController.swift
//  Todoey
//
//  Copyright © 2019 App Brewery. All rights reserved.
//

import UIKit

// Move this extension outside the class, at file scope
extension UIView {
    static func animate(withSpring duration: TimeInterval, delay: TimeInterval, options: UIView.AnimationOptions, animations: @escaping () -> Void) {
        UIView.animate(
            withDuration: duration,
            delay: delay,
            usingSpringWithDamping: 0.6,
            initialSpringVelocity: 0.5,
            options: options,
            animations: animations,
            completion: nil
        )
    }
}

@available(iOS 14.0, *)
class ToDoListViewController: UITableViewController {
    private var items: [Item] = []
    let defaults = UserDefaults.standard
    private let openAIService = OpenAIService()
    
    // Add property for delete all button container
    private let deleteAllContainer: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .systemThinMaterial)
        let container = UIVisualEffectView(effect: blurEffect)
        container.translatesAutoresizingMaskIntoConstraints = false
        return container
    }()
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        loadItems()
        
        // Configure table view appearance
        tableView.separatorStyle = .none
        tableView.backgroundColor = .systemGroupedBackground
        tableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        
        // Add subtle cell spacing
        tableView.cellLayoutMarginsFollowReadableWidth = true
        
        // Configure navigation bar appearance
        navigationController?.navigationBar.prefersLargeTitles = true
        title = "Todoey ✓"
        
        // Ensure title is shown first
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.hidesSearchBarWhenScrolling = false // This helps maintain consistent spacing
        
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .systemBackground.withAlphaComponent(0.8)
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.systemIndigo,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        
        // Setup buttons after navigation bar configuration
        setupNavigationBar()
        setupDeleteAllButton()
    }
    
    private func setupNavigationBar() {
        // Create complete all button with matching style
        let completeAllButton = UIButton(type: .system)
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        
        // Update button based on completion state
        let areAllCompleted = !items.isEmpty && items.allSatisfy { $0.isCompleted }
        let image = areAllCompleted ?
            UIImage(systemName: "checkmark.circle", withConfiguration: symbolConfig) :
            UIImage(systemName: "checkmark.circle.fill", withConfiguration: symbolConfig)
        
        completeAllButton.setImage(image, for: .normal)
        completeAllButton.tintColor = .systemGreen
        completeAllButton.frame = CGRect(x: 0, y: 0, width: 54, height: 44) // Match cell button size
        completeAllButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 0) // Match cell button padding
        completeAllButton.addTarget(self, action: #selector(completeAllTapped), for: .touchUpInside)
        
        // Add button animations
        completeAllButton.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
        completeAllButton.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside])
        
        // Set as left bar button item
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: completeAllButton)
    }
    
    private func setupDeleteAllButton() {
        // Add delete container to view
        view.addSubview(deleteAllContainer)
        
        // Configure container constraints
        NSLayoutConstraint.activate([
            deleteAllContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            deleteAllContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            deleteAllContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            deleteAllContainer.heightAnchor.constraint(equalToConstant: 80)
        ])
        
        // Create delete button with container
        let buttonContainer = UIView()
        buttonContainer.translatesAutoresizingMaskIntoConstraints = false
        deleteAllContainer.contentView.addSubview(buttonContainer)
        
        // Center the button container
        NSLayoutConstraint.activate([
            buttonContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            buttonContainer.centerYAnchor.constraint(equalTo: deleteAllContainer.contentView.centerYAnchor),
            buttonContainer.widthAnchor.constraint(equalToConstant: 80),
            buttonContainer.heightAnchor.constraint(equalToConstant: 80)
        ])
        
        // Create delete button
        let deleteButton = UIButton(type: .system)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure button appearance
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 32, weight: .medium)
        let image = UIImage(systemName: "trash.circle.fill", withConfiguration: symbolConfig)
        deleteButton.setImage(image, for: .normal)
        deleteButton.tintColor = .systemRed
        
        // Add button target directly
        deleteButton.addTarget(self, action: #selector(deleteAllTapped), for: .touchUpInside)
        
        // Add button to container
        buttonContainer.addSubview(deleteButton)
        
        // Center button in its container
        NSLayoutConstraint.activate([
            deleteButton.centerXAnchor.constraint(equalTo: buttonContainer.centerXAnchor),
            deleteButton.centerYAnchor.constraint(equalTo: buttonContainer.centerYAnchor),
            deleteButton.widthAnchor.constraint(equalToConstant: 60),
            deleteButton.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        // Make everything interactive
        deleteButton.isUserInteractionEnabled = true
        buttonContainer.isUserInteractionEnabled = true
        deleteAllContainer.isUserInteractionEnabled = true
        deleteAllContainer.contentView.isUserInteractionEnabled = true
    }
    
    @objc private func completeAllTapped() {
        let areAllCompleted = !items.isEmpty && items.allSatisfy { $0.isCompleted }
        let actionTitle = areAllCompleted ? "Uncomplete All Items?" : "Complete All Items?"
        let actionMessage = areAllCompleted ? "This will unmark all items as completed." : "This will mark all items as completed."
        let buttonTitle = areAllCompleted ? "Uncomplete All" : "Complete All"
        
        let alert = UIAlertController(
            title: actionTitle,
            message: actionMessage,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: buttonTitle, style: .default) { [weak self] _ in
            guard let self = self else { return }
            
            // Toggle completion for all items
            for index in 0..<self.items.count {
                self.items[index].isCompleted = !areAllCompleted
            }
            
            self.saveItems()
            self.tableView.reloadData()
            self.setupNavigationBar() // Update complete all button appearance
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    @objc private func deleteAllTapped() {
        // Only show alert if there are items to delete
        guard !items.isEmpty else { return }
        
        let alert = UIAlertController(
            title: "Delete All Items?",
            message: "This action cannot be undone.",
            preferredStyle: .alert
        )
        
        let deleteAction = UIAlertAction(title: "Delete All", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            
            // Create index paths for all items
            let indexPaths = (0..<self.items.count).map { IndexPath(row: $0, section: 0) }
            
            // Remove all items
            self.items.removeAll()
            self.saveItems()
            
            // Update UI with animation
            UIView.animate(withSpring: 0.3, delay: 0, options: .curveEaseInOut) {
                self.tableView.deleteRows(at: indexPaths, with: .fade)
            }
            
            // Update complete all button state
            self.setupNavigationBar()
        }
        
        alert.addAction(deleteAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    // Update the table view insets
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.contentInset.bottom = 60  // Match the delete button container height
    }
    
    // MARK: - Data Management
    private func loadItems() {
        if let savedItems = defaults.array(forKey: "TodoListArray") as? [String] {
            items = savedItems.map { Item(title: $0) }
        } else {
            items = [
                Item(title: "Buy Eggos"),
                Item(title: "Destroy Demogorgon"),
                Item(title: "Find Mike")
            ]
        }
    }
    
    private func saveItems() {
        defaults.set(items.map { $0.title }, forKey: "TodoListArray")
    }
    
    //@available(iOS 14.0, *)
    //MARK: - UI Actions
    @available(iOS 14.0, *)
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        var textField = UITextField()
        let alert = UIAlertController(title: "Add New Todoey Item", 
                                    message: "", 
                                    preferredStyle: .alert)
        
        let action = UIAlertAction(title: "Add Item", style: .default) { [weak self] _ in
            guard let self = self,
                  let newItemTitle = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !newItemTitle.isEmpty else { return }
            
            // Show loading indicator
            let loadingAlert = UIAlertController(title: nil, message: "Generating inspiring options...", preferredStyle: .alert)
            let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
            loadingIndicator.hidesWhenStopped = true
            loadingIndicator.style = .medium
            loadingIndicator.startAnimating()
            loadingAlert.view.addSubview(loadingIndicator)
            self.present(loadingAlert, animated: true)
            
            // Generate options using OpenAI
            Task {
                do {
                    let options = try await self.openAIService.generateInspiringOptions(text: newItemTitle)
                    
                    DispatchQueue.main.async {
                        loadingAlert.dismiss(animated: true) {
                            if #available(iOS 14.0, *) {
                                // Use the custom UI for iOS 14 and above
                                let customizationVC = TaskCustomizationViewController(
                                    originalText: newItemTitle,
                                    aiSuggestions: options
                                )
                                customizationVC.delegate = self
                                let nav = UINavigationController(rootViewController: customizationVC)
                                self.present(nav, animated: true)
                            } else {
                                // Fallback for iOS 13 and below - use simple alert controller
                                let optionsAlert = UIAlertController(
                                    title: "Choose Your Task",
                                    message: "Select a version:",
                                    preferredStyle: .alert
                                )
                                
                                // Add AI suggestions
                                for option in options {
                                    let action = UIAlertAction(title: option, style: .default) { [weak self] _ in
                                        guard let self = self else { return }
                                        let item = Item(title: option)
                                        self.items.append(item)
                                        self.saveItems()
                                        self.tableView.reloadData()
                                    }
                                    optionsAlert.addAction(action)
                                }
                                
                                // Add original text option
                                let originalAction = UIAlertAction(title: "Use Original", style: .default) { [weak self] _ in
                                    guard let self = self else { return }
                                    let item = Item(title: newItemTitle)
                                    self.items.append(item)
                                    self.saveItems()
                                    self.tableView.reloadData()
                                }
                                optionsAlert.addAction(originalAction)
                                
                                // Add cancel option
                                optionsAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                                
                                self.present(optionsAlert, animated: true)
                            }
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        loadingAlert.dismiss(animated: true)
                        self.showError(error)
                    }
                }
            }
        }
        
        alert.addTextField { alertTextField in
            alertTextField.placeholder = "Create new item"
            textField = alertTextField
        }
        
        alert.addAction(action)
        present(alert, animated: true)
    }
    
    // MARK: - TableView Data Source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ToDoItemCell", for: indexPath)
        let item = items[indexPath.row]
        
        // Configure cell appearance with enhanced styling
        cell.backgroundColor = .clear
        
        // Create a background view with gradient
        let backgroundView = UIView()
        backgroundView.backgroundColor = .systemBackground
        backgroundView.layer.cornerRadius = 12
        backgroundView.layer.masksToBounds = true
        
        // Add shadow container
        let shadowContainer = UIView(frame: CGRect(x: 15, y: 5, width: cell.bounds.width - 30, height: cell.bounds.height - 10))
        shadowContainer.backgroundColor = .clear
        shadowContainer.layer.shadowColor = UIColor.black.cgColor
        shadowContainer.layer.shadowOffset = CGSize(width: 0, height: 2)
        shadowContainer.layer.shadowOpacity = 0.1
        shadowContainer.layer.shadowRadius = 4
        shadowContainer.layer.cornerRadius = 12
        
        // Add gradient background
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = shadowContainer.bounds
        gradientLayer.cornerRadius = 12
        
        if item.isCompleted {
            gradientLayer.colors = [
                UIColor.systemGray6.cgColor,
                UIColor.systemGray5.cgColor
            ]
        } else {
            gradientLayer.colors = [
                UIColor.systemBackground.cgColor,
                UIColor.systemGray6.withAlphaComponent(0.5).cgColor
            ]
        }
        
        backgroundView.layer.addSublayer(gradientLayer)
        shadowContainer.addSubview(backgroundView)
        cell.backgroundView = shadowContainer
        
        // Configure text label with enhanced styling
        cell.textLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        cell.textLabel?.text = item.title
        cell.textLabel?.textColor = UIColor(item.textColor.color)
        cell.textLabel?.adjustsFontForContentSizeCategory = true
        
        // Style for completed items
        if item.isCompleted {
            cell.textLabel?.alpha = 0.7
            let attributeString = NSMutableAttributedString(string: item.title)
            attributeString.addAttribute(.strikethroughStyle, value: 2, range: NSRange(location: 0, length: item.title.count))
            cell.textLabel?.attributedText = attributeString
        } else {
            cell.textLabel?.alpha = 1.0
            cell.textLabel?.attributedText = nil  // Remove any attributed text
            cell.textLabel?.text = item.title     // Set plain text
        }
        
        // Create and configure completion button with enhanced animation
        let button = UIButton(type: .system)
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        let image = item.isCompleted ? 
            UIImage(systemName: "checkmark.circle.fill", withConfiguration: symbolConfig) :
            UIImage(systemName: "circle", withConfiguration: symbolConfig)
        
        button.setImage(image, for: .normal)
        button.tintColor = item.isCompleted ? .systemGreen : .systemGray3
        button.tag = indexPath.row
        button.addTarget(self, action: #selector(completionButtonTapped(_:)), for: .touchUpInside)
        
        // Enhanced button animations
        button.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside])
        
        // Configure button container with padding
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 54, height: 44))
        button.frame = containerView.bounds
        containerView.addSubview(button)
        
        // Set up cell layout with increased spacing
        cell.accessoryView = nil
        cell.imageView?.contentMode = .center
        cell.imageView?.image = nil
        cell.indentationWidth = 54
        cell.indentationLevel = 1
        cell.selectionStyle = .none
        
        // Position button
        containerView.frame.origin.x = 5
        cell.contentView.addSubview(containerView)
        
        return cell
    }
    
    // Enhanced button animations
    @objc private func buttonTouchDown(_ sender: UIButton) {
        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            usingSpringWithDamping: 0.6,
            initialSpringVelocity: 0.5,
            options: .curveEaseInOut,
            animations: {
                sender.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                sender.alpha = 0.7
            },
            completion: nil
        )
    }
    
    @objc private func buttonTouchUp(_ sender: UIButton) {
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 0.6,
            initialSpringVelocity: 0.5,
            options: .curveEaseInOut,
            animations: {
                sender.transform = .identity
                sender.alpha = 1.0
            },
            completion: nil
        )
    }
    
    //Mark - TableView Delegate Methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        
        if #available(iOS 14.0, *) {
            // Show loading indicator
            let loadingAlert = UIAlertController(title: nil, message: "Generating new suggestions...", preferredStyle: .alert)
            let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
            loadingIndicator.hidesWhenStopped = true
            loadingIndicator.style = .medium
            loadingIndicator.startAnimating()
            loadingAlert.view.addSubview(loadingIndicator)
            present(loadingAlert, animated: true)
            
            // Generate new options using OpenAI
            Task {
                do {
                    let options = try await openAIService.generateInspiringOptions(text: item.title)
                    
                    DispatchQueue.main.async {
                        loadingAlert.dismiss(animated: true) {
                            let customizationVC = TaskCustomizationViewController(
                                originalText: item.title,
                                aiSuggestions: options
                            )
                            customizationVC.delegate = self
                            customizationVC.mode = TaskCustomizationMode.edit(index: indexPath.row)
                            // Set the current color
                            if #available(iOS 14.0, *) {
                                customizationVC.currentColor = UIColor(item.textColor.color)
                            }
                            let nav = UINavigationController(rootViewController: customizationVC)
                            self.present(nav, animated: true)
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        loadingAlert.dismiss(animated: true)
                        self.showError(error)
                    }
                }
            }
        } else {
            // Fallback for iOS 13 and below
            let alert = UIAlertController(title: "Edit Item", message: nil, preferredStyle: .alert)
            alert.addTextField { textField in
                textField.text = item.title
            }
            
            let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
                guard let self = self,
                      let newTitle = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                      !newTitle.isEmpty else { return }
                
                self.items[indexPath.row].title = newTitle
                self.saveItems()
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
            
            alert.addAction(saveAction)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            
            present(alert, animated: true)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - TableView Data Source & Delegate Methods
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Remove the item
            items.remove(at: indexPath.row)
            // Save the updated items array
            saveItems()
            // Delete the row with animation
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    // Add support for swipe actions with more customization
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .normal, title: "Delete") { [weak self] (action, view, completionHandler) in
            guard let self = self else { return }
            
            // Remove the item with animation
            self.items.remove(at: indexPath.row)
            self.saveItems()
            tableView.deleteRows(at: [indexPath], with: .fade)
            
            completionHandler(true)
        }
        
        // Style the delete action to match complete action
        deleteAction.backgroundColor = .systemRed
        deleteAction.image = UIImage(systemName: "trash.circle.fill")  // Using SF Symbol to match style
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        // Allow full swipe to delete
        configuration.performsFirstActionWithFullSwipe = true
        
        return configuration
    }
    
    // Add support for leading swipe actions
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let completeAction = UIContextualAction(style: .normal, title: "Complete") { [weak self] (action, view, completion) in
            guard let self = self else { return }
            
            // Toggle completion
            self.items[indexPath.row].isCompleted.toggle()
            self.saveItems()
            
            // Update cell with animation
            tableView.reloadRows(at: [indexPath], with: .automatic)
            
            completion(true)
        }
        
        // Use system green color for completion
        completeAction.backgroundColor = .systemGreen
        
        // Use checkmark image
        completeAction.image = UIImage(systemName: "checkmark.circle.fill")
        
        let configuration = UISwipeActionsConfiguration(actions: [completeAction])
        return configuration
    }
    
    // Add completion button action
    @objc private func completionButtonTapped(_ sender: UIButton) {
        let index = sender.tag
        items[index].isCompleted.toggle()
        saveItems()
        
        // Update the specific row
        let indexPath = IndexPath(row: index, section: 0)
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
    
    // Add helper method for showing errors
    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - TaskCustomizationDelegate
@available(iOS 14.0, *)
extension ToDoListViewController: TaskCustomizationDelegate {
    func didSaveTask(_ task: Item) {
        items.append(task)
        saveItems()
        tableView.reloadData()
    }
    
    func didUpdateTask(_ task: Item, at index: Int) {
        items[index] = task
        saveItems()
        tableView.reloadData()
    }
}

