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
    /// 默认超时时间设置为30秒  改为60秒
    public var timeoutInterval: TimeInterval = 60

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
//    public static func sortedFiles(_ files: [WebDAVFile], foldersFirst: Bool, includeSelf: Bool) -> [WebDAVFile] {
//        print("测试WebDAV的打印:排序前 文件多少个：\(files.count) :   \(files)")
//        var files = files
//        if !includeSelf, !files.isEmpty {
//            files.removeFirst()
//        }
//        if foldersFirst {
//            files = files.filter { $0.isDirectory } + files.filter { !$0.isDirectory }
//        }
//        files = files.filter { !$0.fileName.hasPrefix(".") }
//        print("测试WebDAV的打印:排序后 文件多少个：\(files.count) :   \(files)")
//        return files
//    }

    public static func sortedFiles(_ files: [WebDAVFile], foldersFirst: Bool, includeSelf: Bool) -> [WebDAVFile] {
        print("排序:排序前，文件数量: \(files.count)")

        var files = files

        // 检查是否需要移除第一个文件
        if !includeSelf, !files.isEmpty {
            // 优化：只有当有目录文件时才移除第一个文件
            let hasDirectory = files.contains { $0.isDirectory }
            if hasDirectory {
                files.removeFirst()
                print("移除第一个文件")
            }
            if files.first?.path == "" {
                files.removeFirst()
                print("移除第一个文件,因为是根目录本身")
            }
        }

        // 目录优先排序
        if foldersFirst {
            let directories = files.filter { $0.isDirectory }
            let nonDirectories = files.filter { !$0.isDirectory }
            files = directories + nonDirectories
            //   print("排序:目录优先排序后，文件数量: \(files.count)")
        }

        // 过滤隐藏文件
        files = files.filter { !$0.fileName.hasPrefix(".") }
        // print("排序:过滤隐藏文件后，文件数量: \(files.count)，文件详情: \(files)")

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
            let (data, response) = try await sendRequest(request)
            guard let response = response as? HTTPURLResponse,
                  200 ... 299 ~= response.statusCode
            else {
                throw WebDAVError.getError(response: response, error: nil) ?? WebDAVError.unsupported
            }

            // 打印原始 XML 响应
            if let xmlString = String(data: data, encoding: .utf8) {
                //  print("Received XML: \(xmlString)")
            }

            let xml = XMLHash.config { config in
                config.shouldProcessNamespaces = true
            }.parse(String(data: data, encoding: .utf8) ?? "")
            //  print("xml多少个节点: \(xml.children.first?.children.count ?? 0)")

//            // 检查认证类型并传递对应的认证信息
            let files = xml["multistatus"]["response"].all.compactMap {
                WebDAVFile(
                    xml: $0,
                    baseURL: self.baseURL,
                    auth: self.auth,
                    cookie: self.cookie
                )
            }
            let sortFiles = WebDAV.sortedFiles(files, foldersFirst: foldersFirst, includeSelf: includeSelf)
            return sortFiles
        } catch {
            throw WebDAVError.nsError(error)
        }
    }

    // 封装获取子文件数量的方法
    func fetchChildItemCount(for path: String) async throws -> Int {
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
            let (data, response) = try await sendRequest(request)
            guard let response = response as? HTTPURLResponse,
                  200 ... 299 ~= response.statusCode
            else {
                throw WebDAVError.getError(response: response, error: nil) ?? WebDAVError.unsupported
            }

            // 打印原始 XML 响应
            if let xmlString = String(data: data, encoding: .utf8) {
                //  print("Received XML: \(xmlString)")
            }

            let xml = XMLHash.config { config in
                config.shouldProcessNamespaces = true
            }.parse(String(data: data, encoding: .utf8) ?? "")
            //  print("xml多少个节点: \(xml.children.first?.children.count ?? 0)")

//            // 检查认证类型并传递对应的认证信息
            let files = xml["multistatus"]["response"].all.compactMap {
                WebDAVFile(
                    xml: $0,
                    baseURL: self.baseURL,
                    auth: self.auth,
                    cookie: self.cookie
                )
            }
            let sortFiles = WebDAV.sortedFiles(files, foldersFirst: true, includeSelf: false)
            return sortFiles.count
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
            let (_, response) = try await sendRequest(request)
            guard let response = response as? HTTPURLResponse else {
                return false
            }
            return 200 ... 299 ~= response.statusCode
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
            return 200 ... 299 ~= response.statusCode
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
        // 先分别检查目标文件和源文件的存在性
        let destinationExists = try await fileExists(at: toPath)
        let sourceExists = try await fileExists(at: fromPath)

        // let fromURL = self.baseURL.appendingPathComponent(fromPath)
        let toURL = self.baseURL.appendingPathComponent(toPath)

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
            let (_, response) = try await sendRequest(request)
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
            return 200 ... 299 ~= httpResponse.statusCode
        } catch {
            print("Request failed with error: \(error)")
            throw WebDAVError.nsError(error)
        }
    }

    /// 使用 Head 请求检查远程 WebDAV 服务器上的文件是否存在
    /// - Parameter url: 文件的 URL
    /// - Returns: 文件是否存在
    func fileExists(at path: String) async throws -> Bool {
        guard let request = authorizedRequest(path: path, method: .head) else {
            throw WebDAVError.invalidCredentials
        }

        do {
            let (_, response) = try await sendRequest(request)
            print("判断文件是否存在 \(response)")
            guard let httpResponse = response as? HTTPURLResponse else {
                return false
            }

            // 如果状态码为 200（OK），则文件存在
            return httpResponse.statusCode == 200
        } catch {
            return false
        }
    }

    /// 检查远程 WebDAV 服务器上的路径是否是文件夹
    /// - Parameter path: 路径的字符串
    /// - Returns: 是否是文件夹
    func isDirectory(atPath path: String) async throws -> Bool {
        guard var request = authorizedRequest(path: path, method: .propfind) else {
            throw WebDAVError.invalidCredentials
        }

        // 设置 PROPFIND 请求的 body
        let body =
            """
            <?xml version="1.0" encoding="utf-8" ?>
            <D:propfind xmlns:D="DAV:">
                <D:prop>
                    <D:resourcetype/>
                </D:prop>
            </D:propfind>
            """
        request.httpBody = body.data(using: .utf8)
        request.setValue("0", forHTTPHeaderField: "Depth") // 只检查当前资源

        do {
            let (data, response) = try await sendRequest(request)
            guard let response = response as? HTTPURLResponse,
                  200 ... 299 ~= response.statusCode
            else {
                print("判断文件类型报错 \(response) 原始path：\(path)")
                throw WebDAVError.getError(response: response, error: nil) ?? WebDAVError.unsupported
            }

            // 打印原始 XML 响应
            if let xmlString = String(data: data, encoding: .utf8) {
                print("判断Full XML:\(xmlString)")
            }

            let xml = XMLHash.parse(data)

            // 获取 resourcetype 节点并检查它是否包含 <D:collection/>
            let resourceType = xml["D:multistatus"]["D:response"]["D:propstat"]["D:prop"]["D:resourcetype"]
            // 处理路径以 .app 结尾的情况，强制识别为文件，不在解析，以及解析会出错
            if path.hasSuffix(".app") {
                return false
            }
            print("resourceType XML: \(resourceType)")
            // 只有在 resourcetype 中包含 <D:collection> 才返回 true
            let isDirectory = !resourceType.children.isEmpty && !resourceType["D:collection"].all.isEmpty
            return isDirectory

//            var isDirectory = false
//            // 解析 <collection> 节点
//             let resourceType = xml["multistatus"]["response"]["propstat"]["prop"]["resourcetype"]
//
//             // 打印 resourceType 以调试
//             print("资源类型 XML: \(resourceType)")
//
//             // 判断 <collection> 节点是否存在
//              isDirectory = resourceType["collection"].element != nil
//             print("是否目录: \(isDirectory)")
//              return isDirectory

        } catch {
            throw WebDAVError.nsError(error)
        }
    }
    
    /// 获取远程 WebDAV 服务器上文件的大小
    /// - Parameter path: 文件的路径
    /// - Returns: 文件的大小（以字节为单位）
    func fileSize(atPath path: String) async throws -> Int64 {
        // 使用 authorizedRequest 函数创建授权的请求
        guard var request = authorizedRequest(path: path, method: .propfind) else {
            throw WebDAVError.invalidCredentials
        }
        
        // 设置 PROPFIND 请求的 body，要求返回文件的大小
        let body = """
        <?xml version="1.0" encoding="utf-8" ?>
        <D:propfind xmlns:D="DAV:">
            <D:prop>
                <D:getcontentlength/>
            </D:prop>
        </D:propfind>
        """
        request.httpBody = body.data(using: .utf8)
        request.setValue("0", forHTTPHeaderField: "Depth") // 只检查当前资源

        do {
            // 发送请求并获取响应
            let (data, response) = try await sendRequest(request)
            guard let response = response as? HTTPURLResponse,
                  200 ... 299 ~= response.statusCode else {
                print("获取文件大小报错 \(response) 原始path：\(path)")
                throw WebDAVError.getError(response: response, error: nil) ?? WebDAVError.unsupported
            }
            
            // 打印原始 XML 响应，帮助调试
            if let xmlString = String(data: data, encoding: .utf8) {
                print("Full XML Response: \(xmlString)")
            }
            
            // 使用 XMLHash 解析返回的 XML 数据
            let xml = XMLHash.parse(data)
            
            // 获取 <getcontentlength> 节点的值，即文件大小
            let contentLength = xml["D:multistatus"]["D:response"]["D:propstat"]["D:prop"]["D:getcontentlength"].element?.text
            
            if let fileSizeStr = contentLength, let fileSize = Int64(fileSizeStr) {
                return fileSize
            } else {
                throw WebDAVError.unsupported
            }
            
        } catch {
            throw WebDAVError.nsError(error)
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
            let (_, response) = try await sendRequest(request)
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
            return 200 ... 299 ~= httpResponse.statusCode
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
            let (_, response) = try await sendRequest(request)
            guard let response = response as? HTTPURLResponse else {
                return false
            }
            return 200 ... 299 ~= response.statusCode
        } catch {
            throw WebDAVError.nsError(error)
        }
    }

    /// 下载指定路径的文件
    /// - Parameters:
    ///   - path: 文件路径
    ///   - useStream: 是否使用流式下载
    ///   - destinationPath: 流式下载指定的路径
    /// - Returns: 下载后的文件的临时 URL
    /// - Throws: WebDAVError
    ///
    // 1. 主下载函数
    @available(iOS 15.0, macOS 12.0, *)
    func downloadFile(atPath path: String, useStream: Bool = false, destinationPath: URL? = nil) async throws -> URL {
        // 获取授权请求
        guard let request = authorizedRequest(path: path, method: .get) else {
            print("WAD测试：获取授权请求失败")
            throw WebDAVError.invalidCredentials
        }
        
        do {
            if useStream && destinationPath != nil {
                print("WAD测试：开始流式下载到指定路径: \(destinationPath!.path)")
                
                // 使用 Socks5 代理或默认 session
                let session = Socks5ProxyManager.shared.isProxyActive()
                    ? URLSession(configuration: Socks5ProxyManager.shared.getProxySessionConfiguration() ?? .default)
                    : URLSession.shared
                
                // 使用流式下载
                let (finalURL, response) = try await streamDownload(using: session,
                                                                  for: request,
                                                                  destinationURL: destinationPath!)
                
                // 检查响应状态
                guard let httpResponse = response as? HTTPURLResponse,
                      200 ... 299 ~= httpResponse.statusCode else {
                    throw WebDAVError.getError(response: response, error: nil) ?? WebDAVError.unsupported
                }
                
                return finalURL
            } else {
                // 使用标准下载方式
                let (tempDownloadURL, response) = try await downloadRequest(request, useStream: useStream)
                
                // 检查响应状态
                guard let httpResponse = response as? HTTPURLResponse,
                      200 ... 299 ~= httpResponse.statusCode else {
                    throw WebDAVError.getError(response: response, error: nil) ?? WebDAVError.unsupported
                }
                
                // 确定目标存储路径
                let targetURL: URL
                if let destinationPath = destinationPath {
                    targetURL = destinationPath
                } else {
                    let fileExtension = (path as NSString).pathExtension
                    var fileName = (path as NSString).lastPathComponent
                    
                    if let contentDisposition = httpResponse.value(forHTTPHeaderField: "Content-Disposition"),
                       let extractedFileName = extractFileName(from: contentDisposition) {
                        fileName = extractedFileName
                    } else if !fileExtension.isEmpty && !fileName.hasSuffix(fileExtension) {
                        fileName += ".\(fileExtension)"
                    }
                    
                    targetURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                }
                
                // 如果目标路径已存在文件，则删除
                if FileManager.default.fileExists(atPath: targetURL.path) {
                    try FileManager.default.removeItem(at: targetURL)
                }
                
                // 移动文件到目标位置
                try FileManager.default.moveItem(at: tempDownloadURL, to: targetURL)
                return targetURL
            }
        } catch let error as NSError {
            print("WAD测试：下载过程发生错误: \(error)")
            throw WebDAVError.nsError(error)
        }
    }
    
    
    /// 统一的发送请求方法
    private func sendRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        if Socks5ProxyManager.shared.isProxyActive() {
            // 使用 Socks5 代理的 URLSession 配置
            guard let proxyConfig = Socks5ProxyManager.shared.getProxySessionConfiguration() else {
                throw WebDAVError.proxyConfigurationError("Invalid proxy configuration.")
            }
            let proxySession = URLSession(configuration: proxyConfig)
            return try await proxySession.data(for: request)
        } else {
            // 使用默认的 URLSession
            return try await URLSession.shared.data(for: request)
        }
    }
    /// 统一的下载请求方法，带有重试机制
    private func downloadRequest(_ request: URLRequest, useStream: Bool = false) async throws -> (URL, URLResponse) {
        if #available(iOS 15.0, macOS 12.0, *) {
            let session: URLSession
            if Socks5ProxyManager.shared.isProxyActive() {
                guard let proxyConfig = Socks5ProxyManager.shared.getProxySessionConfiguration() else {
                    throw WebDAVError.proxyConfigurationError("Invalid proxy configuration.")
                }
                session = URLSession(configuration: proxyConfig)
            } else {
                session = URLSession.shared
            }
            
            let maxRetryAttempts = 3
            var lastError: Error?
            
            for attempt in 1...maxRetryAttempts {
                do {
                    print("WAD测试：开始下载，第 \(attempt)/\(maxRetryAttempts) 次尝试")
                    
                    if useStream {
                        return try await streamDownload(using: session,
                                                      for: request,
                                                      destinationURL: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
                    } else {
                        return try await session.download(for: request)
                    }
                } catch {
                    lastError = error
                    print("WAD测试：下载失败，错误: \(error.localizedDescription)")
                    
                    if attempt < maxRetryAttempts {
                        try await Task.sleep(nanoseconds: 1_000_000_000) // 1秒后重试
                    }
                }
            }
            
            if let error = lastError {
                throw error
            } else {
                throw WebDAVError.proxyConfigurationError("下载失败，没有可用的重试。")
            }
        } else {
            // iOS 15/macOS 12 以下的处理
            let (data, response) = try await URLSession.shared.data(for: request)
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try data.write(to: tempURL)
            return (tempURL, response)
        }
    }

    @available(iOS 15.0, macOS 12.0, *)
    private func streamDownload(using session: URLSession,
                              for originalRequest: URLRequest,
                              destinationURL: URL) async throws -> (URL, URLResponse) {
        print("""
            === 流式下载详细日志 ===
            时间: \(Date())
            用户: fanjiashu
            """)
        
        // 1. 获取文件实际大小
        let path = originalRequest.url?.lastPathComponent ?? ""
        let totalSize: Int64
        do {
            totalSize = try await fileSize(atPath: path)
            print("""
                1. 文件信息:
                - 路径: \(path)
                - 总大小: \(totalSize / 1024 / 1024) MB (\(totalSize) 字节)
                """)
        } catch {
            print("错误: 无法获取文件大小 - \(error)")
            throw error
        }
        
        // 确保目标目录存在
        let directoryPath = destinationURL.deletingLastPathComponent().path
        if !FileManager.default.fileExists(atPath: directoryPath) {
            try FileManager.default.createDirectory(atPath: directoryPath, withIntermediateDirectories: true)
            print("已创建目录: \(directoryPath)")
        }

        //2 创建目标文件
        if !FileManager.default.fileExists(atPath: destinationURL.path) {
            let success = FileManager.default.createFile(atPath: destinationURL.path, contents: nil)
            if success {
                print("成功创建占位文件: \(destinationURL.path)")
            } else {
                throw NSError(domain: "FileCreationError", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法创建文件: \(destinationURL.path)"])
            }
        }

        // 打开文件句柄
        let fileHandle: FileHandle
        do {
            fileHandle = try FileHandle(forWritingTo: destinationURL)
            print("成功打开文件句柄")
        } catch {
            print("错误: 无法打开文件句柄 - \(error)")
            throw error
        }
        
        // 3. 设置分片下载参数
        let chunkSize: Int64 = 20 * 1024 * 1024 // 20MB per chunk
        var downloadedSize: Int64 = 0
        let startTime = Date()
        var lastProgressTime = startTime
        var lastDownloadedSize: Int64 = 0
        
        print("""
            4. 开始分片下载:
            - 分片大小: \(chunkSize / 1024 / 1024) MB
            - 预计分片数: \((totalSize + chunkSize - 1) / chunkSize)
            """)
        
        // 保存第一个响应用于返回
        var firstResponse: URLResponse?
        
        while downloadedSize < totalSize {
            let endByte = min(downloadedSize + chunkSize - 1, totalSize - 1)
            var rangeRequest = originalRequest
            rangeRequest.setValue("bytes=\(downloadedSize)-\(endByte)", forHTTPHeaderField: "Range")
            
            // 4. 下载当前分片
            let (bytes, response) = try await session.bytes(for: rangeRequest)
            
            // 保存第一个响应
            if firstResponse == nil {
                firstResponse = response
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 206 else {
                print("错误: 服务器不支持断点续传或返回了错误的状态码")
                throw URLError(.badServerResponse)
            }
            
            // 5. 写入分片数据
            var chunkBuffer = Data(capacity: 1024 * 1024) // 1MB buffer
            var chunkBytesRead: Int64 = 0
            
            for try await byte in bytes {
                chunkBuffer.append(byte)
                chunkBytesRead += 1
                
                if chunkBuffer.count >= 1024 * 1024 { // 每1MB写入一次
                    try fileHandle.write(contentsOf: chunkBuffer)
                    chunkBuffer.removeAll(keepingCapacity: true)
                    
                    // 6. 计算和显示下载速度（每秒更新一次）
                    let now = Date()
                    if now.timeIntervalSince(lastProgressTime) >= 1.0 {
                        let currentDownloadedSize = downloadedSize + chunkBytesRead
                        let timeInterval = now.timeIntervalSince(lastProgressTime)
                        let speed = Double(currentDownloadedSize - lastDownloadedSize) / timeInterval / 1024 / 1024
                        let totalProgress = Double(currentDownloadedSize) * 100.0 / Double(totalSize)
                        
                        print("""
                            下载进度:
                            - 已下载: \(currentDownloadedSize / 1024 / 1024) MB
                            - 总进度: \(String(format: "%.2f", totalProgress))%
                            - 当前速度: \(String(format: "%.2f", speed)) MB/s
                            - 已用时间: \(String(format: "%.1f", now.timeIntervalSince(startTime))) 秒
                            """)
                        
                        lastProgressTime = now
                        lastDownloadedSize = currentDownloadedSize
                    }
                }
            }
            
            // 写入分片剩余数据
            if !chunkBuffer.isEmpty {
                try fileHandle.write(contentsOf: chunkBuffer)
            }
            
            try fileHandle.synchronize()
            downloadedSize += chunkBytesRead
        }
        
        let endTime = Date()
        let totalTime = endTime.timeIntervalSince(startTime)
        let averageSpeed = Double(totalSize) / totalTime / 1024 / 1024
        
        print("""
            6. 下载完成:
            - 总计下载: \(downloadedSize / 1024 / 1024) MB
            - 总耗时: \(String(format: "%.2f", totalTime)) 秒
            - 平均速度: \(String(format: "%.2f", averageSpeed)) MB/s
            - 完成时间: \(endTime)
            """)
        
        // 确保我们有响应可以返回
        guard let finalResponse = firstResponse else {
            throw URLError(.badServerResponse)
        }
        
        return (destinationURL, finalResponse)
    }
    
    
    // 封装获取子文件的第一个文件方法
    func fetchFirstChildFile(for path: String) async throws -> WebDAVFile? {
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
                    <D:getcontenttype/>
                    <D:resourcetype/>
                </D:prop>
            </D:propfind>
            """
        request.httpBody = body.data(using: .utf8)

        do {
            let (data, response) = try await sendRequest(request)
            guard let response = response as? HTTPURLResponse, (200 ... 299).contains(response.statusCode) else {
                throw WebDAVError.getError(response: response, error: nil) ?? WebDAVError.unsupported
            }

            // 打印原始 XML 响应（调试时可启用）
            if let xmlString = String(data: data, encoding: .utf8) {
                // print("Received XML: \(xmlString)")
            }

            let xml = XMLHash.config { config in
                config.shouldProcessNamespaces = true
            }.parse(String(data: data, encoding: .utf8) ?? "")

            // 提取 WebDAV 文件信息
            let files = xml["multistatus"]["response"].all.compactMap {
                WebDAVFile(
                    xml: $0,
                    baseURL: self.baseURL,
                    auth: self.auth,
                    cookie: self.cookie
                )
            }

            // 按规则排序文件，优先返回第一个文件
            let sortedFiles = WebDAV.sortedFiles(files, foldersFirst: true, includeSelf: false)

            // 返回排序后的第一个文件
            return sortedFiles.first
        } catch {
            throw WebDAVError.nsError(error)
        }
    }

    func chunkedDownload(webDAVFile: WebDAVFile, chunkSize: Int = 5 * 1024 * 1024, request: URLRequest) async throws -> (URL, URLResponse) {
        let totalSize = Int(webDAVFile.size)
        print("文件总大小: \(totalSize) 字节")

        // 分块计算
        var chunks: [(start: Int, end: Int)] = []
        var start = 0
        while start < totalSize {
            let end = min(start + chunkSize - 1, totalSize - 1)
            chunks.append((start, end))
            start = end + 1
        }
        print("分块数量: \(chunks.count)")

        // 创建临时文件
        let tempFileURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        FileManager.default.createFile(atPath: tempFileURL.path, contents: nil, attributes: nil)
        let fileHandle = try FileHandle(forWritingTo: tempFileURL)

        // 用于保存最后一个分块的响应（URLResponse）
        var finalResponse: URLResponse?

        // 创建并发下载任务
        var session = URLSession.shared

        if Socks5ProxyManager.shared.isProxyActive() {
            session = URLSession(configuration: Socks5ProxyManager.shared.getProxySessionConfiguration()!)
        }

        let maxConcurrentDownloads = 40 // 控制并发请求数，避免过多的并发请求影响性能
        var currentIndex = 0
        // 异步并发下载每个分块
        while currentIndex < chunks.count {
            let remainingChunks = chunks[currentIndex ..< min(currentIndex + maxConcurrentDownloads, chunks.count)]
            let downloadTasks = remainingChunks.map { chunk -> Task<Void, Never> in
                Task {
                    do {
                        var rangeRequest = request
                        rangeRequest.setValue("bytes=\(chunk.start)-\(chunk.end)", forHTTPHeaderField: "Range")

                        print("正在下载分块 \(currentIndex + 1)/\(chunks.count), 范围: \(chunk.start)-\(chunk.end)")

                        // 下载分块并写入文件
                        let (chunkData, response) = try await session.data(for: rangeRequest)
                        fileHandle.seek(toFileOffset: UInt64(chunk.start))
                        fileHandle.write(chunkData)
                        finalResponse = response // 保存最后一个分块的响应
                    } catch {
                        print("下载分块失败: \(chunk.start)-\(chunk.end), 错误: \(error)")
                        // 可选择增加重试机制，这里简化处理
                    }
                }
            }

            // 等待当前批次下载完成
            await withTaskGroup(of: Void.self) { group in
                for task in downloadTasks {
                    group.addTask {
                        await task.value
                    }
                }
            }

            // 更新当前索引，开始下一个批次
            currentIndex += maxConcurrentDownloads
        }

        // 确保文件写入完成后返回有效的响应
        fileHandle.closeFile()
        guard let finalResponse = finalResponse else {
            throw WebDAVError.unsupported
        }

        return (tempFileURL, finalResponse)
    }
    

    @available(iOS 15.0, macOS 12.0, *)
    func downloadFileFirstPart(atPath path: String, destinationPath: URL, initialSize: Int64 = 5 * 1024 * 1024) async throws -> (URL, Int64, URLResponse) {
        guard let request = authorizedRequest(path: path, method: .get) else {
            throw WebDAVError.invalidCredentials
        }
        
        let session = Socks5ProxyManager.shared.isProxyActive()
            ? URLSession(configuration: Socks5ProxyManager.shared.getProxySessionConfiguration() ?? .default)
            : URLSession.shared
        
        // 1. 获取文件大小
        let totalSize = try await fileSize(atPath: path)
        
        // 2. 创建目标文件
        if FileManager.default.fileExists(atPath: destinationPath.path) {
            try FileManager.default.removeItem(at: destinationPath)
        }
        FileManager.default.createFile(atPath: destinationPath.path, contents: nil)
        
        // 3. 使用更大的缓冲区
        let bufferSize = 1024 * 1024 * 2 // 2MB buffer
        var rangeRequest = request
        rangeRequest.setValue("bytes=0-\(initialSize - 1)", forHTTPHeaderField: "Range")
        
        let (bytes, response) = try await session.bytes(for: rangeRequest)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 206 else {
            throw URLError(.badServerResponse)
        }
        
        // 4. 使用FileHandle进行批量写入
        let fileHandle = try FileHandle(forWritingTo: destinationPath)
        defer {
            try? fileHandle.synchronize()
            try? fileHandle.close()
        }
        
        var buffer = Data(capacity: bufferSize)
        var downloadedSize: Int64 = 0
        
        // 5. 使用更大的批次写入
        for try await byte in bytes {
            buffer.append(byte)
            downloadedSize += 1
            
            if buffer.count >= bufferSize {
                try fileHandle.write(contentsOf: buffer)
                buffer.removeAll(keepingCapacity: true)
                
                let progress = Double(downloadedSize) * 100.0 / Double(initialSize)
                print("下载进度: \(String(format: "%.2f", progress))%")
            }
            
            if downloadedSize >= initialSize {
                break
            }
        }
        
        if !buffer.isEmpty {
            try fileHandle.write(contentsOf: buffer)
        }
        
        return (destinationPath, totalSize, response)
    }

    @available(iOS 15.0, macOS 12.0, *)
    func continueDownload(atPath path: String, destinationPath: URL, fromOffset: Int64, totalSize: Int64) async throws {
        guard let request = authorizedRequest(path: path, method: .get) else {
            throw WebDAVError.invalidCredentials
        }
        
        let session = Socks5ProxyManager.shared.isProxyActive()
            ? URLSession(configuration: Socks5ProxyManager.shared.getProxySessionConfiguration() ?? .default)
            : URLSession.shared
        
        let fileHandle = try FileHandle(forWritingTo: destinationPath)
        try fileHandle.seek(toOffset: UInt64(fromOffset))
        defer {
            try? fileHandle.synchronize()
            try? fileHandle.close()
        }
        
        // 1. 使用更大的分片和缓冲区
        let chunkSize: Int64 = 50 * 1024 * 1024 // 50MB per chunk
        let bufferSize = 5 * 1024 * 1024 // 5MB buffer
        var downloadedSize = fromOffset
        let startTime = Date()
        var lastProgressUpdate = Date()
        
        while downloadedSize < totalSize {
            let endByte = min(downloadedSize + chunkSize - 1, totalSize - 1)
            var rangeRequest = request
            rangeRequest.setValue("bytes=\(downloadedSize)-\(endByte)", forHTTPHeaderField: "Range")
            
            let (bytes, response) = try await session.bytes(for: rangeRequest)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 206 else {
                throw URLError(.badServerResponse)
            }
            
            var buffer = Data(capacity: bufferSize)
            var chunkBytesRead: Int64 = 0
            
            // 2. 批量处理数据
            for try await byte in bytes {
                buffer.append(byte)
                chunkBytesRead += 1
                
                if buffer.count >= bufferSize {
                    try fileHandle.write(contentsOf: buffer)
                    buffer.removeAll(keepingCapacity: true)
                    
                    // 3. 控制进度更新频率
                    let now = Date()
                    if now.timeIntervalSince(lastProgressUpdate) >= 1.0 {
                        let currentSize = downloadedSize + chunkBytesRead
                        let progress = Double(currentSize) * 100.0 / Double(totalSize)
                        let speed = Double(bufferSize) / now.timeIntervalSince(lastProgressUpdate) / 1024 / 1024
                        
                        print("""
                            下载进度:
                            - 已下载: \(currentSize / 1024 / 1024) MB
                            - 进度: \(String(format: "%.2f", progress))%
                            - 速度: \(String(format: "%.2f", speed)) MB/s
                            """)
                        
                        lastProgressUpdate = now
                    }
                }
            }
            
            if !buffer.isEmpty {
                try fileHandle.write(contentsOf: buffer)
            }
            
            downloadedSize += chunkBytesRead
            try fileHandle.synchronize()
        }
    }
}

/// 从 Content-Disposition 提取文件名的函数
/// - Parameter contentDisposition: 响应头中的 Content-Disposition
/// - Returns: 提取到的文件名
private func extractFileName(from contentDisposition: String) -> String? {
    let components = contentDisposition.components(separatedBy: ";")
    for component in components {
        let trimmed = component.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("filename=") {
            let fileName = trimmed.replacingOccurrences(of: "filename=", with: "")
            return fileName.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        }
    }
    return nil
}

// 扩展 WebDAV 类以实现请求创建
public extension WebDAV {
    /// 创建一个授权的 URL 请求，支持两种认证方式
    /// - Parameters:
    ///   - path: 请求的路径
    ///   - method: HTTP 方法
    /// - Returns: 授权后的 URL 请求
    func authorizedRequest(path: String, method: HTTPMethod) -> URLRequest? {
        // 对路径进行 URL 编码，确保特殊字符不会引发错误
        let shouldEncode = self.shouldEncode(path: path)
        let encodedPath = shouldEncode ? path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? path : path

        // 拼接完整的 URL 字符串
        let baseURLString = self.baseURL.absoluteString
        let fullPath: String

        // 判断 baseURL 是否已经包含 path 部分
        if baseURLString.hasSuffix("/") {
            fullPath = baseURLString + (encodedPath.hasPrefix("/") ? String(encodedPath.dropFirst()) : encodedPath)
        } else {
            fullPath = baseURLString + (encodedPath.hasPrefix("/") ? encodedPath : "/" + encodedPath)
        }

        // 创建 URL 对象
        guard let url = URL(string: fullPath) else {
            print("Error: 无法生成有效的 URL")
            return nil
        }
        print("传入后得到的URL \(url)")

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = self.timeoutInterval

        // 设置认证头部
        if let auth = self.auth {
            request.setValue("Basic \(auth)", forHTTPHeaderField: "Authorization")
        } else if let headerFields = self.headerFields {
            for (key, value) in headerFields {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }

        // 如果是 PROPFIND 请求，设置 Depth 头部
        if method == .propfind {
            request.setValue("1", forHTTPHeaderField: "Depth")
        }

        return request
    }

    /// - Parameters:
    ///   - path: 请求的路径
    ///   - method: HTTP 方法
    /// - Returns: 授权后的 URL 请求
//    func authorizedRequest(path: String, method: HTTPMethod) -> URLRequest? {
//        var url: URL
//        // 如果 path 已包含 baseURL 的路径，则不要再拼接
//                if path.hasPrefix(self.baseURL.path) {
//                    // 直接将 path 转化为完整 URL
//                    url = URL(string: path, relativeTo: self.baseURL)!
//                } else {
//                    // 否则，将 path 作为相对路径拼接
//                    url = self.baseURL.appendingPathComponent(path)
//                }
//
//
//        var request = URLRequest(url: url)
//        // 设置请求方式
//        request.httpMethod = method.rawValue
//        // 设置超时时间
//        request.timeoutInterval = self.timeoutInterval
//        // 设置认证头部
//        if let auth = self.auth {
//            request.setValue("Basic \(auth)", forHTTPHeaderField: "Authorization")
//        } else if let headerFields = self.headerFields {
//            for (key, value) in headerFields {
//                request.setValue(value, forHTTPHeaderField: key)
//            }
//        }
//        if method == .propfind {
//            request.setValue("1", forHTTPHeaderField: "Depth")
//        }
//        return request
//    }

    /// 判断路径是否需要编码
    /// - Parameter path: 需要检查的路径
    /// - Returns: 是否需要编码的布尔值
    func shouldEncode(path: String) -> Bool {
        // 定义需要进行编码的字符范围，除了 ASCII 字母、数字、斜杠、下划线、中文字符和括号外的字符都需要编码
        let allowedCharacterSet = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_.~()")
            .union(.urlPathAllowed)
            .union(CharacterSet(charactersIn: "\u{4E00}" ... "\u{9FFF}")) // 中文字符范围

        // 如果路径中包含不在允许集合中的字符，则需要编码
        return path.rangeOfCharacter(from: allowedCharacterSet.inverted) != nil
    }
}
