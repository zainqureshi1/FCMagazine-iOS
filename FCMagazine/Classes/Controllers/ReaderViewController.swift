//
//  ReaderViewController.swift
//  FCMagazine
//
//  Created by Zain on 2/27/17.
//  Copyright © 2017 e2esp. All rights reserved.
//

import UIKit

class ReaderViewController: UIViewController {

    func configureView() {
        if let magazine = self.magazineItem {
            
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureView()
    }

    var magazineItem: Magazine? {
        didSet {
            // Update the view.
            self.configureView()
        }
    }


}

