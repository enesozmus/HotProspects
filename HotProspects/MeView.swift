//
//  MeView.swift
//  HotProspects
//
//  Created by enesozmus on 5.04.2024.
//

import CoreImage.CIFilterBuiltins
import SwiftUI

struct MeView: View {
    /*
        → Core Image lets us generate a QR code from any input string, and do so extremely quickly.
        → However, there’s a problem: the image it generates is very small because it’s only as big as the pixels required to show its data.
        → It’s trivial to make the QR code larger, but to make it look good we also need to adjust SwiftUI’s image interpolation.

        → So, in this step we’re going to ask the user to enter their name and email address in a form, use those two pieces of information to generate a QR code identifying them, and scale up the code without making it fuzzy.

        → First, add these two new pieces of state to hold a name and email address:
    */
    @AppStorage("name") private var name = "Anonymous"
    @AppStorage("emailAddress") private var emailAddress = "you@yoursite.com"
    
    // → Second, we need two properties to store an active Core Image context and an instance of Core Image’s QR code generator filter.
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    
    @State private var qrCode = UIImage()
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                    .textContentType(.name)
                    .font(.title)
                
                TextField("Email address", text: $emailAddress)
                    .textContentType(.emailAddress)
                    .font(.title)
                
                Image(uiImage: qrCode)
                    // → However, take a close look at the QR code – do you notice how it’s fuzzy?
                    // → This is because Core Image is generating a tiny image, and SwiftUI is trying to smooth out the pixels as we scale it up.
                    // → Line art like QR codes and bar codes is a great candidate for disabling image interpolation.
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    // → With a little extra code we can also let the user share that QR code outside the app.
                    // → This is another example of where ShareLink comes in handy.
                    .contextMenu {
                        ShareLink(
                            item: Image(uiImage: qrCode),
                            preview: SharePreview("My QR Code", image: Image(uiImage: qrCode))
                        )
                    }
            }
            .navigationTitle("Your code")
            .onAppear(perform: updateCode)
            .onChange(of: name, updateCode)
            .onChange(of: emailAddress, updateCode)
        }
    }
    
    // ...
    /*
        Making the QR code itself.

            → If you remember, working with Core Image filters requires us to provide some input data, then convert the output CIImage into a CGImage, then that CGImage into a UIImage.

            → We’ll be following the same steps here, except:

                1. Our input for the filter will be a string, but the input for the filter is Data, so we need to convert that.

                2.If conversion fails for any reason we’ll send back the “xmark.circle” image from SF Symbols.

                3. If that can’t be read – which is theoretically possible because SF Symbols is stringly typed – then we’ll send back an empty UIImage.
    */
    func generateQRCode(from string: String) -> UIImage {
        filter.message = Data(string.utf8)

        if let outputImage = filter.outputImage {
            if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgimg)
            }
        }
        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
    
    // ...
    func updateCode() {
        qrCode = generateQRCode(from: "\(name)\n\(emailAddress)")
    }
}

#Preview {
    MeView()
}
