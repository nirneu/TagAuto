//
//  NoteInputView.swift
//  TagAuto
//
//  Created by Nir Neuman on 09/04/2024.
//

import SwiftUI

struct NoteInputView: View {
    @Binding var isPresented: Bool
    @Binding var note: String
    var saveAction: (String) -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextEditor(text: $note)
                    .padding()
                
                Button("Reset Note") {
                    note = ""
                    saveAction(note)
                    isPresented = false
                }
                .foregroundColor(.red)
                .padding()
                .frame(maxWidth: .infinity, alignment: .center)
                
            }
            .navigationBarTitle("Parking Note", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveAction(note)
                        isPresented = false
                    }
                }
            }
        }
    }
}

//#Preview {
//    NoteInputView(isPresented: <#Binding<Bool>#>, note: <#Binding<String>#>, saveAction: <#(String) -> Void#>)
//}
