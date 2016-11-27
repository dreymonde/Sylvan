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

public class CachedProvider<Value> {
    
    fileprivate var _get: () -> Value
    fileprivate var _set: (Value) -> ()
    
    public init(get: @escaping () -> Value, set: @escaping (Value) -> ()) {
        self._get = get
        self._set = set
    }
    
    fileprivate(set) public var cachedValue: Value?
    
    public var value: Value {
        return get()
    }
    
    public func get(reloadingCache: Bool = false) -> Value {
        if reloadingCache {
            return reloadCache()
        }
        if let cachedValue = cachedValue {
            return cachedValue
        } else {
            return reloadCache()
        }
    }
    
    @discardableResult
    public func reloadCache() -> Value {
        let value = _get()
        cachedValue = value
        return value
    }
    
    public func clearCache() {
        cachedValue = nil
    }
    
    public func set(_ value: Value, toCacheOnly: Bool = false) {
        cachedValue = value
        if !toCacheOnly {
            _set(value)
        }
    }
    
    public func pushCache() {
        if let cachedValue = cachedValue {
            self._set(cachedValue)
        }
    }
    
}

