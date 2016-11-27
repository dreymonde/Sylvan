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

public struct Transformer<A, B> {
    
    public let from: (A) -> B
    public let to: (B) -> A
    
    public init(from: @escaping (A) -> B, to: @escaping (B) -> A) {
        self.from = from
        self.to = to
    }
    
}

public enum Transformers { }

public extension Transformers {
    
    static func unwrap<Value>(with nonOptionalValueGetter: @escaping () -> Value) -> Transformer<Value?, Value> {
        return Transformer(from: { $0 ?? nonOptionalValueGetter() }, to: { $0 })
    }
    
}

public extension Transformer {
    
    var optional: Transformer<A?, B?> {
        return Transformer<A?, B?>(from: { (a) -> B? in
            return a.map(self.from)
        }, to: { (b) -> A? in
            return b.map(self.to)
        })
    }
    
}
