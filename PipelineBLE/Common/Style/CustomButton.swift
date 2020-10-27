//
//  CustomButton.swift
//  PipelineBLE
//
//  Created by Samuel Peterson on 9/12/19.
//  Copyright © 2019 Samuel Peterson. All rights reserved.
//

import UIKit

class CustomButton: UIButton {

    override var intrinsicContentSize: CGSize {
        let s = super.intrinsicContentSize
        return CGSize(width: s.width + titleEdgeInsets.left + titleEdgeInsets.right, height: s.height + titleEdgeInsets.top + titleEdgeInsets.bottom)
    }
}
