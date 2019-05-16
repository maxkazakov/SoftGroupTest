//
//  Future.swift
//  SoftexGroupTest
//
//  Created by Максим Казаков on 15/05/2019.
//  Copyright © 2019 Максим Казаков. All rights reserved.
//

import Foundation


class Future<T> {
    
    func get(onSuccess: @escaping (T) -> Void, onError: ((Error) -> Void)? = nil) {
        if isFullfilled {
            if let result = result {
                onSuccess(result)
            } else if let error = error {
                onError?(error)
            }
            return
        }
        
        block { err, result in
            guard !self.isCancelled else {
                return
            }
            
            self.isFullfilled = true
            if let error = err {
                self.error = error
                onError?(error)
            } else if let result = result {
                self.result = result
                onSuccess(result)
            }
        }
    }
    
    func get(onSuccess: @escaping (T) -> Void) {
        get(onSuccess: onSuccess, onError: nil)
    }
    
    func cancel() {
        isCancelled = true
    }
    
    typealias FutureBlock = (@escaping (Error?, T?) -> Void) -> Void
    
    init(_ block: @escaping FutureBlock) {
        self.block = block
    }
    
    private let block: FutureBlock
    private(set) var isFullfilled: Bool = false
    private(set) var isCancelled: Bool = false
    
    var result: T?
    private var error: Error?
}
