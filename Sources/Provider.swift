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

public struct Provider<GetValue, SetValue> {
    
    public let getter: Getter<GetValue>
    public let setter: Setter<SetValue>
    
    public init(get: Getter<GetValue>, set: Setter<SetValue>) {
        self.getter = get
        self.setter = set
    }
    
    public init(get: @escaping () -> GetValue, set: @escaping (SetValue) throws -> ()) {
        self.getter = Getter(get)
        self.setter = Setter(set)
    }
    
    public init<Prov : ProviderProtocol>(_ provider: Prov) where Prov.SetValue == SetValue, Prov.GetValue == GetValue {
        self.init(get: provider.get, set: provider.set)
    }
    
    public func get() -> GetValue {
        return getter.get()
    }
    
    public func set(_ value: SetValue) throws {
        return try setter.set(value)
    }
    
    @discardableResult
    public func ungaranteedSet(_ value: SetValue) -> Bool {
        do {
            try setter.set(value)
            return true
        } catch {
            return false
        }
    }
    
    public var value: GetValue {
        return get()
    }
    
}

public typealias IdenticalProvider<Value> = Provider<Value, Value>

extension Provider {
    
    public func async(dispatchQueue: DispatchQueue) -> AsyncProvider<GetValue, SetValue> {
        return AsyncProvider(syncProvider: self, dispatchQueue: dispatchQueue)
    }
    
    public func mapSet<OtherSetValue>(_ transform: @escaping (OtherSetValue) -> SetValue) -> Provider<GetValue, OtherSetValue> {
        return Provider<GetValue, OtherSetValue>(get: getter, set: setter.map(transform))
    }
    
    public func flatMapSet<OtherSetValue>(_ transform: @escaping (OtherSetValue) -> SetValue?) -> Provider<GetValue, OtherSetValue> {
        return Provider<GetValue, OtherSetValue>(get: self.get,
                                                      set: { try self.set(try transform($0).tryUnwrap()) })
    }
    
    public func mapGet<OtherGetValue>(_ transform: @escaping (GetValue) -> OtherGetValue) -> Provider<OtherGetValue, SetValue> {
        return Provider<OtherGetValue, SetValue>(get: getter.map(transform), set: setter)
    }
    
    public func map<OtherGetValue, OtherSetValue>(outputTransform: @escaping (GetValue) -> OtherGetValue, inputTransform: @escaping (OtherSetValue) -> SetValue) -> Provider<OtherGetValue, OtherSetValue> {
        return Provider<OtherGetValue, OtherSetValue>(get: getter.map(outputTransform), set: setter.map(inputTransform))
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
