//
//  AlertMessageProtocol.swift
//  THONAR
//
//  Created by Kevin Gardner on 1/10/19.
//  Copyright © 2019 THON. All rights reserved.
//

import Foundation

protocol AlertMessageDelegate {
    func showAlert(forMessage message: String, withDismissAnimation animated: Bool)
    func dismissAlert()
}
