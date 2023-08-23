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
        
        TabView(selection: $selection) {
            
            CarsView(mockCars: [])
                .tabItem {
                    Label("Cars", systemImage: "car.2.fill")
                }
                .tag(1)
            
            GroupsView(selection: $selection)
                .tabItem {
                    Label("Groups", systemImage: "person.3")
                }
                .tag(2)
            
            AccountView()
                .tabItem {
                    Label("Account", systemImage: "person.crop.circle")
                }
                .tag(3)
        }
    }
    
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        
        HomeView()
            .environmentObject(SessionServiceImpl())
    }
}
