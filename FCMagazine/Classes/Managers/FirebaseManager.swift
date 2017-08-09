//
//  FirebaseManager.swift
//  Fixer
//
//  Created by Zain on 4/7/17.
//  Copyright © 2017 e2esp. All rights reserved.
//

import Firebase

class FirebaseManager {
    
    static var instance: FirebaseManager!
    
    static func getInstance() -> FirebaseManager {
        if instance == nil {
            instance = FirebaseManager()
        }
        return instance
    }
    
    func configure() {
        FirebaseApp.configure()
    }
    
    func messagingDelegate(_ delegate: MessagingDelegate) {
        Messaging.messaging().delegate = delegate
    }
    
    func subscribe() {
        Messaging.messaging().subscribe(toTopic: "FCMagazine")
    }
    
    func unsubscribe() {
        Messaging.messaging().unsubscribe(fromTopic: "FCMagazine")
    }
    
}

extension AppDelegate : MessagingDelegate {
    // [START refresh_token]
    func messaging(_ messaging: Messaging, didRefreshRegistrationToken fcmToken: String) {
        print("Firebase registration token: \(fcmToken)")
    }
    // [END refresh_token]
    // [START ios_10_data_message]
    // Receive data messages on iOS 10+ directly from FCM (bypassing APNs) when the app is in the foreground.
    // To enable direct data messages, you can set Messaging.messaging().shouldEstablishDirectChannel to true.
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        print("Received data message: \(remoteMessage.appData)")
    }
    // [END ios_10_data_message]
}
