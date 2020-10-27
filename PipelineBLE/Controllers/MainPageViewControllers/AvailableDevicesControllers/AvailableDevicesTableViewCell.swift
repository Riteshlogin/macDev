//
//  SavedDevicesTableViewCell.swift
//  PipelineAnalysis
//
//  Created by Samuel Peterson on 7/29/19.
//  Copyright © 2019 Samuel Peterson. All rights reserved.
//

import UIKit

class AvailableDevicesTableViewCell: UITableViewCell {
    
    //  Mark: UI components and peripheral data
    public let deviceName: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 22)
        label.textColor = .systemBlue
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    public let signalImage: UIImageView = {
        let image = UIImageView()
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()
    public let subtitle: UILabel = {
        let label = UILabel()
        label.font.withSize(10)
        label.textColor = .systemOrange
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override var isHighlighted: Bool {
        didSet{
            backgroundColor = isHighlighted ? UIColor.darkGray : super.backgroundColor
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?){
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        //  Set constraints
        SetUpConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func SetUpConstraints(){
        //  Add the label to the cell
        addSubview(deviceName)
        addSubview(subtitle)
        
        //  Add constraints to the label
        deviceName.topAnchor.constraint(equalTo: topAnchor, constant: 5).isActive = true
        deviceName.bottomAnchor.constraint(equalTo: subtitle.topAnchor, constant: -5).isActive = true
        deviceName.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5).isActive = true
        deviceName.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5).isActive = true
        
        //  Add constraints to the subtitle
        subtitle.topAnchor.constraint(equalTo: deviceName.bottomAnchor, constant: 5).isActive = true
        subtitle.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5).isActive = true
        subtitle.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5).isActive = true
        subtitle.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5).isActive = true
    }
    
    func setSubtitle(text: String, saved: Bool){
        subtitle.text = saved ? "Saved Device (\(text))" : "Not Saved"
    }
    
    
    /*override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }*/

    /*override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }*/

}
