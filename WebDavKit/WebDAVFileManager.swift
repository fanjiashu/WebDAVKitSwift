//
//  WebDAVFileManager.swift
//  hclient3
//
//  Created by mac on 2024/8/20.
//

import Foundation

// WebDAV 文件管理器
class WebDAVFileManager {
    private let webDAV: WebDAV
    
    init(webDAV: WebDAV){
        self.webDAV = webDAV
    }
    
    //检查WebDav是否连接成功
    func checkLinkStatus() async throws -> Bool {
           return  await self.webDAV.ping()
       }
    
    // 列出 WebDAV 服务器上的文件
    func listFiles(atPath path: String) async throws -> [WebDAVFile] {
        return try await webDAV.listFiles(atPath: path)
    }
    
    // 下载 WebDAV 上的文件
    func downloadFile(atPath path: String) async throws -> Data {
        return try await webDAV.downloadFile(atPath: path)
    }
    
    // 上传文件到 WebDAV
    func uploadFile(atPath path: String, data: Data) async throws -> Bool {
        return try await webDAV.uploadFile(atPath: path, data: data)
    }
    
    // 删除 WebDAV 上的文件
    func deleteFile(atPath path: String) async throws -> Bool {
        return try await webDAV.deleteFile(atPath: path)
    }

    // 创建WebDAV 上的文件
    func createFolder(atPath path: String) async throws -> Bool {
        return try await webDAV.createFolder(atPath: path)
    }
    
    // 移动文件
    func moveFile(fromPath: String, toPath: String) async throws -> Bool {
        return try await webDAV.moveFile(fromPath: fromPath, toPath: toPath)
    }
       
    // 复制文件
    func copyFile(fromPath: String, toPath: String) async throws -> Bool {
        return try await webDAV.copyFile(fromPath: fromPath, toPath: toPath)
    }
}
