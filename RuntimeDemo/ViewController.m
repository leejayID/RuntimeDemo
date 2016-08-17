//
//  ViewController.m
//  RuntimeDemo
//
//  Created by LeeJay on 16/8/8.
//  Copyright © 2016年 LeeJay. All rights reserved.
//

#import "ArchiveViewController.h"
#import "AssociatedViewController.h"
#import "AutoDictionary.h"
#import "Dictionary2ModelViewController.h"
#import "MethodSwizzlingViewController.h"
#import "ViewController.h"
#import <objc/runtime.h>
#import "Student.h"

typedef NS_ENUM(NSInteger, DemoType) {
    DemoTypeAssociateObject = 0, // 关联对象
    DemoTypeMethodSwizzling,     // 方法交换
    DemoTypeArchive,             // 归档
    DemoTypeDictionary2Model     // 字典转模型
};

@interface ViewController ()

@property (nonatomic, copy) NSArray *datas;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    [self createClass];
    [self dynamicAddMethodsToClass];
    [self messageForwarding];
    
    self.datas = @[@"关联对象", @"方法交换", @"归档", @"字典转模型"];
}

#pragma mark - 动态的创建一个类

- (void)createClass
{
    // 创建一个名为People的类，它是NSObject的子类
    Class People = objc_allocateClassPair([NSObject class], "People", 0);

    // 为该类添加一个eat的方法
    class_addMethod(People, NSSelectorFromString(@"eat"), (IMP) eatFun, "v@:");

    // 注册该类
    objc_registerClassPair(People);

    // 创建一个People的实例对象p
    id p = [[People alloc] init];

    // 调用eat方法
    [p performSelector:@selector(eat)];
}

// 默认方法都有两个隐式参数 self 和 _cmd
void eatFun(id self, SEL _cmd)
{
    NSLog(@"This object is %p", self);
    NSLog(@"Class is %@ ,and super is %@", [self class], [self superclass]);

    Class currentClass = [self class];
    for (int i = 0; i < 5; i++)
    {
        NSLog(@"Folling the isa pointer %d times gives %p", i, currentClass);
        currentClass = object_getClass(currentClass);
    }

    NSLog(@"NSObject‘s class is %p", [NSObject class]);
    NSLog(@"NSObject‘s metaClass is %p", [NSObject class]);
}

#pragma mark - 动态的给某个类添加方法

- (void)dynamicAddMethodsToClass{
    AutoDictionary *dict = [AutoDictionary new];
    dict.string = @"String";
    dict.date = [NSDate date];
    dict.number = @10;
    dict.opaqueObject = @[@"opaqueObject"];
    
    NSLog(@"%@--%@--%@--%@",dict.string,dict.date,dict.number,dict.opaqueObject);
}

#pragma mark - 完整的消息转发流程

- (void)messageForwarding
{
    Student *s = [[Student alloc] init];
    [s performSelector:@selector(study)];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.datas.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell"];
    cell.textLabel.text = self.datas[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    switch (indexPath.row)
    {
        case DemoTypeAssociateObject:
        {
            AssociatedViewController *associated = [[AssociatedViewController alloc] init];
            [self.navigationController pushViewController:associated animated:YES];
            break;
        }

        case DemoTypeMethodSwizzling:
        {
            MethodSwizzlingViewController *methodSwizzling = [[MethodSwizzlingViewController alloc] init];
            [self.navigationController pushViewController:methodSwizzling animated:YES];
            break;
        }

        case DemoTypeArchive:
        {
            ArchiveViewController *archive = [[ArchiveViewController alloc] init];
            [self.navigationController pushViewController:archive animated:YES];
            break;
        }
        case DemoTypeDictionary2Model:
        {
            Dictionary2ModelViewController *Dictionary2Model = [[Dictionary2ModelViewController alloc] init];
            [self.navigationController pushViewController:Dictionary2Model animated:YES];
            break;
        }
        default:
            break;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
