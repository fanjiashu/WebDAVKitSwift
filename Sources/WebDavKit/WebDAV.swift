//
//  WebDAV.swift
//  hclient3
//
//  Created by mac on 2024/8/20.
//
import Foundation
import SWXMLHash

// WebDAV 类用于管理与 WebDAV 服务器的交互
public class WebDAV {
    var baseURL: URL
    private var auth: String?
    private var headerFields: [String: String]?
    /// 新增的 cookie 属性
    public var cookie: String?
    /// 默认超时时间设置为30秒
    public var timeoutInterval: TimeInterval = 30
    
    // 始化 WebDAV 对象，支持用户名密码认证
    public init(baseURL: String, port: Int, username: String? = nil, password: String? = nil, path: String? = nil) {
        // 确保 baseURL 有协议前缀
        let processedBaseURL: String
        if baseURL.hasPrefix("http://") || baseURL.hasPrefix("https://") {
            processedBaseURL = baseURL
        } else {
            processedBaseURL = "http://" + baseURL
        }
        
        // 创建 URL 对象
        guard let url = URL(string: processedBaseURL) else {
            fatalError("无效的 base URL")
        }
        
        // 处理端口
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        urlComponents.port = (port != 80 && port != 443) ? port : nil
        
        // 处理路径
        if let path = path, !path.isEmpty {
            let trimmedPath = path.hasPrefix("/") ? path : "/\(path)"
            urlComponents.path = trimmedPath
        } else {
            urlComponents.path = ""
        }
        
        // 生成最终的 URL
        let fullURLString = urlComponents.string ?? processedBaseURL
        guard let finalURL = URL(string: fullURLString) else {
            fatalError("无效的 URL")
        }
        
        self.baseURL = finalURL
        
        // 设置认证字符串
        let authString = "\(username ?? ""):\(password ?? "")"
        let authData = authString.data(using: .utf8)
        self.auth = authData?.base64EncodedString() ?? ""
    }
    
    // 新增cookie 初始化
    public init(baseURL: String, port: Int, cookie: String, path: String? = nil) {
        // 处理 baseURL
        var processedBaseURL = baseURL
        if !baseURL.hasPrefix("http://"), !baseURL.hasPrefix("https://") {
            processedBaseURL = "http://" + baseURL
        }
        
        guard let url = URL(string: processedBaseURL) else {
            fatalError("无效的 base URL")
        }
        
        // 配置 URL 组件
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        
        // 处理端口
        if port != 80, port != 443 {
            urlComponents.port = port
        } else {
            urlComponents.port = nil // 移除默认端口设置
        }
        
        // 处理路径
        if let path = path, !path.isEmpty {
            // 确保路径以 '/' 开头，不会影响原始的 baseURL
            if !path.hasPrefix("/") {
                urlComponents.path += "/" + path
            } else {
                urlComponents.path += path
            }
        }
        
        // 构造最终 URL
        guard let finalURL = urlComponents.url else {
            fatalError("无效的 URL")
        }
        
        self.baseURL = finalURL
        
        // 设置 headerFields，用于 Cookie 认证
        self.headerFields = ["Cookie": cookie]
        self.cookie = cookie
    }

    // 静态方法：对文件进行排序
    public static func sortedFiles(_ files: [WebDAVFile], foldersFirst: Bool, includeSelf: Bool) -> [WebDAVFile] {
        var files = files
        if !includeSelf, !files.isEmpty {
            files.removeFirst()
        }
        if foldersFirst {
            files = files.filter { $0.isDirectory } + files.filter { !$0.isDirectory }
        }
        files = files.filter { !$0.fileName.hasPrefix(".") }
        return files
    }
}

// 扩展 WebDAV 类以实现文件操作
public extension WebDAV {
    /// 检测与 WebDAV 服务器的连接是否正常
    func ping() async -> Bool {
        do {
            let _ = try await listFiles(atPath: "/")
            return true
        } catch {
            return false
        }
    }
    
