//
//  LoginView.swift
//  TagAuto
//
//  Created by Nir Neuman on 12/07/2023.
//

import SwiftUI
import _AuthenticationServices_SwiftUI

struct LoginView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @State private var showRegistration = false
    @State private var showForgotPassword = false
    
    @StateObject private var vm = LoginViewModelImpl(service: LoginServiceImpl())
    
    var body: some View {
        
        NavigationStack {
            
            VStack(spacing: 100) {
                
                VStack {
                    Image("Logo", bundle: .main)
                        .resizable()
                        .scaledToFit()
                        .clipShape(.circle)
                    
                    Text("TagAuto")
                        .font(.largeTitle)
                        .bold()
                }
                
                SignInWithAppleButton(
                    onRequest: { request in
                        vm.handleSignInWithAppleRequest(with: request)
                    },
                    onCompletion: { result in
                        vm.handleSignInWithAppleCompletion(with: result)
                    }
                )
                .signInWithAppleButtonStyle(colorScheme == .light ? .black : .white)
                .frame(maxWidth: .infinity, minHeight: 50, maxHeight: 50)
                .cornerRadius(50)
                
            }
            .padding([.horizontal, .top], 15)
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
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            LoginView()
        }
    }
}
