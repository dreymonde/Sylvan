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

public struct Provider<OutputValue, InputValue> {
    
    fileprivate let _get: () -> OutputValue
    fileprivate let _set: (InputValue) throws -> ()
    
    public init(get: @escaping () -> OutputValue, set: @escaping (InputValue) throws -> ()) {
        self._get = get
        self._set = set
    }
    
    public func get() -> OutputValue {
        return _get()
    }
    
    public func set(_ value: InputValue) throws {
        return try _set(value)
    }
    
    public func ungaranteedSet(_ value: InputValue) {
        do {
            try _set(value)
        } catch { }
    }
    
    public var value: OutputValue {
        get {
            return get()
        }
    }
    
}

public typealias IdenticalProvider<Value> = Provider<Value, Value>

extension Provider {
    
    public func async(dispatchQueue: DispatchQueue) -> AsyncProvider<OutputValue, InputValue> {
        return AsyncProvider(syncProvider: self, dispatchQueue: dispatchQueue)
    }
    
    public func mapInput<OtherInputValue>(_ transform: @escaping (OtherInputValue) -> InputValue) -> Provider<OutputValue, OtherInputValue> {
        return Provider<OutputValue, OtherInputValue>(get: self._get,
                                                      set: { try self._set(transform($0)) })
    }
    
    public func flatMapInput<OtherInputValue>(_ transform: @escaping (OtherInputValue) -> InputValue?) -> Provider<OutputValue, OtherInputValue> {
        return Provider<OutputValue, OtherInputValue>(get: self._get,
                                                      set: { try self._set(try transform($0).tryUnwrap()) })
    }
    
    public func mapOutput<OtherOutputValue>(_ transform: @escaping (OutputValue) -> OtherOutputValue) -> Provider<OtherOutputValue, InputValue> {
        return Provider<OtherOutputValue, InputValue>(get: { transform(self._get()) },
                                                      set: self._set)
    }
    
    public func map<OtherOutputValue, OtherInputValue>(outputTransform: @escaping (OutputValue) -> OtherOutputValue, inputTransform: @escaping (OtherInputValue) -> InputValue) -> Provider<OtherOutputValue, OtherInputValue> {
        return Provider<OtherOutputValue, OtherInputValue>(get: { outputTransform(self._get()) },
                                                           set: { try self._set(inputTransform($0)) })
    }
    
}

public enum Providers { }

public extension Providers {
    
    static func inMemory<Value>(initial: Value) -> IdenticalProvider<Value> {
        let box = Box(value: initial)
        return IdenticalProvider<Value>(get: { return box.value }, set: { box.value = $0 })
    }
    
}

internal class Box<Value> {
    var value: Value
    init(value: Value) {
        self.value = value
    }
}