    /// 列出指定路径下的文件
    /// - Parameters:
    ///   - path: 需要列出文件的路径
    ///   - foldersFirst: 是否将文件夹排在前面
    ///   - includeSelf: 是否包含当前目录
    /// - Returns: 文件列表
    /// - Throws: WebDAVError
    func listFiles(atPath path: String, foldersFirst: Bool = true, includeSelf: Bool = false) async throws -> [WebDAVFile] {
        guard var request = authorizedRequest(path: path, method: .propfind) else {
            throw WebDAVError.invalidCredentials
        }

        // 设置 PROPFIND 请求的 body
        let body =
            """
            <?xml version="1.0" encoding="utf-8" ?>
            <D:propfind xmlns:D="DAV:">
                <D:prop>
                    <D:getcontentlength/>
                    <D:getlastmodified/>
                    <D:getcontenttype />
                    <D:resourcetype/>
                </D:prop>
            </D:propfind>
            """
        request.httpBody = body.data(using: .utf8)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse,
                  200...299 ~= response.statusCode
            else {
                throw WebDAVError.getError(response: response, error: nil) ?? WebDAVError.unsupported
            }
            
            // 打印原始 XML 响应
            if let xmlString = String(data: data, encoding: .utf8) {
                print("Received XML: \(xmlString)")
            }
            
            let xml = XMLHash.config { config in
                config.shouldProcessNamespaces = true
            }.parse(String(data: data, encoding: .utf8) ?? "")
            print("xml多少个节点: \(xml.children.first?.children.count ?? 0)")
            
            // 检查认证类型并传递对应的认证信息
            let files = xml["multistatus"]["response"].all.compactMap {
                WebDAVFile(
                    xml: $0,
                    baseURL: self.baseURL,
                    auth: self.auth,
                    cookie: self.cookie
                )
            }
            print("Received XML  多少个文件: \(files.count)")
            let sortFiles = WebDAV.sortedFiles(files, foldersFirst: foldersFirst, includeSelf: includeSelf)
            print("测试WebDAV的打印:排序后 文件多少个：\(sortFiles.count)")
            for item in sortFiles {
                print(item.name)
                print(item.path)
            }
            return sortFiles
        } catch {
            throw WebDAVError.nsError(error)
        }
    }

    /// 删除指定路径的文件
    /// - Parameter path: 需要删除的文件路径
    /// - Returns: 是否删除成功
    /// - Throws: WebDAVError
    func deleteFile(atPath path: String) async throws -> Bool {
        guard let request = authorizedRequest(path: path, method: .delete) else {
            throw WebDAVError.invalidCredentials
        }
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else {
                return false
            }
            return 200...299 ~= response.statusCode
        } catch {
            throw WebDAVError.nsError(error)
        }
    }
    
    /// 创建指定路径的文件夹
    /// - Parameter path: 需要创建的文件夹路径
    /// - Returns: 是否创建成功
    /// - Throws: WebDAVError
    func createFolder(atPath path: String) async throws -> Bool {
        guard let request = authorizedRequest(path: path, method: .mkcol) else {
            throw WebDAVError.invalidCredentials
        }
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else {
                return false
            }
            return 200...299 ~= response.statusCode
        } catch {
            throw WebDAVError.nsError(error)
        }
    }
    
    /// 移动或重命名指定路径的文件
    /// - Parameters:
    ///   - fromPath: 源文件路径
    ///   - toPath: 目标文件路径
    /// - Returns: 是否移动或重命名成功
    /// - Throws: WebDAVError
    func moveFile(fromPath: String, toPath: String) async throws -> Bool {
        let fromURL = self.baseURL.appendingPathComponent(fromPath)
        let toURL = self.baseURL.appendingPathComponent(toPath)

        // 先分别检查目标文件和源文件的存在性
        let destinationExists = try await fileExists(at: toURL)
        let sourceExists = try await fileExists(at: fromURL)

        // 如果目标文件已经存在并且源文件不存在，直接返回成功
        if destinationExists && !sourceExists {
            print("Old file does not exist and new file already exists. Returning success.")
            return true
        }

        guard var request = authorizedRequest(path: fromPath, method: .move) else {
            throw WebDAVError.invalidCredentials
        }

        // 确保 Destination 头部的值是相对路径
        let destinationURL = toURL.absoluteString
        request.addValue(destinationURL, forHTTPHeaderField: "Destination")

        print("Attempting to move file from \(fromPath) to \(destinationURL)")
        print("Request URL: \(request.url?.absoluteString ?? "Unknown")")
        print("Request Method: \(request.httpMethod ?? "Unknown")")
        print("Request Headers: \(request.allHTTPHeaderFields ?? [:])")

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return false
            }

            // 输出响应状态码
            print("Response status code: \(httpResponse.statusCode)")

            // 输出响应数据（如果需要）
            if let data = try? Data(contentsOf: httpResponse.url!) {
                let responseData = String(data: data, encoding: .utf8) ?? "No response data"
                print("Response data: \(responseData)")
            }

            // 检查状态码
            return 200...299 ~= httpResponse.statusCode
        } catch {
            print("Request failed with error: \(error)")
            throw WebDAVError.nsError(error)
        }
    }
    
    /// 使用 PROPFIND 请求检查远程 WebDAV 服务器上的文件是否存在
    /// - Parameter url: 文件的 URL
    /// - Returns: 文件是否存在
    private func fileExists(at url: URL) async throws -> Bool {
        guard var request = authorizedRequest(path: url.path, method: .propfind) else {
            throw WebDAVError.invalidCredentials
        }

        // 设置 PROPFIND 请求的深度为 0，仅查询目标资源本身
        request.addValue("0", forHTTPHeaderField: "Depth")

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return false
            }

            // 如果状态码为 207（Multi-Status），则文件存在
            return httpResponse.statusCode == 207
        } catch {
            return false
        }
    }
    
    /// 复制指定路径的文件
    /// - Parameters:
    ///   - fromPath: 源文件路径
    ///   - toPath: 目标文件路径
    /// - Returns: 是否复制成功
    /// - Throws: WebDAVError
    func copyFile(fromPath: String, toPath: String) async throws -> Bool {
        guard var request = authorizedRequest(path: fromPath, method: .copy) else {
            throw WebDAVError.invalidCredentials
        }
        
        // 确保 Destination 头部的值是相对路径
        let destinationURL = self.baseURL.appendingPathComponent(toPath).absoluteString
        request.addValue(destinationURL, forHTTPHeaderField: "Destination")
        
        print("Attempting to copy file from \(fromPath) to \(destinationURL)")
        print("Request URL: \(request.url?.absoluteString ?? "Unknown")")
        print("Request Method: \(request.httpMethod ?? "Unknown")")
        print("Request Headers: \(request.allHTTPHeaderFields ?? [:])")
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return false
            }
            
            // 输出响应状态码
            print("Response status code: \(httpResponse.statusCode)")
            
            // 输出响应数据
            if let data = try? Data(contentsOf: httpResponse.url!) {
                let responseData = String(data: data, encoding: .utf8) ?? "No response data"
                print("Response data: \(responseData)")
            }
            
            // 检查状态码
            return 200...299 ~= httpResponse.statusCode
        } catch {
            print("Request failed with error: \(error)")
            throw WebDAVError.nsError(error)
        }
    }

    /// 上传文件到指定路径
    /// - Parameters:
    ///   - path: 文件路径
    ///   - data: 文件数据
    /// - Returns: 是否上传成功
    /// - Throws: WebDAVError
    func uploadFile(atPath path: String, data: Data) async throws -> Bool {
        guard var request = authorizedRequest(path: path, method: .put) else {
            throw WebDAVError.invalidCredentials
        }
        request.httpBody = data
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else {
                return false
            }
            return 200...299 ~= response.statusCode
        } catch {
            throw WebDAVError.nsError(error)
        }
    }
    
    /// 下载指定路径的文件
    /// - Parameter path: 文件路径
    /// - Returns: 文件数据
    /// - Throws: WebDAVError
    func downloadFile(atPath path: String) async throws -> Data {
        guard let request = authorizedRequest(path: path, method: .get) else {
            throw WebDAVError.invalidCredentials
        }
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse,
                  200...299 ~= response.statusCode
            else {
                throw WebDAVError.getError(response: response, error: nil) ?? WebDAVError.unsupported
            }
            return data
        } catch {
            throw WebDAVError.nsError(error)
        }
    }
}

// 扩展 WebDAV 类以实现请求创建
public extension WebDAV {
    /// 创建一个授权的 URL 请求，支持两种认证方式
    /// - Parameters:
    ///   - path: 请求的路径
    ///   - method: HTTP 方法
    /// - Returns: 授权后的 URL 请求
    func authorizedRequest(path: String, method: HTTPMethod) -> URLRequest? {
        let url = self.baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        // 设置请求方式
        request.httpMethod = method.rawValue
        // 设置超时时间
        request.timeoutInterval = self.timeoutInterval
        // 设置认证头部
        if let auth = self.auth {
            request.setValue("Basic \(auth)", forHTTPHeaderField: "Authorization")
        } else if let headerFields = self.headerFields {
            for (key, value) in headerFields {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        if method == .propfind {
            request.setValue("1", forHTTPHeaderField: "Depth")
        }
        return request
    }
}
