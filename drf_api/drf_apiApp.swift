//
//  drf_apiApp.swift
//  drf_api
//
//  Created by Gerald Bryan on 12/07/23.
//

import SwiftUI

@main
struct drf_apiApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
