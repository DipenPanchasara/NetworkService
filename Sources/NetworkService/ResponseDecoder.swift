//
//  ResponseDecoder.swift
//  NetworkService
//
//  Created by Dipen Panchasara on 20/05/2024.
//

import Foundation

public protocol ResponseDecoderProvider: Sendable {
  func decode<T>(_ type: T.Type, from data: Data) throws -> T where T: Decodable
}

public final class ResponseDecoder: JSONDecoder, ResponseDecoderProvider {
  public override func decode<T>(_ type: T.Type, from data: Data) throws -> T where T: Decodable {
    do {
      return try super.decode(type, from: data)
    } catch DecodingError.typeMismatch(let type, let context) {
      let errorMessage = "Decoding Error: \n" +
            "TypeMismatch: \(type),\n" +
            "for CodingPath \(context.codingPath),\n" +
            "Description: \(context.debugDescription)"
      throw DecoderError.decodingFailed(errorMessage)
    } catch DecodingError.valueNotFound(let value, let context) {
      let errorMessage = "Decoding Error: \n" +
            "ValueNotFound: \(value),\n" +
            "for CodingPath \(context.codingPath),\n" +
            "Description: \(context.debugDescription)"
      throw DecoderError.decodingFailed(errorMessage)
    } catch DecodingError.keyNotFound(let key, let context) {
      let errorMessage = "Decoding Error: \n" +
            "KeyNotFound: \(key),\n" +
            "for CodingPath \(context.codingPath),\n" +
            "Description: \(context.debugDescription)"
      throw DecoderError.decodingFailed(errorMessage)
    } catch DecodingError.dataCorrupted(let context) {
      let errorMessage = "Decoding Error: DataCurrupted\n" +
            "for CodingPath \(context.codingPath),\n" +
            "Description: \(context.debugDescription)"
      throw DecoderError.decodingFailed(errorMessage)
    } catch {
      print("Decoding Error: Unknown error")
      throw DecoderError.decodingFailed(error.localizedDescription)
    }
  }
}

extension ResponseDecoder {
  public enum DecoderError: Error {
    case decodingFailed(String)
  }
}
