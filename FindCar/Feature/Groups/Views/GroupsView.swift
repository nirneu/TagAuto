//
//  GroupsView.swift
//  FindCar
//
//  Created by Nir Neuman on 01/08/2023.
//

import SwiftUI

struct GroupsView: View {
    
    @EnvironmentObject var sessionService: SessionServiceImpl
    
    @StateObject private var vm = GroupsViewModelImpl(service: GroupsServiceImpl())
    
    @State private var showCreateGroup = false
    
    @Binding var selection: Int
    
    let mockGroups = GroupDetails.mockGroups
    
    var body: some View {
        
        NavigationStack {
            
            VStack {
                
                switch vm.state {
                case .na:
                    Text("You don't have any Groups yet")
                case .successful:
                    if vm.groups.isEmpty {
                        Text("You don't have any Groups yet")
                    } else {
                        
                        List(vm.groups, id: \.id) { group in
                            NavigationLink(destination: GroupDetailView(group: group)
                                .environmentObject(vm)) {
                                    HStack {
                                        Image(systemName: "person.3")
                                            .frame(width: 20, height: 20)
                                            .padding(.trailing, 10)
                                        
                                        VStack(alignment: .leading) {
                                            Text("\(group.name)")
                                                .font(.headline)
                                            Text("Members: \(group.members.count)")
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                            Text("Cars: \(group.cars.count)")
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                        
                                        Spacer()
                                    }
                                }
                        }
                    }
                case .failed(let error):
                    Text("Error: \(error.localizedDescription)")
                }
                
            }
            .onAppear {
                vm.fetchUserGroups(userId: sessionService.userDetails?.userId ?? "")
            }
            .onReceive(vm.$groupCreated) { created in
                if created {
                    vm.fetchUserGroups(userId: sessionService.userDetails?.userId ?? "")
                    vm.groupCreated = false
                }
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
            .navigationTitle("Groups")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showCreateGroup.toggle()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .sheet(isPresented: $showCreateGroup, onDismiss: {
                        selection = 2
                    }) {
                        CreateGroupView(showingSheet: $showCreateGroup)
                            .environmentObject(vm)
                    }
                }
            }
            
        }
        
    }
}

struct GroupsView_Previews: PreviewProvider {
    static var previews: some View {
        
        let service = SessionServiceImpl()
        
        @State var mockInt: Int = 2
        
        GroupsView(selection: $mockInt)
            .environmentObject(service)
    }
}
