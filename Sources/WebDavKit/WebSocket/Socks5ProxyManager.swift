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
    
    /// 开启 Socks5 代理 ---当前这个仅支持mac
    public func enableProxy() {
#if os(macOS)
        guard proxyHost != nil, proxyPort != nil else {
            print("Socks5 proxy not configured.")
            return
        }
        isProxyEnabled = true
#else
        isProxyEnabled = false
#endif
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
#if os(macOS)
        let configuration = URLSessionConfiguration.default
        print("代理地址: \(self.proxyHost ?? "未设置")")
        print("代理端口: \(self.proxyPort ?? 0)")
        
        // 代理设置
        let proxyDict: [String: Any] = [
            kCFNetworkProxiesSOCKSEnable as String: 1,
            kCFNetworkProxiesSOCKSProxy as String: self.proxyHost ?? "代理地址",
            kCFNetworkProxiesSOCKSPort as String: self.proxyPort ?? 1080
        ]
        configuration.connectionProxyDictionary = proxyDict
        return configuration
#else
        // 其他平台如 iOS 不使用代理
        return nil
#endif
    }
}
