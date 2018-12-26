//
//  MenuView.swift
//  THONAR
//
//  Created by Kevin Gardner on 12/19/18.
//  Copyright © 2018 THON. All rights reserved.
//

import UIKit

protocol MenuViewSelectionDelegate: class {
    func selectionView(inputView: UIView, didSelect mode: Mode)
}

class VisualEffectMenuView: UIVisualEffectView {
    
    var visualEffect: UIVisualEffect!
    
    init(forEffect effect: UIVisualEffect) {
        self.visualEffect = effect
        super.init(effect: self.visualEffect)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
