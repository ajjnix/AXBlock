//
// Copyright (c) 2016 Artem Mylnikov (ajjnix)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <XCTest/XCTest.h>
#import "NSString+AX_NSString.h"


@interface AX_NSString_Tests : XCTestCase
@end


@implementation AX_NSString_Tests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testUnformatInt {
    NSString *input = @"NSString:13 helper:32,number32";
    NSString *expected = @"NSString:%@ helper:%@,number%@";
    NSString *result = [input ax_unformatDecToObj];
    XCTAssertEqualObjects(result, expected);
}

- (void)testNumbers {
    NSString *input = @"NSString:13 helper:32,number33";
    NSArray *expected = @[@13, @32, @33];
    NSArray *result = [input ax_numbers];
    XCTAssertEqualObjects(result, expected);
}

- (void)testStringWithFormat {
    NSString *format = @"%@, foo:%@, hello%@";
    NSArray *input = @[@(12), @(13), @" world"];
    NSString *expected = @"12, foo:13, hello world";
    NSString *result = [NSString ax_stringWithFormat:format array:input];
    XCTAssertEqualObjects(result, expected);
}

@end
