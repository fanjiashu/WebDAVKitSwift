//
//  ViewController.swift
//  WebDavForSwiftExample
//
//  Created by mac on 2024/8/21.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .blue
        self.testWebDAVFunctions()
    }
    private func testWebDAVFunctions() {
        // 配置 WebDAV
        let webDAV = WebDAV(baseURL: "http://192.168.100.148:8080/", port: 8080, username: "fjs", password: "123")
        let fileManager = WebDAVFileManager(webDAV: webDAV)

        Task {
            do {
                let webDAVTitle = "测试WebDAV的打印"

                // 检查连接状态
                let isConnected = try await fileManager.checkLinkStatus()
                print("\(webDAVTitle) WebDAV connection status: \(isConnected)")

                // 创建文件夹
                let folderCreated = try await fileManager.createFolder(atPath: "/testFolder")
                print("\(webDAVTitle) Folder creation status: \(folderCreated)")

                // 上传文件
                let sampleData = "Sample file content".data(using: .utf8)!
                let fileUploaded = try await fileManager.uploadFile(atPath: "/testFolder/sample.txt", data: sampleData)
                print("\(webDAVTitle) File upload status: \(fileUploaded)")

                // 列出文件，确认文件存在
                let files = try await fileManager.listFiles(atPath: "/testFolder")
                print("\(webDAVTitle) Files in folder: \(files)")

                // 确认文件存在
                if files.contains(where: { $0.fileName == "sample.txt" }) {
                    // 下载测试并进行分享
                    let downloadTestData = try await fileManager.downloadFile(atPath: "/testFolder/sample.txt")
                    let downloadTestFileName = "sample.txt"

                    // 保存下载文件到临时目录
                    let tempDirectory = FileManager.default.temporaryDirectory
                    let tempFileURL = tempDirectory.appendingPathComponent(downloadTestFileName)
                    try downloadTestData.write(to: tempFileURL)

                    // 系统分享下载的内容
                    let activityViewController = UIActivityViewController(activityItems: [tempFileURL], applicationActivities: nil)
                    self.present(activityViewController, animated: true, completion: nil)
                } else {
                    print("\(webDAVTitle) File does not exist for download.")
                }

                // 复制文件
                let fileCopied = try await fileManager.copyFile(fromPath: "/testFolder/sample.txt", toPath: "/testFolder/sample_copy.txt")
                print("\(webDAVTitle) File copy status: \(fileCopied)")

                // 移动文件
                let fileMoved = try await fileManager.moveFile(fromPath: "/testFolder/sample_copy.txt", toPath: "/testFolder/sample_moved.txt")
                print("\(webDAVTitle) File move status: \(fileMoved)")

                // 删除文件
                let fileDeleted = try await fileManager.deleteFile(atPath: "/testFolder/sample_moved.txt")
                print("\(webDAVTitle) File delete status: \(fileDeleted)")

                // 删除文件夹
                let folderDeleted = try await fileManager.deleteFile(atPath: "/testFolder")
                print("\(webDAVTitle) Folder delete status: \(folderDeleted)")

            } catch {
                let webDAVTitle = "测试WebDAV的打印:函数执行Catch报错"
                print("\(webDAVTitle) Error: \(error)")
            }
        }
    }


}

