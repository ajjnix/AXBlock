This is library for use block like method with generating selector for call block.

https://habrahabr.ru/post/276599/

Example
```objective-c
    [button addTarget:self action:[self ax_lambda:^(UIButton *sender, UIEvent *event){
        NSLog(@"click on button %@, event = %@", sender, event);
    }] forControlEvents:UIControlEventTouchUpInside];
```   
``` objective-c
    [button addTarget:self action:[self ax_lambda:^{
        NSLog(@"click");
    }] forControlEvents:UIControlEventTouchUpInside];
```   
``` objective-c
    __block NSInteger sum = 0;
    [self performSelector:[self ax_lambda:^(NSNumber *argA, NSNumber *argB) {
        sum = [argA integerValue] + [argB integerValue];
    }] withObject:@(2) withObject:@(3)];
    //sum — 5
```   
``` objective-c
    SEL selSum = [self ax_lambda:^NSInteger(NSInteger argA, NSInteger argB){
        return argA + argB;
    }];
    NSInteger(*funcSum)(id, SEL, NSInteger, NSInteger) = (NSInteger(*)(id, SEL, NSInteger, NSInteger))objc_msgSend;
    NSInteger sum2 = funcSum(self, selSum, 2, 3);
    //sum2 — 5
```
