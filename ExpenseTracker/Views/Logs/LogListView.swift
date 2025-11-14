//
//  LogListView.swift
//  ExpenseTracker
//
//  Created by Alfian Losari on 19/04/20.
//  Copyright © 2020 Alfian Losari. All rights reserved.
//

import SwiftUI
import CoreData

struct LogListView: View {
    
    @State var logToEdit: ExpenseLog?
    @State private var selectedGroup: String = "All" // State for group filtering
    var groups: [String] = ["All", "Group 1", "Group 2", "Group 3"] // Example group list
    
    @Environment(\.managedObjectContext)
    var context: NSManagedObjectContext
    
    @FetchRequest(
        entity: ExpenseLog.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \ExpenseLog.date, ascending: false)
        ]
    )
    private var result: FetchedResults<ExpenseLog>
    
    init(predicate: NSPredicate?, sortDescriptor: NSSortDescriptor) {
        let fetchRequest = NSFetchRequest<ExpenseLog>(entityName: ExpenseLog.entity().name ?? "ExpenseLog")
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        if let predicate = predicate {
            fetchRequest.predicate = predicate
        }
        _result = FetchRequest(fetchRequest: fetchRequest)
    }
    
    var body: some View {
        VStack {
            if #available(iOS 14.0, *) {
                Picker("Filter by Group", selection: $selectedGroup) {
                    ForEach(groups, id: \.self) { group in
                        Text(group)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .onChange(of: selectedGroup) { newValue in
                    applyGroupFilter()
                }
            } else {
                Picker("Filter by Group", selection: $selectedGroup) {
                    ForEach(groups, id: \.self) { group in
                        Text(group)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                Text("Group filtering is not supported on this iOS version.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            List {
                ForEach(result) { (log: ExpenseLog) in
                    Button(action: {
                        self.logToEdit = log
                    }) {
                        HStack(spacing: 16) {
                            CategoryImageView(category: log.categoryEnum)

                            VStack(alignment: .leading, spacing: 8) {
                                Text(log.nameText).font(.headline)
                                Text(log.dateText).font(.subheadline)
                                if selectedGroup != "All" {
                                    Text("Split: \(calculateSplit(for: log))")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                            Spacer()
                            Text(log.amountText).font(.headline)
                        }
                        .padding(.vertical, 4)
                    }
                }
               
                .onDelete(perform: onDelete)
                .sheet(item: $logToEdit, onDismiss: {
                    self.logToEdit = nil
                }) { (log: ExpenseLog) in
                    LogFormView(
                        logToEdit: log,
                        context: self.context,
                        name: log.name ?? "",
                        amount: log.amount?.doubleValue ?? 0,
                        category: Category(rawValue: log.category ?? "") ?? .food,
                        date: log.date ?? Date()
                    )
                }
            }
        }
    }
    
    private func applyGroupFilter() {
        if selectedGroup == "All" {
            if #available(iOS 15.0, *) {
                result.nsPredicate = nil
            } else {
                // Fallback for earlier iOS versions
                print("Group filtering is not supported on this iOS version.")
            }
        } else {
            if #available(iOS 15.0, *) {
                result.nsPredicate = NSPredicate(format: "group.name == %@", selectedGroup)
            } else {
                // Fallback for earlier iOS versions
                print("Group filtering is not supported on this iOS version.")
            }
        }
    }
    
    private func calculateSplit(for log: ExpenseLog) -> String {
        guard let group = log.group, let members = group.members, members.count > 0 else {
            return "-"
        }
        let splitAmount = (log.amount?.doubleValue ?? 0) / Double(members.count)
        return Utils.numberFormatter.string(from: NSNumber(value: splitAmount)) ?? "-"
    }
    
    private func onDelete(with indexSet: IndexSet) {
        indexSet.forEach { index in
            let log = result[index]
            context.delete(log)
        }
        try? context.saveContext()
    }
}

struct LogListView_Previews: PreviewProvider {
    static var previews: some View {
        let stack = CoreDataStack(containerName: "ExpenseTracker")
        let sortDescriptor = ExpenseLogSort(sortType: .date, sortOrder: .descending).sortDescriptor
        return LogListView(predicate: nil, sortDescriptor: sortDescriptor)
            .environment(\.managedObjectContext, stack.viewContext)
    }
}
