//
//  GroupDetailView.swift
//  FindCar
//
//  Created by Nir Neuman on 01/08/2023.
//

import SwiftUI

struct GroupDetailView: View {
    
    @State private var showingAddMember = false
    @State private var showingAddCar = false
    
    let group: Groups
    
    var body: some View {
        List {
            Section(header: headerView(title: "Members", action: { showingAddMember = true })) {
                ForEach(group.members, id: \.self) { member in
                    HStack {
                        Image(systemName: "person.fill")
                        Text(member)
                    }
                }
            }
            
            Section(header: headerView(title: "Cars", action: { showingAddCar = true })) {
                ForEach(group.cars, id: \.self) { car in
                    HStack {
                        Image(systemName: "car.fill")
                        Text(car)
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle(group.name)
        .sheet(isPresented: $showingAddMember) {
            // Display view to add a new member
        }
        .sheet(isPresented: $showingAddCar) {
            // Display view to add a new car
        }
    }
    
    private func headerView(title: String, action: @escaping () -> Void) -> some View {
        HStack {
            Text(title)
            Spacer()
            Button(action: action) {
                Image(systemName: "plus")
            }
        }
    }
}

struct GroupDetailView_Previews: PreviewProvider {
    static var previews: some View {
        GroupDetailView(group: Groups.mockGroups.first!)
    }
}
