//
//  ProductImage.h
//  RuntimeDemo
//
//  Created by LeeJay on 16/8/16.
//  Copyright © 2016年 LeeJay. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ProductImage : NSObject

@property (nonatomic, copy) NSString *imageUrl;
@property (nonatomic, assign) float width;
@property (nonatomic, assign) float height;
@property (nonatomic, copy) NSString *imageId;

@end
