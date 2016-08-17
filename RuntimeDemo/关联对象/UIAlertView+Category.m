//
//  UIAlertView+Category.m
//  RuntimeDemo
//
//  Created by LeeJay on 16/8/8.
//  Copyright © 2016年 LeeJay. All rights reserved.
//

#import "UIAlertView+Category.h"
#import <objc/runtime.h>

@implementation UIAlertView (Category)

@dynamic alertViewClicked;

- (void)setAlertViewClicked:(void (^)(UIAlertView *, NSInteger))alertViewClicked
{
    self.delegate = self;
    objc_setAssociatedObject(self, @selector(alertViewClicked), alertViewClicked, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void (^)(UIAlertView *, NSInteger))alertViewClicked
{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (self.alertViewClicked)
    {
        self.alertViewClicked(alertView, buttonIndex);
    }
}

@end
