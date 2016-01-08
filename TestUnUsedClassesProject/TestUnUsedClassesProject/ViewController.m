//
//  ViewController.m
//  TestUnUsedClassesProject
//
//  Created by CatchZeng on 15/12/28.
//  Copyright © 2015年 catch. All rights reserved.
//

#import "ViewController.h"
#import "CATUsedClass.h"
#import "CATUsedClass2.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    CATUsedClass* obj = [[CATUsedClass alloc]init];
    CATUsedClass2* obj2 = [[CATUsedClass2 alloc]init];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
