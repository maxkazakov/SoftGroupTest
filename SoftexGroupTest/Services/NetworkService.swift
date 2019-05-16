//
//  NetworkService.swift
//  SoftexGroupTest
//
//  Created by Максим Казаков on 13/05/2019.
//  Copyright © 2019 Максим Казаков. All rights reserved.
//

import Foundation


protocol NetworkService {
    
    /// Загрузить данные
    ///
    /// - Parameters:
    ///   - queue: Очередь, на которой будет вызван callback
    ///   - completion: callback
    func loadData(queue: DispatchQueue, completion: @escaping (Result<[CountryDTO], Error>) -> Void)
}


class NetworkServiceImpl: NetworkService {
    
    func loadData(queue: DispatchQueue, completion: @escaping (Result<[CountryDTO], Error>) -> Void) {
        let session = URLSession(configuration: .default)
        
        let dataTask = session.dataTask(with: apiUrl) { data, response, error in
            if let error = error {
                queue.async {
                    completion(.failure(error))
                }
            } else if let data = data {
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .formatted(self.dateFormatter)
                    let result = try decoder.decode([CountryDTO].self, from: data)
                    queue.async {
                        completion(.success(result))
                    }
                } catch {
                    queue.async {
                        completion(.failure(error))
                    }
                }
            }
        }
        dataTask.resume()
        // load
    }
    
    
    // MARK: -Private
    private let apiUrl = URL(string: "https://raw.githubusercontent.com/Softex-Group/task-mobile/master/test.json")!
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS"
        return formatter
    }()
}
