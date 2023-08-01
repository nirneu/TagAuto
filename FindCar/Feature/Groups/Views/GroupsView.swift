//
//  GroupsView.swift
//  FindCar
//
//  Created by Nir Neuman on 01/08/2023.
//

import SwiftUI

struct GroupsView: View {
    
    @StateObject private var vm = GroupsViewModelImpl(service: GroupsServiceImpl())
    
    @State private var showCreateGroup = false
    
    @Binding var selection: Int
    
    let mockGroups = Groups.mockGroups
    
    var body: some View {
        
        NavigationStack {
            
            VStack {
                
                switch vm.state {
                case .na:
                    List(mockGroups, id: \.id) { group in
                        NavigationLink(destination: GroupDetailView(group: group)) {
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
                                
                                Spacer() // This pushes the content to the left
                            }
                        }
                    }
                case .successful:
                    List(vm.groups, id: \.self) { group in
                        Text(group)
                    }
                case .failed(let error):
                    Text("Error: \(error.localizedDescription)")
                }
                
            }
            .onAppear {
                // Replace "testUserID" with the actual user id
                //            vm.fetchUserGroups(userId: "testUserID")
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
                        CreateGroup()
                    }
                }
            }
            
        }
        
    }
}

struct GroupsView_Previews: PreviewProvider {
    static var previews: some View {
        @State var mockInt: Int = 2
        
        GroupsView(selection: $mockInt)
    }
}
