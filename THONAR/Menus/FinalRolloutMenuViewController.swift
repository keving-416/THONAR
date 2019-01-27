//
//  MenuViewController.swift
//  THONAR
//
//  Created by Kevin Gardner on 12/19/18.
//  Copyright © 2018 THON. All rights reserved.
//

import UIKit


class FinalRolloutMenuViewController: MenuViewController {

    @IBOutlet weak var gameButton: MenuButton!
    @IBOutlet weak var storybookButton: MenuButton!
    @IBOutlet weak var dismissMenuButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    // Called in super class
    override func setUpButtons() {
        gameButton.mode = "Game"
        gameButton.arMode = GameMode(forView: sceneView!)
        buttons?.append(gameButton)
        
        storybookButton.mode = "Storybook"
        storybookButton.arMode = TourMode(forView: sceneView!)
        buttons?.append(storybookButton)
        
        // Make menu button a circle
        dismissMenuButton.layer.cornerRadius = dismissMenuButton.frame.width/2
        buttons?.append(dismissMenuButton)
    }
    
    @IBAction func menuButtonPressed(_ sender: Any) {
        if let button = sender as? UIButton {
            print("Menu button pressed")
            // Call on the menuDelegate to handle what happens when a button is tapped
            menuDelegate?.menuViewControllerMenuButtonTapped(forViewController: self, forSender: button)
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
