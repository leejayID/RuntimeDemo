//
//  AssociatedViewController.m
//  RuntimeDemo
//
//  Created by LeeJay on 16/8/17.
//  Copyright © 2016年 LeeJay. All rights reserved.
//

#import "AssociatedViewController.h"
#import "Person+Category.h"
#import "UIAlertView+Category.h"

@interface AssociatedViewController ()

@property (nonatomic, strong) Person *p;

@end

@implementation AssociatedViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    _p = [[Person alloc] init];
}

- (IBAction)btnClick:(id)sender
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"关联对象" delegate:self cancelButtonTitle:nil otherButtonTitles:@"确定", nil];
    [alert show];
    __weak typeof(self) weakSelf = self;
    alert.alertViewClicked = ^(UIAlertView *alertView, NSInteger buttonIndex) {
        weakSelf.p.nickName = @"LeeJay";
        weakSelf.p.weight = 60;

        NSLog(@"对象关联成功咯--nickName：%@，weight%.1f", weakSelf.p.nickName, weakSelf.p.weight);
    };
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
