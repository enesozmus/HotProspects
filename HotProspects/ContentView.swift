//
//  ContentView.swift
//  HotProspects
//
//  Created by enesozmus on 5.04.2024.
//

import SwiftUI

struct ContentView: View {
//    @StateObject var prospects = Prospects()
    
    var body: some View {
        /*
            → This app is going to display four SwiftUI views inside a tab bar:
         
                1. one to show everyone that you met
                2. one to show people you have contacted
                3. another to show people you haven’t contacted
                4. and a final one showing your personal information for others to scan

            → Those first three views are variations on the same concept, but the last one is quite different.
            → We can represent that with an enum plus a property on ProspectsView.
         
            → TabView : A view that switches between multiple child views using → interactive user interface elements

            → tabItem(_:) : Sets the tab bar item associated with this view.
            → label : The tab bar item to associate with this view.
            → Use tabItem(_:) to configure a view as a tab bar item in a TabView.
        */
        TabView {
            ProspectsView(filter: .none)
                .tabItem {
                    Label("Everyone", systemImage: "person.3")
                }
            
            ProspectsView(filter: .contacted)
                .tabItem {
                    Label("Contacted", systemImage: "checkmark.circle")
                }
            
            ProspectsView(filter: .uncontacted)
                .tabItem {
                    Label("Uncontacted", systemImage: "questionmark.diamond")
                }
            
            MeView()
                .tabItem {
                    Label("Me", systemImage: "person.crop.square")
                }
        }
//        .environmentObject(prospects)
    }
}

#Preview {
    ContentView()
}
