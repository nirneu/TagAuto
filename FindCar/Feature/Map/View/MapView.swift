//
//  MapView.swift
//  FindCar
//
//  Created by Nir Neuman on 26/07/2023.
//

import SwiftUI
import MapKit

struct MapView: View {
    
    @StateObject private var vm = MapViewModelImpl()

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
                } else {
                    Text("Something went wrong")
                }
            }
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView()
    }
}
