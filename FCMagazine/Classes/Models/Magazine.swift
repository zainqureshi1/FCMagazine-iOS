//
//  Magazine.swift
//  FCMagazine
//
//  Created by Zain on 8/8/17.
//  Copyright © 2017 e2esp. All rights reserved.
//

import UIKit

class Magazine {
    
    var name: String
    var coverImage: UIImage!
    var date: Date!
    
    var fileUrls: [URL]?
    
    var downloading = false
    var downloaded = false
    
    var totalPages = 0
    var downloadedPages = 0
    
    init(_ name: String, _ coverImage: UIImage, _ date: Date) {
        self.name = name
        self.coverImage = coverImage
        self.date = date
    }
    
}
