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
    public private(set) var auth: String?
    public private(set) var cookie: String?

    init?(xml: XMLIndexer, baseURL: URL, auth: String? = nil, cookie: String? = nil) {
        print("Received XML: \(String(describing: xml.element))")

        // 处理 href 元素
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
        // 处理没有 getlastmodified 的情况
        if date == nil {
            for propstat in xml["propstat"].all {
                if let dateString = propstat["prop"]["getlastmodified"].element?.text {
                    print("Date String (fallback): \(dateString)")
                    date = WebDAVFile.rfc1123Formatter.date(from: dateString)
                    if date != nil {
                        print("Parsed Date (fallback): \(date!)")
                        break
                    }
                }
            }
        }

        guard let validDate = date else {
            print("Failed to get getlastmodified")
            return nil
        }

        // 解析是否为目录
        let isDirectory: Bool
        if let collectionElement = xml["propstat"]["prop"]["resourcetype"]["collection"].element {
            isDirectory = collectionElement.text.isEmpty
        } else {
            isDirectory = xml["propstat"]["prop"]["resourcetype"]["collection"].element != nil
        }
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

        // 处理路径
        // 处理路径
        var path = href

        // 替换掉 URL 中的 scheme 和 host 部分，而保留路径部分
        let basePath = baseURL.path
        if path.hasPrefix(basePath) {
            path = String(path.dropFirst(basePath.count))
        }
        // 移除路径前面的斜杠，如果有的话
        if path.first == "/" {
            path.removeFirst()
        }
        print("Final Path: \(path)")

        // 创建文件的 URL
        let url = baseURL.deletingLastPathComponent().appendingPathComponent(path)

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
    
    
    
    
    /// 新的初始化器，允许使用文件路径、修改日期、大小和其他属性创建 WebDAVFile 实例。
    /// - Parameters:
    ///   - path: 文件系统上的文件路径。
    ///   - lastModified: 文件最后修改日期。
    ///   - size: 文件大小。
    ///   - isDirectory: 指示是否为目录。
    ///   - auth: 用于访问控制的认证信息。
    ///   - cookie: 用于会话管理的 cookie。
  public init?(path: String, lastModified: Date? = nil, size: Int64 = 0, isDirectory: Bool = false, auth: String? = nil, cookie: String? = nil) {
        // 确保路径是有效的
        guard !path.isEmpty else { return nil }
        
        // 如果提供了 lastModified，则使用它；否则使用当前日期和时间。
        let modifiedDate = lastModified ?? Date()
        
        // 根据路径创建 URL
        let fileURL = URL(fileURLWithPath: path)
        
        // 根据路径创建一个唯一的 ID
        let id = isDirectory ? fileURL.lastPathComponent : fileURL.absoluteString
        
        self.path = path
        self.id = id
        self.isDirectory = isDirectory
        self.lastModified = modifiedDate
        self.size = size
        self.url = fileURL
        self.auth = auth
        self.cookie = cookie
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
