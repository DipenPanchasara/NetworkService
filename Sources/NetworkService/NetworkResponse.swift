//
//  NetworkResponse.swift
//  NetworkService
//
//  Created by Dipen Panchasara on 20/05/2024.
//

import Foundation
import Combine

public struct NetworkResponse: Equatable {
  let data: Data?
  let response: HTTPURLResponse
  
  var urlResponse: URLResponse {
    response as URLResponse
  }
  
  init(data: Data?, response: URLResponse) {
    self.data = data
    guard let response = response as? HTTPURLResponse else {
      self.response = HTTPURLResponse()
      return
    }
    self.response = response
  }
  
  init(data: Data?, response: HTTPURLResponse) {
    self.data = data
    self.response = response
  }
}

public extension NetworkResponse {
  func decode<T: Decodable>(decoder: ResponseDecoder = ResponseDecoder()) throws -> T {
    guard let data = self.data else { throw URLError(.cannotDecodeContentData) }
    return try decoder.decode(T.self, from: data)
  }
}
