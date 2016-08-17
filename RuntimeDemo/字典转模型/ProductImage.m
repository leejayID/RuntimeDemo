//
//  ProductImage.m
//  RuntimeDemo
//
//  Created by LeeJay on 16/8/16.
//  Copyright © 2016年 LeeJay. All rights reserved.
//

#import "NSObject+Property.h"
#import "ProductImage.h"

@implementation ProductImage

// imageId替换id
+ (NSDictionary *)replacedKeyFromPropertyName
{
    return @{ @"imageId": @"id" };
}

@end
