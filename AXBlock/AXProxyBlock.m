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


@interface AXProxyBlock () <NSCopying>  {
    //isa exist in NSObject
    int _flags;
    int _reserved;
    IMP _invoke;
    struct AXBlockStruct_1 *_descriptor;
    
    AXProxyBlockInterpose _before;
    id _block;
    NSMethodSignature *_blockSignature;
    IMP _blockInvoke;
}

@end


@implementation AXProxyBlock

+ (instancetype)initWithBlock:(id)block {
    return [[self alloc] initWithBlock:block];
}

- (instancetype)initWithBlock:(id)block {
    if (self != nil) {
        self.block = block;
        
        AXBlockStruct *blockRef = (__bridge AXBlockStruct *)block;
        _flags = blockRef->flags;
        _reserved = blockRef->reserved;
        _descriptor = calloc(1, sizeof(AXBlockStruct_1));
        _descriptor->size = class_getInstanceSize([self class]);
        
        BOOL flag_stret = _flags & AXBlockFlag_HasStret;
        _invoke = (flag_stret ? (IMP)_objc_msgForward_stret : (IMP)_objc_msgForward);
        _blockInvoke = (IMP)blockRef->invoke;
        _blockSignature = [self blockSignature];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (NSMethodSignature *)blockSignature {
    const char *signature = [self signatureCTypes];
    return [NSMethodSignature signatureWithObjCTypes:signature];
}

- (const char *)signatureCTypes {
    AXBlockStruct *blockRef = (__bridge AXBlockStruct *)self.block;
    
    const int flags = blockRef->flags;
    
    void *signatureLocation = blockRef->descriptor;
    if (flags & AXBlockFlag_HasSignature) {
        
        signatureLocation += sizeof(unsigned long int);
        signatureLocation += sizeof(unsigned long int);
        
        if (flags & AXBlockFlag_HasCopyDispose) {
            signatureLocation += sizeof(void(*)(void *dst, void *src));
            signatureLocation += sizeof(void (*)(void *src));
        }
    }
    
    return (*(const char **)signatureLocation);
}

- (void)setBlock:(id)block {
    _block = [block copy];
}

- (id)block {
    return _block;
}

- (void)setBefore:(AXProxyBlockInterpose)before {
    _before = [before copy];
}

- (AXProxyBlockInterpose)before {
    return _before;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    return _blockSignature;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    [anInvocation setTarget:_block];
    if (self.before) {
        self.before(anInvocation);
    }
    IMP imp = _blockInvoke;
    [anInvocation invokeUsingIMP:imp];
}

@end
