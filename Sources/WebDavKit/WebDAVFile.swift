
//
//  WebDAVFile.swift
//  hclient3
//
//  Created by mac on 2024/8/20.
//

import Foundation
import SWXMLHash

struct WebDAVFile: Identifiable, Codable, Equatable, Hashable {

    public private(set) var path: String
    public private(set) var id: String
    public private(set) var isDirectory: Bool
    public private(set) var lastModified: Date
    public private(set) var size: Int64
    public private(set) var url: URL
    public private(set) var auth: String

    init(path: String, id: String, isDirectory: Bool, lastModified: Date, size: Int64, url: URL, auth: String) {
        self.path = path
        self.id = id
        self.isDirectory = isDirectory
        self.lastModified = lastModified
        self.size = size
        self.url = url
        self.auth = auth
    }
    
    /*
     Received XML: <?xml version="1.0" encoding="utf-8" ?><D:multistatus xmlns:D="DAV:">
     <D:response><D:href>/testFolder</D:href><D:propstat><D:prop><D:resourcetype><D:collection/></D:resourcetype><D:getlastmodified>Tue, 20 Aug 2024 10:33:53 GMT</D:getlastmodified></D:prop><D:status>HTTP/1.1 200 OK</D:status></D:propstat></D:response>
     <D:response><D:href>/testFolder/sample.txt</D:href><D:propstat><D:prop><D:resourcetype/><D:getlastmodified>Tue, 20 Aug 2024 10:33:53 GMT</D:getlastmodified><D:getcontentlength>19</D:getcontentlength></D:prop><D:status>HTTP/1.1 200 OK</D:status></D:propstat></D:response>
     </D:multistatus>
     */

    init?(xml: XMLIndexer, baseURL: URL, auth: String) {
        // Print the XML content as a string
        print("Received XML: \(String(describing: xml.element))")
        
        guard let hrefElement = xml["href"].element else {
            print("Failed to get href")
            return nil
        }
        let href = hrefElement.text.removingPercentEncoding ?? ""
        print("Href: \(href)")

        guard let dateString = xml["propstat"]["prop"]["getlastmodified"].element?.text else {
            print("Failed to get getlastmodified")
            return nil
        }
        print("Date String: \(dateString)")
        guard let date = WebDAVFile.rfc1123Formatter.date(from: dateString) else {
            print("Failed to parse date")
            return nil
        }
        print("Parsed Date: \(date)")

        let isDirectory = xml["propstat"]["prop"]["resourcetype"]["collection"].element != nil
        print("Is Directory: \(isDirectory)")
        
        let sizeString = xml["propstat"]["prop"]["getcontentlength"].element?.text
        print("Size String: \(sizeString ?? "nil")")
        let size: Int64 = Int64(sizeString ?? "0") ?? 0
        print("Size: \(size)")

        var path = href.replacingOccurrences(of: baseURL.absoluteString, with: "")
        if path.first == "/" {
            path.removeFirst()
        }
        print("Path: \(path)")

        let url = baseURL.appendingPathComponent(path)
        
        self.init(path: path, id: UUID().uuidString, isDirectory: isDirectory, lastModified: date, size: size, url: url, auth: auth)
    }


    static let rfc1123Formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    public var description: String {
        "WebDAVFile(path: \(path), id: \(id), isDirectory: \(isDirectory), lastModified: \(WebDAVFile.rfc1123Formatter.string(from: lastModified)), size: \(size))"
    }
    public var fileURL: URL {
        URL(fileURLWithPath: path)
    }
    public var fileName: String {
        fileURL.lastPathComponent
    }
    public var `extension`: String {
        fileURL.pathExtension
    }
    public var name: String {
        isDirectory ? fileName : fileURL.deletingPathExtension().lastPathComponent
    }
}
