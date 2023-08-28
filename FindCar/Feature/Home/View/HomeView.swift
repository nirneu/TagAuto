//
//  HomeView.swift
//  FindCar
//
//  Created by Nir Neuman on 13/07/2023.
//

import SwiftUI

struct HomeView: View {
    
    @EnvironmentObject var sessionService: SessionServiceImpl
    
    @StateObject var carsViewModel = CarsViewModelImpl(service: CarsServiceImpl())
    @StateObject var mapViewModel = MapViewModelImpl(service: MapServiceImpl())
    
    @State private var showCarsSheet = true
    @State private var showMoreSheet = false
    @State private var sheetDetentSelection = PresentationDetent.fraction(0.3)
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
                            Text(car.name)
                                .font(.title2.bold())
                            
                            Spacer()
                            Button {
                                selectedCar = nil
                            } label: {
                                Image(systemName: "xmark.circle")
                                    .font(.title2)
                            }
                            
                        }
                        .padding([.top, .leading, .trailing, .bottom])
                        
                        CarDetailsView(car: car)
                            .environmentObject(sessionService)
                            .environmentObject(mapViewModel)
                            .environmentObject(carsViewModel)
                            .padding([.leading, .trailing])
                    } else {
                        HStack {
                            Text("Cars")
                                .font(.title2.bold())
                            Spacer()
                            Button {
                                showMoreSheet = true
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .font(.title2)
                            }
                            
                        }
                        .padding([.top, .leading, .trailing])
                        
                        CarsView(selectedCar: $selectedCar, dismissCarsView: $dismissCarsView)
                            .environmentObject(carsViewModel)
                            .environmentObject(mapViewModel)
                            .environmentObject(sessionService)
                            .sheet(isPresented: $showMoreSheet) {
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
                .background(.thinMaterial)
                .presentationDetents([.fraction(0.3), .large], selection: $sheetDetentSelection)
                .presentationDragIndicator(.visible)
                .interactiveDismissDisabled()
                .presentationBackgroundInteraction(.enabled)
            }
    }
    
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        
        HomeView()
            .environmentObject(SessionServiceImpl())
    }
}
