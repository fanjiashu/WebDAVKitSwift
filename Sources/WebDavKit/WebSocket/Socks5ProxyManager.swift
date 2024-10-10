//
//  Untitled.swift
//  WebDavForSwiftExample
//
//  Created by mac on 2024/10/10.
//

import Foundation

public class Socks5ProxyManager {
    public static let shared = Socks5ProxyManager()

    private var proxyHost: String?
    private var proxyPort: Int?
    private var isProxyEnabled = false

    private init() {}

    /// 配置 Socks5 代理
    public  func configureProxy(host: String, port: Int) {
        self.proxyHost = host
        self.proxyPort = port
    }

    /// 开启 Socks5 代理
    public func enableProxy() {
        guard proxyHost != nil, proxyPort != nil else {
            print("Socks5 proxy not configured.")
            return
        }
        isProxyEnabled = true
    }

    /// 关闭 Socks5 代理
    public func disableProxy() {
        isProxyEnabled = false
    }

    /// 判断代理是否启用
    public func isProxyActive() -> Bool {
        return isProxyEnabled
    }

    /// 获取代理配置的 URLSession 配置
    public func getProxySessionConfiguration() -> URLSessionConfiguration? {
        guard let proxyHost = proxyHost, let proxyPort = proxyPort else {
            return nil
        }

        // 创建代理配置
        let config = URLSessionConfiguration.default
        config.connectionProxyDictionary = [
            "HTTPEnable": 1,
            "HTTPProxy": proxyHost,
            "HTTPPort": proxyPort,
            "HTTPSEnable": 1,
            "HTTPSProxy": proxyHost,
            "HTTPSPort": proxyPort
        ]
        return config
    }
}
