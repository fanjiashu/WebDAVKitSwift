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
      //let webDAV = WebDAV(baseURL: "http://192.168.100.149:8080/", port: 8080, username: "fjs", password: "123")
        
       // WAD测试：URL = https://file.jxl888.heiyu.space/_lzc/files/home, toekn = a49b4c55-4f15-415e-8674-c4e6364bb06a
        //WAD测试：URL = https://file.workspace.heiyu.space/_lzc/files/home, toekn = 98a07f2a-01c3-4b21-8f4f-566093e00fa1
         //let webDAV = WebDAV(baseURL: "https://file.workspace.heiyu.space/_lzc/files/home", port: 443, cookie: "HC-Auth-Token=98a07f2a-01c3-4b21-8f4f-566093e00fa1")
        let webDAV = WebDAV(baseURL: "https://file.workspace.heiyu.space/_lzc/files/home", port: 443, cookie: "Lzc-Auth-Token=62ac4237-5341-45c0-9cfd-c47a574de1f0")
        print("Base URL: \(webDAV.baseURL)")

        let fileManager = WebDAVFileManager(webDAV: webDAV)

        Task {
            do {
                let webDAVTitle = "测试WebDAV的打印"

//                // 检查连接状态
                let isConnected = try await fileManager.checkLinkStatus()
                print("\(webDAVTitle) WebDAV connection status: \(isConnected)")
               let files = try await fileManager.listFiles(atPath: "/下载")
                for (index, file) in files.enumerated() {
                    print("/：文件\(file.path)有\(String(describing: file.childItemCount)) 个文件")
                }
////                files = try await fileManager.listFiles(atPath: "/Test/Text")
//                for (index, file) in files.enumerated() {
//                    print("/Test/Text路径下：第\(index)文件是：\(file)")
//                }
//                
//                let status = try await webDAV.fileExists(at: "/testFolder/sample.txt")
//                print("文件存在 \(status)")
//                
               // let test_path = "/#@$%.txt"
               // let test_path = "/财会讲义(1).docx"
               // let test_path = "#济高等数学第六版下册习题全解指南-25.pdf"
               // let test_path = "/通讯录.xls"
               // let test_path = "/所有“iCloud”.vcf"
//                let test_path = "/RPReplay_Final1723533092 (1).MP4"
//               // let test_path = "/下载"
//                
//                let fileStatus = try await webDAV.isDirectory(atPath: test_path)
//                print("是否文件夹 \(fileStatus)")
//                
//                let isExti = try await webDAV.fileExists(at: test_path)
//                print("是否存在 \(isExti)")
//                    // 下载测试并进行分享
 //               let url = try await fileManager.downloadFile(atPath: test_path)
//               let downloadTestData = try Data(contentsOf: url)
//                let downloadTestFileName = "#@$%.txt"
//                    print("下载到的资源：\(downloadTestData.count)")
//                    print("接收到的文件路径： \(url)")
                
                    // 保存下载文件到临时目录
//                    let tempDirectory = FileManager.default.temporaryDirectory
//                    let tempFileURL = tempDirectory.appendingPathComponent(downloadTestFileName)
//                    try downloadTestData.write(to: tempFileURL)
//
//                    // 系统分享下载的内容
//                    let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
//                    self.present(activityViewController, animated: true, completion: nil)
                

//                // 创建文件夹
//                let folderCreated = try await fileManager.createFolder(atPath: "/testFolder")
//                print("\(webDAVTitle) Folder creation status: \(folderCreated)")
//
//                // 上传文件
//                let sampleData = "Sample file content".data(using: .utf8)!
//                let fileUploaded = try await fileManager.uploadFile(atPath: "/testFolder/sample.txt", data: sampleData)
//                print("\(webDAVTitle) File upload status: \(fileUploaded)")

//                // 列出文件，确认文件存在
//                let files = try await fileManager.listFiles(atPath: "/testFolder")
//                print("\(webDAVTitle) Files in folder: \(files)")

//                // 确认文件存在
//                if files.contains(where: { $0.fileName == "sample.txt" }) {
//                    // 下载测试并进行分享
//                    let downloadTestData = try await fileManager.downloadFile(atPath: "/testFolder/sample.txt")
//                    let downloadTestFileName = "sample.txt"
//
//                    // 保存下载文件到临时目录
//                    let tempDirectory = FileManager.default.temporaryDirectory
//                    let tempFileURL = tempDirectory.appendingPathComponent(downloadTestFileName)
//                    try downloadTestData.write(to: tempFileURL)
//
//                    // 系统分享下载的内容
//                    let activityViewController = UIActivityViewController(activityItems: [tempFileURL], applicationActivities: nil)
//                    self.present(activityViewController, animated: true, completion: nil)
//                } else {
//                    print("\(webDAVTitle) File does not exist for download.")
//                }
//
//                // 复制文件
//                let fileCopied = try await fileManager.copyFile(fromPath: "/testFolder/sample.txt", toPath: "/testFolder/sample_copy.txt")
//                print("\(webDAVTitle) File copy status: \(fileCopied)")
//
//                // 移动文件
//                let fileMoved = try await fileManager.moveFile(fromPath: "/testFolder/sample_copy.txt", toPath: "/testFolder/sample_moved2.txt")
//                print("\(webDAVTitle) File move status: \(fileMoved)")

//                // 删除文件
//                let fileDeleted = try await fileManager.deleteFile(atPath: "/testFolder/sample_moved.txt")
//                print("\(webDAVTitle) File delete status: \(fileDeleted)")
//
//                // 删除文件夹
//                let folderDeleted = try await fileManager.deleteFile(atPath: "/testFolder")
//                print("\(webDAVTitle) Folder delete status: \(folderDeleted)")

            } catch {
                let webDAVTitle = "测试WebDAV的打印:函数执行Catch报错"
                print("\(webDAVTitle) Error: \(error)")
            }
        }
    }


}

