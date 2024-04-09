//
//  CarsView.swift
//  TagAuto
//
//  Created by Nir Neuman on 04/08/2023.
//

import SwiftUI

struct CarsView: View {
    
    @EnvironmentObject var sessionService: SessionServiceImpl
    @EnvironmentObject var carsViewModel: CarsViewModelImpl
    @EnvironmentObject var groupsViewModel: GroupsViewModelImpl
    
    @State private var showLocationUpdateAlert = false
    
    @Binding var selectedCar: Car?
    @Binding var sheetDetentSelection: PresentationDetent
    
    func handleTap(_ car: Car) {
        self.selectedCar = car
        Task {
            await carsViewModel.selectCar(car)
        }
        self.sheetDetentSelection = PresentationDetent.fraction(Constants.defaultPresentationDetentFraction)
    }
    
    var body: some View {
        
        NavigationStack {
            
            List {
                
                if carsViewModel.isLoadingCars {
                    ProgressView().id(UUID())
                        .listRowBackground(Color.clear)
                    
                } else {
                    
                    if !carsViewModel.cars.isEmpty {
                        
                        let sortedUniqueCarsNames = Array(Set(carsViewModel.cars.map { $0.groupName })).sorted(by: <)
                        
                        ForEach(sortedUniqueCarsNames) { groupName in
                            
                            Section(header: Text(groupName)) {
                                
                                ForEach(carsViewModel.cars.filter { $0.groupName == groupName }.sorted(by: { $0.name < $1.name }), id: \.self) { car in
                                    
                                    HStack {
                                        Text(car.icon)
                                            .font(.title2)
                                        VStack(alignment: .leading, spacing: 5) {
                                            Text(car.name)
                                                .font(.title3.bold())
                                            if car.currentlyInUse {
                                                HStack(spacing: 5) {
                                                    Image(systemName: "exclamationmark.circle")
                                                        .font(.subheadline)
                                                        .bold()
                                                        .foregroundColor(.gray)
                                                    
                                                    Text("The vehicle is currently in use")
                                                        .bold()
                                                        .font(.subheadline)
                                                        .foregroundColor(.gray)
                                                }
                                            } else {
                                                if car.address.isEmpty {
                                                    HStack(spacing: 5) {
                                                        Image(systemName: "exclamationmark.circle")
                                                            .foregroundColor(.gray)
                                                            .font(.subheadline)
                                                        
                                                        Text("The vehicle doesn't have a location yet")
                                                            .font(.subheadline)
                                                        
                                                            .foregroundColor(.gray)
                                                    }
                                                } else {
                                                    Text(car.address)
                                                        .foregroundColor(.gray)
                                                        .font(.subheadline)
                                                    
                                                }
                                                
                                                if !car.note.isEmpty {
                                                    Text(car.note)
                                                        .foregroundColor(.gray)
                                                        .font(.subheadline)
                                                }
                                            }
                                        }
                                        Spacer()
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        self.handleTap(car)
                                    }
                                    
                                }
                                .frame(height: 55)
                                .listRowBackground(Color.clear)
                            }
                        }
                    } else {
                        
                        Text("You still don't have any vehicles. Click on the ellipsis button, and then go to the Groups section to add one.")
                            .listRowBackground(Color.clear)
                        
                    }
                }
            }
            .listStyle(.plain)
        }
        .onAppear {
            if let userId = sessionService.userDetails?.userId {
                Task {
                    await carsViewModel.fetchUserCars(userId: userId)
                }
            }
        }
        .onChange(of: sessionService.userDetails) { newUserDetails in
            if let userId = sessionService.userDetails?.userId {
                Task {
                    await carsViewModel.fetchUserCars(userId: userId)
                }
            }
        }
        .onReceive(groupsViewModel.$carListReload) { change in
            if let userId = sessionService.userDetails?.userId {
                Task {
                    await carsViewModel.fetchUserCars(userId: userId)
                }
            }
        }
        .alert("Error", isPresented: $carsViewModel.hasError) {
            Button("OK", role: .cancel) { }
        } message: {
            if case .failed(let error) = carsViewModel.state {
                Text(error.localizedDescription)
            } else {
                Text("Something went wrong")
            }
        }
        
    }
    
}

extension String: Identifiable {
    public typealias ID = Int
    public var id: Int {
        return hash
    }
}

struct CarsView_Previews: PreviewProvider {
    static var previews: some View {
        
        @State var selectedCar: Car?
        @State var sheetDetentSelection = PresentationDetent.fraction(Constants.defaultPresentationDetentFraction)
        
        let sessionService = SessionServiceImpl()
        let carsViewModel = CarsViewModelImpl(service: CarsServiceImpl())
        
        CarsView(selectedCar: $selectedCar, sheetDetentSelection: $sheetDetentSelection)
            .environmentObject(sessionService)
            .environmentObject(carsViewModel)
        
    }
}

