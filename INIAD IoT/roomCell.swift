//
//  roomCell.swift
//  INIAD IoT
//
//  Created by Kentaro on 2019/05/28.
//  Copyright © 2019 Kentaro. All rights reserved.
//

import UIKit

class roomCell: UITableViewCell {

    @IBOutlet weak var room_name: UILabel!
    @IBOutlet weak var room_other_name: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
        super.setSelected(false, animated: animated)
    }

}
