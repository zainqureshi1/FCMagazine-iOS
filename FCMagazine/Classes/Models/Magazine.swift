//
//  Magazine.swift
//  FCMagazine
//
//  Created by Zain on 2/27/17.
//  Copyright © 2017 e2esp. All rights reserved.
//

import UIKit

class Magazine: NSObject {
    
    var name: String
    var cover: UIImage!
    var dirPath: String
    var pageCount: Int
    
    var filler: Bool
    
    init(_ name: String, withCover cover: UIImage, _ dirPath: String, andPageCount pageCount: Int) {
        self.name = name
        self.cover = cover
        self.dirPath = dirPath
        self.pageCount = pageCount
        self.filler = false
    }
    
    init(isFiller filler: Bool) {
        self.name = ""
        self.cover = nil
        self.dirPath = ""
        self.pageCount = 0
        self.filler = filler
    }
    
}
