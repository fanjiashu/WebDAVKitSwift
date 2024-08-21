# README

## Overview
Welcome to **DAVKitSwift**, a lightweight and powerful WebDAV client library for Swift. This package enables you to interact with WebDAV servers seamlessly, providing a suite of functionalities to manage files and directories on the server.

## Features
- Establish connections to WebDAV servers using basic authentication.
- Create, list, and delete directories directly from your Swift applications.
- Upload and download files with support for various content types.
- Copy and move files between different directories on the server.
- Comprehensive error handling to ensure smooth operation.

## Requirements
- iOS 13.0+ / macOS 10.15+ (Catalyst is not supported)
- Xcode 12.0+
- Swift 5.3+

## Installation
You can install **DAVKitSwift** using the Swift Package Manager. Add the following entry to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/fanjiashu/DAVKitSwift.git", from: "1.0.0"),
]
```

Or, you can integrate it directly through Xcode:
1. Click on `File` > `Swift Packages` > `Add Package Dependency...`
2. Enter the URL: `https://github.com/fanjiashu/DAVKitSwift.git`
3. Follow the prompts to complete the installation.

## Usage
After integrating **DAVKitSwift** into your project, you can start using it by importing the package and calling its API:

```swift
import DAVKitSwift

// Example: Initialize WebDAV client and perform operations
let webDAVClient = WebDAVClient(baseURL: "https://your.webdav.server")
// Add your WebDAV operations here
```

### Example Operations
- Creating a directory
- Uploading a file
- Listing directory contents
- Downloading a file
- Deleting a file or directory

## Contributing
We welcome contributions to **DAVKitSwift**. If you have suggestions or find any issues, feel free to create an issue or submit a pull request.

## License
**DAVKitSwift** is released under the [Apache License 2.0](LICENSE). For more information, see the LICENSE file.

---

# 概述
欢迎使用 **DAVKitSwift**，这是一个用于 Swift 的轻量级且功能强大的 WebDAV 客户端库。这个包使您能够无缝地与 WebDAV 服务器交互，提供了一系列功能来管理服务器上的文件和目录。

## 特性
- 使用基本认证建立与 WebDAV 服务器的连接。
- 直接从您的 Swift 应用程序中创建、列出和删除目录。
- 支持多种内容类型上传和下载文件。
- 在服务器上的不同目录之间复制和移动文件。
- 全面的错误处理，确保操作顺畅。

## 要求
- iOS 13.0+ / macOS 10.15+ (不支持 Catalyst)
- Xcode 12.0+
- Swift 5.3+

## 安装
您可以使用 Swift Package Manager 安装 **DAVKitSwift**。向您的 `Package.swift` 文件添加以下条目：

```swift
dependencies: [
    .package(url: "https://github.com/fanjiashu/DAVKitSwift.git", from: "1.0.0"),
]
```

或者，您可以直接通过 Xcode 集成：
1. 点击 `文件` > `Swift 包` > `添加包依赖...`
2. 输入 URL：`https://github.com/fanjiashu/DAVKitSwift.git`
3. 按照提示完成安装。

## 使用方法
将 **DAVKitSwift** 集成到您的项目后，您可以通过导入包并调用其 API 开始使用它：

```swift
import DAVKitSwift

// 示例：初始化 WebDAV 客户端并执行操作
let webDAVClient = WebDAVClient(baseURL: "https://your.webdav.server")
// 在此处添加您的 WebDAV 操作
```

### 示例操作
- 创建目录
- 上传文件
- 列出目录内容
- 下载文件
- 删除文件或目录

## 贡献
我们欢迎对 **DAVKitSwift** 的贡献。如果您有建议或发现任何问题，请随时提出问题或提交拉取请求。

## 许可证
**DAVKitSwift** 根据 [Apache License 2.0](LICENSE) 发布。更多信息请参见 LICENSE 文件。

