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

public final class CachedAsyncProvider<Value> {
    
    fileprivate let _get: (@escaping (Value) -> ()) -> Void
    fileprivate let _set: ((Value), @escaping (Error?) -> ()) -> Void
    
    public init(get: @escaping (@escaping (Value) -> ()) -> Void,
                set: @escaping ((Value), @escaping (Error?) -> ()) -> Void) {
        self._get = get
        self._set = set
    }
    
    fileprivate(set) internal var cached: Synchronized<Value?> = .init(nil)
    
    public var cachedValue: Value? {
        return cached.get()
    }
    
    public func get(reloadingCache: Bool = false, completion: @escaping (Value) -> ()) {
        if reloadingCache {
            reloadCache(completion: completion)
            return
        }
        if let cachedValue = cached.get() {
            completion(cachedValue)
        } else {
            reloadCache(completion: completion)
        }
    }
    
    public func reloadCache(completion: @escaping (Value) -> ()) {
        self._get { [unowned self] newValue in
            self.cached.set(newValue)
            completion(newValue)
        }
    }
    
    public func set(_ value: Value, completion: @escaping (Error?) -> () = { _ in }) {
        self.cached.set(value)
        self.pushCache(completion: completion)
    }
    
    public func ungaranteedSet(_ value: Value, completion: @escaping () -> () = { }) {
        _set(value, { _ in completion() })
    }
    
    public func set(with mutation: @escaping (inout Value) -> (), completion: @escaping (Error?) -> () = { _ in }) {
        get { (existing) in
            var mutable = existing
            mutation(&mutable)
            self.cached.set(mutable)
            self.pushCache(completion: completion)
        }
    }
    
    public func pushCache(completion: @escaping (Error?) -> ()) {
        if let cached = cached.get() {
            self._set(cached, completion)
        }
    }
    
    public func clearCached() {
        cached.set(nil)
    }
    
}
