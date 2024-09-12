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
            if files.first?.path == ""{
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
            let (data, response) = try await URLSession.shared.data(for: request)
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
//            // 使用并发请求来获取每个文件夹的子文件数量
//            let childCounts = try await withThrowingTaskGroup(of: (Int, Int).self) { group in
//                for (index, file) in sortFiles.enumerated() {
//                    if file.isDirectory {
//                        group.addTask {
//                            let count = try await self.fetchChildItemCount(for: file.path)
//                            return (index, count) // 返回文件的索引和子文件数量
//                        }
//                    }
//                }
//
//                var counts = Array(repeating: 0, count: sortFiles.count)
//                for try await (index, count) in group {
//                    counts[index] = count // 根据索引将数量存储到对应位置
//                }
//                return counts
//            }
//
//            let childItemCounts = childCounts
//            // 将子文件数量整合到文件对象中
//            let updatedFiles = sortFiles.enumerated().map { index, file -> WebDAVFile in
//                var mutableFile = file
//                if mutableFile.isDirectory {
//                    mutableFile.childItemCount = childItemCounts[index]
//                }
//                return mutableFile
//            }
//
//            return updatedFiles
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
            let (data, response) = try await URLSession.shared.data(for: request)
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
    
    /// 使用 Head 请求检查远程 WebDAV 服务器上的文件是否存在
    /// - Parameter url: 文件的 URL
    /// - Returns: 文件是否存在
    func fileExists(at path: String) async throws -> Bool {
        let url = self.baseURL.appendingPathComponent(path)
        guard let request = authorizedRequest(path: url.path, method: .head) else {
            throw WebDAVError.invalidCredentials
        }

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
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
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse,
                  200...299 ~= response.statusCode
            else {
                print("报错 \(response)")
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
    func downloadFile(atPath path: String) async throws -> URL {
        // 获取授权请求
           guard let request = authorizedRequest(path: path, method: .get) else {
               throw WebDAVError.invalidCredentials
           }
           
           // 创建 URLSession 配置（可以选择后台任务配置）
           let configuration = URLSessionConfiguration.default
           let session = URLSession(configuration: configuration)
           
           do {
               // 使用 downloadTask 下载文件
               let (tempDownloadURL, response) = try await session.download(for: request)
               
               // 检查 HTTP 响应状态码
               guard let httpResponse = response as? HTTPURLResponse,
                     200...299 ~= httpResponse.statusCode else {
                   throw WebDAVError.getError(response: response, error: nil) ?? WebDAVError.unsupported
               }
               
               // 提取文件扩展名，首先从 path 中提取
               let fileExtension = (path as NSString).pathExtension
               var fileName = (path as NSString).lastPathComponent // 使用传入路径中的文件名
            
               // 尝试从响应头中提取文件名（Content-Disposition）
               if let contentDisposition = httpResponse.value(forHTTPHeaderField: "Content-Disposition"),
                  let extractedFileName = extractFileName(from: contentDisposition) {
                   fileName = extractedFileName
               } else if !fileExtension.isEmpty {
                   // 如果没有 Content-Disposition, 则使用原路径中的扩展名
                   fileName += ".\(fileExtension)"
               }
               
               // 将文件保存到临时目录，带有正确的文件格式
               let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
               
               // 将下载的文件移动到带有正确扩展名的临时文件路径
               try FileManager.default.moveItem(at: tempDownloadURL, to: tempURL)
               
               return tempURL
           } catch {
               throw WebDAVError.nsError(error)
           }
    }
}

func extractFileName(from contentDisposition: String) -> String? {
    let pattern = "filename=\"([^\"]+)\""
    let regex = try? NSRegularExpression(pattern: pattern, options: [])
    let nsString = contentDisposition as NSString
    let results = regex?.firstMatch(in: contentDisposition, options: [], range: NSRange(location: 0, length: nsString.length))
    
    if let range = results?.range(at: 1) {
        return nsString.substring(with: range)
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
        let shouldEncode =  self.shouldEncode(path: path)
        // 如果需要编码则进行编码
        let encodedPath = shouldEncode ? path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? path : path
            
       // let encodedPath = path
        var url: URL
        // 如果 path 已包含 baseURL 的路径，则不要再拼接
        if encodedPath.hasPrefix(self.baseURL.path) {
            // 直接将 path 转化为完整 URL
            url = URL(string: encodedPath, relativeTo: self.baseURL)!
        } else {
            // 否则，将 path 作为相对路径拼接
            url = self.baseURL.appendingPathComponent(encodedPath)
        }

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
    
    
    func shouldEncode(path: String) -> Bool {
        // 仅对非 ASCII 字符且不是中文字符的部分进行编码
        // 中文字符的 Unicode 范围是 \u4E00-\u9FFF
        return path.range(of: "[^a-zA-Z0-9/_\\u4E00-\\u9FFF-]", options: .regularExpression) != nil
    }
}
