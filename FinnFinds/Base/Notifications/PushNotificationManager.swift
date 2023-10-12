//
//  PushNotifications.swift
//  FinnFinds
//
//  Created by Nir Neuman on 28/09/2023.
//

import Foundation

class PushNotificationManager {
    static func sendPushNotification(to receiverFCM: String, title: String, body: String, link: String) {
        if let serverKey = Bundle.main.infoDictionary?["SERVER_KEY"] as? String {
            
            let url = URL(string: "https://fcm.googleapis.com/fcm/send")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            // Set the request headers
            request.setValue("key=\(serverKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // Set the request body data
            let requestBody: [String: Any] = [
                "to": receiverFCM,
                "notification": [
                    "title": title,
                    "body": body
                ],
                "data": [
                    "link": link
                ]
            ]
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) {
                request.httpBody = jsonData
                
                // Send the request
                URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        print("Error: \(error.localizedDescription)")
                        return
                    }
                    
                    if let data = data {
                        if let responseString = String(data: data, encoding: .utf8) {
                            print("Response: \(responseString)")
                        }
                    }
                }.resume()
            }
        }
    }
}
