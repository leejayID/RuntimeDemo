//
//  Person+Category.h
//  RuntimeDemo
//
//  Created by LeeJay on 16/8/8.
//  Copyright © 2016年 LeeJay. All rights reserved.
//

#import "Person.h"

@interface Person (Category)

@property (nonatomic, copy) NSString *nickName;
@property (nonatomic, assign) float weight;

@end
