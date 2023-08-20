//
//  AccountView.swift
//  FindCar
//
//  Created by Nir Neuman on 17/08/2023.
//

import SwiftUI


struct AccountView: View {
    
    @EnvironmentObject var sessionService: SessionServiceImpl
    
    @StateObject var accountViewModel: AccountViewModelImpl
    
    var body: some View {
        
        NavigationStack {
            
            VStack(alignment: .leading, spacing: 20) {
                
                Text("\(BaseFunctions.greetingLogic()), \(sessionService.userDetails?.firstName ?? "")")
                    .font(.title)
                
                VStack(alignment: .leading, spacing: 25) {
                    
                    Divider()
                    
                    VStack(alignment: .leading) {
                        Text("Your user's email is:")
                            .font(.headline)

                        Text("\(sessionService.userDetails?.userEmail ?? "")")
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
            
                    }

                }
                
                Divider()
                
                ButtonView(title: "Sign Out") {
                    sessionService.logout()
                }
            }
            .onAppear {
                if let userEmail = sessionService.userDetails?.userEmail {
                    accountViewModel.fetchAccountInvitations(userEmail: userEmail)
                }
            }
            .onChange(of: sessionService.userDetails) { newUserDetails in
                if let userEmail = newUserDetails?.userEmail {
                    accountViewModel.fetchAccountInvitations(userEmail: userEmail)
                }
            }
            .padding([.horizontal, .bottom], 16)
            .navigationTitle("Account")
        }
    }
    
}

struct AccountView_Previews: PreviewProvider {
    static var previews: some View {
        AccountView(accountViewModel: AccountViewModelImpl(service: AccountServiceImpl()))
            .environmentObject(SessionServiceImpl())
    }
}

