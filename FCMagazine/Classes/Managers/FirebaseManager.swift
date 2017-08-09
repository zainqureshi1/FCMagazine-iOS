//
//  FirebaseManager.swift
//  Fixer
//
//  Created by Zain on 4/7/17.
//  Copyright © 2017 e2esp. All rights reserved.
//

import Foundation
import Firebase

class FirebaseManager {
    
    static var instance: FirebaseManager!
    
    static func getInstance() -> FirebaseManager {
        if instance == nil {
            instance = FirebaseManager()
        }
        return instance
    }
    
    var delegate: FirebaseSignInDelegate?
    
    func configure() {
        FIRApp.configure()
    }
    
    func setDelegate(_ delegate: FirebaseSignInDelegate) {
        self.delegate = delegate
    }
    
    func getClientId() -> String! {
        return FIRApp.defaultApp()?.options.clientID
    }
    
    var stateChangeListeners = [UIViewController : FIRAuthStateDidChangeListenerHandle]()
    
    func addStateChangeListener(forViewController viewController:UIViewController) {
        let handler = FIRAuth.auth()?.addStateDidChangeListener() { (auth, user) in
            if let user = user {
                self.delegate?.firebaseSuccess(userId: user.uid, email: user.email!, displayName: user.displayName, photoUrl: user.photoURL)
            }
        }
        stateChangeListeners[viewController] = handler
    }
    
    func removeStateChangeListener(forViewController viewController:UIViewController) {
        FIRAuth.auth()?.removeStateDidChangeListener(stateChangeListeners[viewController]!)
    }
    
}
