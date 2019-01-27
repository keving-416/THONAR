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
    func menuViewControllerMenuButtonTapped(forViewController viewController: MenuViewController, forSender sender: UIButton)
}

class MenuViewController: UIViewController {
    
    weak var menuDelegate: MenuViewControllerDelegate?
    
    @IBOutlet var menuView: UIView!
    @IBOutlet weak var backgroundMenuView: VisualEffectView!
    
    var buttons: [UIButton]?
    
    var sceneView: ARSCNView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        buttons = []
        
        // Set button modes
        setUpButtons()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // sets color to the yellow used for THON
        let color = UIColor(red: 0.996, green: 0.796, blue: 0.102, alpha: 1)
        
        // Fades in the menu
        UIView.animate(withDuration: 0.4) {
            self.menuView.alpha = 1
            
            // Sets the tint of the blur to color
            self.backgroundMenuView.colorTint = color
            
            // Sets the alpha of the tint
            self.backgroundMenuView.colorTintAlpha = 0.4
            
            // Sets the blur radius (changes how blurred the background is)
            self.backgroundMenuView.blurRadius = 10
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

/// VisualEffectView is a dynamic background blur view.
open class VisualEffectView: UIVisualEffectView {
    
    /// Returns the instance of UIBlurEffect.
    private let blurEffect = (NSClassFromString("_UICustomBlurEffect") as! UIBlurEffect.Type).init()
    
    /**
     Tint color.
     
     The default value is nil.
     */
    open var colorTint: UIColor? {
        get { return _value(forKey: "colorTint") as? UIColor }
        set { _setValue(newValue, forKey: "colorTint") }
    }
    
    /**
     Tint color alpha.
     
     The default value is 0.0.
     */
    open var colorTintAlpha: CGFloat {
        get { return _value(forKey: "colorTintAlpha") as! CGFloat }
        set { _setValue(newValue, forKey: "colorTintAlpha") }
    }
    
    /**
     Blur radius.
     
     The default value is 0.0.
     */
    open var blurRadius: CGFloat {
        get { return _value(forKey: "blurRadius") as! CGFloat }
        set { _setValue(newValue, forKey: "blurRadius") }
    }
    
    /**
     Scale factor.
     
     The scale factor determines how content in the view is mapped from the logical coordinate space (measured in points) to the device coordinate space (measured in pixels).
     
     The default value is 1.0.
     */
    open var scale: CGFloat {
        get { return _value(forKey: "scale") as! CGFloat }
        set { _setValue(newValue, forKey: "scale") }
    }
    
    // MARK: - Initialization
    
    public override init(effect: UIVisualEffect?) {
        super.init(effect: effect)
        
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        commonInit()
    }
    
    private func commonInit() {
        scale = 1
    }
    
    // MARK: - Helpers
    
    /// Returns the value for the key on the blurEffect.
    private func _value(forKey key: String) -> Any? {
        return blurEffect.value(forKeyPath: key)
    }
    
    /// Sets the value for the key on the blurEffect.
    private func _setValue(_ value: Any?, forKey key: String) {
        blurEffect.setValue(value, forKeyPath: key)
        self.effect = blurEffect
    }
}
