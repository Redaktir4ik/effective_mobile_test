import SwiftUI

struct DatePickerOptionalView: View {
    @Binding var date: Date?
    
    @State private var selectedDate: Date = Date.now
    @State private var showingDatePicker = false
    
    var body: some View {
        HStack {
            Text ("Дата задачи: ")
            Button {
                showingDatePicker.toggle()
            } label: {
                HStack {
                    if let date {
                        Text(date, style: .date)
                            .font(.body)
                    } else {
                        Text("Выберите дату")
                            .foregroundColor(.gray)
                            .font(.body)
                    }
                    
                    Image(systemName: "calendar")
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemFill))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
            )
            if date != nil {
                Button {
                    date = nil
                } label: {
                    Image(systemName: "x.circle")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .onChange(of: selectedDate) {
            date = selectedDate
            showingDatePicker = false
        }
        .sheet(isPresented: $showingDatePicker) {
            VStack {
                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding()
                Spacer()
            }
            .presentationDetents([.height(400)])
        }
    }
}
