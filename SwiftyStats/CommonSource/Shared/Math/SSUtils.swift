//
//  SSUtils.swift
//  SwiftyStats
//
//  Created by Volker Thieme on 03.07.17.
//
/*
 Copyright (c) 2017 Volker Thieme
 
 GNU GPL 3+
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, version 3 of the License.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.

 */

import Foundation





/// Tests, if a value is integer.
/// - Paramter value: A double-value.
internal func isInteger<T: SSFloatingPoint>(_ value: T) -> Bool {
    return value.truncatingRemainder(dividingBy: 1).isZero
}

/// Tests, if a value is odd.
/// - Paramter value: A double-value.
internal func isOdd<T: SSFloatingPoint>(_ value: T) -> Bool {
    var modr: (T, T)
    modr = modf(value)
    if !modr.1.isZero {
        return false;
    }
    else if modr.0.truncatingRemainder(dividingBy: 2).isZero {
        return false
    }
    else {
        return true
    }
}

internal func integerValue<T: SSFloatingPoint, I: BinaryInteger>(_ x: T) -> I {
    switch x {
    case let d as Double:
        switch I.self {
        case is Int32.Type:
            let r = Int32(d)
            return r as! I
        case is Int16.Type:
            let r = Int16(d)
            return r as! I
        case is Int64.Type:
            let r = Int64(d)
            return r as! I
        case is Int8.Type:
            let r = Int8(d)
            return r as! I
        case is UInt.Type:
            let r = UInt(d)
            return r as! I
        case is UInt32.Type:
            let r = UInt32(d)
            return r as! I
        case is UInt16.Type:
            let r = UInt16(d)
            return r as! I
        case is UInt8.Type:
            let r = UInt8(d)
            return r as! I
        case is UInt64.Type:
            let r = UInt64(d)
            return r as! I
        default:
            let r = Int(d)
            return r as! I
        }
    case let d as Float:
        switch I.self {
        case is Int32.Type:
            let r = Int32(d)
            return r as! I
        case is Int16.Type:
            let r = Int16(d)
            return r as! I
        case is Int64.Type:
            let r = Int64(d)
            return r as! I
        case is Int8.Type:
            let r = Int8(d)
            return r as! I
        case is UInt.Type:
            let r = UInt(d)
            return r as! I
        case is UInt32.Type:
            let r = UInt32(d)
            return r as! I
        case is UInt16.Type:
            let r = UInt16(d)
            return r as! I
        case is UInt8.Type:
            let r = UInt8(d)
            return r as! I
        case is UInt64.Type:
            let r = Int64(d)
            return r as! I
        default:
            let r = Int(d)
            return r as! I
        }
        #if arch(x86_64)
    case let d as Float80:
        switch I.self {
        case is Int32.Type:
            let r = Int32(d)
            return r as! I
        case is Int16.Type:
            let r = Int16(d)
            return r as! I
        case is Int64.Type:
            let r = Int64(d)
            return r as! I
        case is Int8.Type:
            let r = Int8(d)
            return r as! I
        case is UInt.Type:
            let r = UInt(d)
            return r as! I
        case is UInt32.Type:
            let r = UInt32(d)
            return r as! I
        case is UInt16.Type:
            let r = UInt16(d)
            return r as! I
        case is UInt8.Type:
            let r = UInt8(d)
            return r as! I
        case is UInt64.Type:
            let r = Int64(d)
            return r as! I
        default:
            let r = Int(d)
            return r as! I
        }
        #endif
    default:
        return 0
    }
}


/// Returns the integer part of a floating point number
internal func integerPart<T: SSFloatingPoint>(_ x: T) -> T {
    var modr: (T, T)
    modr = modf(x)
    return modr.0
//    switch x {
//    case let d as Double:
//        var intPart: Double = 0.0
//        let _ = modf(d, &intPart)
//        return intPart as! T
//    case let f as Float:
//        var intPart: Float = 0.0
//        let _ = modff(f, &intPart)
//        return intPart as! T
//        #if arch(x86_64)
//    case let f80 as Float80:
//        var intPart: Float80 = 0.0
//        let _ = modfl(f80, &intPart)
//        return intPart as! T
//        #endif
//    default:
//        return T.nan
//    }
}


