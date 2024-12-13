//
//  WebDAVError.swift
//  hclient3
//
//  Created by mac on 2024/8/20.
//
import Foundation

public enum WebDAVError: Error {
    ///无法对凭证或路径进行编码。
    ///没有网络请求被调用
    case invalidCredentials
    /// 凭证不正确。
    case unauthorized
    /// 服务器无法存储所提供的数据。
    case insufficientStorage
    /// 服务器不支持此特性。
    case unsupported
    /// 发生另一个未指定的错误。
    case nsError(Error)
    /// 返回值只是一个占位符。
    case placeholder
    /// 断开与服务器的链接 Webscoket专用
    case connectionLost
    /// 无效的响应 Webscoket专用
    case invalidResponse
    /// 代理配置错误
    case proxyConfigurationError(String)
    /// 下载失败错误
    case downloadUnsupported(String)
    
    static func getError(statusCode: Int?, error: Error?) -> WebDAVError? {
        if let statusCode = statusCode {
            switch statusCode {
            case 200...299: // Success
                return nil
            case 401...403:
                return .unauthorized
            case 507:
                return .insufficientStorage
            default:
                break
            }
        }
    
        if let error = error {
            return .nsError(error)
        }
        return nil
    }

    static func getError(response: URLResponse?, error: Error?) -> WebDAVError? {
        getError(statusCode: (response as? HTTPURLResponse)?.statusCode, error: error)
    }
}
