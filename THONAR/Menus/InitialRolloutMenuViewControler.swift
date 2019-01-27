//
//  InitialRolloutMenuViewControler.swift
//  THONAR
//
//  Created by Kevin Gardner on 12/21/18.
//  Copyright © 2018 THON. All rights reserved.
//

import UIKit

class InitialRolloutMenuViewController: MenuViewController {
    
    // Add @IBOutlet for each button in menu
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        setUpButtons()
    }
    
    override func setUpButtons() {
        // Set arMode for each button in menu
    }
    
    @IBAction func menuButtonPressed(_ sender: Any) {
        if let button = sender as? MenuButton {
            print("Menu button pressed")
            // Call on the menuDelegate to handle what happens when a button is tapped
            menuDelegate?.menuViewControllerMenuButtonTapped(forViewController: self, forSender: button)
        }
    }
    
    
    @IBAction func dismissMenu(_ sender: Any) {
        
    }
    
}