/// Returns the fractional part of a double-value
/// - Paramter value: A double-value.
internal func fractionalPart<T: SSFloatingPoint>(_ value: T) -> T {
    var modr: (T, T)
    modr = modf(value)
    return modr.1
}

/// Tests, if a value is numeric
/// - Paramter value: A value of type T
internal func isNumber<T>(_ value: T) -> Bool {
    let valueMirror = Mirror(reflecting: value)
    #if arch(arm) || arch(arm64)
        if (valueMirror.subjectType == Int.self || valueMirror.subjectType == UInt.self || valueMirror.subjectType == Double.self || valueMirror.subjectType == Int8.self || valueMirror.subjectType == Int16.self || valueMirror.subjectType == Int32.self || valueMirror.subjectType == Int64.self || valueMirror.subjectType == UInt8.self || valueMirror.subjectType == UInt16.self || valueMirror.subjectType == UInt32.self || valueMirror.subjectType == UInt64.self || valueMirror.subjectType == Float.self || valueMirror.subjectType == Float32.self || valueMirror.subjectType == NSNumber.self || valueMirror.subjectType == NSDecimalNumber.self ) {
            return true
        }
        else {
            return false
        }
    #else
        if (valueMirror.subjectType == Int.self || valueMirror.subjectType == UInt.self || valueMirror.subjectType == Double.self || valueMirror.subjectType == Int8.self || valueMirror.subjectType == Int16.self || valueMirror.subjectType == Int32.self || valueMirror.subjectType == Int64.self || valueMirror.subjectType == UInt8.self || valueMirror.subjectType == UInt16.self || valueMirror.subjectType == UInt32.self || valueMirror.subjectType == UInt64.self || valueMirror.subjectType == Float.self || valueMirror.subjectType == Float32.self || valueMirror.subjectType == Float80.self || valueMirror.subjectType == NSNumber.self || valueMirror.subjectType == NSDecimalNumber.self ) {
            return true
        }
        else {
            return false
        }
    #endif
}

