
//
//  WebDAV.swift
//  hclient3

#if canImport(UIKit)
import UIKit
#endif

import SwiftUI

public struct AsyncImageWithAuth<Content: View, Placeholder: View>: View {
    #if canImport(UIKit)
    @State var uiImage: UIImage?
    #else
    @State var uiImage: Any? // Placeholder for non-iOS platforms
    #endif

    let file: WebDAVFile
    let content: (Image) -> Content
    let placeholder: () -> Placeholder
    
    public init(
        file: WebDAVFile,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ){
        self.file = file
        self.content = content
        self.placeholder = placeholder
    }
    
    public var body: some View {
        #if canImport(UIKit)
        if let uiImage = uiImage {
            content(Image(uiImage: uiImage))
        } else {
            placeholder()
                .task {
                    self.uiImage = await getImage()
                }
        }
        #else
        placeholder()
        #endif
    }
    
    #if canImport(UIKit)
    private func getImage() async -> UIImage? {
        var request = URLRequest(url: file.url)
        request.addValue("Basic \(file.auth)", forHTTPHeaderField: "Authorization")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { fatalError("Error while fetching attachment") }
            return UIImage(data: data)
        } catch {
            return nil
        }
    }
    #endif
}


