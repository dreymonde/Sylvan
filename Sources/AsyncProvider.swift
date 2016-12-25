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

public struct AsyncGetter<Value> {
    
    public typealias AsyncGet = (@escaping (Value) -> ()) -> Void
    
    fileprivate let _get: AsyncGet
    
    public init(_ get: @escaping AsyncGet) {
        self._get = get
    }
    
    public static func block(_ get: @escaping AsyncGet) -> AsyncGetter<Value> {
        return AsyncGetter(get)
    }
    
    public func get(completion: @escaping (Value) -> ()) {
        _get(completion)
    }
    
}

public extension AsyncGetter {
    
    func map<OtherValue>(_ transform: @escaping (Value) -> OtherValue) -> AsyncGetter<OtherValue> {
        return AsyncGetter<OtherValue>({ (completion) in
            self.get(completion: { (value) in
                completion(transform(value))
            })
        })
    }
    
}

public struct AsyncSetter<Value> {
    
    public typealias AsyncSet = ((Value), @escaping (Error?) -> ()) -> Void
    
    fileprivate let _set: AsyncSet
    
    public init(_ set: @escaping AsyncSet) {
        self._set = set
    }
    
    public static func block(_ set: @escaping AsyncSet) -> AsyncSetter<Value> {
        return AsyncSetter(set)
    }
    
    public func set(_ value: Value, completion: @escaping (Error?) -> () = { _ in }) {
        _set(value, completion)
    }
    
}

public extension AsyncSetter {
    
    func map<OtherValue>(_ transform: @escaping (OtherValue) -> Value) -> AsyncSetter<OtherValue> {
        return AsyncSetter<OtherValue>({ (otherValue, completion) in
            self.set(transform(otherValue), completion: completion)
        })
    }
    
}

public struct AsyncProvider<GetValue, SetValue> {
    
    public let output: AsyncGetter<GetValue>
    public let input: AsyncSetter<SetValue>
    
    public init(get: AsyncGetter<GetValue>,
                set: AsyncSetter<SetValue>) {
        self.output = get
        self.input = set
    }
    
    public init(get: @escaping (@escaping (GetValue) -> ()) -> Void,
                set: @escaping ((SetValue), @escaping (Error?) -> ()) -> Void) {
        self.output = AsyncGetter(get)
        self.input = AsyncSetter(set)
    }
    
    public init<AsyncProv : AsyncProviderProtocol>(_ asyncProvider: AsyncProv) where AsyncProv.GetValue == GetValue, AsyncProv.SetValue == SetValue {
        self.init(get: asyncProvider.get, set: asyncProvider.set)
    }
        
    public init(syncProvider: Provider<GetValue, SetValue>, dispatchQueue: DispatchQueue) {
        self.output = AsyncGetter { completion in
            dispatchQueue.async {
                let value = syncProvider.get()
                completion(value)
            }
        }
        self.input = AsyncSetter { value, completion in
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
    
    public func get(completion: @escaping (GetValue) -> ()) {
        output.get(completion: completion)
    }
    
    public func set(_ value: SetValue, completion: @escaping (Error?) -> () = { _ in }) {
        input.set(value, completion: completion)
    }
    
}

public typealias IdenticalAsyncProvider<Value> = AsyncProvider<Value, Value>

public extension AsyncProvider {
    
    func mapSet<OtherSetValue>(_ transform: @escaping (OtherSetValue) -> SetValue) -> AsyncProvider<GetValue, OtherSetValue> {
        return AsyncProvider<GetValue, OtherSetValue>(get: output, set: input.map(transform))
    }
    
//    func flatMapSet<OtherSetValue>(_ transform: @escaping (OtherSetValue) -> SetValue?) -> AsyncProvider<GetValue, OtherSetValue> {
//        return AsyncProvider<GetValue, OtherSetValue>(get: self.output,
//                                                           set: { (value, completion) in
//                                                            do {
//                                                                let value = try transform(value).tryUnwrap()
//                                                                self.input(value, completion)
//                                                            } catch {
//                                                                completion(error)
//                                                            }
//        })
//    }
    
    func mapGet<OtherGetValue>(_ transform: @escaping (GetValue) -> OtherGetValue) -> AsyncProvider<OtherGetValue, SetValue> {
        return AsyncProvider<OtherGetValue, SetValue>(get: output.map(transform), set: input)
    }
    
    func map<OtherGetValue, OtherSetValue>(_ outputTransform: @escaping (GetValue) -> OtherGetValue, inputTransform: @escaping (OtherSetValue) -> SetValue) -> AsyncProvider<OtherGetValue, OtherSetValue> {
        return AsyncProvider<OtherGetValue, OtherSetValue>(get: output.map(outputTransform), set: input.map(inputTransform))
    }
    
}

public extension AsyncProvider {
    
    func synchronized() -> AsyncProvider<GetValue, SetValue> {
        let queue = DispatchQueue(label: "\(self)-SynchronizationQueue")
        return AsyncProvider<GetValue, SetValue>(get: { (completion) in
            queue.async { self.get(completion: completion) }
        }, set: { (value, completion) in
            queue.async { self.set(value, completion: completion) }
        })
    }
    
}

public extension CachedAsyncProvider {
    
    convenience init(_ provider: IdenticalAsyncProvider<Value>) {
        self.init(get: provider.output.get, set: provider.input.set)
    }
    
}
