//
//  MenuController.swift
//  THONAR
//
//  Created by Kevin Gardner on 12/14/18.
//  Copyright © 2018 THON. All rights reserved.
//

import UIKit

class MenuController: UIViewController {

    @IBOutlet weak var storyBookButton: MenuButton!
    
    @IBAction func MenuButtonPressed(_ sender: Any) {
        performSegue(withIdentifier: "ModeSelectedSegue", sender: sender)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        addBlurredBackgroundView(view: view)
        
        storyBookButton.mode = "Storybook"
    }
    
    func addBlurredBackgroundView(view: UIView!) {
        view.backgroundColor = .clear
        let blurEffect = UIBlurEffect(style: .light)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(blurView, at: 0)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Sets the viewController's mode when a button is pressed that performs the segue with
        //  identifier: ModeSelectedSegue
        if segue.identifier == "ModeSelectedSegue" {
            if let vc = segue.destination as? ViewController {
                if let button = sender as? MenuButton {
                    vc.mode = button.mode
                }
            }
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
