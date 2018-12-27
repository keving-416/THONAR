//
//  MenuViewController.swift
//  THONAR
//
//  Created by Kevin Gardner on 12/21/18.
//  Copyright © 2018 THON. All rights reserved.
//

import UIKit
import ARKit

protocol MenuViewControllerDelegate: class {
    func menuViewControllerMenuButtonTapped(forViewController viewController: UIViewController, forSender sender: MenuButton)
}

class MenuViewController: UIViewController {
    
    weak var menuDelegate: MenuViewControllerDelegate?
    
    @IBOutlet var menuView: UIView!
    @IBOutlet var backgroundMenuView: UIVisualEffectView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.menuView.alpha = 0
        
        // Set button modes
        setUpButtons()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        UIView.animate(withDuration: 0.4) {
            self.menuView.alpha = 1
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // Animation not working because the view is already gone by this point???
        UIView.animate(withDuration: 0.3) {
            self.menuView.alpha = 0
        }
    }
    
    // Implement in subclasses
    func setUpButtons() {}
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
