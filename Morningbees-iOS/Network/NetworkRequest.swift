//
//  NetworkRequest.swift
//  Morningbees-iOS
//
//  Created by iiwii on 2019/12/18.
//  Copyright © 2019 JUN LEE. All rights reserved.
//

import Foundation

enum Path: String {
    case base = "https://api-morningbees.thragoo.com"
    case validNickname = "/api/auth/valid_nickname"
    case signIn = "/api/auth/sign_in"
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}

enum ResponseError: Error {
    case unknown
    case badRequest
}

protocol RequestModel {

    associatedtype ModelType: Decodable
    var method: HTTPMethod { get set }
    var path: Path { get set }
}

final class RequestSet {

    let method: HTTPMethod
    let path: Path
    
    init(
        method: HTTPMethod,
        path: Path
    ) {
        self.method = method
        self.path = path
    }
}

final class Request<Model> where Model: Decodable {

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config)
    }()

    func request<T: Encodable>(req: RequestSet,
                               param: T,
                               completion: @escaping (Model?, Error?) -> Void) {
        var urlComponents = URLComponents(string: Path.base.rawValue)
        urlComponents?.path = req.path.rawValue
        
        //TODO: queryParams might be changed if httpMethod is POST.
        if let queryParams = param as? [String: String] {
            urlComponents?.queryItems = queryParams.map({ (key, value) -> URLQueryItem in
                URLQueryItem(name: key, value: value)
            })
        }

        guard let componentsURL = urlComponents?.url else {
            completion(nil, ResponseError.unknown)
            return
        }
        var request = URLRequest(url: componentsURL)
        request.httpMethod = req.method.rawValue
        
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let dataTask = session.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("error: \(error)")
            }
            guard let data = data else {
                completion(nil, ResponseError.unknown)
                return
            }
            guard let response = response as? HTTPURLResponse else {
                completion(nil, ResponseError.unknown)
                return
            }
            if response.statusCode > 299 || response.statusCode < 200 {
                if let result = String(data: data, encoding: .utf8) {
                    print("Error: \(result)")
                }
                completion(nil, ResponseError.badRequest)
                return
            }
            guard let result = try? JSONDecoder().decode(Model.self, from: data) else {
                completion(nil, ResponseError.unknown)
                return
            }
            completion(result, nil)
        }
        dataTask.resume()
    }
}
