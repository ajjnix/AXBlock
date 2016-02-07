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

#import "NSString+AX_NSString.h"


@implementation NSString (AX_NSString)

- (NSString *)ax_unformatDec {
    NSCharacterSet *characterSet = [NSCharacterSet decimalDigitCharacterSet];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"length > 0"];
    NSArray *separated = [[self componentsSeparatedByCharactersInSet:characterSet] filteredArrayUsingPredicate:predicate];
    NSString *format = [separated componentsJoinedByString:@"%@"];
    if ([[self lastSubstring] isEqualToString:[format lastSubstring]] ) {
        return format;
    } else {
        return [format stringByAppendingString:@"%@"];
    }
}

- (NSString *)lastSubstring {
    NSInteger lastIndex = [self length] - 1;
    return [self substringFromIndex:lastIndex];
}

- (NSArray *)ax_numbers {
    NSString *pattern = @"\\d+";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
    NSRange fullRange = NSMakeRange(0, [self length]);
    NSArray *matches = [regex matchesInString:self options:NSMatchingReportProgress range:fullRange];
    
    NSMutableArray *numbers = [NSMutableArray array];
    for (NSTextCheckingResult *checkingResult in matches) {
        NSRange range = [checkingResult range];
        NSString *numberStr = [self substringWithRange:range];
        NSNumber *number = @([numberStr integerValue]);
        [numbers addObject:number];
    }
    
    return numbers;
}

+ (instancetype)ax_stringWithFormat:(NSString *)format array:(NSArray *)arrayArguments {
    NSMethodSignature *methodSignature = [self ax_generateSignatureForArguments:arrayArguments];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];

    [invocation setTarget:self];
    [invocation setSelector:@selector(stringWithFormat:)];
    
    [invocation setArgument:&format atIndex:2];
    for (NSInteger i = 0; i < [arrayArguments count]; i++) {
        id obj = arrayArguments[i];
        [invocation setArgument:(&obj) atIndex:i+3];
    }
    
    [invocation invoke];
    
    __autoreleasing NSString *string;
    [invocation getReturnValue:&string];
    
    return string;
}

//https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html
+ (NSMethodSignature *)ax_generateSignatureForArguments:(NSArray *)arguments {
    NSInteger count = [arguments count];
    NSInteger sizeptr = sizeof(void *);
    NSInteger sumArgInvoke = count + 3; //self + _cmd + (NSString *)format
    NSInteger offsetReturnType = sumArgInvoke * sizeptr;
    
    NSMutableString *mstring = [[NSMutableString alloc] init];
    [mstring appendFormat:@"@%zd@0:%zd", offsetReturnType, sizeptr];
    for (NSInteger i = 2; i < sumArgInvoke; i++) {
        [mstring appendFormat:@"@%zd", sizeptr * i];
    }
    return [NSMethodSignature signatureWithObjCTypes:[mstring UTF8String]];
}

@end
