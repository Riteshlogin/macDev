//
//  UARTTextField.swift
//  PipelineBLE
//
//  Created by Samuel Peterson on 9/12/19.
//  Copyright © 2019 Samuel Peterson. All rights reserved.
//

import UIKit

class UARTTextField: UITextField {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configureStyle()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureStyle(){
        self.backgroundColor = UIColor(white: 1, alpha: 0.2)
        self.borderStyle = .roundedRect
        self.translatesAutoresizingMaskIntoConstraints = false
    }
    
}
