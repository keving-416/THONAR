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
    
    override func setUpButtons() {
        gameButton.mode = "Game"
        gameButton.arMode = GameMode(forView: sceneView!, forResourceGroup: resourceGroup!)
        buttons?.append(gameButton)
        
        storybookButton.mode = "Storybook"
        storybookButton.arMode = TourMode(forView: sceneView!, forResourceGroup: resourceGroup!)
        buttons?.append(storybookButton)
        
        // Make menu button a circle
        dismissMenuButton.layer.cornerRadius = dismissMenuButton.frame.width/2
        buttons?.append(dismissMenuButton)
    }
    
    @IBAction func menuButtonPressed(_ sender: Any) {
        if let button = sender as? UIButton {
            print("Menu button pressed")
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
