//
//  NetworkRequest.swift
//  NetworkService
//
//  Created by Dipen Panchasara on 20/05/2024.
//

import Foundation

public struct NetworkRequest: Equatable {
  enum HTTPType: String {
    case get
    case post
    case put
    case delete

    var value: String {
      self.rawValue.capitalized
    }
  }

  let httpMethod: HTTPType
  let endpoint: Endpoint
  let headers: [String: String]?
  let data: Data?

  init(
    httpMethod: HTTPType,
    endpoint: Endpoint,
    headers: [String: String]? = nil,
    data: Data? = nil
  ) {
    self.httpMethod = httpMethod
    self.endpoint = endpoint
    self.headers = headers
    self.data = data
  }
}
