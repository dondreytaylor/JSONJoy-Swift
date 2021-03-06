//////////////////////////////////////////////////////////////////////////////////////////////////
//
//  JSONJoy.swift
//
//  Created by Dalton Cherry on 9/17/14.
//  Copyright (c) 2014 Vluxe. All rights reserved.
//
//////////////////////////////////////////////////////////////////////////////////////////////////

import Foundation

public enum JSONError: ErrorType {
    case WrongType
}

public class JSONDecoder {
    var value: AnyObject?
    
    ///return the value raw
    public var rawValue: AnyObject? {
        return value
    }
    ///print the description of the JSONDecoder
    public var description: String {
        return self.print()
    }
    ///convert the value to a String
    public var string: String? {
        return value as? String
    }

    ///convert the value to an Int
    public var integer: Int? {
        return value as? Int
    }
    ///convert the value to an UInt
    public var unsigned: UInt? {
        return value as? UInt
    }
    ///convert the value to a Double
    public var double: Double? {
        return value as? Double
    }
    ///convert the value to a float
    public var float: Float? {
        return value as? Float
    }
    ///convert the value to an NSNumber
    public var number: NSNumber? {
        return value as? NSNumber
    }
    ///treat the value as a bool
    public var bool: Bool {
        if let str = self.string {
            let lower = str.lowercaseString
            if lower == "true" || Int(lower) > 0 {
                return true
            }
        } else if let num = self.integer {
            return num > 0
        } else if let num = self.double {
            return num > 0.99
        } else if let num = self.float {
            return num > 0.99
        }
        return false
    }
    //get  the value if it is an error
    public var error: NSError? {
        return value as? NSError
    }
    //get  the value if it is a dictionary
    public var dictionary: Dictionary<String,JSONDecoder>? {
        return value as? Dictionary<String,JSONDecoder>
    }
    //get  the value if it is an array
    public var array: Array<JSONDecoder>? {
        return value as? Array<JSONDecoder>
    }
    
    //get the string and have it throw if it doesn't work
    public func getString() throws -> String {
        guard let str = string else {throw JSONError.WrongType}
        return str
    }
    
    //get the int and have it throw if it doesn't work
    public func getInt() throws -> Int {
        guard let i = integer else {throw JSONError.WrongType}
        return i
    }
    
    //get the unsigned and have it throw if it doesn't work
    public func getUnsigned() throws -> UInt {
        guard let i = unsigned else {throw JSONError.WrongType}
        return i
    }
    
    //get the double and have it throw if it doesn't work
    public func getDouble() throws -> Double {
        guard let i = double else {throw JSONError.WrongType}
        return i
    }
    
    //get the Float and have it throw if it doesn't work
    public func getFloat() throws -> Float {
        guard let i = float else {throw JSONError.WrongType}
        return i
    }
    
    //get the number and have it throw if it doesn't work
    public func getFloat() throws -> NSNumber {
        guard let i = number else {throw JSONError.WrongType}
        return i
    }
    
    //get the bool and have it throw if it doesn't work
    public func getBool() throws -> Bool {
        if let _ = value as? NSNull {
            throw JSONError.WrongType
        }
        return bool
    }
    
    //pull the raw values out of an array
    public func getArray<T>(inout collect: Array<T>?) {
        if let array = value as? Array<JSONDecoder> {
            if collect == nil {
                collect = Array<T>()
            }
            for decoder in array {
                if let obj = decoder.value as? T {
                    collect?.append(obj)
                }
            }
        }
    }
    ///pull the raw values out of a dictionary.
    public func getDictionary<T>(inout collect: Dictionary<String,T>?) {
        if let dictionary = value as? Dictionary<String,JSONDecoder> {
            if collect == nil {
                collect = Dictionary<String,T>()
            }
            for (key,decoder) in dictionary {
                if let obj = decoder.value as? T {
                    collect?[key] = obj
                }
            }
        }
    }
    ///the init that converts everything to something nice
    public init(_ raw: AnyObject, isSub: Bool = false) {
        var rawObject: AnyObject = raw
        if let str = rawObject as? String where !isSub {
            rawObject = str.dataUsingEncoding(NSUTF8StringEncoding)!
        }
        if let data = rawObject as? NSData {
            var response: AnyObject?
            do {
                try response = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions())
                rawObject = response!
            }
            catch let error as NSError {
                value = error
                return
            }
        }
        if let array = rawObject as? NSArray {
            var collect = [JSONDecoder]()
            for val: AnyObject in array {
                collect.append(JSONDecoder(val, isSub: true))
            }
            value = collect
        } else if let dict = rawObject as? NSDictionary {
            var collect = Dictionary<String,JSONDecoder>()
            for (key,val) in dict {
                collect[key as! String] = JSONDecoder(val, isSub: true)
            }
            value = collect
        } else {
            value = rawObject
        }
    }
    ///Array access support
    public subscript(index: Int) -> JSONDecoder {
        get {
            if let array = self.value as? NSArray {
                if array.count > index {
                    return array[index] as! JSONDecoder
                }
            }
            return JSONDecoder(createError("index: \(index) is greater than array or this is not an Array type."))
        }
    }
    ///Dictionary access support
    public subscript(key: String) -> JSONDecoder {
        get {
            if let dict = self.value as? NSDictionary {
                if let value: AnyObject = dict[key] {
                    return value as! JSONDecoder
                }
            }
            return JSONDecoder(createError("key: \(key) does not exist or this is not a Dictionary type"))
        }
    }
    ///private method to create an error
    func createError(text: String) -> NSError {
        return NSError(domain: "JSONJoy", code: 1002, userInfo: [NSLocalizedDescriptionKey: text]);
    }
    
    ///print the decoder in a JSON format. Helpful for debugging.
    public func print() -> String {
        if let arr = self.array {
            var str = "["
            for decoder in arr {
                str += decoder.print() + ","
            }
            str.removeAtIndex(str.endIndex.advancedBy(-1))
            return str + "]"
        } else if let dict = self.dictionary {
            var str = "{"
            for (key, decoder) in dict {
                str += "\"\(key)\": \(decoder.print()),"
            }
            str.removeAtIndex(str.endIndex.advancedBy(-1))
            return str + "}"
        }
        if let v = value {
            if let s = self.string {
                return "\"\(s)\""
            } else if let _ = value as? NSNull {
                return "null"
            }
            return "\(v)"
        }
        return ""
    }
}

///Implement this protocol on all objects you want to use JSONJoy with
public protocol JSONJoy {
    init(_ decoder: JSONDecoder) throws
}