internal func makeFP<T, FPT: SSFloatingPoint>(_ value: T) -> FPT {
    switch value {
    case let s as String:
        switch FPT.self {
            #if arch(i386) || arch(x86_64)
        case is Float80.Type:
            return Float80.init(s) as! FPT
            #endif
        case is Float.Type:
            return Float.init(s) as! FPT
        case is Double.Type:
            return Double.init(s) as! FPT
        default:
            return FPT.nan
        }
    case let f as Float:
        switch FPT.self {
            #if arch(i386) || arch(x86_64)
        case is Float80.Type:
            return Float80.init("\(f)") as! FPT
            #endif
        case is Float.Type:
            return Float.init("\(f)") as! FPT
        case is Double.Type:
            return Double.init(f) as! FPT
        default:
            return FPT.nan
        }
    case let f as Double:
        switch FPT.self {
            #if arch(i386) || arch(x86_64)
        case is Float80.Type:
            return Float80.init("\(f)") as! FPT
            #endif
        case is Float.Type:
            return Float.init("\(f)") as! FPT
        case is Double.Type:
            return Double.init(f) as! FPT
        default:
            return FPT.nan
        }
        #if arch(i386) || arch(x86_64)
    case let f as Float80:
        switch FPT.self {
        case is Float80.Type:
            return Float80.init("\(f)") as! FPT
        case is Float.Type:
            return Float.init("\(f)") as! FPT
        case is Double.Type:
            return Double.init(f) as! FPT
        default:
            return FPT.nan
        }
        #endif
    case let i as Int:
        switch FPT.self {
            #if arch(i386) || arch(x86_64)
        case is Float80.Type:
            return Float80.init(i) as! FPT
            #endif
        case is Float.Type:
            return Float.init(i) as! FPT
        case is Double.Type:
            return Double.init(i) as! FPT
        default:
            return FPT.nan
        }
    case let i as Int8:
        switch FPT.self {
            #if arch(i386) || arch(x86_64)
        case is Float80.Type:
            return Float80.init(i) as! FPT
            #endif
        case is Float.Type:
            return Float.init(i) as! FPT
        case is Double.Type:
            return Double.init(i) as! FPT
        default:
            return FPT.nan
        }
    case let i as Int16:
        switch FPT.self {
            #if arch(i386) || arch(x86_64)
        case is Float80.Type:
            return Float80.init(i) as! FPT
            #endif
        case is Float.Type:
            return Float.init(i) as! FPT
        case is Double.Type:
            return Double.init(i) as! FPT
        default:
            return FPT.nan
        }
    case let i as Int32:
        switch FPT.self {
            #if arch(i386) || arch(x86_64)
        case is Float80.Type:
            return Float80.init(i) as! FPT
            #endif
        case is Float.Type:
            return Float.init(i) as! FPT
        case is Double.Type:
            return Double.init(i) as! FPT
        default:
            return FPT.nan
        }
    case let i as Int64:
        switch FPT.self {
            #if arch(i386) || arch(x86_64)
        case is Float80.Type:
            return Float80.init(i) as! FPT
            #endif
        case is Float.Type:
            return Float.init(i) as! FPT
        case is Double.Type:
            return Double.init(i) as! FPT
        default:
            return FPT.nan
        }
    case let i as UInt:
        switch FPT.self {
            #if arch(i386) || arch(x86_64)
        case is Float80.Type:
            return Float80.init(i) as! FPT
            #endif
        case is Float.Type:
            return Float.init(i) as! FPT
        case is Double.Type:
            return Double.init(i) as! FPT
        default:
            return FPT.nan
        }
    case let i as UInt8:
        switch FPT.self {
            #if arch(i386) || arch(x86_64)
        case is Float80.Type:
            return Float80.init(i) as! FPT
            #endif
        case is Float.Type:
            return Float.init(i) as! FPT
        case is Double.Type:
            return Double.init(i) as! FPT
        default:
            return FPT.nan
        }
    case let i as UInt16:
        switch FPT.self {
            #if arch(i386) || arch(x86_64)
        case is Float80.Type:
            return Float80.init(i) as! FPT
            #endif
        case is Float.Type:
            return Float.init(i) as! FPT
        case is Double.Type:
            return Double.init(i) as! FPT
        default:
            return FPT.nan
        }
    case let i as UInt32:
        switch FPT.self {
            #if arch(i386) || arch(x86_64)
        case is Float80.Type:
            return Float80.init(i) as! FPT
            #endif
        case is Float.Type:
            return Float.init(i) as! FPT
        case is Double.Type:
            return Double.init(i) as! FPT
        default:
            return FPT.nan
        }
    case let i as UInt64:
        switch FPT.self {
            #if arch(i386) || arch(x86_64)
        case is Float80.Type:
            return Float80.init(i) as! FPT
            #endif
        case is Float.Type:
            return Float.init(i) as! FPT
        case is Double.Type:
            return Double.init(i) as! FPT
        default:
            return FPT.nan
        }
    default:
        return FPT.nan
    }
}

internal func castArrayToFloatingPoint<T, FPT>(_ array: Array<T>) -> Array<FPT>? where T: Numeric & Codable & Hashable & Comparable, FPT: SSFloatingPoint & Codable {
    if array.isEmpty {
        return nil
    }
    var temp: FPT
    var result: Array<FPT> = Array<FPT>()
    for item in array {
        temp = makeFP(item)
        result.append(temp)
    }
    return result as Array<FPT>
}



/// Returns the maximum of two comparable values
internal func maximum<T>(_ t1: T, _ t2: T) -> T where T:Comparable {
    if t1 > t2 {
        return t1
    }
    else {
        return t2
    }
}

/// Returns the minimum of two comparable values
internal func minimum<T>(_ t1: T, _ t2: T) -> T where T:Comparable {
    if t1 < t2 {
        return t1
    }
    else {
        return t2
    }
}

