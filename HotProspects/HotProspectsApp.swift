//
//  HotProspectsApp.swift
//  HotProspects
//
//  Created by enesozmus on 5.04.2024.
//

import SwiftData
import SwiftUI

@main
struct HotProspectsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // → That creates storage for our Prospect class,
        // → but also places a shared SwiftData model context into every SwiftUI view in our app, all with one line of code.
        // → We want all our ProspectsView instances to share that model data, so they are all pointing to the same underlying data.
        // → This means adding two properties: one to access the model context that was just created for us, and one to perform a query for Prospect objects.
        .modelContainer(for: Prospect.self)
    }
}
