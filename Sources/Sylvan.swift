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

public protocol InputProviderProtocol {
    
    associatedtype InputValue
    
    func set(_ value: InputValue) throws
    
}

public protocol OutputProviderProtocol {
    
    associatedtype OutputValue
    
    func get() -> OutputValue
    
}

public typealias ProviderProtocol = InputProviderProtocol & OutputProviderProtocol

public protocol AsyncOutputProviderProtocol {
    
    associatedtype OutputValue
    
    func get(completion: (OutputValue) -> ())
    
}

public protocol AsyncInputProviderProtocol {
    
    associatedtype InputValue
    
    func set(_ value: InputValue, completion: (Error?) -> ())
    
}

public typealias AsyncProviderProtocol = AsyncOutputProviderProtocol & AsyncInputProviderProtocol

internal struct Synchronized<Value> {
    
    fileprivate let accessQueue: DispatchQueue
    fileprivate var value: Value
    
    internal init(_ value: Value, queueLabel: String = "\(Value.self)SynchronizedQueue") {
        self.value = value
        self.accessQueue = DispatchQueue(label: queueLabel)
    }
    
    internal func get() -> Value {
        return accessQueue.sync(execute: { return value })
    }
    
    internal mutating func set(_ value: Value) {
        accessQueue.sync {
            self.value = value
        }
    }
    
    internal mutating func set(_ change: (inout Value) -> ()) {
        accessQueue.sync {
            change(&value)
        }
    }
    
}
