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

- (NSString *)ax_unformatDecToObj {
    NSCharacterSet *characterSet = [NSCharacterSet decimalDigitCharacterSet];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"length > 0"];
    NSArray *separated = [[self componentsSeparatedByCharactersInSet:characterSet] filteredArrayUsingPredicate:predicate];
    NSString *format = [[separated componentsJoinedByString:@"%@"] stringByAppendingString:@"%@"];
    return format;
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
    [invocation setSelector:@selector(ax_string:)];
    
    [invocation setArgument:(void*)&format atIndex:2];
    for (NSInteger i = 0; i < [arrayArguments count]; i++) {
        NSNumber *numb = arrayArguments[i];
        [invocation setArgument:(void*)(&numb) atIndex:i+3];
    }
    
    [invocation invoke];
    
    __autoreleasing NSString *string;
    [invocation getReturnValue:&string];
    
    return string;
}

+ (instancetype)ax_string:(NSString *)format, ... {
    va_list list;
    va_start(list, format);
    NSString *str = [[NSString alloc] initWithFormat:format arguments:list];
    va_end(list);
    return str;
}

+ (NSMethodSignature *)ax_generateSignatureForArguments:(NSArray *)arrayArguments {
    NSInteger count = [arrayArguments count];
    NSInteger sizeptr = sizeof(void *);
    NSMutableString *mstring = [[NSMutableString alloc] init];
    NSInteger sumArgInvoke = count + 3;
    [mstring appendFormat:@"@%zd@?0", sumArgInvoke * sizeptr];
    for (NSInteger i = 1; i < sumArgInvoke; i++) {
        [mstring appendFormat:@"@%zd", sizeptr * i];
    }
    return [NSMethodSignature signatureWithObjCTypes:[mstring UTF8String]];
}

@end
