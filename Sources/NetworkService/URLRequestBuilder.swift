//
//  URLRequestBuilder.swift
//  
//
//  Created by Dipen Panchasara on 20/05/2024.
//

import Foundation

protocol URLRequestBuilding {
  static func build(
    scheme: String,
    baseURLString: String,
    networkRequest: NetworkRequest
  ) throws -> URLRequest
}

struct URLRequestBuilder: URLRequestBuilding {
  static func build(
    scheme: String,
    baseURLString: String,
    networkRequest: NetworkRequest
  ) throws -> URLRequest {
    let endpoint = networkRequest.endpoint
    var components = URLComponents()
    components.scheme = scheme
    components.host = baseURLString
    components.path = "/api/json/v1/1/\(endpoint.path)"
    if let queryItems = endpoint.queryItems {
      components.queryItems = queryItems.map { queryItem in
        URLQueryItem(name: queryItem.key, value: queryItem.value)
      }
    }
    guard
      let url = components.url
    else {
      throw NetworkError.badURL(request: networkRequest)
    }
    var request = URLRequest(url: url)
    request.httpMethod = networkRequest.httpMethod.value
    request.httpBody = networkRequest.data
    if let headers = networkRequest.headers {
      request.allHTTPHeaderFields = headers
    }
    return request
  }
}
