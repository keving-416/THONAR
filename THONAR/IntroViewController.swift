//
//  IntroViewController.swift
//  THONAR
//
//  Created by Kevin Gardner on 2/3/19.
//  Copyright © 2019 THON. All rights reserved.
//

import UIKit

class IntroViewController: UIViewController {

    @IBOutlet weak var overlayView: UIView!
    @IBOutlet weak var backgroundImageView: UIImageView!
    
    @IBOutlet weak var pageTitle: UILabel!
    @IBOutlet weak var pageDescription: UILabel!
    
    @IBOutlet weak var pageControl: UIPageControl!
    
    @IBOutlet weak var nextButton: UIButton!
    
    var titleArray = ["Bubble Mode",
                      "Tour Mode",
                      "Four Diamond Pop-Up",
                      "THON in Numbers"]
    
    var descriptionArray = ["Blow bubbles all around you by either tapping the screen or blowing into the phone",
                            "Experience the magic of the Bryce Jordan Center by pointing the camera at certain photos. These images will come to life in front of your very eyes!",
                            "Learn about the meaning behind Four Diamonds like never before",
                            "Learn about the impact of THON by the numbers"]
    
    var imageArray = [UIImage(named: "Intro (Test)"),
                      UIImage(named: "Intro (test 3)"),
                      UIImage(named: "Intro (test 2)"),
                      UIImage(named: "Intro (Test)")]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let leftswap = UISwipeGestureRecognizer(target: self, action: #selector(handleSwap(_:)))
        let rightswap = UISwipeGestureRecognizer(target: self, action: #selector(handleSwap(_:)))
        
        leftswap.direction = .left
        rightswap.direction = .right
        view.addGestureRecognizer(leftswap)
        view.addGestureRecognizer(rightswap)
        
        pageControl.numberOfPages = titleArray.count
        
        pageTitle.text = titleArray[pageControl.currentPage]
        pageDescription.text = descriptionArray[pageControl.currentPage]
        backgroundImageView.image = imageArray[pageControl.currentPage]
        
        overlayView.layer.cornerRadius = 10
        
        backgroundImageView.layer.cornerRadius = 10
        backgroundImageView.clipsToBounds = true
        
        nextButton.alpha = 0.0
        
    }
    
    @objc func handleSwap(_ sender: UISwipeGestureRecognizer){
        if (sender.direction == .left) && (pageControl.currentPage < (titleArray.count - 1)) {
            pageControl.currentPage += 1
            pageTitle.text = titleArray[pageControl.currentPage]
            pageDescription.text = descriptionArray[pageControl.currentPage]
            backgroundImageView.image = imageArray[pageControl.currentPage]
            
            if pageControl.currentPage == titleArray.count-1 {
                nextButton.alpha = 1.0
            }
        }
        
        if(sender.direction == .right) && (pageControl.currentPage > 0){
            pageControl.currentPage -= 1
            pageTitle.text = titleArray[pageControl.currentPage]
            pageDescription.text = descriptionArray[pageControl.currentPage]
            backgroundImageView.image = imageArray[pageControl.currentPage]
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
