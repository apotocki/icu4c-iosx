//
//  icufuncs.swift
//  icu4c-demo
//
//  Created by Alexander Pototskiy on 20.04.21.
//

import Foundation

func icuToUpper(_ str: String) -> String? {
    let count = str.utf8.count + 1
    let buff = UnsafeMutablePointer<Int8>.allocate(capacity: count)
    str.withCString { (baseAddress) in
        buff.initialize(from: baseAddress, count: count)
    }
    let result = UnsafeMutablePointer<Int8>.allocate(capacity: count)
    if 1 == toUpper(buff, result, UInt32(count)) {
        return String(cString: result, encoding: String.Encoding.utf8)
    }
    return nil
}
