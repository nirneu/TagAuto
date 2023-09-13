//
//  FinnFinds.swift
//  FinnFinds
//
//  Created by Nir Neuman on 12/07/2023.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore

// Added class for Firebase setup
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct FinnFinds: App {
    // Register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
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
