//
//  ArchiveViewController.m
//  RuntimeDemo
//
//  Created by LeeJay on 16/8/8.
//  Copyright © 2016年 LeeJay. All rights reserved.
//

#import "ArchiveViewController.h"
#import "NSObject+Archive.h"
#import "Person.h"

@interface ArchiveViewController ()

@end

@implementation ArchiveViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

// 存
- (IBAction)save:(id)sender
{
    Person *p = [Person new];
    p.age = 18;
    p.name = @"LeeJay";
    p.height = 180.0;
    p.Id = @"100";
    // 不需要归档的属性
    p.ignoredIvarNames = @[@"Id"];
    [NSKeyedArchiver archiveRootObject:p toFile:[self createAppendingPath:@"person.data"]];
}

// 取
- (IBAction)read:(id)sender
{
    Person *p = [NSKeyedUnarchiver unarchiveObjectWithFile:[self createAppendingPath:@"person.data"]];
    NSLog(@"我叫%@，我今年%d岁，我的身高是%f，我的Id是%@", p.name, p.age, p.height, p.Id);
}

- (NSString *)createAppendingPath:(NSString *)appendingPath
{
    NSString *searchPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    NSString *filePath = [searchPath stringByAppendingPathComponent:appendingPath];
    return filePath;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
