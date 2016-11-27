/**
 *  Sylvan
 *
 *  Copyright (c) 2016 Oleg Dreyman. Licensed under the MIT license, as follows:
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in all
 *  copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *  SOFTWARE.
 */

import Foundation

public struct Provider<Value> {
    
    fileprivate let _get: () -> Value
    fileprivate let _set: (Value) -> ()
    
    public init(get: @escaping () -> Value, set: @escaping (Value) -> ()) {
        self._get = get
        self._set = set
    }
    
    public func get() -> Value {
        return _get()
    }
    
    public func set(_ value: Value) {
        _set(value)
    }
    
    public var value: Value {
        get {
            return get()
        }
    }
    
}

public enum Providers { }

extension Providers {
    
    public static func userDefaults(userDefaults: UserDefaults, storingKey: String) -> Provider<[String: Any]?> {
        let get: () -> [String: Any]? = {
            return userDefaults.dictionary(forKey: storingKey)
        }
        let set: ([String: Any]?) -> () = { dict in
            if let dict = dict {
                userDefaults.set(dict, forKey: storingKey)
            }
        }
        return Provider(get: get, set: set)
    }
    
    public static func inMemory<Value>(initial: Value) -> Provider<Value> {
        let box = Box<Value>(value: initial)
        let get: () -> Value = {
            return box.value
        }
        let set: (Value) -> () = { value in
            box.value = value
        }
        return Provider(get: get, set: set)
    }
    
}

internal class Box<Value> {
    var value: Value
    init(value: Value) {
        self.value = value
    }
}

extension Provider {
    
    public func map<OtherValue>(_ transform: Transformer<Value, OtherValue>) -> Provider<OtherValue> {
        return Provider<OtherValue>(get: { () -> OtherValue in
            return transform.from(self.value)
        }, set: { (otherValue) in
            self.set(transform.to(otherValue))
        })
    }
    
}
