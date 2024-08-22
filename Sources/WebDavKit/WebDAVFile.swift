//
//  WebDAVFile.swift
//  hclient3
//
//  Created by mac on 2024/8/20.
//

import Foundation
import SWXMLHash

public struct WebDAVFile: Identifiable, Codable, Equatable, Hashable {

    public private(set) var path: String
    public private(set) var id: String
    public private(set) var isDirectory: Bool
    public private(set) var lastModified: Date
    public private(set) var size: Int64
    public private(set) var url: URL
    public private(set) var auth: String?  // 基本认证信息
    public private(set) var cookie: String?  // Cookie 认证信息

    init(path: String, id: String, isDirectory: Bool, lastModified: Date, size: Int64, url: URL, auth: String? = nil, cookie: String? = nil) {
        self.path = path
        self.id = id
        self.isDirectory = isDirectory
        self.lastModified = lastModified
        self.size = size
        self.url = url
        self.auth = auth
        self.cookie = cookie
    }

    init?(xml: XMLIndexer, baseURL: URL, auth: String? = nil, cookie: String? = nil) {
        print("Received XML: \(String(describing: xml.element))")

        guard let hrefElement = xml["href"].element else {
            print("Failed to get href")
            return nil
        }
        let href = hrefElement.text.removingPercentEncoding ?? ""
        print("Href: \(href)")

        // 解析 getlastmodified 时间
        var date: Date? = nil
        for propstat in xml["propstat"].all {
            if let dateString = propstat["prop"]["getlastmodified"].element?.text {
                print("Date String: \(dateString)")
                date = WebDAVFile.rfc1123Formatter.date(from: dateString)
                if date != nil {
                    print("Parsed Date: \(date!)")
                    break
                }
            }
        }
        guard let validDate = date else {
            print("Failed to get getlastmodified")
            return nil
        }

        let isDirectory = xml["propstat"]["prop"]["resourcetype"]["collection"].element != nil
        print("Is Directory: \(isDirectory)")

        // 解析文件大小
        var size: Int64 = 0
        for propstat in xml["propstat"].all {
            if let sizeString = propstat["prop"]["getcontentlength"].element?.text {
                print("Size String: \(sizeString)")
                size = Int64(sizeString) ?? 0
                print("Size: \(size)")
                break
            }
        }

        var path = href.replacingOccurrences(of: baseURL.absoluteString, with: "")
        if path.first == "/" {
            path.removeFirst()
        }
        print("Path: \(path)")

        let url = baseURL.appendingPathComponent(path)

        self.path = path
        self.id = UUID().uuidString
        self.isDirectory = isDirectory
        self.lastModified = validDate
        self.size = size
        self.url = url
        self.auth = auth
        self.cookie = cookie

        print("Parsed WebDAVFile: \(self)")
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

