//
//  EffectiveMobileApp.swift
//  EffectiveMobile
//
//  Created by Евгений on 19.06.2025.
//

import SwiftUI

@main
struct EffectiveMobileApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
