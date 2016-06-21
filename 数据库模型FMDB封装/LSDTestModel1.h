//
//  LSDTestModel1.h
//  数据库模型FMDB封装
//
//  Created by ls on 16/6/21.
//  Copyright © 2016年 szrd. All rights reserved.
//

#import "LSDDataBaseModel.h"

@interface LSDTestModel1 : LSDDataBaseModel

///
@property(copy,nonatomic)NSString *name;

///
@property(copy,nonatomic)NSString *age;

///
@property(assign,nonatomic)BOOL sex;

///
@property(assign,nonatomic)BOOL vip;


@end
