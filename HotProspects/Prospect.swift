//
//  Prospect.swift
//  HotProspects
//
//  Created by enesozmus on 5.04.2024.
//

import SwiftData
import SwiftUI

// → In our app we have a TabView that contains three instances of ProspectsView, and we want all three of those to work as different views on the same shared data.
// → In SwiftData terms, this means they all access the same model context, but using slightly different queries.
// → ✅ challenge 3
@Model
class Prospect : Comparable {
    var name: String
    var emailAddress: String
    var isContacted: Bool
    
    init(name: String, emailAddress: String, isContacted: Bool) {
        self.name = name
        self.emailAddress = emailAddress
        self.isContacted = isContacted
    }
    
    // → ✅ challenge 3
    static func <(lhs: Prospect, rhs: Prospect) -> Bool {
        return lhs.name < rhs.name
    }
}

/*
 
    → Remember, SwiftData's @Model macro can only be used on a class, but it means we can share instances of that object in several views to have them all kept up to date automatically.
    → Now that we have something to store, we can tell SwiftData to create a model container for it.
    → This means going to HotProspectsApp.swift, giving it an import for SwiftData, then adding the modelContainer(for:) modifier.
 */
