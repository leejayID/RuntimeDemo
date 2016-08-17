//
//  AutoDictionary.h
//  RuntimeDemo
//
//  Created by LeeJay on 16/8/9.
//  Copyright © 2016年 LeeJay. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AutoDictionary : NSObject

@property (nonatomic, strong) NSString *string;
@property (nonatomic, strong) NSNumber *number;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) id opaqueObject;

@end
