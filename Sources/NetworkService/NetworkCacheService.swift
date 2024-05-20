//
//  NetworkCacheService.swift
//  
//
//  Created by Dipen Panchasara on 20/05/2024.
//

import Combine
import Foundation

public protocol NetworkCacheServiceProvider {
  func cached(urlRequest: URLRequest) -> AnyPublisher<NetworkResponse, any Error>

  func cache(for request: NetworkRequest) -> NetworkResponse?
  func clearCache()
  func clearCache(for request: NetworkRequest) -> Bool
}

public struct NetworkCacheService: NetworkCacheServiceProvider {
  public enum CacheError: Error, Equatable {
    case noCache
  }

  private let networkSession: NetworkSession
  private var session: URLSession {
    networkSession.session
  }
  private let mapper: MapResponseToNetworkResponseProvider = MapResponseToNetworkResponse()

  public init(networkSession: NetworkSession) {
    self.networkSession = networkSession
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
  
  public func cache(for request: NetworkRequest) -> NetworkResponse? {
    var urlRequest: URLRequest
    do {
      urlRequest = try URLRequestBuilder.build(
        scheme: "networkSession.",
        baseURLString: "baseURLString",
        networkRequest: request
      )
      if
        let cache = session.configuration.urlCache,
        let response = cache.cachedResponse(for: urlRequest) {
        return try mapper.map(result: (data: response.data, response: response.response))
      }
    } catch {
      return nil
    }

    return nil
  }
  
  public func clearCache() {
    session.configuration.urlCache?.removeAllCachedResponses()
  }
  
  public func clearCache(for request: NetworkRequest) -> Bool {
    var urlRequest: URLRequest
    do {
      urlRequest = try URLRequestBuilder.build(
        scheme: "networkSession.",
        baseURLString: "baseURLString",
        networkRequest: request
      )
    } catch {
      return false
    }
    if
      let cache = session.configuration.urlCache,
      let response = cache.cachedResponse(for: urlRequest) {
      cache.removeCachedResponse(for: urlRequest)
      return true
    }
    return false
  }
}
