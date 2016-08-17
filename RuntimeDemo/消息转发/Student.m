//
//  Student.m
//  RuntimeDemo
//
//  Created by LeeJay on 16/8/17.
//  Copyright © 2016年 LeeJay. All rights reserved.
//

#import "Student.h"

@implementation Student

#pragma mark - 完整的消息转发流程

/**
 消息转发第一步：对象在收到无法解读的消息后，首先调用此方法，可用于动态添加方法，方法决定是否动态添加方法。如果返回YES，则调用class_addMethod动态添加方法，消息得到处理，结束；如果返回NO，则进入下一步；
 */
+ (BOOL)resolveInstanceMethod:(SEL)sel
{
    return NO;
}

/**
 当前接收者还有第二次机会处理未知的选择子，在这一步中，运行期系统会问：能不能把这条消息转给其他接收者来处理。会进入此方法，用于指定备选对象响应这个selector，不能指定为self。如果返回某个对象则会调用对象的方法，结束。如果返回nil，则进入下一步；
 */
- (id)forwardingTargetForSelector:(SEL)aSelector
{
    return nil;
}

/**
 这步我们要通过该方法签名，如果返回nil，则消息无法处理。如果返回methodSignature，则进入下一步。
 */
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    if ([NSStringFromSelector(aSelector) isEqualToString:@"study"])
    {
        return [NSMethodSignature signatureWithObjCTypes:"v@:"];
    }
    return [super methodSignatureForSelector:aSelector];
}

/**
 这步调用该方法，我们可以通过anInvocation对象做很多处理，比如修改实现方法，修改响应对象等，如果方法调用成功，则结束。如果失败，则进入doesNotRecognizeSelector方法。
 */
- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    [anInvocation setSelector:NSSelectorFromString(@"play")];
    [anInvocation invokeWithTarget:self];
}

- (void)play
{
    NSLog(@"---%s---",__func__);
}

/**
 抛出异常，此异常表示选择子最终未能得到处理。
 */
- (void)doesNotRecognizeSelector:(SEL)aSelector
{
    NSLog(@"无法处理消息：%@", NSStringFromSelector(aSelector));
}

@end
