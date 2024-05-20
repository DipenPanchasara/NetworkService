//
//  NetworkCacheService.swift
//  
//
//  Created by Dipen Panchasara on 20/05/2024.
//

import Combine
import Foundation

public protocol NetworkCacheProvider {
  func cached(urlRequest: URLRequest) -> AnyPublisher<NetworkResponse, any Error>
}

public struct NetworkCacheManager: NetworkCacheProvider {
  private let session: URLSession
  
  init(session: URLSession) {
    self.session = session
  }
  
  public func cached(urlRequest: URLRequest) -> AnyPublisher<NetworkResponse, any Error> {
    if let cachedResponse = session.configuration.urlCache?.cachedResponse(for: urlRequest) {
      return Just(NetworkResponse(data: cachedResponse.data, response: cachedResponse.response as! HTTPURLResponse))
        .setFailureType(to: Error.self)
        .eraseToAnyPublisher()
    }
    return Fail(error: CacheError.noCache)
      .eraseToAnyPublisher()
  }
  
  enum CacheError: Error, Equatable {
    case noCache
  }
}
