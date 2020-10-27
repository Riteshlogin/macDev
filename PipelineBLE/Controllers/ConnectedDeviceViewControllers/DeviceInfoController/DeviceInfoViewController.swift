//
//  DeviceInfoViewController.swift
//  PipelineBLE
//
//  Created by Samuel Peterson on 8/26/19.
//  Copyright © 2019 Samuel Peterson. All rights reserved.
//

import UIKit
import CoreData

class DeviceInfoViewController: UIViewController {

    private let pageTitle = "Device Info"
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    let originalNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    let uuidLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    let notesLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    let nameTextBox: UITextField = {
        let box = UITextField()
        box.translatesAutoresizingMaskIntoConstraints = false
        box.font = UIFont.boldSystemFont(ofSize: 18)
        box.borderStyle = .roundedRect
        box.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 1))
        box.leftViewMode = .always
        box.backgroundColor = UIColor(white: 1, alpha: 0.2)
        return box
    }()
    let originalNameTextBox: UITextField = {
        let box = UITextField()
        box.translatesAutoresizingMaskIntoConstraints = false
        box.font = UIFont.boldSystemFont(ofSize: 18)
        box.borderStyle = .roundedRect
        box.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 1))
        box.leftViewMode = .always
        box.backgroundColor = UIColor(white: 1, alpha: 0.2)
        return box
    }()
    let uuidTextBox: UITextField = {
        let box = UITextField()
        box.translatesAutoresizingMaskIntoConstraints = false
        box.adjustsFontSizeToFitWidth = true
        box.font = UIFont.boldSystemFont(ofSize: 18)
        box.borderStyle = .roundedRect
        box.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 1))
        box.leftViewMode = .always
        box.backgroundColor = UIColor(white: 1, alpha: 0.2)
        return box
    }()
    let notesTextBox: UITextView = {
        let box = UITextView()
        box.translatesAutoresizingMaskIntoConstraints = false
        box.font = UIFont.boldSystemFont(ofSize: 18)
        box.layer.cornerRadius = 8
        box.layer.borderWidth = 1
        box.layer.borderColor = UIColor.gray.cgColor
        box.backgroundColor = UIColor(white: 1, alpha: 0.2)
        box.isScrollEnabled = true
        return box
    }()
    let scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.showsVerticalScrollIndicator = false
        scroll.showsHorizontalScrollIndicator = false
        return scroll
    }()
    let saveButton: UARTButtons = {
        let button = UARTButtons()
        button.configureVisual(text: "  Save  ")
        button.showsTouchWhenHighlighted = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    let doneEditingBar: UIToolbar = {
        let toolbar = UIToolbar(frame: CGRect(x: 0.0, y: 0.0, width: UIScreen.main.bounds.size.width, height: 44.0))
        let flexible = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)//2
        let barButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(done(_:)))//3
        toolbar.setItems([flexible, barButton], animated: false)
        return toolbar
    }()
    
    weak var blePeripheral: BlePeripheral?
    var savedPeripheral: SavedPeripheral?
    
    //  Bottom anchor to adjust when keyboard is open
    var bottomConstraint: NSLayoutConstraint?
    private let keyboardPositionNotifier = KeyboardPositionNotifier()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //  Set up the UI
        setupUI()
        
        //  Make self delegate to know when keyboard is toggled
        keyboardPositionNotifier.delegate = self
    }
    
    func loadData(){
        //  Let's load in any data available about the device
        
    }
    
    func setupUI(){
        //  Change the title of the screen
        navigationItem.title = savedPeripheral?.name ?? blePeripheral?.name ?? "Device Info"
        view.backgroundColor = .darkGray
        
        //  Add scrollview
        view.addSubview(scrollView)
        
        //  Now set up the scrollview subviews
        scrollView.addSubview(nameLabel)
        scrollView.addSubview(nameTextBox)
        scrollView.addSubview(originalNameLabel)
        scrollView.addSubview(originalNameTextBox)
        scrollView.addSubview(uuidLabel)
        scrollView.addSubview(uuidTextBox)
        scrollView.addSubview(notesLabel)
        scrollView.addSubview(notesTextBox)
        scrollView.addSubview(saveButton)
        
        //  Make scrollview the size of the screen
        scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: 10).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10).isActive = true
        scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10).isActive = true
