# DAVKitSwift

## Overview
This Swift package provides a comprehensive set of functions to interact with WebDAV servers, allowing you to perform various file operations such as creating folders, uploading, listing, downloading, copying, moving, and deleting files and folders within your iOS or macOS applications.

## Features
- Connect to WebDAV servers using basic authentication.
- Create and delete directories on the server.
- Upload and download files with ease.
- List all files within a specified directory.
- Copy and move files to different server locations.
- Check the connection status to the WebDAV server.
- Handle errors and provide feedback for each operation.

## Requirements
- iOS 13.0+ / macOS 10.15+ (Catalyst is not supported)
- Xcode 12.0+
- Swift 5.3+

## Installation
You can install this package using the Swift Package Manager by adding the following repository URL to your Xcode project:
```
https://github.com/yourusername/yourwebdavpackage
```

## Usage
To use the package, first, import it in your Swift file:

```swift
import YourWebDAVPackage
```

Then, initialize the WebDAV instance with the server's base URL, port, username, and password:

```swift
let webDAV = WebDAV(baseURL: "http://192.168.100.148:8080", port: 8080, username: "fjs", password: "123")
```

After that, you can call various functions to perform operations on the WebDAV server.

## Contributing
We welcome contributions! For any issues or suggestions, feel free to open an issue or submit a pull request.

## License
This package is released under the [Apache License 2.0](LICENSE). For details, check the LICENSE file.

---

# 概述
这个 Swift 包提供了与 WebDAV 服务器交互的全面功能集，允许您在 iOS 或 macOS 应用程序中执行创建文件夹、上传、列出、下载、复制、移动和删除文件和文件夹等各种文件操作。

## 特性
- 使用基本认证连接到 WebDAV 服务器。
- 在服务器上创建和删除目录。
- 轻松上传和下载文件。
- 列出指定目录中的所有文件。
- 复制和移动文件到服务器的不同位置。
- 检查与 WebDAV 服务器的连接状态。
- 处理错误并为每个操作提供反馈。

## 要求
- iOS 13.0+ / macOS 10.15+ (不支持 Catalyst)
- Xcode 12.0+
- Swift 5.3+

## 安装
您可以使用 Swift Package Manager 安装此包，将以下仓库 URL 添加到您的 Xcode 项目中：
```
https://github.com/yourusername/yourwebdavpackage
```

## 使用方法
首先，在 Swift 文件中导入此包：

```swift
import YourWebDAVPackage
```

然后，使用服务器的基础 URL、端口、用户名和密码初始化 WebDAV 实例：

```swift
let webDAV = WebDAV(baseURL: "http://192.168.100.148:8080", port: 8080, username: "fjs", password: "123")
```

之后，您可以调用各种函数在 WebDAV 服务器上执行操作。

## 贡献
我们欢迎贡献！对于任何问题或建议，请随时提出问题或提交拉取请求。

## 许可证
此包根据 [Apache License 2.0](LICENSE) 发布。详情请参阅 LICENSE 文件。

---

请确保将 `YourWebDAVPackage` 替换为您的包名称，并使用您自己的 GitHub 仓库 URL。此外，确保您的项目中有一个名为 `LICENSE` 的文件，其中包含 Apache License 2.0 的完整文本。
