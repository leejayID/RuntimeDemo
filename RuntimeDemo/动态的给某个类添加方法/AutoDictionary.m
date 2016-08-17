//
//  AutoDictionary.m
//  RuntimeDemo
//
//  Created by LeeJay on 16/8/9.
//  Copyright © 2016年 LeeJay. All rights reserved.
//

#import "AutoDictionary.h"
#import <objc/runtime.h>

@interface AutoDictionary ()

@property (nonatomic, strong) NSMutableDictionary *backingStore;

@end

@implementation AutoDictionary

@dynamic string, date, number, opaqueObject;

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _backingStore = [NSMutableDictionary new];
    }
    return self;
}

+ (BOOL)resolveInstanceMethod:(SEL)sel
{
    NSString *sel_string = NSStringFromSelector(sel);
    if ([sel_string hasPrefix:@"set"])
    {
        /**
         *  动态的给某个类添加方法
         *
         *  @param self  给哪个类添加方法
         *  @param sel   添加方法的方法编号（选择子）
         *  @param IMP   添加方法的函数实现(函数地址)
         *  @param types 函数的类型,(返回值+参数类型) v:void @:对象->self :表示SEL->_cmd
         */
        class_addMethod(self, sel, (IMP) autoDictionarySetter, "v@:@");
    }
    
    else
    {
        class_addMethod(self, sel, (IMP) autoDictionaryGetter, "@@:");
    }
    return YES;
}

// setter
id autoDictionaryGetter(id self, SEL _cmp)
{
    AutoDictionary *typedSelf = (AutoDictionary *) self;
    NSMutableDictionary *backingStore = typedSelf.backingStore;
    NSString *key = NSStringFromSelector(_cmp);
    return [backingStore objectForKey:key];
}

// getter
void autoDictionarySetter(id self, SEL _cmp, id value)
{
    AutoDictionary *typedSelf = (AutoDictionary *) self;
    NSMutableDictionary *backingStore = typedSelf.backingStore;
    NSString *key = NSStringFromSelector(_cmp);
    NSMutableString *mutableKey = [key mutableCopy];

    [mutableKey deleteCharactersInRange:NSMakeRange(mutableKey.length - 1, 1)];
    [mutableKey deleteCharactersInRange:NSMakeRange(0, 3)];
    NSString *lower = [[mutableKey substringToIndex:1] lowercaseString];
    [mutableKey replaceCharactersInRange:NSMakeRange(0, 1) withString:lower];

    if (value)
    {
        [backingStore setObject:value forKey:mutableKey];
    }
    else
    {
        [backingStore removeObjectForKey:mutableKey];
    }
}

@end
