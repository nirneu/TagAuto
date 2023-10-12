//
//  NotificationsManager.swift
//  FinnFinds
//
//  Created by Nir Neuman on 27/09/2023.
//

import Foundation
import UserNotifications

@MainActor
class NotificationsManager: ObservableObject {
    
    @Published private(set) var hasPermission = false
    
    init() {
        Task {
            await self.getAuthStatus()
        }
    }
    
    func request() async {
        do {
            self.hasPermission = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            print(error)
        }
    }
    
    func getAuthStatus() async {
        let status = await UNUserNotificationCenter.current().notificationSettings()
        switch status.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            hasPermission = true
        default:
            hasPermission = false
        }
    }
    
}
