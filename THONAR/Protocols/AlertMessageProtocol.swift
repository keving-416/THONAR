//
//  AlertMessageProtocol.swift
//  THONAR
//
//  Created by Kevin Gardner on 1/10/19.
//  Copyright © 2019 THON. All rights reserved.
//

import Foundation

enum AlertSize {
    case small
    case large
}
protocol AlertMessageDelegate {
    func showAlert(forMessage message: String, ofSize size: AlertSize, withDismissAnimation animated: Bool)
    func dismissAlert(ofSize size: AlertSize)
}


