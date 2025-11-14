//
//  LogFormView.swift
//  ExpenseTracker
//
//  Created by Alfian Losari on 19/04/20.
//  Copyright © 2020 Alfian Losari. All rights reserved.
//

import SwiftUI
import CoreData

struct LogFormView: View {
    
    var logToEdit: ExpenseLog?
    var context: NSManagedObjectContext
    
    @State var name: String = ""
    @State var amount: Double = 0
    @State var category: Category = .utilities
    @State var date: Date = Date()
    @State private var expenseType: String = "Individual" // New state for expense type
    @State private var selectedGroup: String = "" // State for group selection
    @State private var newGroupName: String = "" // State for new group creation
    var groups: [String] = ["Group 1", "Group 2", "Group 3"] // Example group list
    
    @Environment(\.presentationMode)
    var presentationMode
    
    var title: String {
        logToEdit == nil ? "Create Expense Log" : "Edit Expense Log"
    }
    
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Name", text: $name)
                    .disableAutocorrection(true)
                TextField("Amount", value: $amount, formatter: Utils.numberFormatter)
                    .keyboardType(.numbersAndPunctuation)
                    
                Picker(selection: $category, label: Text("Category")) {
                    ForEach(Category.allCases) { category in
                        Text(category.rawValue.capitalized).tag(category)
                    }
                }
                DatePicker(selection: $date, displayedComponents: .date) {
                    Text("Date")
                }
                
                Section(header: Text("Expense Type")) {
                    Picker("Type", selection: $expenseType) {
                        Text("Individual").tag("Individual")
                        Text("Group").tag("Group")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                if expenseType == "Group" {
                    Section(header: Text("Group")) {
                        Picker("Select Group", selection: $selectedGroup) {
                            ForEach(groups, id: \.self) { group in
                                Text(group)
                            }
                        }

                        TextField("New Group Name", text: $newGroupName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
            }

            .navigationBarItems(
                leading: Button(action: self.onCancelTapped) { Text("Cancel")},
                trailing: Button(action: self.onSaveTapped) { Text("Save")}
            ).navigationBarTitle(title)
            
        }
        
    }
    
    private func onCancelTapped() {
        self.presentationMode.wrappedValue.dismiss()
    }
    
    private func onSaveTapped() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        let log: ExpenseLog
        if let logToEdit = self.logToEdit {
            log = logToEdit
        } else {
            log = ExpenseLog(context: self.context)
            log.id = UUID()
        }
        
        log.name = self.name
        log.category = self.category.rawValue
        log.amount = NSDecimalNumber(value: self.amount)
        log.date = self.date
        
        do {
            try context.save()
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        
        self.presentationMode.wrappedValue.dismiss()
    }
    
}

struct LogFormView_Previews: PreviewProvider {
    static var previews: some View {
        let stack = CoreDataStack(containerName: "ExpenseTracker")
        return LogFormView(context: stack.viewContext)
    }
}
