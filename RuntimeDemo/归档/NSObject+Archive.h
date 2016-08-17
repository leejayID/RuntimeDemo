//
//  NSObject+Archive.h
//  RuntimeDemo
//
//  Created by LeeJay on 16/8/8.
//  Copyright © 2016年 LeeJay. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (Archive)

/**
 *  归档
 */
- (void)encode:(NSCoder *)aCoder;

/**
 *  解档
 */
- (void)decode:(NSCoder *)aDecoder;

/**
 *  这个数组中的成员变量名将会被忽略：不进行归档
 */
@property (nonatomic, strong) NSArray *ignoredIvarNames;

@end
