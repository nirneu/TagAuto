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
    @State private var showEditCar = false
    @State private var sheetDetentSelection = PresentationDetent.fraction(Constants.defaultPresentationDetentFraction)
    @State private var selectedCar: Car?
    @State private var isVehicleDeleted: Bool = false
    @State private var dismissCarsView = true
    
    var body: some View {
        
        MapView()
            .environmentObject(carsViewModel)
            .environmentObject(mapViewModel)
            .sheet(isPresented: $showCarsSheet) {
                
                VStack(alignment: .leading, spacing: 0) {
                    
                    if let car = selectedCar {
                        
                        HStack {
//                            Text(car.icon)
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
                            .sheet(isPresented: $showMoreSheet, onDismiss: {
                                refreshCars()
                            }) {
                                NavigationStack {
                                    
                                    List {
                                        Section(header: Text("Groups")) {
                                            NavigationLink(destination: GroupsView().environmentObject(groupsViewModel)) {
                                                Label("Groups", systemImage: "person.3")
                                            }
                                            
                                        }
                                        Section(header: Text("Account")) {
                                            NavigationLink(destination: AccountView()) {
                                                Label("Account", systemImage: "person.crop.circle")
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
            }
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
