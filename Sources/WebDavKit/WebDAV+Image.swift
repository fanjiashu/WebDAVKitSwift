
//
//  WebDAV.swift
//  hclient3
//
//  Created by mac on 2024/8/20.
//
import SwiftUI

struct AsyncImageWithAuth<Content: View, Placeholder: View>: View {
    @State var uiImage: UIImage?

    let file: WebDAVFile
    let content: (Image) -> Content
    let placeholder: () -> Placeholder
    
    init(
        file: WebDAVFile,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ){
        self.file = file
        self.content = content
        self.placeholder = placeholder
    }
    var body: some View {
        if let uiImage = uiImage {
            content(Image(uiImage: uiImage))
        } else {
            placeholder()
                .task {
                    self.uiImage = await getImage()
                }
        }
    }
    private func getImage() async -> UIImage? {
        var request = URLRequest(url: file.url)
        request.addValue("Basic \(file.auth)", forHTTPHeaderField: "Authorization")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { fatalError("Error while fetching attchment") }
            return UIImage(data: data)
        } catch {
            return nil
        }
    }
}
