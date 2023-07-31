//
//  HomeView.swift
//  FindCar
//
//  Created by Nir Neuman on 13/07/2023.
//

import SwiftUI

struct HomeView: View {
    
    @EnvironmentObject var sessionService: SessionServiceImpl
    
    @State private var selection = 1
    
    var body: some View {
        
        NavigationView {
            TabView(selection: $selection) {
                
                MapView()
                    .tabItem {
                        Label("FindCar", systemImage: "map")
                    }
                    .edgesIgnoringSafeArea(.top)
                    .tag(1)
                
                VStack(alignment: .leading, spacing: 16) {
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("First Name: \(sessionService.userDetails?.firstName ?? "NA")")
                        Text("Last Name: \(sessionService.userDetails?.lastName ?? "NA")")
                    }
                    
                    ButtonView(title: "Logout") {
                        sessionService.logout()
                    }
                }
                .padding(.horizontal, 16)
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
                .tag(2)
                
                Text("settings")
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                    .tag(3)
                
            }
            .navigationTitle(
                selection == 1 ? "" : selection == 2 ? "Profile" : "Settings"
            )
        }
    }
    
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HomeView()
                .environmentObject(SessionServiceImpl())
        }
    }
}
