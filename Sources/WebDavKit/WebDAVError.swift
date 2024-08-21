//
//  WebDAVError.swift
//  hclient3
//
//  Created by mac on 2024/8/20.
//
import Foundation

public enum WebDAVError: Error {
    /// The credentials or path were unable to be encoded.
    /// No network request was called.
    case invalidCredentials
    /// 凭证不正确。
    case unauthorized
    /// 服务器无法存储所提供的数据。
    case insufficientStorage
    /// The server does not support this feature.
    case unsupported
    /// Another unspecified Error occurred.
    case nsError(Error)
    /// The returned value is simply a placeholder.
    case placeholder

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
