//
//  File.swift
//  RecipeLibrary
//
//  Created by SeanHuang on 12/29/24.
//

import Foundation

///Error thrown by reused HTTP session access
public enum APIError : LocalizedError{
    case develpmentError(desciption: String)
    case requestError(url : String)
    case decodeError(decodableType: String)
    case networkError(url : String, detail:String) //network layer error that needs retry
    case imageDecodeError(url: String)
    
    var description: String?{
        switch self{
            case .decodeError(decodableType: let type):
                return "Error when decoding type \(type)"
            case .networkError(url: let url, detail :let detail):
                return "NetWork Error when making request at: \(url)\n Detail:\(detail)"
            case .requestError(url: let url):
                return "Response Error when making request at: \(url)"
            case .imageDecodeError(url: let url):
                return "Image Conversion error at: \(url)"
            case .develpmentError(desciption: let desciption):
                return desciption
                
        }
    }
}

public enum HTTPMethod: String{
    case get
    case post
}

///Class that includes all the reusable generic API calling methods
@available(iOS 16.0, *)
public class APIManager : AsyncDebugLogger{
    
    /// Defines an Http request(usually POST) with following parameters
    /// - Parameters:
    ///   - url: endpoint address
    ///   - method: request method
    ///   - body: encoded data
    ///   - timeout: http request time out
    ///   - headers: header setters (content-type, authorization bearer, etc.)
    ///   - decodeHandler: When data is not decodable as Json data
    /// - Returns: generic data type desired by caller
    public static func sendHTTPRequestForJSON<T: Decodable>(url: URL, method: HTTPMethod, body: Data?, timeout: Double = 10.0, headers: (inout URLRequest)->Void = {req in }) async throws -> T?{
        var request = URLRequest(url: url)
        
        switch method{
            case .get:
                request.httpMethod = "GET"
            case .post:
                request.httpMethod = "POST"
                request.httpBody = body
        }
        
        headers(&request)
    
        let session = URLSession.shared
        do{
            request.timeoutInterval = timeout
            let (data,response) = try await session.data(for: request)
            guard let res = response as? HTTPURLResponse else{
                printF("HTTP response not valid {\(url)}")
                return nil
            }
            let responseBody = String(data: data, encoding: .utf8) ?? "Unable to decode response body"
            printF("Response Body:\n\(responseBody)")

            if res.statusCode == 200 || res.statusCode == 201{
                return try JSONDecoder().decode(T.self, from: data)
            }else{
                printF("HTTP Request unsuccessful response:\n\(res) \nfor {\(url)}")
                printF("Body:\n\(responseBody)")
            }
        }catch{
            printF("HTTP Request Error for {\(url)}:\n  \(error)")
        }
        return nil
    }
    
    
    /// Description
    /// - Behavior: return converted data successfully converted by dataConverter, all other unexpected behaviors will result in a nil return.
    /// - Parameters:
    ///   - url: endpoint address
    ///   - method: request method
    ///   - body: encoded data
    ///   - timeout: http request time out
    ///   - headers: header setters (content-type, authorization bearer, etc.)
    ///   - dataConverter: handler when data
    /// - Returns: converted data
    public static func sendHTTPRequestForData<T>(url: URL, method: HTTPMethod, body: Data?, timeout: Double = 10.0, headers: (inout URLRequest)->Void = {req in },
                                                     dataConverter: @escaping (Data) throws ->T) async throws -> T?{
        var request = URLRequest(url: url)
        
        switch method{
            case .get:
                request.httpMethod = "GET"
            case .post:
                request.httpMethod = "POST"
                request.httpBody = body
        }
        
        headers(&request)
    
        let session = URLSession.shared
        do{
            request.timeoutInterval = timeout
            let (data,response) = try await session.data(for: request)
            guard let res = response as? HTTPURLResponse else{
                printF("HTTP response not valid {\(url)}")
                return nil
            }
            //let responseBody = String(data: data, encoding: .utf8) ?? "Unable to decode response body"
            //printF("Response Body:\n\(responseBody)")

            if res.statusCode == 200 || res.statusCode == 201{
                return try dataConverter(data)
            }else{
                printF("HTTP Request unsuccessful response:\n\(res) \nfor {\(url)}")
                //printF("Body:\n\(responseBody)")
            }
        }catch{
            printF("HTTP Request Error for {\(url)}:\n  \(error)")
        }
        return nil
    }
  

}
