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
#import "AXLambda.h"
#import <objc/message.h>


@interface AXLambda_Tests : XCTestCase
@end


@implementation AXLambda_Tests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testLambdaFunc {
    const NSInteger a = 3;
    const NSInteger b = 2;
    const NSInteger expected = 5;
    
    __block NSInteger sum = 0;
    NSMutableArray *array = [NSMutableArray array];
    SEL selSum = ax_lambda(self, ^(NSNumber *argA){
        sum = [argA integerValue] + b;
    }, array);
    
    XCTAssertEqual([array count], 1);
    
    [self performSelector:selSum withObject:@(a)];
    XCTAssertEqual(sum, expected);
}

- (void)testLambdaFuncReturn {
    const NSInteger a = 3;
    const NSInteger b = 2;
    const NSInteger expected = 5;
    
    NSMutableArray *array = [NSMutableArray array];
    SEL selSum = ax_lambda(self, ^NSInteger(NSInteger argA, NSInteger argB){
        return argA + argB;
    }, array);
    
    XCTAssertEqual([array count], 1);
    
    NSInteger(*funcSum)(id, SEL, NSInteger, NSInteger) = (NSInteger(*)(id, SEL, NSInteger, NSInteger))objc_msgSend;
    NSInteger sum = funcSum(self, selSum, a, b);
    XCTAssertEqual(sum, expected);
}

- (void)testLambdaFuncReturn2 {
    const NSInteger a = 3;
    const NSInteger b = 2;
    const NSInteger expected = 5;
    
    NSObject *obj = [[NSObject alloc] init];
    SEL selSum = [obj lambda:^NSInteger(NSInteger argA, NSInteger argB){
        return argA + argB;
    }];
    
    NSInteger(*funcSum)(id, SEL, NSInteger, NSInteger) = (NSInteger(*)(id, SEL, NSInteger, NSInteger))objc_msgSend;
    NSInteger sum = funcSum(obj, selSum, a, b);
    XCTAssertEqual(sum, expected);
}

- (void)testLambdaFuncReturn3 {
    const NSInteger a = 3;
    const NSInteger b = 2;
    const NSInteger expectedSum = 5;
    const NSInteger expectedDed = 1;
    NSInteger(*func)(id, SEL, NSInteger, NSInteger) = (NSInteger(*)(id, SEL, NSInteger, NSInteger))objc_msgSend;
    
    NSMutableArray *array = [NSMutableArray array];
    SEL selSum = ax_lambda(self, ^NSInteger(NSInteger argA, NSInteger argB){
        return argA + argB;
    }, array);
    
    SEL selDed = ax_lambda(self, ^NSInteger(NSInteger argA, NSInteger argB){
        return argA - argB;
    }, array);
    
    XCTAssertEqual([array count], 2);
    
    NSInteger sum = func(self, selSum, a, b);
    XCTAssertEqual(sum, expectedSum);
    
    NSInteger ded = func(self, selDed, a, b);
    XCTAssertEqual(ded, expectedDed);
}

- (void)testLambdaNSObject {
    NSObject *object = [[NSObject alloc] init];
    
    const NSInteger a = 3;
    const NSInteger b = 2;
    const NSInteger expected = 5;
    
    __block NSInteger sum = 0;
    SEL selSum = [object lambda:^(NSNumber *argA, NSNumber *argB) {
        sum = [argA integerValue] + [argB integerValue];
    }];
    
    [object performSelector:selSum withObject:@(a) withObject:@(b)];
    XCTAssertEqual(sum, expected);
}

@end
