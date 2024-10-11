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
    func getProxySessionConfiguration() -> URLSessionConfiguration? {
        let configuration = URLSessionConfiguration.default
        // 代理设置
        let proxyDict: [String: Any] = [
            "SOCKSEnable": 1,
            "SOCKSProxy": self.proxyHost ?? "代理地址", // SOCKS5代理地址
            "SOCKSPort": self.proxyPort ?? 1080 // SOCKS5端口
        ]
        // 这里配置 SOCKS 代理
        configuration.connectionProxyDictionary = proxyDict
        return configuration
    }
}
