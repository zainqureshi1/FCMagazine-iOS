//
//  Section.swift
//  FCMagazine
//
//  Created by Zain on 2/28/17.
//  Copyright © 2017 e2esp. All rights reserved.
//

import UIKit

class Section {
    var heading: String
    var itemsPerRow: Int
    var magazines: [Magazine]
    
    init(_ heading: String, withItemsPerRow itemsPerRow: Int, andMagazines magazines: [Magazine]) {
        self.heading = heading
        self.itemsPerRow = itemsPerRow
        self.magazines = magazines
    }
    
}
