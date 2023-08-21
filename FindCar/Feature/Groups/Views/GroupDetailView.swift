//
//  GroupDetailView.swift
//  FindCar
//
//  Created by Nir Neuman on 01/08/2023.
//

import SwiftUI

struct GroupDetailView: View {
    
    @EnvironmentObject var vm: GroupsViewModelImpl
    @EnvironmentObject var sessionService: SessionServiceImpl
    
    @State private var showingInviteMember = false
    @State private var showingAddCar = false
    
    let group: GroupDetails
    
    var body: some View {
        List {
            Section(header: headerView(title: "Members", action: { showingInviteMember = true })) {
                
                if vm.isLoadingMembers {
                    ProgressView()
                } else {
                    
                    if !vm.memberDetails.isEmpty {
                        ForEach(vm.memberDetails.sorted { $0.firstName < $1.firstName }, id: \.self) { member in
                            HStack {
                                Image(systemName: "person.fill")
                                Text(member.firstName + " " + member.lastName)
                            }
                        }
                        .onDelete(perform: deleteMember(at:))
                    } else {
                        Text("There are no members yet")
                    }
                }
            }
            .onAppear {
                vm.getMembers(of: group.id)
            }
            .onReceive(vm.$userListReload) { change in
                if change {
                    vm.getMembers(of: group.id)
                    vm.userListReload = false
                }
            }
            
            Section(header: headerView(title: "Cars", action: { showingAddCar = true })) {
                
                if vm.isLoadingCars {
                    ProgressView()
                } else {
                    
                    if !vm.groupCars.isEmpty {
                        ForEach(vm.groupCars.sorted { $0.name < $1.name }, id: \.self) { car in
                            HStack {
                                Image(systemName: "car.fill")
                                Text(car.name)
                            }
                        }
                        .onDelete(perform: deleteCar(at:))
                    } else {
                        Text("There are no cars yet")
                    }
                }
         
            }
            .onAppear {
                vm.fetchGroupCars(groupId: group.id)
            }
            .onReceive(vm.$carListReload) { change in
                if change {
                    vm.fetchGroupCars(groupId: group.id)
                    vm.carListReload = false
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle(group.name)
        .sheet(isPresented: $showingInviteMember) {
            InviteMemberView(showingSheet: $showingInviteMember, group: group)
                .environmentObject(vm)
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
    
    private func deleteCar(at offsets: IndexSet) {
        for index in offsets {
            let carToDelete = vm.groupCars.sorted { $0.name < $1.name }[index]
            vm.deleteCar(groupId: group.id, car: carToDelete)  
        }
    }
    
    private func deleteMember(at offsets: IndexSet) {
        for index in offsets {
            let memberToDelete = vm.memberDetails.sorted { $0.firstName < $1.firstName }[index]
            
            vm.deleteMember(userId: memberToDelete.userId, groupId: group.id)
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
