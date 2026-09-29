import SwiftUI

public struct MoreDetailsSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding public var merchant: String
    @Binding public var notes: String
    @Binding public var date: Date
    @Binding public var isRecurring: Bool
    
    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Merchant & Notes")) {
                    TextField("Merchant or Store (Optional)", text: $merchant)
                    TextField("Notes / Description (Optional)", text: $notes)
                }
                
                Section(header: Text("Date & Time")) {
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section(header: Text("Recurring Status"), footer: Text("Mark if this is a recurring monthly or regular payment.")) {
                    Toggle("Mark as Recurring", isOn: $isRecurring)
                }
            }
            .navigationTitle("More Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
