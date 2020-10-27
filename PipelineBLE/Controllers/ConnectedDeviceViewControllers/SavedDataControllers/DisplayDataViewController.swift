//
//  DisplayDataViewController.swift
//  PipelineBLE
//
//  Created by Samuel Peterson on 10/16/19.
//  Copyright © 2019 Samuel Peterson. All rights reserved.
//

import UIKit

class DisplayDataViewController: UIViewController {
    
    //  UI Components
    var pageTitle = "Saved Data ID"
    var comTextView: UITextView = {
        let textView = UITextView()
        textView.returnKeyType = .done
        textView.isScrollEnabled = true
        textView.isEditable = false
        textView.backgroundColor = UIColor(white: 1, alpha: 0.2)
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()
    var dataAsString: String = ""
    var exportButton: UIBarButtonItem!
    var plot: Bool = false
    var plotData: [[[Double]]]?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set up the UI
        setUpUI()
    }
    
    // MARK: - Set Up UI
    func setUpUI(){
        //  Set background and title
        view.backgroundColor = .darkGray
        navigationItem.title = pageTitle
        
        //  Create export button
        exportButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(onClickExport(_:)))
        navigationItem.rightBarButtonItem = exportButton
        
        //  Init offset
        var textViewConstraint = navigationController?.navigationBar.frame.height ?? 20
        textViewConstraint += 35
        
        //  Decide how to set up depending on what we're working with
        if plot{
            //  Create the plot pages
            let plotPages = PlotPagesView()
            plotPages.translatesAutoresizingMaskIntoConstraints = false
            
            //  Add constraints to the plots
            genericConstraints(subView: plotPages, topOffset: textViewConstraint)
            
            //  Initialize the plots
            plotPages.initialize(data: plotData!)
        }
        else{
            /*
            //  Add items to screen
            view.addSubview(comTextView)
            
            //  Set the layout of the screen
            comTextView.topAnchor.constraint(equalTo: view.topAnchor, constant: textViewConstraint).isActive = true
            comTextView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -15).isActive = true
            comTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15).isActive = true
            comTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15).isActive = true
            */
            //  Add the generic constraints
            genericConstraints(subView: comTextView, topOffset: textViewConstraint)
            
            comTextView.text = dataAsString
            comTextView.font = comTextView.font?.withSize(20)
        }
        
        
    }
    
    func genericConstraints(subView: UIView, topOffset: CGFloat){
        //  Apply generic constraints
        view.addSubview(subView)
        
        //  Set the layout of the screen
        subView.topAnchor.constraint(equalTo: view.topAnchor, constant: topOffset).isActive = true
        subView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -15).isActive = true
        subView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15).isActive = true
        subView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15).isActive = true
    }
    
    //  MARK: - Actions
    @objc func onClickExport(_ export: UIBarButtonItem){
        //  Export button was pressed, call the export button class
        ExportData.exportData(view: self, button: exportButton, data: dataAsString as NSObject)
    }

}
