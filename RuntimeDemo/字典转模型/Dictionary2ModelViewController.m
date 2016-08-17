//
//  Dictionary2ModelViewController.m
//  RuntimeDemo
//
//  Created by LeeJay on 16/8/15.
//  Copyright © 2016年 LeeJay. All rights reserved.
//

#import "Dictionary2ModelViewController.h"
#import "NSObject+Property.h"
#import "Product.h"
#import "ProductImage.h"
#import "ProductList.h"

@interface Dictionary2ModelViewController ()

@end

@implementation Dictionary2ModelViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    self.view.backgroundColor = [UIColor whiteColor];

    NSString *path = [[NSBundle mainBundle] pathForResource:@"product" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];

    NSDictionary *dataDict = dict[@"product"];
    Product *p = [Product objectWithDictionary:dataDict];
    NSLog(@"%@", p.name);

    for (ProductList *product in p.productList)
    {
        NSLog(@"%@----%@----%.1f", product.name, product.productId, product.price);
        NSLog(@"%@----%@----%.1f----%.1f", product.image.imageUrl, product.image.imageId, product.image.width, product.image.height);
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
