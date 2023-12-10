//
//  AccountView.swift
//  TagAuto
//
//  Created by Nir Neuman on 17/08/2023.
//

import SwiftUI


struct AccountView: View {
    
    @EnvironmentObject var sessionService: SessionServiceImpl
    
    @StateObject var accountViewModel = AccountViewModelImpl(service: AccountServiceImpl())
    
    @State var isDeleteAccountAlert = false
    
    private let pastboard = UIPasteboard.general
    
    var body: some View {
        
        NavigationStack {
            
            VStack(alignment: .leading, spacing: 20) {
                
                if accountViewModel.isLoadingDeleteAccount {
                    VStack(alignment: .center) {
                        ProgressView()
                        Text("Deleting account please wait..")
                            .bold()
                    }
                } else {
                    
                    VStack(alignment: .leading, spacing: 25) {
                        
                        Divider()
                        
                        VStack(alignment: .leading) {
                            Text("Your user's email is:")
                                .font(.headline)
                            
                            Text("\(sessionService.userDetails?.userEmail ?? "")")
                            
                            Button {
                                pastboard.string = sessionService.userDetails?.userEmail ?? ""
                            } label: {
                                Label("Copy to Clipboard", systemImage: "doc.on.doc").font(.subheadline)
                            }
                            .disabled(sessionService.userDetails?.userEmail == nil)
                            .padding(.top, 5)
                        }
                        
                        
                        Text("List of group invitations for you to join:")
                            .font(.headline)
                        
                        
                        if accountViewModel.isLoading {
                            ProgressView()
                            Spacer()
                        } else {
                            
                            List {
                                
                                if !accountViewModel.accountInvitations.isEmpty {
                                    
                                    ForEach(accountViewModel.accountInvitations.sorted(by: { $0.id < $1.id }), id: \.self) { invitation in
                                        
                                        HStack {
                                            Image(systemName: "envelope")
                                                .font(.title3)
                                            Text("\(invitation.groupName)")
                                                .font(.title3)
                                            
                                            Spacer()
                                            
                                            Button {
                                                accountViewModel.acceptInvitation(userId: sessionService.userDetails?.userId ?? "", groupId: invitation.groupId, invitationId: invitation.id, userEmail: invitation.email)
                                            } label: {
                                                Image(systemName: "checkmark.circle")
                                                    .font(.title3)
                                            }
                                            .buttonStyle(.borderless)
                                            
                                            Divider()
                                            
                                            Button {
                                                accountViewModel.removeInvitation(invitationId: invitation.id, userEmail: invitation.email)
                                            } label: {
                                                Image(systemName: "xmark.circle")
                                                    .font(.title3)
                                            }
                                            .buttonStyle(.borderless)
                                            
                                        }
                                        
                                    }
                                    
                                } else {
                                    Text("You don't have any invitations yet")
                                }
                                
                            }
                            .listStyle(.plain)
                            .refreshable {
                                if let userEmail = sessionService.userDetails?.userEmail {
                                    accountViewModel.fetchAccountInvitations(userEmail: userEmail)
                                }
                            }
                            
                        }
                        
                    }
                    
                    Divider()
                    
                    ButtonView(title: "Sign Out") {
                        sessionService.logout()
                    }
                    
                    ButtonView(title: "Delete Account", background: .red) {
                        isDeleteAccountAlert = true
                    }
                    .disabled(sessionService.userDetails?.userId.isEmpty ?? true)
                    .alert("Delete Account", isPresented: $isDeleteAccountAlert) {
                        Button("Confirm", action: {
                            Task {
                                if let userId = sessionService.userDetails?.userId {
                                    if await accountViewModel.deleteAccount(userId: userId) {
                                        sessionService.logout()
                                    }
                                }
                            }
                        })
                        Button("Cancel", role: .cancel) {
                            isDeleteAccountAlert = false
                        }
                    } message: {
                        Text("Confirm if you intend to delete your account along with all its associated data.")
                    }
                }

            }
            .onAppear {
                accountViewModel.isLoading = true

                if let userEmail = sessionService.userDetails?.userEmail {
                    accountViewModel.fetchAccountInvitations(userEmail: userEmail)
                }
            }
            .onChange(of: sessionService.userDetails) { newUserDetails in
                accountViewModel.isLoading = true

                if let userEmail = newUserDetails?.userEmail {
                    accountViewModel.fetchAccountInvitations(userEmail: userEmail)
                }
            }
            .padding([.horizontal, .bottom], 16)
            .navigationTitle("Account")
            .alert("Error", isPresented: $accountViewModel.hasError) {
                Button("OK", role: .cancel) { }
            } message: {
                if case .failed(let error) = accountViewModel.state {
                    Text(error.localizedDescription)
                } else {
                    Text("Something went wrong")
                }
            }
        }
    }
    
}

struct AccountView_Previews: PreviewProvider {
    static var previews: some View {
        AccountView(accountViewModel: AccountViewModelImpl(service: AccountServiceImpl()))
            .environmentObject(SessionServiceImpl())
    }
}

