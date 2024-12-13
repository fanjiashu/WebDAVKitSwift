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
     // let webDAV = WebDAV(baseURL: "http://192.168.101.209:8080/", port: 8080, username: "fjs", password: "123")
        
       // WAD测试：URL = https://file.jxl888.heiyu.space/_lzc/files/home, toekn = a49b4c55-4f15-415e-8674-c4e6364bb06a
        //WAD测试：URL = https://file.workspace.heiyu.space/_lzc/files/home, toekn = 98a07f2a-01c3-4b21-8f4f-566093e00fa1
         //let webDAV = WebDAV(baseURL: "https://file.workspace.heiyu.space/_lzc/files/home", port: 443, cookie: "HC-Auth-Token=98a07f2a-01c3-4b21-8f4f-566093e00fa1")
        //WADæµè¯ï¼URL = https://file.workspace.heiyu.space/_lzc/files/home, lzc-auth = Lzc-Auth-Token=f3093f1f-1770-43f3-8057-538353777a34
        //Lzc-Auth-Token=a930479e-7681-4573-a8cd-468149425ece
        let webDAV = WebDAV(baseURL: "https://file.workspace.heiyu.space/_lzc/files/home", port: 443, cookie: "Lzc-Auth-Token=61daf3e7-4d8f-433a-93ed-87aa70c8b63f")
        print("Base URL: \(webDAV.baseURL)")

        let fileManager = WebDAVFileManager(webDAV: webDAV)
        Task {
            do {
                let webDAVTitle = "测试WebDAV的打印"
                
                /*
                 {"level":"info","ts":"2024-11-21T17:35:57.415+0800","logger":"platform","caller":"pc/entry_pc.go:104","msg":"start socks proxy success: 127.0.0.1:56528"}
                 {"level":"info","ts":"2024-11-21T17:35:57.415+0800","logger":"platform","caller":"pc/entry_pc.go:110","msg":"start http proxy success: 127.0.0.1:56529"}
                 */
               // 开启scocks5 代理加速
                // 配置 SOCKS5 代理
                Socks5ProxyManager.shared.configureProxy(host: "127.0.0.1", port:64435)
                // 开启 SOCKS5 代理
                Socks5ProxyManager.shared.enableProxy()
               
                


                // 检查连接状态
                let isConnected = try await fileManager.checkLinkStatus()
                print("\(webDAVTitle) WebDAV connection status: \(isConnected)")
                
                
                let filePaths = [
                    "/2.mkv",
                ]
                await downloadMultipleFiles(filePaths: filePaths,fileManager: fileManager)
                
                            
             //  let test_path = "/模仿游戏.The.Imitation.Game.2014.1080p.BluRay.x264-.国英双语中字.mkv"
            //    do {
//                    // 记录开始时间
//                    let startTime = Date()
//                    
//                    // 下载文件
//                    _ = try await fileManager.downloadFile(atPath: test_path)
//                    
//                    // 记录结束时间
//                    let endTime = Date()
//                    
//                    // 计算下载耗时
//                    let downloadDuration = endTime.timeIntervalSince(startTime)
//                    
//                    // 打印耗时
//                    print("开启Socks5代理：Download completed in \(downloadDuration) seconds.")
//                } catch {
//                    // 处理下载失败的情况
//                    //print("Failed to download file: \(error.localizedDescription)")
//                }
                
                
                
                
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
                
                
                //  let result =  await self.detectFileExtension(for: "/" , webDav: webDAV)
                   
                   
   //               let files = try await fileManager.listFiles(atPath: "/下载")
   //                for (index, file) in files.enumerated() {
   //                    print("/：文件\(file.path)有\(String(describing: file.childItemCount)) 个文件")
   //                }
   ////                files = try await fileManager.listFiles(atPath: "/Test/Text")
   //                for (index, file) in files.enumerated() {
   //                    print("/Test/Text路径下：第\(index)文件是：\(file)")
   //                }
   //
   //                let status = try await webDAV.fileExists(at: "/testFolder/sample.txt")
   //                print("文件存在 \(status)")

            } catch {
                let webDAVTitle = "测试WebDAV的打印:函数执行Catch报错"
                print("\(webDAVTitle) Error: \(error)")
            }
        }
    }
    
    // 多文件下载
    func downloadMultipleFiles(filePaths: [String], fileManager: WebDAVFileManager) async {
        do {
            let startTime = Date()  // 开始计时，记录下载时间

            // 并行下载文件
            try await withThrowingTaskGroup(of: Void.self) { group in
                for path in filePaths {
                    group.addTask {
                        do {
                            let url = try await fileManager.downloadFile(atPath: path)
                            print("下载成功 file at path: \(url)")
                            
                            // 缓存清理不算入时间统计中
                            // 在这里异步清理缓存，但不影响下载时间统计
                            Task {
                                await self.clearCache(for: url)
                            }
                        } catch {
                            print("Failed to download file at path: \(path). Error: \(error.localizedDescription)")
                        }
                    }
                }
                try await group.waitForAll()  // 等待所有任务完成
            }

            let endTime = Date()  // 记录下载完成时间
            let totalDuration = endTime.timeIntervalSince(startTime)  // 计算总时间（仅包含下载时间）

            print("不开启Socks5代理：All files downloaded in \(totalDuration) seconds.")
        } catch {
            print("Failed to download files: \(error.localizedDescription)")
        }
    }

    // 清理下载文件的缓存
    func clearCache(for downloadedFileURL: URL) async {
           let fileManager = FileManager.default
           do {
               // 假设你想删除临时下载的文件
               if fileManager.fileExists(atPath: downloadedFileURL.path) {
                   try fileManager.removeItem(at: downloadedFileURL)
                   print("Cache cleared at URL: \(downloadedFileURL)")
               } else {
                   print("File does not exist at URL: \(downloadedFileURL)")
               }
           } catch {
               print("Failed to clear cache for \(downloadedFileURL): \(error.localizedDescription)")
           }
       }
    
    
    
    // 动态检测并返回文件的扩展名（如果有）
    func detectFileExtension(for path: String, webDav: WebDAV) async -> String? {
        // 获取父目录路径和文件名
        let directoryPath = (path as NSString).deletingLastPathComponent
        let fileNameWithoutExtension = (path as NSString).lastPathComponent
        
        print("WAD文件名称匹配：目标路径: \(path), 父目录路径: \(directoryPath), 无扩展名文件名: \(fileNameWithoutExtension)")
        
        do {
            // 异步获取当前目录中的所有文件
            let files = try await webDav.listFiles(atPath: directoryPath)
            
            // 遍历文件，寻找匹配的文件名
            for file in files {
                let nsFilePath = file.path as NSString
                let fileName = nsFilePath.deletingPathExtension
                
                // 匹配文件名
                if fileName == fileNameWithoutExtension {
                    let fileExtension = nsFilePath.pathExtension
                    if fileExtension.isEmpty {
                        print("WAD文件名称匹配：匹配成功-文件夹！文件路径: \(file.path), 扩展名: \(fileExtension)")
                    } else {
                        print("WAD文件名称匹配：匹配成功-文件！文件路径: \(file.path), 扩展名: \(fileExtension)")
                    }
                    // 提前返回，避免继续无意义的遍历
                    return fileExtension.isEmpty ? nil : "." + fileExtension
                }
            }
            
            print("WAD文件名称匹配：无匹配结果")
        } catch {
            print("WAD检测文件扩展名时出错: \(error)，路径 = \(path)")
        }
        
        return nil // 如果未找到匹配文件，返回 nil
    }


}

