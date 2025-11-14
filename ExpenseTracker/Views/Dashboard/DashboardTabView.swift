//
//  DashboardTabView.swift
//  ExpenseTracker
//
//  Created by Alfian Losari on 19/04/20.
//  Copyright © 2020 Alfian Losari. All rights reserved.
//

import SwiftUI
import CoreData

struct DashboardTabView: View {
    @Environment(\.managedObjectContext) var context
    @FetchRequest(
        entity: Group.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Group.name, ascending: true)]
    ) var groups: FetchedResults<Group>

    @State private var isSyncing: Bool = false // State for syncing status
    @State private var categorySums: [CategorySum] = [] // State for chart data

    var body: some View {
        NavigationView {
            VStack {
                if isSyncing {
                    if #available(iOS 14.0, *) {
                        HStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                            Text("Syncing with iCloud...")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding()
                    } else {
                        Text("Syncing with iCloud...")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding()
                    }
                }

                if !categorySums.isEmpty {
                    PieChartView(data: categorySums.map { $0.sum }, labels: categorySums.map { $0.category.rawValue }, title: "Expenses by Category")
                        .frame(height: 300)
                        .padding()
                } else {
                    Text("No data available for chart.")
                        .foregroundColor(.gray)
                        .padding()
                }

                List {
                    ForEach(groups, id: \ .self) { group in
                        NavigationLink(destination: GroupBalanceView(group: group)) {
                            VStack(alignment: .leading) {
                                Text(group.name ?? "Unnamed Group").font(.headline)
                                if let expenses = group.expenses as? Set<ExpenseLog> {
                                    let totalExpense = expenses.reduce(0) { $0 + ($1.amount?.doubleValue ?? 0) }
                                    Text("Total Expense: \(Utils.numberFormatter.string(from: NSNumber(value: totalExpense)) ?? "-")")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                }
            }
            .navigationBarTitle("Dashboard")
            .onAppear(perform: loadChartData)
        }
    }

    private func loadChartData() {
        // Fetch category sums for the chart
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "ExpenseLog")
        fetchRequest.resultType = .dictionaryResultType
        fetchRequest.propertiesToGroupBy = ["category"]
        fetchRequest.propertiesToFetch = [
            NSExpressionDescription(
                name: "sum",
                expression: NSExpression(forFunction: "sum:", arguments: [NSExpression(forKeyPath: "amount")]),
                expressionResultType: .decimalAttributeType
            ),
            "category"
        ]

        do {
            let results = try context.fetch(fetchRequest) as? [[String: Any]]
            categorySums = results?.compactMap { result in
                guard let sum = result["sum"] as? Double, let category = result["category"] as? String else { return nil }
                return CategorySum(sum: sum, category: Category(rawValue: category) ?? .other)
            } ?? []
        } catch {
            print("Failed to load chart data: \(error.localizedDescription)")
        }
    }
}

struct GroupBalanceView: View {
    var group: Group

    var body: some View {
        VStack {
            Text("Balances for \(group.name ?? "Unnamed Group")")
                .font(.title)
                .padding()

            if let members = group.members as? Set<User>, let expenses = group.expenses as? Set<ExpenseLog> {
                let totalExpense = expenses.reduce(0) { $0 + ($1.amount?.doubleValue ?? 0) }
                let splitAmount = totalExpense / Double(members.count)

                List {
                    ForEach(Array(members), id: \ .self) { member in
                        let memberExpenses = expenses.filter { $0.user == member }
                        let memberTotal = memberExpenses.reduce(0) { $0 + ($1.amount?.doubleValue ?? 0) }
                        let balance = memberTotal - splitAmount

                        HStack {
                            Text(member.name ?? "Unnamed Member")
                            Spacer()
                            Text(Utils.numberFormatter.string(from: NSNumber(value: balance)) ?? "-")
                                .foregroundColor(balance >= 0 ? .green : .red)
                        }
                    }
                }
            } else {
                Text("No data available.")
                    .foregroundColor(.gray)
            }
        }
        .navigationBarTitle("Group Balances", displayMode: .inline)
    }
}

struct CategorySum: Identifiable, Equatable {
    let sum: Double
    let category: Category
    
    var id: String { "\(category)\(sum)" }
}

struct GroupManagementView: View {
    @Environment(\.managedObjectContext) var context
    @State private var groupName: String = ""
    @FetchRequest(
        entity: Group.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Group.name, ascending: true)]
    ) var groups: FetchedResults<Group>

    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text("Create New Group")) {
                        TextField("Group Name", text: $groupName)
                        Button(action: createGroup) {
                            Text("Add Group")
                        }
                        .disabled(groupName.isEmpty)
                    }

                    Section(header: Text("Existing Groups")) {
                        List {
                            ForEach(groups, id: \ .self) { group in
                                HStack {
                                    Text(group.name ?? "Unnamed Group")
                                    Spacer()
                                    Button(action: { deleteGroup(group) }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationBarTitle("Manage Groups")
        }
    }

    private func createGroup() {
        let newGroup = Group(context: context)
        newGroup.name = groupName
        do {
            try context.save()
            groupName = ""
        } catch {
            print("Failed to save group: \(error.localizedDescription)")
        }
    }

    private func deleteGroup(_ group: Group) {
        context.delete(group)
        do {
            try context.save()
        } catch {
            print("Failed to delete group: \(error.localizedDescription)")
        }
    }
}

struct DashboardTabView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardTabView()
    }
}
