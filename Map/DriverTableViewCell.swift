//
//  DriverTableViewCell.swift
//  Map
//
//  Created by Gary Chen on 17/4/2018.
//  Copyright © 2018 Gary Chen. All rights reserved.
//

import UIKit

class DriverTableViewCell: UITableViewCell {

    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var userEmail: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    
    func configureCell(profileImage: UIImage, email: String, detail: String) {
        self.profileImage.image = profileImage
        self.userEmail.text = email
        self.detailLabel.text = detail
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
}