/// Returns a SSExamine object of length one and count "count"
/// - Parameter value: Value
/// - Parameter count: Number of values
internal func replicateExamine<T, FPT: SSFloatingPoint & Codable>(value: T!, count: Int!) -> SSExamine<T, FPT> where T: Comparable, T: Hashable, FPT: Codable {
    let array = Array<T>.init(repeating: value, count: count)
    let res = SSExamine<T, FPT>.init(withArray: array, name: nil, characterSet: nil)
    return res
}


/*************************************************************
 scanning functions
*************************************************************/

internal func scanDouble(string: String?) -> Double? {
    guard string != nil else {
        return nil
    }
    var res: Double = 0.0
    let s = Scanner.init(string: string!)
    if s.scanDouble(&res) {
        return res
    }
    else {
        return nil
    }
}

internal func scanDecimal(string: String?) -> Decimal? {
    guard string != nil else {
        return nil
    }
    var res: Decimal = 0.0
    let s = Scanner.init(string: string!)
    if s.scanDecimal(&res) {
        return res
    }
    else {
        return nil
    }
}

internal func scanFloat(string: String?) -> Float? {
    guard string != nil else {
        return nil
    }
    var res: Float = 0.0
    let s = Scanner.init(string: string!)
    if s.scanFloat(&res) {
        return res
    }
    else {
        return nil
    }
}

internal func scanHexDouble(string: String?) -> Double? {
    guard string != nil else {
        return nil
    }
    var res: Double = 0.0
    let s = Scanner.init(string: string!)
    if s.scanHexDouble(&res) {
        return res
    }
    else {
        return nil
    }
}

internal func scanHexFloat(string: String?) -> Float? {
    guard string != nil else {
        return nil
    }
    var res: Float = 0.0
    let s = Scanner.init(string: string!)
    if s.scanHexFloat(&res) {
        return res
    }
    else {
        return nil
    }
}

internal func scanHexInt32(string: String?) -> UInt32? {
    guard string != nil else {
        return nil
    }
    var res: UInt32 = 0
    let s = Scanner.init(string: string!)
    if s.scanHexInt32(&res) {
        return res
    }
    else {
        return nil
    }
}

internal func scanHexInt64(string: String?) -> UInt64? {
    guard string != nil else {
        return nil
    }
    var res: UInt64 = 0
    let s = Scanner.init(string: string!)
    if s.scanHexInt64(&res) {
        return res
    }
    else {
        return nil
    }
}

internal func scanInt32(string: String?) -> Int32? {
    guard string != nil else {
        return nil
    }
    var res: Int32 = 0
    let s = Scanner.init(string: string!)
    if s.scanInt32(&res) {
        return res
    }
    else {
        return nil
    }
}


internal func scanInt64(string: String?) -> Int64? {
    guard string != nil else {
        return nil
    }
    var res: Int64 = 0
    let s = Scanner.init(string: string!)
    if s.scanInt64(&res) {
        return res
    }
    else {
        return nil
    }
}

internal func scanUInt64(string: String?) -> UInt64? {
    guard string != nil else {
        return nil
    }
    var res: UInt64 = 0
    let s = Scanner.init(string: string!)
    if s.scanUnsignedLongLong(&res) {
        return res
    }
    else {
        return nil
    }
}


internal func scanInt(string: String?) -> Int? {
    guard string != nil else {
        return nil
    }
    var res: Int = 0
    let s = Scanner.init(string: string!)
    if s.scanInt(&res) {
        return res
    }
    else {
        return nil
    }
}


internal func scanString(string: String?) -> String? {
    guard string != nil else {
        return nil
    }
    return string
}

class StandardErrorOutputStream: TextOutputStream {
    func write(_ string: String) {
        let stdErr = FileHandle.standardError
        if let data = string.data(using: .utf8) {
            stdErr.write(data)
        }
        else {
            stdErr.write("ERROR WRITING TO stdErr in SwiftyStats".data(using: .utf8)!)
        }
    }
}

internal func printError(_ message: String!) {
    var outputStream = StandardErrorOutputStream()
    print(message, to: &outputStream)
}







