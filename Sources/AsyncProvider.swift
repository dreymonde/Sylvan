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

public struct AsyncProvider<Value> {
    
    fileprivate let _get: (@escaping (Value) -> ()) -> Void
    fileprivate let _set: ((Value), @escaping () -> ()) -> Void
    
    public init(get: @escaping (@escaping (Value) -> ()) -> Void,
                set: @escaping ((Value), @escaping () -> ()) -> Void) {
        self._get = get
        self._set = set
    }
    
    public func get(completion: @escaping (Value) -> ()) {
        _get(completion)
    }
    
    public func set(_ value: Value, completion: @escaping () -> ()) {
        _set(value, completion)
    }
    
}

public extension AsyncProvider {
    
    func map<OtherValue>(_ transform: Transformer<Value, OtherValue>) -> AsyncProvider<OtherValue> {
        return AsyncProvider<OtherValue>(get: { (completion) in
            self.get(completion: { completion(transform.from($0)) })
        }, set: { (value, completion) in
            self.set(transform.to(value), completion: completion)
        })
    }
    
}

public enum AsyncProviders { }

extension AsyncProviders {
    
    public static func userDefaults(userDefaults: UserDefaults = .standard,
                                    storingKey: String,
                                    dispatchQueue: DispatchQueue) -> AsyncProvider<[String: Any]?> {
        return AsyncProvider<[String: Any]?>(get: { (completion) in
            dispatchQueue.async {
                let dictionary = userDefaults.dictionary(forKey: storingKey)
                completion(dictionary)
            }
        }, set: { (value, completion) in
            dispatchQueue.async {
                userDefaults.set(value, forKey: storingKey)
                completion()
            }
        })
    }
    
    public static func inMemory<Value>(initial: Value) -> AsyncProvider<Value> {
        let box = Box(value: initial)
        return AsyncProvider(get: { (completion) in
            completion(box.value)
        }, set: { (value, completion) in
            box.value = value
            completion()
        })
    }
    
}

