//
//  MenuButton.swift
//  THONAR
//
//  Created by Kevin Gardner on 12/14/18.
//  Copyright © 2018 THON. All rights reserved.
//

import UIKit

class MenuButton: UIButton {
    
    var mode: String
    var arMode: Mode?
    
    public init(forMode modeTypeString:String, modeType: Mode) {
        self.mode = modeTypeString
        self.arMode = modeType
        super.init(frame: .zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.mode = ""
        self.arMode = nil
        super.init(coder: aDecoder)
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
