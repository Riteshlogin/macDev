//
//  UARTButtons.swift
//  PipelineBLE
//
//  Created by Samuel Peterson on 9/12/19.
//  Copyright © 2019 Samuel Peterson. All rights reserved.
//

import UIKit

class UARTButtons: UIButton {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func configureVisual(text: String){
        //  Use this to ensure all buttons on the UART look identical
        self.setTitle(text, for: .normal)
        self.layer.borderColor = UIColor(red: 4/255, green: 155/255, blue: 255/255, alpha: 1).cgColor
        self.layer.borderWidth = 1
        self.layer.cornerRadius = 8
        self.backgroundColor = UIColor(white: 1, alpha: 0.5)
        self.backgroundColor = UIColor.clear
        self.setTitleColor(UIColor(red: 4/255, green: 155/255, blue: 255/255, alpha: 1), for: .normal)
        self.translatesAutoresizingMaskIntoConstraints = false
    }
}
