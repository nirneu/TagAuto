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
    @StateObject var mapViewModel = MapViewModelImpl()
    
    @State private var showCarsSheet = true
    @State private var showMoreSheet = false
    @State private var sheetDetentSelection = PresentationDetent.fraction(Constants.defaultPresentationDetentFraction)
    @State private var selectedCar: Car?
    @State private var dismissCarsView = true
    
    var body: some View {
        
        MapView()
            .environmentObject(carsViewModel)
            .environmentObject(mapViewModel)
            .sheet(isPresented: $showCarsSheet) {
                
                VStack(alignment: .leading, spacing: 0) {
                    
                    if let car = selectedCar {
                        
                        HStack {
                            Text(car.icon)
                                .font(.title2.bold())
                            Text(car.name)
                                .font(.title2.bold())
                            
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
                        
                        CarDetailsView(carId: car.id)
                            .environmentObject(sessionService)
                            .environmentObject(mapViewModel)
                            .environmentObject(carsViewModel)
                            .padding([.leading, .trailing])
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
                                if let userId = sessionService.userDetails?.userId {
                                    carsViewModel.isLoadingCars = true
                                    carsViewModel.fetchUserCars(userId: userId)
                                }
                            }) {
                                NavigationStack {
                                    
                                    List {
                                        Section(header: Text("Groups")) {
                                            NavigationLink(destination: GroupsView()) {
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
    
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        
        HomeView()
            .environmentObject(SessionServiceImpl())
    }
}
