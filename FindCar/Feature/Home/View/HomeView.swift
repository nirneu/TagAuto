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
    
    @StateObject private var carsViewModel = CarsViewModelImpl(service: CarsServiceImpl())
    
    var body: some View {
        
        TabView(selection: $selection) {
            
            GeometryReader { geometry in
                VStack {
                    
                    NavigationStack {
                        
                        MapView()
                            .environmentObject(carsViewModel)
                            .edgesIgnoringSafeArea(.top)
                    }
                    .frame(height: geometry.size.height * 0.7)
                    
                    
                    NavigationStack {
                        
                        CarsView()
                            .environmentObject(carsViewModel)
                    }
                    
                    .frame(height: (geometry.size.height * 0.3) - 15)
                }
            }
            .tabItem {
                Label("Cars", systemImage: "map")
            }
            .tag(1)
            
            GroupsView(selection: $selection)
                .tabItem {
                    Label("Groups", systemImage: "person.3")
                }
                .tag(2)
            
            NavigationStack {
                
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
                .navigationTitle("Profile")
                
            }
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle")
            }
            .tag(3)
            
        }
    }
    
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        //        NavigationStack {
        HomeView()
            .environmentObject(SessionServiceImpl())
        //        }
    }
}
