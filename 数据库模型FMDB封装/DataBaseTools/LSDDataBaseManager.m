//
//  LSDDataBaseManager.m
//  图文混排和数据库操作
//
//  Created by ls on 16/6/16.
//  Copyright © 2016年 szrd. All rights reserved.
//

#import "LSDDataBaseManager.h"
@interface LSDDataBaseManager ()

@end

@implementation LSDDataBaseManager

static LSDDataBaseManager *_manager = nil;
#pragma mark -- 单例对象
+(instancetype)sharedManager
{

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (_manager == nil) {
            _manager = [[LSDDataBaseManager alloc]init];
        }
    });
    
    return _manager;
}

#pragma mark -- 数据库管理队列
-(FMDatabaseQueue *)lsd_dbQueue
{
    if (_lsd_dbQueue == nil) {
        _lsd_dbQueue = [FMDatabaseQueue databaseQueueWithPath:[[self class] lsd_dataBasePath]];
    }
    return _lsd_dbQueue;
}

#pragma mark -- 数据库文件路径
+ (NSString *)lsd_dataBasePath
{
    NSString *docsdir = [NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSFileManager *filemanage = [NSFileManager defaultManager];
    ///创建目录
    docsdir = [docsdir stringByAppendingPathComponent:@"LSDDB"];
    BOOL isDir;
    BOOL exit =[filemanage fileExistsAtPath:docsdir isDirectory:&isDir];
    if (!exit || !isDir) {
        [filemanage createDirectoryAtPath:docsdir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    ///创建数据库文件路径
    NSString *dbpath = [docsdir stringByAppendingPathComponent:@"LSDDBSource.db"];
    return dbpath;
}



@end













