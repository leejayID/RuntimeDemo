//
//  MethodSwizzlingViewController.m
//  RuntimeDemo
//
//  Created by LeeJay on 16/8/11.
//  Copyright © 2016年 LeeJay. All rights reserved.
//

#import "MethodSwizzlingViewController.h"

@interface MethodSwizzlingViewController ()

@property (weak, nonatomic) IBOutlet UILabel *contentLabel;

@end

@implementation MethodSwizzlingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.contentLabel.text = @"如果现在有这样一个需求，需要把项目中所有的Label的颜色都改成红色，字体大小都改为15，可以使用UILabel + Category中的思路去实现，这边只提供一种思路，有兴趣的同学可以去拓展！";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
