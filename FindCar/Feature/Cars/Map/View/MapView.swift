//
//  MapView.swift
//  FindCar
//
//  Created by Nir Neuman on 26/07/2023.
//

import SwiftUI
import MapKit

struct MapView: View {
    
    @StateObject private var vm = MapViewModelImpl(service: MapServiceImpl())
    
    var body: some View {
        Map(coordinateRegion: $vm.region, showsUserLocation: true)
            .onAppear {
                vm.checkIfLocationServicesIsEnabled()
            }
            .alert("Error", isPresented: $vm.hasError) {
                Button("OK", role: .cancel) { }
            } message: {
                if case .failed(let error) = vm.state {
                    Text(error.localizedDescription)
                } else if case .unauthorized(let reason) = vm.state {
                    Text(reason)
                } else {
                    Text("Something went wrong")
                }
            }
            .overlay(Button(action: {
                //                            vm.markLocationAsParked()
            }) {
                Text("Save Parking Location")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .font(.system(size: 16, weight: .bold))
            }, alignment: .bottom)
            .navigationTitle("")
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView()
    }
}
