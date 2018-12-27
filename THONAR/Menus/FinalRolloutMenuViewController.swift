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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func setUpButtons() {
        gameButton.mode = "Game"
        gameButton.arMode = GameMode()
        
        storybookButton.mode = "Storybook"
        storybookButton.arMode = TourMode()
    }
    
    @IBAction func menuButtonPressed(_ sender: Any) {
        if let button = sender as? MenuButton {
            print("Menu button pressed")
            menuDelegate?.menuViewControllerMenuButtonTapped(forViewController: self, forSender: button)
        }
    }
    
    @IBAction func dismissMenu(_ sender: Any) {
        
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
