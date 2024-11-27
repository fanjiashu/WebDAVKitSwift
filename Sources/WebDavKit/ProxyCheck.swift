import Foundation

//class ProxyChecker {
//
//    // 通过请求外部服务来判断代理是否生效
//    static func checkProxyStatus(completion: @escaping (Bool) -> Void) {
//        // 创建请求
//        let url = URL(string: "https://httpbin.org/ip")!
//        let request = URLRequest(url: url)
//        
//        // 配置代理
//        let proxyHost = "56528"  // 代理服务器地址
//        let proxyPort = "127.0.0.1"  // 代理服务器端口
//        
//        let config = URLSessionConfiguration.default
//        config.connectionProxyDictionary = [
//            kCFNetworkProxiesHTTPEnable: true,
//            kCFNetworkProxiesHTTPProxy: proxyHost,
//            kCFNetworkProxiesHTTPPort: proxyPort
//        ]
//        
//        let session = URLSession(configuration: config)
//        
//        // 发起请求
//        let task = session.dataTask(with: request) { data, response, error in
//            if let error = error {
//                print("请求失败: \(error.localizedDescription)")
//                completion(false)
//                return
//            }
//            
//            guard let data = data else {
//                print("没有返回数据")
//                completion(false)
//                return
//            }
//            
//            do {
//                // 解析响应中的 IP 地址
//                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
//                   let ip = json["origin"] as? String {
//                    print("返回的 IP 地址: \(ip)")
//                    // 根据返回的 IP 地址判断是否通过代理访问
//                    if ip == "172.29.157.30" { // 将这里替换为期望的代理 IP 地址
//                        print("代理生效")
//                        completion(true) // 代理生效
//                    } else {
//                        print("代理未生效")
//                        completion(false) // 代理未生效
//                    }
//                }
//            } catch {
//                print("解析响应数据失败: \(error.localizedDescription)")
//                completion(false)
//            }
//        }
//        
//        task.resume()
//    }
//}


import Foundation

class ProxyChecker {
    
    // 获取当前系统的代理设置
    static func getSystemProxySettings() -> [String: Any]? {
        let proxySettings = CFNetworkCopySystemProxySettings()?.takeRetainedValue() as? [String: Any]
        return proxySettings
    }

    // 检查系统代理是否生效
    static func checkIfProxyIsActive() -> Bool {
        guard let proxySettings = getSystemProxySettings() else {
            return false
        }
        
        // 检查是否设置了 HTTP 代理
        if let proxies = proxySettings["HTTPEnable"] as? Bool, proxies {
            print("HTTP代理已启用")
            return true
        }
        
        // 检查是否设置了 HTTPS 代理
        if let proxies = proxySettings["HTTPSEnable"] as? Bool, proxies {
            print("HTTPS代理已启用")
            return true
        }

        // 如果没有启用代理，则返回 false
        return false
    }
}
