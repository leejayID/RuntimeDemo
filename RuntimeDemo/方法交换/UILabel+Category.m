//
//  UILabel+Category.m
//  RuntimeDemo
//
//  Created by LeeJay on 16/8/9.
//  Copyright © 2016年 LeeJay. All rights reserved.
//

#import "UILabel+Category.h"
#import <objc/runtime.h>

@implementation UILabel (Category)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{

        SEL originalSelector = @selector(willMoveToSuperview:);
        SEL swizzledSelector = @selector(myWillMoveToSuperview:);

        Method originalMethod = class_getInstanceMethod(self, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(self, swizzledSelector);

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

- (void)myWillMoveToSuperview:(UIView *)newSuperview
{
    [self myWillMoveToSuperview:newSuperview];
    if (newSuperview != nil)
    {
        [self setFont:[UIFont systemFontOfSize:15]];
        [self setTextColor:[UIColor redColor]];
    }
}

@end
