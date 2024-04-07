//
//  ProspectsView.swift
//  HotProspects
//
//  Created by enesozmus on 5.04.2024.
//

/*
 Scanning QR codes with SwiftUI (import CodeScanner)

    → Scanning a QR code – or indeed any kind of visible code such as barcodes – can be done by Apple’s AVFoundation library.
    → This doesn’t integrate into SwiftUI terribly smoothly.
    → So to skip over a whole lot of pain I’ve packaged up a QR code reader into a Swift package that we can add and use directly inside Xcode.

        1. Go to File > Add Package Dependencies.
        2. Enter https://github.com/twostraws/CodeScanner as the package repository URL.
        3. For the version rules, leave “Up to Next Major” selected
        4. Press Add Package to import the finished package into your project.

    → The CodeScanner package gives us one CodeScannerView SwiftUI view to use, which can be presented in a sheet and handle code scanning in a clean, isolated way.
    → The best way to write SwiftUI is to isolate functionality in discrete methods and wrappers, so that all you expose to your SwiftUI layouts is clean, clear, and unambiguous.
*/
import CodeScanner
import SwiftData
import SwiftUI
import UserNotifications

struct ProspectsView: View {
    /*
        → We can represent that with an enum plus a property on ProspectsView.
        → Now we can use that to allow each instance of ProspectsView to be slightly different by giving it a new property:
     */
    enum FilterType {
        case none, contacted, uncontacted
    }
    let filter: FilterType
    
    // → First let’s use it to customize each of the three views just a little by giving them a navigation bar title.
    var title: String {
        switch filter {
        case .none:
            return "Everyone"
        case .contacted:
            return "Contacted people"
        case .uncontacted:
            return "Uncontacted people"
        }
    }

    // → We want all our ProspectsView instances to share that model data, so they are all pointing to the same underlying data.
    // → This means adding two properties: one to access the model context that was just created for us, and one to perform a query for Prospect objects.
    
    // → Our basic SwiftData query looks like this:
    // → By default that will load all Prospect model objects, sorting them by name,
    // → and while that's fine for the Everyone tab it's not enough for the other two.
    @Query(sort: \Prospect.name) var prospects: [Prospect]
    // → Our model context
    @Environment(\.modelContext) var modelContext
    
    // → the isShowingScanner state that determines whether to show a code scanner or not
    @State private var isShowingScanner = false
    
    // → We'll add is to let users select multiple rows at the same time and delete them in one go.
    // → That means adding some new local state to store their active selection.
    // → Then binding that selection to our list:
    @State private var selectedProspects = Set<Prospect>()
    
    var body: some View {
        NavigationStack {
            List(prospects, selection: $selectedProspects) { prospect in
                HStack{
                    VStack(alignment: .leading) {
                        Text(prospect.name)
                            .font(.headline)
                        
                        Text(prospect.emailAddress)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Spacer()
                    // ✅ challenge 1
                    if filter == .none{
                        Image(
                            systemName: (
                                prospect.isContacted == true
                                ?
                                    "person.crop.circle.badge.xmark"
                                :
                                    "person.crop.circle.fill.badge.checkmark"
                            )
                        )
                        .foregroundStyle((prospect.isContacted == true ? .green : .gray))
                    }
                }
                // → ...a way to move people between the Contacted and Uncontacted tabs
                // → This will allow users to swipe on any person in the list, then tap a single option to move them between the tabs.
                .swipeActions {
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        modelContext.delete(prospect)
                    }
                    if prospect.isContacted {
                        Button("Mark Uncontacted", systemImage: "person.crop.circle.badge.xmark") {
                            prospect.isContacted.toggle()
                        }
                        .tint(.blue)
                    } else {
                        Button("Mark Contacted", systemImage: "person.crop.circle.fill.badge.checkmark") {
                            prospect.isContacted.toggle()
                        }
                        .tint(.green)
                        
                        Button("Remind Me", systemImage: "bell") {
                            addNotification(for: prospect)
                        }
                        .tint(.orange)
                    }
                }
                // → To help SwiftUI understand that each row in our List corresponds to a single prospect, it's important to add the following code after the swipe actions:
                .tag(prospect)
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Scan", systemImage: "qrcode.viewfinder") {
                        isShowingScanner = true
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
                if selectedProspects.isEmpty == false {
                    ToolbarItem(placement: .bottomBar) {
                        Button("Delete Selected", action: delete)
                    }
                }
            }
            // → We can now attach a sheet() modifier to present our scanner UI.
            .sheet(isPresented: $isShowingScanner) {
            /*
                Creating a CodeScannerView takes at least three parameters:

                    1. An array of the types of codes we want to scan.
                    2. A string to use as simulated data.
                    3. A completion function to use.
            */
                CodeScannerView(
                    codeTypes: [.qr],
                    simulatedData: "Paul Hudson\npaul@hackingwithswift.com",
                    completion: handleScan
                )
            }
        }
    }
    
