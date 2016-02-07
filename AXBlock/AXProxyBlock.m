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

#import "AXProxyBlock.h"
#import "NSInvocation+AXPrivate_API.h"
#import <objc/message.h>


typedef struct AXBlockStruct_1 {
    unsigned long int reserved;
    unsigned long int size;
    
    void (*copy_helper)(void *dst, void *src);
    void (*dispose_helper)(void *src);
    
    const char *signature;
} AXBlockStruct_1;

typedef struct AXBlockStruct {
    void *isa;
    int flags;
    int reserved;
    void (*invoke)(void *, ...);
    struct AXBlockStruct_1 *descriptor;
} AXBlockStruct;


typedef NS_ENUM(NSUInteger, AXBlockFlag) {
    AXBlockFlag_HasCopyDispose = (1 << 25),
    AXBlockFlag_HasCtor = (1 << 26),
    AXBlockFlag_IsGlobal = (1 << 28),
    AXBlockFlag_HasStret = (1 << 29),
    AXBlockFlag_HasSignature = (1 << 30)
};


@interface AXProxyBlock ()  {
    //isa exist in NSObject
    int _flags;
    int _reserved;
    IMP _invoke;
    AXBlockStruct_1 *_descriptor;
    
    AXProxyBlockInterpose _beforeInvoke;
    id _block;
    NSMethodSignature *_blockMethodSignature;
    IMP _impBlockInvoke;
}

@end


@implementation AXProxyBlock

+ (instancetype)initWithBlock:(id)block {
    return [[self alloc] initWithBlock:block];
}

- (instancetype)initWithBlock:(id)block {
    if (self != nil) {
        AXBlockStruct *blockRef = (__bridge AXBlockStruct *)block;
        _flags = blockRef->flags;
        _reserved = blockRef->reserved;
        _descriptor = calloc(1, sizeof(AXBlockStruct_1));
        _descriptor->size = class_getInstanceSize([self class]);
        
        BOOL flag_stret = _flags & AXBlockFlag_HasStret;
        _invoke = (flag_stret ? (IMP)_objc_msgForward_stret : (IMP)_objc_msgForward);
        
        _block = block;
        _impBlockInvoke = (IMP)blockRef->invoke;
        _blockMethodSignature = [self blockMethodSignature];
    }
    return self;
}

- (void)setBeforeInvoke:(AXProxyBlockInterpose)beforeInvoke {
    _beforeInvoke = beforeInvoke;
}

- (NSMethodSignature *)blockMethodSignature {
    const char *signature = [[self blockSignatureStringCTypes] UTF8String];
    return [NSMethodSignature signatureWithObjCTypes:signature];
}

- (NSString *)blockSignatureStringCTypes {
    AXBlockStruct *blockRef = (__bridge AXBlockStruct *)_block;
    
    const int flags = blockRef->flags;
    
    void *signatureLocation = blockRef->descriptor;
    signatureLocation += sizeof(unsigned long int);
    signatureLocation += sizeof(unsigned long int);
    
    if (flags & AXBlockFlag_HasCopyDispose) {
        signatureLocation += sizeof(void(*)(void *dst, void *src));
        signatureLocation += sizeof(void (*)(void *src));
    }
    
    const char *signature = (*(const char **)signatureLocation);
    return [NSString stringWithUTF8String:signature];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    return _blockMethodSignature;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    [anInvocation setTarget:_block];
    if (_beforeInvoke) {
        _beforeInvoke(anInvocation);
    }
    IMP imp = _impBlockInvoke;
    [anInvocation invokeUsingIMP:imp];
}

@end
