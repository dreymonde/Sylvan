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

public struct AsyncProvider<OutputValue, InputValue> {
    
    fileprivate let _get: (@escaping (OutputValue) -> ()) -> Void
    fileprivate let _set: ((InputValue), @escaping (Error?) -> ()) -> Void
    
    public init(get: @escaping (@escaping (OutputValue) -> ()) -> Void,
                set: @escaping ((InputValue), @escaping (Error?) -> ()) -> Void) {
        self._get = get
        self._set = set
    }
        
    public init(syncProvider: Provider<OutputValue, InputValue>, dispatchQueue: DispatchQueue) {
        self._get = { completion in
            dispatchQueue.async {
                let value = syncProvider.get()
                completion(value)
            }
        }
        self._set = { value, completion in
            dispatchQueue.async {
                do {
                    try syncProvider.set(value)
                    completion(nil)
                } catch {
                    completion(error)
                }
            }
        }
    }
    
    public func get(completion: @escaping (OutputValue) -> ()) {
        _get(completion)
    }
    
    public func set(_ value: InputValue, completion: @escaping (Error?) -> () = { _ in }) {
        _set(value, completion)
    }
    
    public func ungaranteedSet(_ value: InputValue, completion: @escaping () -> () = { }) {
        _set(value, { _ in completion() })
    }
    
}

public typealias IdenticalAsyncProvider<Value> = AsyncProvider<Value, Value>

public extension AsyncProvider {
    
    func mapInput<OtherInputValue>(_ transform: @escaping (OtherInputValue) -> InputValue) -> AsyncProvider<OutputValue, OtherInputValue> {
        return AsyncProvider<OutputValue, OtherInputValue>(get: self._get,
                                                           set: { (value, completion) in
                                                            self._set(transform(value), completion)
        })
    }
    
    func flatMapInput<OtherInputValue>(_ transform: @escaping (OtherInputValue) -> InputValue?) -> AsyncProvider<OutputValue, OtherInputValue> {
        return AsyncProvider<OutputValue, OtherInputValue>(get: self._get,
                                                           set: { (value, completion) in
                                                            do {
                                                                let value = try transform(value).tryUnwrap()
                                                                self._set(value, completion)
                                                            } catch {
                                                                completion(error)
                                                            }
        })
    }
    
    func mapOutput<OtherOutputValue>(_ transform: @escaping (OutputValue) -> OtherOutputValue) -> AsyncProvider<OtherOutputValue, InputValue> {
        return AsyncProvider<OtherOutputValue, InputValue>(get: { (completion) in
            self._get({ completion(transform($0)) })
        },
                                                           set: self._set)
    }
    
    func map<OtherOutputValue, OtherInputValue>(_ outputTransform: @escaping (OutputValue) -> OtherOutputValue, inputTransform: @escaping (OtherInputValue) -> InputValue) -> AsyncProvider<OtherOutputValue, OtherInputValue> {
        return AsyncProvider<OtherOutputValue, OtherInputValue>(get: { (completion) in
            self._get({ completion(outputTransform($0)) })
        }, set: { (value, completion) in
            self._set(inputTransform(value), completion)
        })
    }
    
}

public extension CachedAsyncProvider {
    
    convenience init(provider: IdenticalAsyncProvider<Value>) {
        self.init(get: provider._get, set: provider._set)
    }
    
}

//public extension AsyncProvider {
//    
//    func map<OtherValue>(_ transform: Transformer<Value, OtherValue>) -> AsyncProvider<OtherValue> {
//        return AsyncProvider<OtherValue>(get: { (completion) in
//            self.get(completion: { completion(transform.from($0)) })
//        }, set: { (value, completion) in
//            self.set(transform.to(value), completion: completion)
//        })
//    }
//    
//}

