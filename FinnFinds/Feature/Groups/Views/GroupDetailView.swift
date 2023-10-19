//
//  GroupDetailView.swift
//  FinnFinds
//
//  Created by Nir Neuman on 01/08/2023.
//

import SwiftUI

struct GroupDetailView: View {
    
    @EnvironmentObject var vm: GroupsViewModelImpl
    @EnvironmentObject var sessionService: SessionServiceImpl
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showingInviteMember = false
    @State private var showingAddCar = false
    @State private var showDeleteGroup = false
    @State var selectedCar: Car?
    @State var isDelete: Bool = false
    @State var isError: Bool = false
    @State var errorMessage: String = ""
    
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
                                Image(systemName: "person.crop.circle")
                                    .foregroundColor(Color(uiColor: .systemBlue))
                                VStack(alignment: .leading) {
                                    Text(member.firstName + " " + member.lastName).font(.system(.headline)).bold()
                                    Text(member.userEmail).font(.subheadline)
                                }
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
            
            Section(header: headerView(title: "Vehicles", action: { showingAddCar = true })) {
                
                if vm.isLoadingCars {
                    ProgressView()
                } else {
                    
                    if !vm.groupCars.isEmpty {
                        ForEach(vm.groupCars.sorted { $0.name < $1.name }, id: \.self) { car in
                            HStack {
                                Text(car.icon)
                                Text(car.name)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedCar = car
                            }
                        }
                    } else {
                        Text("There are no vehicles yet")
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
        .sheet(item: $selectedCar, content: { car in
            EditCarView(isDelete: $isDelete, car: car)
                .environmentObject(vm)
        })
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showDeleteGroup.toggle()
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .alert("Delete Group", isPresented: $showDeleteGroup) {
            Button("Confirm", action: {
                vm.deleteGroup(group.id)
                self.showDeleteGroup = false
                presentationMode.wrappedValue.dismiss()
            })
            Button("Cancel", role: .cancel) {
                self.showDeleteGroup = false
            }
        } message: {
            Text("Are you sure you want to delete the group: \(group.name)?")
        }
        .alert("Error", isPresented: $vm.hasError) {
            Button("OK", role: .cancel) { }
        } message: {
            if case .failed(let error) = vm.state {
                Text(error.localizedDescription)
            } else {
                Text("Something went wrong")
            }
        }
        .alert("Error", isPresented: $isError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
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
        if vm.memberDetails.count > 1 {
            for index in offsets {
                let memberToDelete = vm.memberDetails.sorted { $0.firstName < $1.firstName }[index]
                
                vm.deleteMember(userId: memberToDelete.userId, groupId: group.id)
                
                if memberToDelete.userId == sessionService.userDetails?.userId {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        } else {
            DispatchQueue.main.async {
                errorMessage = "Cannot leave group with only one member"
                isError = true
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
