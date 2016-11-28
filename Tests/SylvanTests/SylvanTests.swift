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
import XCTest
import Sylvan

class SylvanTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        //// XCTAssertEqual(Sylvan().text, "Hello, World!")
    }
    
    func testInMemoryBasic() {
        let provider = Providers.inMemory(initial: 10)
        provider.ungaranteedSet(15)
        XCTAssertEqual(provider.get(), 15)
    }
    
    func testMap() {
        let intProvider = Providers.inMemory(initial: 10)
        let stringProvider = intProvider
            .flatMapInput({ Int($0) })
            .mapOutput({ String($0) })
        stringProvider.ungaranteedSet("19")
        XCTAssertEqual(stringProvider.get(), "19")
        XCTAssertThrowsError(try stringProvider.set("Alba"))
    }
    
    func testInMemoryBasicAsync() {
        let provider = Providers.inMemory(initial: 10).async(dispatchQueue: .global())
        let expectation = self.expectation(description: "onprovider")
        provider.ungaranteedSet(15) {
            provider.get { number in
                XCTAssertEqual(number, 15)
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 5.0)
    }
    
    func testMapAsync() {
        let intProvider = Providers.inMemory(initial: 10).async(dispatchQueue: .global())
        let stringProvider = intProvider
            .flatMapInput({ Int($0) })
            .mapOutput({ String($0) })
        let expectation = self.expectation(description: "onprov")
        stringProvider.ungaranteedSet("19") {
            stringProvider.get { string in
                XCTAssertEqual(string, "19")
                expectation.fulfill()
            }
        }
        let expectation2 = self.expectation(description: "onprov2")
        stringProvider.set("Alba") { error in
            XCTAssertNotNil(error)
            expectation2.fulfill()
        }
        waitForExpectations(timeout: 5.0)
    }
        
}

#if os(Linux)
extension SylvanTests {
    static var allTests : [(String, (SylvanTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
#endif
