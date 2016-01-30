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

#import "AXLambda.h"
#import <objc/runtime.h>
#import "AXProxyBlock.h"
#import "AXProxyBlockWithSelf.h"


static char kAX_NSObjectAssociatedObjectKey;


@interface NSObject (_AX_Lambda)

@property (copy, nonatomic) NSMutableArray *ax_lambdas;

@end


@implementation NSObject (_AX_Lambda)

@dynamic ax_lambdas;

- (void)setAx_lambdas:(NSMutableArray *)lambdas {
    objc_setAssociatedObject(self, &kAX_NSObjectAssociatedObjectKey, lambdas, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSMutableArray *)ax_lambdas {
    NSMutableArray *marrey = objc_getAssociatedObject(self, &kAX_NSObjectAssociatedObjectKey);
    if (marrey == nil) {
        self.ax_lambdas = [NSMutableArray array];
    }
    return objc_getAssociatedObject(self, &kAX_NSObjectAssociatedObjectKey);
}

@end

@implementation NSObject (AX_Lambda)

- (SEL)ax_lambda:(id)block {
    return ax_lambda(self, block, self.ax_lambdas);
}

@end



SEL ax_generateFreeSelector(id self);
void ax_offsetArgInInvocation(NSInvocation *invocation);

SEL ax_lambda(id obj, id block, NSMutableArray *lambdas) {
    SEL selector = ax_generateFreeSelector(obj);
    
    AXProxyBlockWithSelf *proxyBlock = [AXProxyBlockWithSelf initWithBlock:block];
    proxyBlock.before = ^(NSInvocation *invocation){
        ax_offsetArgInInvocation(invocation);
    };
    [lambdas addObject:proxyBlock];
    
    IMP imp = imp_implementationWithBlock(proxyBlock);
    NSString *signatureString = [proxyBlock signatureStringWithSelf];
    class_addMethod([obj class], selector, imp, [signatureString UTF8String]);
    
    return selector;
}

SEL ax_generateFreeSelector(id obj) {
    SEL selector;
    NSMutableString *mstring = [NSMutableString string];
    do {
        [mstring setString:@"ax_rundom_selector"];
        u_int32_t rand = arc4random_uniform(UINT32_MAX);
        [mstring appendFormat:@"%zd", rand];
        selector = NSSelectorFromString(mstring);
    } while ([obj respondsToSelector:selector]);
    return selector;
}

void ax_offsetArgInInvocation(NSInvocation *invocation) {
    void *foo = malloc(sizeof(void*));
    NSInteger arguments = [invocation.methodSignature numberOfArguments];
    for (NSInteger i = 1; i < arguments-1; i++) { //i = 0 is self
        [invocation getArgument:foo atIndex:i+1];
        [invocation setArgument:foo atIndex:i];
    }
    
    free(foo);
}
