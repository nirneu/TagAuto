//
//  FinnFinds.swift
//  FinnFinds
//
//  Created by Nir Neuman on 12/07/2023.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore
import FirebaseMessaging
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        FirebaseApp.configure()
        
        Messaging.messaging().delegate = self
        
        UNUserNotificationCenter.current().delegate = self
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { _, _ in }
        )
        
        application.registerForRemoteNotifications()
        
        return true
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        return [.banner, .badge, .list, .sound]
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        if let deepLink = response.notification.request.content.userInfo["link"] as? String {
            await UIApplication
                   .shared
                   .open(URL(string: "myfindcarapp://\(deepLink)")!)
        }
        
    }
}

extension AppDelegate: MessagingDelegate {
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        // Save FCM registration token in order to send notifications for the user's device
        Messaging.messaging().token { token, error in
            if let error = error {
                print("Error fetching FCM registration token: \(error)")
            } else if let token = token {
                let dataDict: [String: String] = [Constants.FCM_TOKEN: token]
                NotificationCenter.default.post(name: Notification.Name(Constants.FCM_TOKEN), object: token, userInfo: dataDict)
                // Save the fcm token in UserDefaults
                UserDefaults.standard.set(token, forKey: Constants.FCM_TOKEN)
            }
        }
    }
}

@main
struct FinnFinds: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    
    @StateObject var sessionService = SessionServiceImpl()
    
    var body: some Scene {
        WindowGroup {
            switch sessionService.state {
            case .loggedIn:
                HomeView()
                    .environmentObject(sessionService)

            case .loggedOut:
                LoginView()
            }
        }
    }
}
