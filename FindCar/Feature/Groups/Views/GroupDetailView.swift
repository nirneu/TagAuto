//
//  GroupDetailView.swift
//  FindCar
//
//  Created by Nir Neuman on 01/08/2023.
//

import SwiftUI

struct GroupDetailView: View {
    
    @EnvironmentObject var vm: GroupsViewModelImpl
    
    @State private var showingAddMember = false
    @State private var showingAddCar = false
    
    let group: GroupDetails
    
    var body: some View {
        List {
            Section(header: headerView(title: "Members", action: { showingAddMember = true })) {
                if !vm.memberDetails.isEmpty {
                    ForEach(vm.memberDetails, id: \.self) { member in
                        HStack {
                            Image(systemName: "person.fill")
                            Text(member.firstName + " " + member.lastName)
                        }
                    }
                } else {
                    ForEach(group.members, id: \.self) { member in
                        HStack {
                            Image(systemName: "person.fill")
                            Text(member)
                        }
                    }
                }
            }
            .onAppear {
                vm.fetchUserDetails(for: group.members)
            }
            
            Section(header: headerView(title: "Cars", action: { showingAddCar = true })) {
                if !vm.groupCars.isEmpty {
                    ForEach(vm.groupCars, id: \.self) { car in
                        HStack {
                            Image(systemName: "car.fill")
                            Text(car.name)
                        }
                    }
                } else {
                    ForEach(group.cars, id: \.self) { car in
                        HStack {
                            Image(systemName: "car.fill")
                            Text(car)
                        }
                    }
                }
         
            }
            .onAppear {
                vm.fetchGroupCars(groupId: group.id)
            }
            .onReceive(vm.$carCreated) { created in
                if created {
                    vm.fetchGroupCars(groupId: group.id)
                    vm.carCreated = false
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle(group.name)
        .sheet(isPresented: $showingAddMember) {
            // Display view to add a new member
        }
        .sheet(isPresented: $showingAddCar) {
            AddCarView(showingSheet: $showingAddCar, group: group)
                .environmentObject(vm)
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
        
        let viewModel = GroupsViewModelImpl(service: GroupsServiceImpl())
        
        GroupDetailView(group: GroupDetails.mockGroups.first!)
            .environmentObject(viewModel)
    }
}
