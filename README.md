
# README

## Overview
Welcome to **WebDAVKitSwift**, a Swift package that provides a lightweight and easy-to-use WebDAV client for iOS and macOS applications. With this library, you can perform a variety of file operations on WebDAV servers, including creating, uploading, listing, downloading, copying, moving, and deleting files and folders.

## Features
- Connect to WebDAV servers with basic authentication.
- Create, list, and delete directories on the server.
- Upload and download files with ease.
- Copy and move files to different locations on the server.
- Comprehensive error handling and status reporting.
- Designed for both iOS and macOS platforms.

## Requirements
- iOS 13.0+ / macOS 10.15+ (Catalyst is not supported)
- Xcode 12.0+
- Swift 5.3+

## Installation
You can install **WebDAVKitSwift** using the Swift Package Manager. Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/fanjiashu/WebDAVKitSwift.git", from: "1.0.0"),
]
```

Or, integrate it directly through Xcode:
1. Click on `File` > `Swift Packages` > `Add Package Dependency...`
2. Enter the repository URL: `https://github.com/fanjiashu/WebDAVKitSwift.git`
3. Complete the installation by following the prompts.

## Usage
After integrating **WebDAVKitSwift** into your project, you can start using it by importing the package and performing WebDAV operations:

```swift
import WebDAVKitSwift

// Example: Initialize WebDAV client and perform operations
let webDAVClient = WebDAVClient(baseURL: "https://your.webdav.server.com")
// Add your WebDAV operations here
```

### Example Operations
- Creating directories
- Uploading files with progress tracking
- Listing contents of a directory
- Downloading files with support for resuming
- Copying and moving files
- Deleting files and directories

## Contributing
We welcome contributions to **WebDAVKitSwift**. If you have suggestions or find any issues, feel free to create an issue or submit a pull request.

## License
**WebDAVKitSwift** is released under the [Apache License 2.0](LICENSE). For more details, refer to the LICENSE file.

---

# 概述
欢迎使用 **WebDAVKitSwift**，这是一个为 iOS 和 macOS 应用提供的 Swift 包，它包含一个轻量级且易于使用的 WebDAV 客户端。利用这个库，您可以在 WebDAV 服务器上执行各种文件操作，包括创建、上传、列出、下载、复制、移动和删除文件和文件夹。

## 特性
- 使用基本认证连接到 WebDAV 服务器。
- 在服务器上创建、列出和删除目录。
- 轻松上传和下载文件。
- 复制和移动服务器上的文件到不同位置。
- 全面的错误处理和状态报告。
- 为 iOS 和 macOS 平台设计。

## 要求
- iOS 13.0+ / macOS 10.15+ (不支持 Catalyst)
- Xcode 12.0+
- Swift 5.3+

## 安装
您可以使用 Swift Package Manager 安装 **WebDAVKitSwift**。在您的 `Package.swift` 文件中添加以下内容：

```swift
dependencies: [
    .package(url: "https://github.com/fanjiashu/WebDAVKitSwift.git", from: "1.0.0"),
]
```

或者，您可以直接通过 Xcode 集成：
1. 点击 `文件` > `Swift 包` > `添加包依赖...`
2. 输入仓库 URL：`https://github.com/fanjiashu/WebDAVKitSwift.git`
3. 按照提示完成安装。

## 使用方法
将 **WebDAVKitSwift** 集成到您的项目后，您可以通过导入包并执行 WebDAV 操作开始使用它：

```swift
import WebDAVKitSwift

// 示例：初始化 WebDAV 客户端并执行操作
let webDAVClient = WebDAVClient(baseURL: "https://你的.webdav.server.com")
// 在此处添加您的 WebDAV 操作

1.4.0 增加socks5加速
// 配置 Socks5 代理
Socks5ProxyManager.shared.configureProxy(host: "127.0.0.1", port: 1080)

// 开启代理
Socks5ProxyManager.shared.enableProxy()

// 执行 WebDAV 操作，例如创建文件夹
let webDAV = WebDAV()
do {
    let success = try await webDAV.createFolder(atPath: "/path/to/folder")
    print("Folder created: \(success)")
} catch {
    print("Error creating folder: \(error)")
}

// 关闭代理
Socks5ProxyManager.shared.disableProxy()

```

### 示例操作
- 创建目录
- 上传文件并跟踪进度
- 列出目录的内容
- 支持断点续传的下载文件
- 复制和移动文件
- 删除文件和目录

## 贡献
我们欢迎对 **WebDAVKitSwift** 的贡献。如果您有建议或发现任何问题，请随时提出问题或提交拉取请求。

## 许可证
**WebDAVKitSwift** 根据 [Apache License 2.0](LICENSE) 发布。有关更多详情，请参阅 LICENSE 文件。

