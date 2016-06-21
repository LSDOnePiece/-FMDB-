//
//  LSDDataBaseManager.h
//  图文混排和数据库操作
//
//  Created by ls on 16/6/16.
//  Copyright © 2016年 szrd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDB/FMDB.h"

@interface LSDDataBaseManager : NSObject

#pragma mark -- 数据库相关
///数据库管理者单例
+(nullable instancetype)sharedManager;

///数据库操作队列
@property(nullable,strong,nonatomic)FMDatabaseQueue *lsd_dbQueue;

/// 数据库文件路径
+ (nullable NSString *)lsd_dataBasePath;



@end
