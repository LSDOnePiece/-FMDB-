//
//  ViewController.m
//  数据库模型FMDB封装
//
//  Created by ls on 16/6/21.
//  Copyright © 2016年 szrd. All rights reserved.
//

#import "ViewController.h"
#import "LSDTestModel1.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    [LSDTestModel1 lsd_clearTable];
    
    NSMutableArray *muArray = [NSMutableArray array];
    
    for (int i = 0; i < 10 ; i ++) {
          LSDTestModel1 *model1 = [[LSDTestModel1 alloc]init];
        
        model1.name = [NSString stringWithFormat:@"name%zd",i];
        model1.age = [NSString stringWithFormat:@"age%zd",i];
        model1.vip = 1;
        
        [muArray addObject:model1];
    }
   
    [LSDTestModel1 lsd_saveObjects:muArray.copy];
    
//    NSArray *array = [LSDTestModel1 lsd_findAll];
    [LSDTestModel1 lsd_deleteObjectsByCriteria:@"WHERE age = 'age5'"];
    


}


@end
