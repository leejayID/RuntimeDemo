//
//  ProductList.h
//  RuntimeDemo
//
//  Created by LeeJay on 16/8/15.
//  Copyright © 2016年 LeeJay. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ProductImage;

@interface ProductList : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *productId;
@property (nonatomic, assign) float price;

@property (nonatomic, strong) ProductImage *image;

@end
