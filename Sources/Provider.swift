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

public struct Getter<Value> {
    
    fileprivate let _get: () -> Value
    
    public init(_ get: @escaping () -> Value) {
        self._get = get
    }
    
    public static func block(_ get: @escaping () -> Value) -> Getter<Value> {
        return Getter(get)
    }
    
    public func get() -> Value {
        return _get()
    }
    
}

public extension Getter {
    
    public func map<OtherValue>(_ transform: @escaping (Value) -> OtherValue) -> Getter<OtherValue> {
        return Getter<OtherValue>({ transform(self.get()) })
    }
    
}

public struct Setter<Value> {
    
    fileprivate let _set: (Value) throws -> ()
    
    public init(_ set: @escaping (Value) throws -> ()) {
        self._set = set
    }
    
    public static func block(_ set: @escaping (Value) throws -> ()) -> Setter<Value> {
        return Setter(set)
    }
    
    public func set(_ value: Value) throws {
        return try _set(value)
    }
    
    @discardableResult
    public func ungaranteedSet(_ value: Value) -> Bool {
        do {
            try set(value)
            return true
        } catch {
            return false
        }
    }
    
}

public extension Setter {
    
    public func map<OtherValue>(_ transform: @escaping (OtherValue) -> Value) -> Setter<OtherValue> {
        return Setter<OtherValue>({ try self.set(transform($0)) })
    }
    
}

public struct Provider<OutputValue, InputValue> {
    
    public let output: Getter<OutputValue>
    public let input: Setter<InputValue>
    
    public init(get: Getter<OutputValue>, input: Setter<InputValue>) {
        self.output = get
        self.input = input
    }
    
    public init(get: @escaping () -> OutputValue, set: @escaping (InputValue) throws -> ()) {
        self.output = Getter(get)
        self.input = Setter(set)
    }
    
    public init<Prov : ProviderProtocol>(_ provider: Prov) where Prov.InputValue == InputValue, Prov.OutputValue == OutputValue {
        self.init(get: provider.get, set: provider.set)
    }
    
    public func get() -> OutputValue {
        return output.get()
    }
    
    public func set(_ value: InputValue) throws {
        return try input.set(value)
    }
    
    @discardableResult
    public func ungaranteedSet(_ value: InputValue) -> Bool {
        do {
            try input.set(value)
            return true
        } catch {
            return false
        }
    }
    
    public var value: OutputValue {
        return get()
    }
    
}

public typealias IdenticalProvider<Value> = Provider<Value, Value>

extension Provider {
    
    public func async(dispatchQueue: DispatchQueue) -> AsyncProvider<OutputValue, InputValue> {
        return AsyncProvider(syncProvider: self, dispatchQueue: dispatchQueue)
    }
    
    public func mapInput<OtherInputValue>(_ transform: @escaping (OtherInputValue) -> InputValue) -> Provider<OutputValue, OtherInputValue> {
        return Provider<OutputValue, OtherInputValue>(get: output, input: input.map(transform))
    }
    
    public func flatMapInput<OtherInputValue>(_ transform: @escaping (OtherInputValue) -> InputValue?) -> Provider<OutputValue, OtherInputValue> {
        return Provider<OutputValue, OtherInputValue>(get: self.get,
                                                      set: { try self.set(try transform($0).tryUnwrap()) })
    }
    
    public func mapOutput<OtherOutputValue>(_ transform: @escaping (OutputValue) -> OtherOutputValue) -> Provider<OtherOutputValue, InputValue> {
        return Provider<OtherOutputValue, InputValue>(get: output.map(transform), input: input)
    }
    
    public func map<OtherOutputValue, OtherInputValue>(outputTransform: @escaping (OutputValue) -> OtherOutputValue, inputTransform: @escaping (OtherInputValue) -> InputValue) -> Provider<OtherOutputValue, OtherInputValue> {
        return Provider<OtherOutputValue, OtherInputValue>(get: output.map(outputTransform), input: input.map(inputTransform))
    }
        
}

public extension CachedProvider {
    
    convenience init(_ provider: IdenticalProvider<Value>) {
        self.init(get: provider.get, set: provider.set)
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
