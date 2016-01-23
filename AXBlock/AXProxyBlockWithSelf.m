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

#import "AXProxyBlockWithSelf.h"
#import "NSString+AX_NSString.h"


@implementation AXProxyBlockWithSelf

- (NSMethodSignature *)blockSignature {
    const char *signatureCTypes = strdup([self signatureCTypes]);
    NSString *signature = [NSString stringWithUTF8String:signatureCTypes];
    NSString *unformatObject = [signature ax_unformatDecToObj];
    NSString *formatNewSignature = [self addSelfFormat:unformatObject];
    
    NSArray *byteSignature = [signature ax_numbers];
    NSArray *byteNewSignature = [self changeByteSignature:byteSignature];
    
    NSString *resultSignature = [NSString ax_stringWithFormat:formatNewSignature array:byteNewSignature];
    
    free((void *)signatureCTypes);
    NSMethodSignature *methodSignature = [NSMethodSignature signatureWithObjCTypes:[resultSignature UTF8String]];
    return methodSignature;
}

- (NSString *)addSelfFormat:(NSString *)format {
    NSMutableArray *marray = [[format componentsSeparatedByString:@"?"] mutableCopy];
    [marray insertObject:@"?%@@" atIndex:1];
    return [marray componentsJoinedByString:@""];
}

- (NSArray *)changeByteSignature:(NSArray *)byteSignature {
    NSInteger value = sizeof(void *);
    NSMutableArray *marray = [NSMutableArray array];
    for (NSNumber *number in byteSignature) {
        NSInteger offset = [number integerValue] + value;
        [marray addObject:@(offset)];
    }
    [marray insertObject:@0 atIndex:1];
    return marray;
}

@end
