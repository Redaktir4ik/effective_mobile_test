import SwiftUI

struct SearchBarView: View {
    @Binding var text: String
    @State private var isEditing = false
    
    var body: some View {
        HStack {
            TextField("", text: $text)
                .padding(7)
                .padding(.horizontal, 25)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .padding(.leading, 8)
                        if !isEditing {
                            Text("Поиск")
                                .foregroundStyle(.gray)
                        }
                        Spacer()
                    }
                )
                .padding(.horizontal, 10)
                .onChange(of: text) {
                    if !text.isEmpty {
                        isEditing = true
                    } else {
                        isEditing = false
                    }
                }
            
            if isEditing {
                Button(action: {
                    isEditing = false
                    text = ""
                }) {
                    Text("Отмена")
                }
                .padding(.trailing, 10)
            }
        }
        .onTapGesture {
            isEditing = true
        }
    }
}