    // ...
    // → In our app, we have three instances of ProspectsView that vary only according to the FilterType property that gets passed in from our tab view.
    // → We’re already using that to set the title of each view, but we can also use it to filter our query.
    // → Yes, we already have a default query in place, but if we add an initializer we can override that when a filter is set.
    init(filter: FilterType) {
        self.filter = filter
        
        if filter != .none {
            /*
                filter == .contacted
             
                    → That will return true if filter is equal to .contacted, or false otherwise. And now this part:

                let showContactedOnly =
             
                    → That will assign the result of filter == .contacted to a new constant called showContactedOnly.
                    → So, if we read the whole line, it means "set showContactedOnly to true if our filter is set to .contacted."
            */
            let showContactedOnly = filter == .contacted
            
            _prospects = Query(filter: #Predicate {
                $0.isContacted == showContactedOnly
            }, sort: [SortDescriptor(\Prospect.name)])
        }
    }
    
    // ...
    /*
        → Before we show the scanner and try to handle its result, we need to ask the user for permission to use the camera:

            1. Go to your target’s configuration options under its Info tab.
            2. Right-click on an existing key and select Add Row.
            3. Select “Privacy - Camera Usage Description” for the key.
            4. For the value enter “We need to scan QR codes.”
            5. And now we’re ready to scan some QR codes!
    */
    func handleScan(result: Result<ScanResult, ScanError>) {
        isShowingScanner = false
        
        switch result {
        case .success(let result):
            let details = result.string.components(separatedBy: "\n")
            guard details.count == 2 else { return }
            
            let person = Prospect(name: details[0], emailAddress: details[1], isContacted: false)
            
            modelContext.insert(person)
        case .failure(let error):
            print("Scanning failed: \(error.localizedDescription)")
        }
    }
    
    // ...
    // → a method to call that will delete all the rows we selected:
    func delete() {
        for prospect in selectedProspects {
            modelContext.delete(prospect)
        }
    }
    // → And now we can add two new toolbar items to the existing toolbar() modifier, one to create the edit button:
    // → And then another one to create the delete button, but only when there are actually selections to delete:
    
    // ...
    func addNotification(for prospect: Prospect) {
        let center = UNUserNotificationCenter.current()

        // → That puts all the code to create a notification for the current prospect into a closure, which we can call whenever we need.
        let addRequest = {
            let content = UNMutableNotificationContent()
            content.title = "Contact \(prospect.name)"
            content.subtitle = prospect.emailAddress
            content.sound = UNNotificationSound.default

            // → I set it to have an hour component of 9, which means it will trigger the next time 9am comes about.
            // var dateComponents = DateComponents()
            // dateComponents.hour = 9
            // let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)


            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            center.add(request)
        }

        // more code to come
        center.getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                addRequest()
            } else {
                center.requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
                    if success {
                        addRequest()
                    } else if let error {
                        print(error.localizedDescription)
                    }
                }
            }
        }
    }
}

#Preview {
    ProspectsView(filter: .none)
        .modelContainer(for: Prospect.self)
}
