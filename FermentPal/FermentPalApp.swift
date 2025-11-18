//
//  FermentPalApp.swift
//  FermentPal
//
//  Created by CR on 23/9/25.
//

import SwiftUI
import SwiftData

@main
struct FermentPalApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Fermentation.self,
            Record.self,
            Reminder.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(sharedModelContainer)
    }
}
