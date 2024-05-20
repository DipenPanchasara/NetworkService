//
//  Endpoint.swift
//
//
//  Created by Dipen Panchasara on 20/05/2024.
//

import Foundation

public struct Endpoint: Equatable, Hashable {
  let path: String
  var queryItems: [String: String]?
  
  public init(path: String, queryItems: [String : String]? = nil) {
    self.path = path
    self.queryItems = queryItems
  }
}
