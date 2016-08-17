//
//  ProductList.m
//  RuntimeDemo
//
//  Created by LeeJay on 16/8/15.
//  Copyright © 2016年 LeeJay. All rights reserved.
//

#import "NSObject+Property.h"
#import "ProductList.h"

@implementation ProductList

// productId替换id
+ (NSDictionary *)replacedKeyFromPropertyName
{
    return @{ @"productId": @"id" };
}

@end
