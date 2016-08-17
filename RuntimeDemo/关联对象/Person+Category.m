//
//  Person+Category.m
//  RuntimeDemo
//
//  Created by LeeJay on 16/8/8.
//  Copyright © 2016年 LeeJay. All rights reserved.
//

#import "Person+Category.h"
#import <objc/runtime.h>

@implementation Person (Category)

static char *key;

- (NSString *)nickName
{
    return objc_getAssociatedObject(self, key);
}

- (void)setNickName:(NSString *)nickName
{
    objc_setAssociatedObject(self, key, nickName, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (float)weight
{
    return [objc_getAssociatedObject(self, _cmd) floatValue];
}

- (void)setWeight:(float)weight
{
    objc_setAssociatedObject(self, @selector(weight), @(weight), OBJC_ASSOCIATION_ASSIGN);
}

@end
