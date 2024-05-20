//
//  NetworkService.swift
//  NetworkService
//
//  Created by Dipen Panchasara on 20/05/2024.
//

import Foundation
import Combine

protocol NetworkServiceProvider {
  func execute<T>(networkRequest: NetworkRequest) -> AnyPublisher<T, Error> where T: Decodable
  func execute(networkRequest: NetworkRequest) -> AnyPublisher<NetworkResponse, Error>
  func execute(networkRequest: NetworkRequest) -> AsyncThrowingStream<NetworkResponse, Error>
}

final class NetworkService: NetworkServiceProvider {
  private let scheme: String
  private let baseURLString: String
  private let session: NetworkSessionProvider
  private let cache: NetworkCacheProvider?
  private let decoder: ResponseDecoderProvider
  private var cancellables = Set<AnyCancellable>()
  private let mapper: MapResponseToNetworkResponseProvider = MapResponseToNetworkResponse()

  init(
    scheme: String,
    baseURLString: String,
    session: NetworkSessionProvider = NetworkSession.shared,
    cache: NetworkCacheProvider?,
    decoder: ResponseDecoderProvider = ResponseDecoder()
  ) {
    self.scheme = scheme
    self.baseURLString = baseURLString
    self.session = session
    self.cache = cache
    self.decoder = decoder
  }

  func execute<T>(networkRequest: NetworkRequest) -> AnyPublisher<T, Error> where T: Decodable  {
    var urlRequest: URLRequest
    do {
      urlRequest = try URLRequestBuilder.build(
        scheme: scheme,
        baseURLString: baseURLString,
        networkRequest: networkRequest
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
  
  func execute(networkRequest: NetworkRequest) -> AnyPublisher<NetworkResponse, Error> {
    var urlRequest: URLRequest
    do {
      urlRequest = try URLRequestBuilder.build(
        scheme: scheme,
        baseURLString: baseURLString,
        networkRequest: networkRequest
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
      return Publishers.Merge(hasCachedPublisher, networkPublisher)
        .eraseToAnyPublisher()
    }
    return networkPublisher
      .eraseToAnyPublisher()
  }
  
  func execute(networkRequest: NetworkRequest) -> AsyncThrowingStream<NetworkResponse, any Error> {
    AsyncThrowingStream { continuation in
      var urlRequest: URLRequest
      do {
        urlRequest = try URLRequestBuilder.build(
          scheme: scheme,
          baseURLString: baseURLString,
          networkRequest: networkRequest
        )
        cache?.cached(urlRequest: urlRequest)
          .sink(receiveCompletion: { completion in
            switch completion {
              case .finished:
                continuation.finish()
              case .failure(let error):
                continuation.finish(throwing: error)
            }
          }, receiveValue: { response in
            continuation.yield(response)
          })
          .store(in: &cancellables)
        session.dataTaskPublisher(for: urlRequest)
          .tryMap {
            try self.mapper.map(result: $0)
          }
          .sink { completion in
            switch completion {
              case .finished:
                continuation.finish()
              case .failure(let error):
                continuation.finish(throwing: error)
            }
          } receiveValue: { response in
            continuation.yield(response)
          }
          .store(in: &cancellables)
      } catch {
        continuation.finish(throwing: URLError(.badURL))
      }
    }
  }
}
