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

public struct AsyncOutputProvider<Value> {
    
    public typealias AsyncGet = (@escaping (Value) -> ()) -> Void
    
    fileprivate let _get: AsyncGet
    
    public init(_ get: @escaping AsyncGet) {
        self._get = get
    }
    
    public func get(completion: @escaping (Value) -> ()) {
        _get(completion)
    }
    
}

public extension AsyncOutputProvider {
    
    func map<OtherValue>(_ transform: @escaping (Value) -> OtherValue) -> AsyncOutputProvider<OtherValue> {
        return AsyncOutputProvider<OtherValue>({ (completion) in
            self.get(completion: { (value) in
                completion(transform(value))
            })
        })
    }
    
}

public struct AsyncInputProvider<Value> {
    
    public typealias AsyncSet = ((Value), @escaping (Error?) -> ()) -> Void
    
    fileprivate let _set: AsyncSet
    
    public init(_ set: @escaping AsyncSet) {
        self._set = set
    }
    
    public func set(_ value: Value, completion: @escaping (Error?) -> () = { _ in }) {
        _set(value, completion)
    }
    
}

public extension AsyncInputProvider {
    
    func map<OtherValue>(_ transform: @escaping (OtherValue) -> Value) -> AsyncInputProvider<OtherValue> {
        return AsyncInputProvider<OtherValue>({ (otherValue, completion) in
            self.set(transform(otherValue), completion: completion)
        })
    }
    
}

public struct AsyncProvider<OutputValue, InputValue> {
    
    public let output: AsyncOutputProvider<OutputValue>
    public let input: AsyncInputProvider<InputValue>
    
    public init(get: AsyncOutputProvider<OutputValue>,
                set: AsyncInputProvider<InputValue>) {
        self.output = get
        self.input = set
    }
    
    public init(get: @escaping (@escaping (OutputValue) -> ()) -> Void,
                set: @escaping ((InputValue), @escaping (Error?) -> ()) -> Void) {
        self.output = AsyncOutputProvider(get)
        self.input = AsyncInputProvider(set)
    }
    
    public init<AsyncProv : AsyncProviderProtocol>(_ asyncProvider: AsyncProv) where AsyncProv.OutputValue == OutputValue, AsyncProv.InputValue == InputValue {
        self.init(get: asyncProvider.get, set: asyncProvider.set)
    }
        
    public init(syncProvider: Provider<OutputValue, InputValue>, dispatchQueue: DispatchQueue) {
        self.output = AsyncOutputProvider { completion in
            dispatchQueue.async {
                let value = syncProvider.get()
                completion(value)
            }
        }
        self.input = AsyncInputProvider { value, completion in
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
        output.get(completion: completion)
    }
    
    public func set(_ value: InputValue, completion: @escaping (Error?) -> () = { _ in }) {
        input.set(value, completion: completion)
    }
    
}

public typealias IdenticalAsyncProvider<Value> = AsyncProvider<Value, Value>

public extension AsyncProvider {
    
    func mapInput<OtherInputValue>(_ transform: @escaping (OtherInputValue) -> InputValue) -> AsyncProvider<OutputValue, OtherInputValue> {
        return AsyncProvider<OutputValue, OtherInputValue>(get: output, set: input.map(transform))
    }
    
//    func flatMapInput<OtherInputValue>(_ transform: @escaping (OtherInputValue) -> InputValue?) -> AsyncProvider<OutputValue, OtherInputValue> {
//        return AsyncProvider<OutputValue, OtherInputValue>(get: self.output,
//                                                           set: { (value, completion) in
//                                                            do {
//                                                                let value = try transform(value).tryUnwrap()
//                                                                self.input(value, completion)
//                                                            } catch {
//                                                                completion(error)
//                                                            }
//        })
//    }
    
    func mapOutput<OtherOutputValue>(_ transform: @escaping (OutputValue) -> OtherOutputValue) -> AsyncProvider<OtherOutputValue, InputValue> {
        return AsyncProvider<OtherOutputValue, InputValue>(get: output.map(transform), set: input)
    }
    
    func map<OtherOutputValue, OtherInputValue>(_ outputTransform: @escaping (OutputValue) -> OtherOutputValue, inputTransform: @escaping (OtherInputValue) -> InputValue) -> AsyncProvider<OtherOutputValue, OtherInputValue> {
        return AsyncProvider<OtherOutputValue, OtherInputValue>(get: output.map(outputTransform), set: input.map(inputTransform))
    }
    
}

public extension CachedAsyncProvider {
    
    convenience init(provider: IdenticalAsyncProvider<Value>) {
        self.init(get: provider.output.get, set: provider.input.set)
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

