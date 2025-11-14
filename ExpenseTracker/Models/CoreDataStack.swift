//
//  CoreDataStack.swift
//  ExpenseTracker
//
//  Created by Alfian Losari on 19/04/20.
//  Copyright © 2020 Alfian Losari. All rights reserved.
//

import CoreData

class CoreDataStack {
    
    private let containerName: String
    var viewContext: NSManagedObjectContext { persistentContainer.viewContext }
    
    private lazy var persistentContainer: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: containerName)
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                print("Unresolved error: \(error), \(error.userInfo)")
            } else {
                print("Store loaded: \(storeDescription)")
            }
        })

        // Enable automatic syncing with CloudKit
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        // Observe CloudKit errors (iOS 14.0 or newer)
        if #available(iOS 14.0, *) {
            NotificationCenter.default.addObserver(
                forName: NSPersistentCloudKitContainer.eventChangedNotification,
                object: container,
                queue: .main
            ) { notification in
                if let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey] as? NSPersistentCloudKitContainer.Event {
                    self.handleCloudKitEvent(event)
                }
            }
        }

        return container
    }()
    
    init(containerName: String) {
        self.containerName = containerName
        _ = persistentContainer
    }

    @available(iOS 14.0, *)
    private func handleCloudKitEvent(_ event: NSPersistentCloudKitContainer.Event) {
        switch event.type {
        case .setup:
            print("CloudKit setup event: \(event)")
        case .import:
            print("CloudKit import event: \(event)")
        case .export:
            print("CloudKit export event: \(event)")
        default:
            print("Unhandled CloudKit event: \(event)")
        }
    }

    func calculateBalances(for group: Group) -> [String: Double] {
        var balances: [String: Double] = [:]
        guard let members = group.members as? Set<User>, let expenses = group.expenses as? Set<ExpenseLog> else {
            return balances
        }

        let totalExpense = expenses.reduce(0) { $0 + ($1.amount?.doubleValue ?? 0) }
        let splitAmount = totalExpense / Double(members.count)

        for member in members {
            let memberExpenses = expenses.filter { $0.user == member }
            let memberTotal = memberExpenses.reduce(0) { $0 + ($1.amount?.doubleValue ?? 0) }
            balances[member.name ?? ""] = memberTotal - splitAmount
        }

        return balances
    }
}

extension NSManagedObjectContext {
    
    func saveContext() throws {
        guard hasChanges else { return }
        try save()
    }
}
