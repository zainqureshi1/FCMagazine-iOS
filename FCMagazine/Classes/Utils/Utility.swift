//
//  Utility.swift
//  FCMagazine
//
//  Created by Zain on 8/8/17.
//  Copyright © 2017 e2esp. All rights reserved.
//

import UIKit

class Utility {
    
    static func showAlert(viewController:UIViewController, title:String, message:String, actionTitle:String = "OK", handler:((UIAlertAction)-> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: actionTitle, style: .default, handler: handler))
        viewController.present(alert, animated: true, completion: nil)
    }
    
    static func showMultiActionAlert(viewController:UIViewController, title:String, message:String, actionTitles:[String] = ["OK"], handlers:[((UIAlertAction)-> Void)]? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        for i in 0..<actionTitles.count {
            if let handlers = handlers, handlers.count > i {
                alert.addAction(UIAlertAction(title: actionTitles[i], style: .default, handler: handlers[i]))
            } else {
                alert.addAction(UIAlertAction(title: actionTitles[i], style: .default, handler: nil))
            }
        }
        viewController.present(alert, animated: true, completion: nil)
    }
    
    static func showActionSheet(viewController:UIViewController, sourceView:UIView?, title:String?, message:String?, actionTitle:String = "OK", handler:((UIAlertAction)-> Void)? = nil) {
        let actionSheet = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: actionTitle, style: .default, handler: handler))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        if let sourceView = sourceView {
            actionSheet.popoverPresentationController?.sourceView = sourceView
            actionSheet.popoverPresentationController?.sourceRect = sourceView.bounds
        }
        viewController.present(actionSheet, animated: true, completion: nil)
    }
    
    static func showMultiActionSheet(viewController:UIViewController, sourceView:UIView?, title:String, message:String, actionTitles:[String] = ["OK"], handlers:[((UIAlertAction)-> Void)]? = nil) {
        let actionSheet = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        for i in 0..<actionTitles.count {
            if let handlers = handlers, handlers.count > i {
                actionSheet.addAction(UIAlertAction(title: actionTitles[i], style: .default, handler: handlers[i]))
            } else {
                actionSheet.addAction(UIAlertAction(title: actionTitles[i], style: .default, handler: nil))
            }
        }
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        if let sourceView = sourceView {
            actionSheet.popoverPresentationController?.sourceView = sourceView
            actionSheet.popoverPresentationController?.sourceRect = sourceView.bounds
        }
        viewController.present(actionSheet, animated: true, completion: nil)
    }
    
}
