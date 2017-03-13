//
//  ArrayHelper.swift
//  DJKSwiftFlipper
//
//  Created by Koza, Daniel on 7/13/15.
//  Copyright (c) 2015 Daniel Koza. All rights reserved.
//

import Foundation

//stolen from http://stackoverflow.com/a/24939100
extension Array {
    mutating func removeObject<U: Equatable>(_ object: U) -> Bool {
        for (idx, objectToCompare) in enumerated() {
            if let to = objectToCompare as? U {
                if object == to {
                    self.remove(at: idx)
                    return true
                }
            }
        }
        return false
    }
}
