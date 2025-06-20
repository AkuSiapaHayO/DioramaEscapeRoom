//
//  Dictionary.swift
//  DioramaEscapeRoom
//
//  Created by Derend Marvel Hanson Prionggo on 20/06/25.
//

import Foundation

extension Dictionary {
    func compactMapKeys<T: Hashable>(_ transform: (Key) -> T?) -> [T: Value] {
        var result: [T: Value] = [:]
        for (key, value) in self {
            if let newKey = transform(key) {
                result[newKey] = value
            }
        }
        return result
    }
}
