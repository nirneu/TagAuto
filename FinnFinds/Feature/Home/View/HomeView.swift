//
//  HomeView.swift
//  FinnFinds
//
//  Created by Nir Neuman on 13/07/2023.
//

import SwiftUI

struct HomeView: View {
    
    @EnvironmentObject var sessionService: SessionServiceImpl
    
    @StateObject var carsViewModel = CarsViewModelImpl(service: CarsServiceImpl())
    @StateObject var groupsViewModel = GroupsViewModelImpl(service: GroupsServiceImpl())
    @StateObject var mapViewModel = MapViewModelImpl()
    
    @State private var showCarsSheet = true
    @State private var showMoreSheet = false
    @State private var showAccountView = false
    @State private var showGroupsView = false
    @State private var showEditCar = false
    @State private var sheetDetentSelection = PresentationDetent.fraction(Constants.defaultPresentationDetentFraction)
    @State private var selectedCar: Car?
    @State private var isVehicleDeleted: Bool = false
    @State private var dismissCarsView = true
    
    var body: some View {
        
        /*
            The front view of the app is based on a main map which has a permanent sheet on top for showing the user's cars and a specific car details.
            Then on top of the first sheet there's another sheet for more app info.
            This is designed like this in order to give the app the modern feel of Apple's maps apps.
        */
        MapView()
            .environmentObject(carsViewModel)
            .environmentObject(mapViewModel)
            .environmentObject(sessionService)
            .sheet(isPresented: $showCarsSheet) {
                
                VStack(alignment: .leading, spacing: 0) {
                    
                    // Show selected car details view
                    if let car = selectedCar {
                        
                        HStack {
                            Text(carsViewModel.currentCarInfo.icon)
                                .font(.title2.bold())
                            Text(carsViewModel.currentCarInfo.name)
                                .font(.title2.bold())
                            Button {
                                showEditCar = true
                            } label: {
                                Image(systemName: "pencil")
                                    .foregroundColor(Color(uiColor: .lightGray))
                                    .font(.title2)
                            }
                            Spacer()
                            
                            Button {
                                selectedCar = nil
                                carsViewModel.selectedCar = nil
                            } label: {
                                Image(systemName: "xmark.circle")
                                    .foregroundColor(Color(uiColor: .lightGray))
                                    .font(.title2)
                            }
                            
                        }
                        .padding([.top, .leading, .trailing, .bottom])
                        .onAppear {
                            carsViewModel.getCar(carId: car.id)
                        }
                        
                        CarDetailsView(carId: car.id)
                            .environmentObject(sessionService)
                            .environmentObject(mapViewModel)
                            .environmentObject(carsViewModel)
                            .padding([.leading, .trailing])
                            .sheet(isPresented: $showEditCar) {
                                EditCarView(isDelete: $isVehicleDeleted, car: car).environmentObject(groupsViewModel)
                                    .onDisappear {
                                        refreshCars()
                                        carsViewModel.getCar(carId: car.id)
                                        showEditCar = false
                                        if isVehicleDeleted {
                                            selectedCar = nil
                                        }
                                    }
                            }
                        
                    } else {
                        // Show cars view
                        HStack {
                            Text("Vehicles")
                                .font(.title2.bold())
                            Spacer()
                            Button {
                                showMoreSheet = true
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .foregroundColor(Color(uiColor: .lightGray))
                                    .font(.title2)
                            }
                            
                        }
                        .padding([.top, .leading, .trailing])
                        
                        CarsView(selectedCar: $selectedCar, sheetDetentSelection: $sheetDetentSelection)
                            .environmentObject(carsViewModel)
                            .environmentObject(mapViewModel)
                            .environmentObject(sessionService)
                            // Second sheet for more app information on top of the current sheet
                            .sheet(isPresented: $showMoreSheet, onDismiss: {
                                refreshCars()
                                showAccountView = false
                                showGroupsView = false
                            }) {
                                NavigationStack {
                                    
                                    List {
                                        // User's groups
                                        Section(header: Text("Groups")) {
                                            HStack {
                                                Button {
                                                    showGroupsView = true
                                                } label: {
                                                    Label("Groups", systemImage: "person.3")
                                                }
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .font(.footnote)
                                                    .foregroundStyle(.secondary)
                                            }
                                            .navigationDestination(isPresented: $showGroupsView) {
                                                GroupsView().environmentObject(groupsViewModel)
                                            }
                                            
                                        }
                                        // User's account info and it's group invitiations
                                        Section(header: Text("Account")) {
                                            HStack {
                                                Button {
                                                    showAccountView = true
                                                } label: {
                                                    Label("Account", systemImage: "person.crop.circle")
                                                }
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .font(.footnote)
                                                    .foregroundStyle(.secondary)
                                            }
                                            .navigationDestination(isPresented: $showAccountView) {
                                                AccountView()
                                            }
                                        }
                                    }
                                    .navigationTitle("More")
                                    .toolbar {
                                        ToolbarItem(placement: .navigationBarTrailing) {
                                            Button {
                                                showMoreSheet = false
                                            } label: {
                                                Text("Done")
                                            }
                                            
                                        }
                                    }
                                }
                                .presentationDetents([.large])
                                .presentationDragIndicator(.visible)
                            }
                    }
                    
                }
                .presentationDetents([.fraction(Constants.defaultPresentationDetentFraction), .large], selection: $sheetDetentSelection)
                .presentationDragIndicator(.visible)
                .interactiveDismissDisabled()
                .presentationBackgroundInteraction(.enabled)
                .onChange(of: carsViewModel.selectedCar) { newCar in
                    DispatchQueue.main.async {
                        selectedCar = newCar
                    }
                }
                .alert("Error", isPresented: $mapViewModel.hasError) {
                    Button("OK", role: .cancel) { }
                } message: {
                    if case .failed(let error) = mapViewModel.state {
                        Text(error.localizedDescription)
                    } else if case .unauthorized(let reason) = mapViewModel.state {
                        Text(reason)
                    } else {
                        Text("Something went wrong")
                    }
                }
            }
            // On opening the app from outside
            // Currently supports only for a notification about a group invitation
            .onOpenURL(perform: { url in
                guard url.scheme == "myfindcarapp" else {
                    return
                }
                guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
                    print("Invalid URL")
                    return
                }
                
                guard let action = components.host, action == "group-invitation" else {
                    print("Unknown URL, we can't handle this one!")
                    return
                }
                
                // Show the relevant views when someone open the app from a group invitation notification
                showMoreSheet = true
                showAccountView = true
            })
        
    }
    
    private func refreshCars() {
        if let userId = sessionService.userDetails?.userId {
            carsViewModel.isLoadingCars = true
            carsViewModel.fetchUserCars(userId: userId)
        }
    }
    
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        
        HomeView()
            .environmentObject(SessionServiceImpl())
    }
}
