import SwiftUI

struct AddSubjectView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var store: AttendanceStore

    @State private var name = ""
    @State private var targetPercentage = 75.0

    var body: some View {
        NavigationView {
            Form {
                TextField("Subject Name", text: $name)

                Section(header: Text("Target Percentage")) {
                    HStack {
                        Slider(value: $targetPercentage, in: 0...100, step: 1)
                        Text("\(Int(targetPercentage))%")
                    }
                }
            }
            .navigationTitle("Add Subject")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.addSubject(name: name, target: targetPercentage)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
