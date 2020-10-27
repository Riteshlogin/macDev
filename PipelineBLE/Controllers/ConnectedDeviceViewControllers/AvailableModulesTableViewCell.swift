//
//  AvailableModulesTableViewCell.swift
//  PipelineBLE
//
//  Created by Samuel Peterson on 8/26/19.
//  Copyright © 2019 Samuel Peterson. All rights reserved.
//

import UIKit

class AvailableModulesTableViewCell: UITableViewCell {

    //  Mark: UI components and module data
    public let moduleName: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.text = "~Module Name~"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    public let moduleImage: UIImageView = {
        let image = UIImageView()
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        //  Must alter the individual cell
        SetUpConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func SetUpConstraints(){
        //  Add device name
        addSubview(moduleName)
        
        //  Add constraints to the label
        moduleName.topAnchor.constraint(equalTo: topAnchor, constant: 10).isActive = true
        moduleName.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10).isActive = true
        moduleName.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10).isActive = true
        moduleName.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10).isActive = true
        
        //  Change background
        backgroundView?.tintColor = .blue
    }
    
    /*
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }*/

}
