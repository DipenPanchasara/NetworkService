//
//  MapResponseToNetworkResponse.swift
//  
//
//  Created by Dipen Panchasara on 20/05/2024.
//

import Foundation

protocol MapResponseToNetworkResponseProvider {
  func map(result: (data: Data, response: URLResponse)) throws -> NetworkResponse
}

struct MapResponseToNetworkResponse: MapResponseToNetworkResponseProvider {
  func map(result: (data: Data, response: URLResponse)) throws -> NetworkResponse {
    guard let httpURLResponse = result.response as? HTTPURLResponse else { throw NetworkError.invalidResponse }
    switch httpURLResponse.statusCode {
      case 200...299:
        return NetworkResponse(data: result.data, response: httpURLResponse)
      case 400: throw NetworkError.badRequest
      case 401: throw NetworkError.unauthorized
      case 403: throw NetworkError.forbidden
      case 404: throw NetworkError.notFound
      case 402, 405...499: throw NetworkError.error4xx(code: httpURLResponse.statusCode)
      case 500: throw NetworkError.serverError
      case 501...599: throw NetworkError.error5xx(code: httpURLResponse.statusCode)
      default: throw NetworkError.unknownError
    }
  }
}
