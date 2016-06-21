//
//  LSDTestDBModel.h
//  图文混排和数据库操作
//
//  Created by ls on 16/6/17.
//  Copyright © 2016年 szrd. All rights reserved.
//

#import "LSDDataBaseModel.h"

@interface LSDTestDBModel : LSDDataBaseModel


///
@property(copy,nonatomic)NSString *name;

///
@property(assign,nonatomic)NSInteger age;

///
@property(assign,nonatomic)BOOL isVip;

///
@property(strong,nonatomic)NSArray *dataArray;


@end