//        view.setNeedsLayout()
//        view.layoutIfNeeded()
        
        //  Start adding components to the scrollview top down
        nameLabel.text = "Saved Name:"
        nameLabel.textAlignment = .left
        nameLabel.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 10).isActive = true
        nameLabel.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor).isActive = true
        nameLabel.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor).isActive = true
        nameLabel.bottomAnchor.constraint(equalTo: nameTextBox.topAnchor, constant: -10).isActive = true
        nameLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
        
        nameTextBox.text = savedPeripheral?.name
        genericConstraints(main: nameTextBox, bottom: originalNameLabel, top: nameLabel, superView: scrollView)
        
        originalNameLabel.text = "Advertised Name:"
        originalNameLabel.textAlignment = .left
        genericConstraints(main: originalNameLabel, bottom: originalNameTextBox, top: nameTextBox, superView: scrollView)
        
        originalNameTextBox.placeholder = savedPeripheral?.originalName ?? blePeripheral?.name ?? "Unavailable"
        originalNameTextBox.isEnabled = false
        genericConstraints(main: originalNameTextBox, bottom: uuidLabel, top: originalNameLabel, superView: scrollView)
        
        uuidLabel.text = "UUID:"
        uuidLabel.textAlignment = .left
        genericConstraints(main: uuidLabel, bottom: uuidTextBox, top: originalNameTextBox, superView: scrollView)
        
        uuidTextBox.placeholder = savedPeripheral?.uuid?.uuidString ?? blePeripheral?.identifier.uuidString ?? "Unavailable"
        uuidTextBox.isEnabled = false
        genericConstraints(main: uuidTextBox, bottom: notesLabel, top: uuidLabel, superView: scrollView)
        
        notesLabel.text = "Device Notes:"
        notesLabel.textAlignment = .left
        genericConstraints(main: notesLabel, bottom: notesTextBox, top: uuidTextBox, superView: scrollView)
        
        notesTextBox.text = savedPeripheral?.notes
        genericConstraints(main: notesTextBox, bottom: saveButton, top: notesLabel, superView: scrollView)
        notesTextBox.heightAnchor.constraint(equalTo: scrollView.heightAnchor, multiplier: 0.6).isActive = true
        
        //  Need to do more custom constraints for the button
        saveButton.topAnchor.constraint(equalTo: notesTextBox.bottomAnchor, constant: 10).isActive = true
        saveButton.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        saveButton.addTarget(self, action: #selector(save(_:)), for: .touchDown)
        
        //  Keep track of the save button bottom anchor so we can adjust when keyboard opens
        bottomConstraint = saveButton.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -10)
        bottomConstraint?.isActive = true
        
        //  Add a done button to the editable views
        nameTextBox.inputAccessoryView = doneEditingBar
        notesTextBox.inputAccessoryView = doneEditingBar
    
    }
    
    func genericConstraints(main: UIView, bottom: UIView, top: UIView, superView: UIView){
        //  Apply generic constraints to the views
        main.topAnchor.constraint(equalTo: top.bottomAnchor, constant: 10).isActive = true
        main.leadingAnchor.constraint(equalTo: superView.leadingAnchor).isActive = true
        main.trailingAnchor.constraint(equalTo: superView.trailingAnchor).isActive = true
        main.bottomAnchor.constraint(equalTo: bottom.topAnchor, constant: -10).isActive = true
        main.widthAnchor.constraint(equalTo: superView.widthAnchor).isActive = true
    }

    @objc func save(_ sender: AnyObject){
        //  Need to save the updated content to the saved peripheral
        savedPeripheral?.name = nameTextBox.text
        savedPeripheral?.notes = notesTextBox.text
        PersistenceService.saveContext()
    }
    
    @objc func done(_ sender: AnyObject){
        self.view.endEditing(true)
    }
}

extension DeviceInfoViewController: KeyboardPositionNotifierDelegate {
    func onKeyboardPositionChanged(keyboardFrame: CGRect, keyboardShown: Bool) {
        if keyboardShown {
            // Keyboard is now shown, so we want to adjust the view
            let spacerHeight = keyboardFrame.height
            bottomConstraint?.isActive = false
            bottomConstraint = saveButton.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -1 * spacerHeight)
            bottomConstraint?.isActive = true
        }
        else{
            //  Keyboard is hidden, so readjust back to normal size
            bottomConstraint?.isActive = false
            bottomConstraint = saveButton.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -10)
            bottomConstraint?.isActive = true
        }
    }
    
    
}
