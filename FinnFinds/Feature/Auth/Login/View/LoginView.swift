//
//  LoginView.swift
//  FinnFinds
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
            
            VStack(spacing: 16) {
                
                VStack(spacing: 16) {
                    
                    InputTextFieldView(text: $vm.credentials.email, placeholder: "Email", keyboardType: .emailAddress, sfSymbol: "envelope")
                    
                    InputPasswordView(password: $vm.credentials.password, placeholder: "Password", sfSymbol: "lock")
                }
                
                HStack {
                    Spacer()
                    Button {
                        showForgotPassword.toggle()
                    } label: {
                        Text("Forgot Password?")
                    }
                    .font(.system(size: 16, weight: .bold))
                    .sheet(isPresented: $showForgotPassword) {
                        ForgotPasswordView()
                    }
                }
                
                VStack(spacing: 16) {
                    
                    ButtonView(title: "Login") {
                        vm.login()
                    }
                    
                    ButtonView(title: "Register", background: .clear, foreground: .blue, border: .blue) {
                        showRegistration.toggle()
                    }
                    .sheet(isPresented: $showRegistration) {
                        RegisterView()
                    }
                }
                
                HStack {
                    VStack { Divider() }
                    Text("or")
                    VStack { Divider() }
                }
                
                VStack(spacing: 16) {
                    SignInWithAppleButton(
                        onRequest: { request in
                            vm.handleSignInWithAppleRequest(with: request)
                        },
                        onCompletion: { result in
                            vm.handleSignInWithAppleCompletion(with: result)
                        }
                    )
                    .signInWithAppleButtonStyle(colorScheme == .light ? .black : .white)
                    .frame(maxWidth: .infinity, maxHeight: 50)
                    .cornerRadius(50)
                }
            }
            .padding(.horizontal, 15)
            .navigationTitle("Login")
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
