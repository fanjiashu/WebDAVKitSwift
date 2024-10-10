//
//  Untitled.swift
//  WebDavForSwiftExample
//
//  Created by mac on 2024/10/10.
//

import Foundation

class WebSocketProxyManager {
    private var webSocketTask: URLSessionWebSocketTask?
    private var proxyURL: URL?

    // 设置 WebSocket 代理服务器的 URL
    func configureProxy(with url: URL) {
        self.proxyURL = url
    }

    // 启动 WebSocket 代理
    func startProxy() {
        guard let proxyURL = proxyURL else {
            print("WebSocket proxy URL is not configured")
            return
        }
        let urlSession = URLSession(configuration: .default)
        webSocketTask = urlSession.webSocketTask(with: proxyURL)
        webSocketTask?.resume()
        receiveMessage()
    }

    // 停止 WebSocket 代理
    func stopProxy() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
    }

    // 通过 WebSocket 发送请求
    func sendRequestOverWebSocket(_ requestData: Data, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let webSocketTask = webSocketTask else {
            print("WebSocket is not connected")
            return
        }
        
        // 发送数据
        webSocketTask.send(.data(requestData)) { error in
            if let error = error {
                completion(.failure(error))
                return
            }

            // 等待接收响应
            self.receiveResponse(completion: completion)
        }
    }

    // 接收 WebSocket 响应
    private func receiveResponse(completion: @escaping (Result<Data, Error>) -> Void) {
        webSocketTask?.receive { result in
            switch result {
            case .success(.data(let data)):
                completion(.success(data))
            case .success(.string(let message)):
                if let data = message.data(using: .utf8) {
                    completion(.success(data))
                } else {
                    completion(.failure(WebSocketProxyError.invalidResponse))
                }
            case .failure(let error):
                completion(.failure(error))
            default:
                completion(.failure(WebSocketProxyError.unknownError))
            }
        }
    }

    // 处理接收消息
    private func receiveMessage() {
        webSocketTask?.receive { result in
            switch result {
            case .success(.string(let message)):
                print("Received message: \(message)")
            case .success(.data(let data)):
                print("Received data: \(data)")
            case .failure(let error):
                print("Error receiving message: \(error)")
            @unknown default:
                break
            }
        }
    }

    // 自定义错误
    enum WebSocketProxyError: Error {
        case invalidResponse
        case unknownError
    }
}
