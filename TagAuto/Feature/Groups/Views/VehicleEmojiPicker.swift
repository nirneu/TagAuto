//
//  CarEmojiPicker.swift
//  TagAuto
//
//  Created by Nir Neuman on 28/08/2023.
//

import SwiftUI

struct VehicleEmojiPicker: View {
    
    @Binding var selectedEmoji: String

      let emojis = ["🚗", "🚙", "🛻", "🚛", "🏎️", "🛵", "🏍️", "🚲", "🚁", "🛩️", "🛳️", "🚀"]
    
      let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

      var body: some View {
          VStack {
              Text("Selected Vehicle Icon: \(selectedEmoji)")
                  .padding(.bottom, 10)

              LazyVGrid(columns: columns, spacing: 10) {
                  ForEach(emojis, id: \.self) { emoji in
                      Text(emoji)
                          .font(.largeTitle)
                          .onTapGesture {
                              selectedEmoji = emoji
                          }
                          .padding()
                          .background(selectedEmoji == emoji ? Color.gray.opacity(0.3) : Color.clear)
                          .cornerRadius(10)
                  }
              }
          }
          .padding()
      }
}

struct CarEmojiPicker_Previews: PreviewProvider {
    static var previews: some View {
        @State var selectedEmoji: String = ""

        VehicleEmojiPicker(selectedEmoji: $selectedEmoji)
    }
}
