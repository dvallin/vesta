import SwiftUI

struct FilterCriteriaView: View {
    @Binding var filterMode: FilterMode
    @Binding var showCompletedItems: Bool
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Filter Mode")) {
                    Picker("Filter Mode", selection: $filterMode) {
                        ForEach(FilterMode.allCases.filter { $0 != .overdue }, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                Section {
                    Toggle("Show Completed Items", isOn: $showCompletedItems)
                }
            }
            .navigationTitle("Filter Criteria")
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                })
        }
        .presentationDetents([.medium, .large])
    }
}

enum FilterMode: String, CaseIterable {
    case all = "Show All"
    case today = "Only Today"
    case noDueDate = "No Due Date"
    case overdue = "Overdue"
}
