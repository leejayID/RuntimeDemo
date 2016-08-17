//
//  Person.h
//  RuntimeDemo
//
//  Created by LeeJay on 16/8/8.
//  Copyright © 2016年 LeeJay. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Person : NSObject <NSCoding>

@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) int age;
@property (nonatomic, assign) float height;
@property (nonatomic, copy) NSString *Id;

@end
