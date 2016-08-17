//
//  NSMutableArray+Category.m
//  RuntimeDemo
//
//  Created by LeeJay on 16/8/9.
//  Copyright © 2016年 LeeJay. All rights reserved.
//

#import "NSMutableArray+Category.h"
#import <objc/runtime.h>

@implementation NSMutableArray (Category)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{

        SEL originalSelector = @selector(addObject:);
        SEL swizzledSelector = @selector(lj_AddObject:);

        // NSMutableArray是类簇，真正的类名是__NSArrayM。
        Method originalMethod = class_getInstanceMethod(objc_getClass("__NSArrayM"), originalSelector);
        Method swizzledMethod = class_getInstanceMethod(objc_getClass("__NSArrayM"), swizzledSelector);

        if (!originalMethod)
        {
            NSLog(@"original method %@ not found for class %@", NSStringFromSelector(originalSelector), [self class]);
        }

        if (!swizzledMethod)
        {
            NSLog(@"swizzled method %@ not found for class %@", NSStringFromSelector(swizzledSelector), [self class]);
        }

        BOOL didAddMethod = class_addMethod(self,
                                            originalSelector,
                                            method_getImplementation(swizzledMethod),
                                            method_getTypeEncoding(swizzledMethod));

        if (didAddMethod)
        {
            class_replaceMethod(self,
                                swizzledSelector,
                                method_getImplementation(originalMethod),
                                method_getTypeEncoding(originalMethod));
        }
        else
        {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }

    });
}

- (void)lj_AddObject:(id)object
{
    if (object != nil)
    {
        [self lj_AddObject:object];
    }
}

@end
