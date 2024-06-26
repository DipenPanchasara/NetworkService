//
//  NetworkService.swift
//  NetworkService
//
//  Created by Dipen Panchasara on 20/05/2024.
//

import Foundation
import Combine

public protocol NetworkServiceProvider {
  func execute<T>(request: NetworkRequest) -> AnyPublisher<T, Error> where T: Decodable
  func execute(request: NetworkRequest) -> AnyPublisher<NetworkResponse, Error>
  func execute(request: NetworkRequest) -> AsyncThrowingStream<NetworkResponse, Error>
}

public final class NetworkService: NetworkServiceProvider {
  private let scheme: String
  private let baseURLString: String
  private let session: NetworkSession
  private let cache: NetworkCacheServiceProvider?
  private let decoder: ResponseDecoderProvider
  private var cancellables = Set<AnyCancellable>()
  private let mapper: MapResponseToNetworkResponseProvider = MapResponseToNetworkResponse()

  public init(
    scheme: String,
    baseURLString: String,
    session: NetworkSession,
    cache: NetworkCacheServiceProvider?,
    decoder: ResponseDecoderProvider?
  ) {
    self.scheme = scheme
    self.baseURLString = baseURLString
    self.session = session
    self.cache = cache
    self.decoder = decoder ?? ResponseDecoder()
  }

  public func execute<T>(request: NetworkRequest) -> AnyPublisher<T, Error> where T: Decodable  {
    var urlRequest: URLRequest
    do {
      urlRequest = try URLRequestBuilder.build(
        scheme: scheme,
        baseURLString: baseURLString,
        networkRequest: request
      )
    } catch {
      return Fail(error: URLError(.badURL))
        .eraseToAnyPublisher()
    }
    
    return session.dataTaskPublisher(for: urlRequest)
      .tryMap {
        try self.mapper.map(result: $0)
      }
      .tryMap { response in
        guard let data = response.data else {
          throw URLError(.zeroByteResource)
        }
        return data
      }
      .decode(type: T.self, decoder: JSONDecoder())
      .eraseToAnyPublisher()
  }
  
  public func execute(request: NetworkRequest) -> AnyPublisher<NetworkResponse, Error> {
    var urlRequest: URLRequest
    do {
      urlRequest = try URLRequestBuilder.build(
        scheme: scheme,
        baseURLString: baseURLString,
        networkRequest: request
      )
    } catch {
      return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
    }
    
    let cachedPublisher = cache?.cached(urlRequest: urlRequest)

    let networkPublisher = session.dataTaskPublisher(for: urlRequest)
      .tryMap {
        try self.mapper.map(result: $0)
      }
    
    if let hasCachedPublisher = cachedPublisher {
      print("executed with cache")
      return Publishers.Merge(hasCachedPublisher, networkPublisher)
        .eraseToAnyPublisher()
    }
    print("executed without cache")
    return networkPublisher
      .eraseToAnyPublisher()
  }
  
  public func execute(request: NetworkRequest) -> AsyncThrowingStream<NetworkResponse, any Error> {
    AsyncThrowingStream { continuation in
      var urlRequest: URLRequest
      do {
        urlRequest = try URLRequestBuilder.build(
          scheme: scheme,
          baseURLString: baseURLString,
          networkRequest: request
        )
        cache?.cached(urlRequest: urlRequest)
          .sink(receiveCompletion: { completion in
            print("executeStream cache completion: \(completion)")
            switch completion {
              case .finished:
                break
              case .failure(let error):
                continuation.finish(throwing: error)
            }
          }, receiveValue: { response in
            print("executeStream cache: \(response)")
            continuation.yield(response)
          })
          .store(in: &cancellables)
        session.dataTaskPublisher(for: urlRequest)
          .tryMap {
            try self.mapper.map(result: $0)
          }
          .sink { completion in
            print("executeStream network completion: \(completion)")
            switch completion {
              case .finished:
                continuation.finish()
              case .failure(let error):
                continuation.finish(throwing: error)
            }
          } receiveValue: { response in
            print("executeStream network: \(response)")
            continuation.yield(response)
          }
          .store(in: &cancellables)
      } catch {
        continuation.finish(throwing: URLError(.badURL))
      }
      
      continuation.onTermination = { @Sendable value in
        print("stream terminated. \(value)")
      }
    }
  }
}
