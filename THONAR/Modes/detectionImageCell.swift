//
//  detectionImageCell.swift
//  THONAR
//
//  Created by Kevin Gardner on 2/3/19.
//  Copyright © 2019 THON. All rights reserved.
//

import UIKit


class DetectionImageCollectionCell: UICollectionViewCell {
    
    var imageView: UIImageView = UIImageView()
    
    func autolayoutCell() {
        self.addSubview(imageView)
        
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        imageView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
    }
    
    var image: UIImage? {
        didSet {
            imageView.alpha = 0.0
            imageView.image = image
            
            UIView.animate(withDuration: 0.3) {
                self.imageView.alpha = 1.0
            }
        }
    }
}
