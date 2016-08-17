//
//  UIAlertView+Category.h
//  RuntimeDemo
//
//  Created by LeeJay on 16/8/8.
//  Copyright © 2016年 LeeJay. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIAlertView (Category) <UIAlertViewDelegate>

@property (nonatomic, copy) void (^alertViewClicked) (UIAlertView *, NSInteger);

@end
