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

public class AsyncCachedProvider<Value> {
    
    fileprivate let _get: (@escaping (Value) -> ()) -> Void
    fileprivate let _set: ((Value), @escaping () -> ()) -> Void
    
    fileprivate let queue = DispatchQueue(label: "AsyncCachedProvider\(Value.self)")
    
    public init(get: @escaping (@escaping (Value) -> ()) -> Void,
                set: @escaping ((Value), @escaping () -> ()) -> Void) {
        self._get = get
        self._set = set
    }
    
    fileprivate(set) public var cachedValue: Value?
    
    public func get(reloadingCache: Bool = false, completion: @escaping (Value) -> ()) {
        if reloadingCache {
            reloadCache(completion: completion)
            return
        }
        if let cachedValue = cachedValue {
            completion(cachedValue)
        } else {
            reloadCache(completion: completion)
        }
    }
    
    public func reloadCache(completion: @escaping (Value) -> ()) {
        queue.async {
            self._get { [unowned self] newValue in
                self.cachedValue = newValue
                completion(newValue)
            }
        }
    }
    
    public func set(_ value: Value, completion: (() -> ())? = nil) {
        queue.async {
            self.cachedValue = value
            self.sync_pushCache(completion: completion ?? { })
        }
    }
    
    public func set(with mutation: @escaping (inout Value) -> (), completion: (() -> ())? = nil) {
        get { (existing) in
            var mutable = existing
            mutation(&mutable)
            self.cachedValue = mutable
            self.sync_pushCache(completion: completion ?? { })
        }
    }
    
    private func sync_pushCache(completion: @escaping () -> ()) {
        if let cachedValue = self.cachedValue {
            self._set(cachedValue, {  })
            completion()
            return
        }
        completion()
    }
    
    public func pushCache(completion: @escaping () -> ()) {
        queue.async { self.sync_pushCache(completion: completion) }
    }
    
    public func clearCached() {
        cachedValue = nil
    }
    
}
