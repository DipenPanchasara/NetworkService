//
//  NetworkSession.swift
//  NetworkService
//
//  Created by Dipen Panchasara on 20/05/2024.
//

import Foundation
import Combine

protocol NetworkSessionProvider: Sendable {
  func dataTaskPublisher(for urlRequest: URLRequest) -> AnyPublisher<(data: Data, response: URLResponse), Error>
  func dataTaskPublisher(for urlRequest: URLRequest) -> AnyPublisher<NetworkResponse, Error>
}

public struct NetworkSession {
  private let configuration: URLSessionConfiguration
  private let session: URLSession

  public init(configuration: URLSessionConfiguration) {
    self.configuration = configuration
    self.session = URLSession(configuration: configuration)
  }
}

extension NetworkSession: NetworkSessionProvider {
  func dataTaskPublisher(for urlRequest: URLRequest) -> AnyPublisher<(data: Data, response: URLResponse), Error> {
    URLSession.DataTaskPublisher(request: urlRequest, session: session)
      .tryMap {
        ($0.data, $0.response)
      }
      .eraseToAnyPublisher()
  }
  
  func dataTaskPublisher(for urlRequest: URLRequest) -> AnyPublisher<NetworkResponse, Error> {
    URLSession.DataTaskPublisher(request: urlRequest, session: session)
      .tryMap {
        return NetworkResponse(data: $0.data, response: $0.response)
      }
      .eraseToAnyPublisher()
  }
}

public extension NetworkSession {
  private static var sessionConfiguration: URLSessionConfiguration {
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 30
    return config
  }

  static let shared: NetworkSession = NetworkSession(configuration: sessionConfiguration)
}
