//
//  LSDDataBaseModel.h
//  图文混排和数据库操作
//
//  Created by ls on 16/6/17.
//  Copyright © 2016年 szrd. All rights reserved.
//

/**
 继承自这个数据库模型的数据模型将在第一次使用的时候创建数据库及表文件
 **/

#import <Foundation/Foundation.h>
#import "LSDDataBaseManager.h"

///SQLite的注意事项:
//SQLite 没有单独的 Boolean 存储类。相反，布尔值被存储为整数 0（false）和 1（true）
//SQLite 没有一个单独的用于存储日期和/或时间的存储类，但 SQLite 能够把日期和时间存储为 TEXT、REAL 或 INTEGER 值。
//存储类	日期格式
//TEXT	格式为 "YYYY-MM-DD HH:MM:SS.SSS" 的日期。
//REAL	从公元前 4714 年 11 月 24 日格林尼治时间的正午开始算起的天数。
//INTEGER	从 1970-01-01 00:00:00 UTC 算起的秒数。

/** SQLite五种数据类型 */
///文本字符串
#define LSD_SQLTEXT     @"TEXT"
///带符号的整数
#define LSD_SQLINTEGER  @"INTEGER"
///浮点数(8字节,小数)
#define LSD_SQLREAL     @"REAL"
///值是一个 blob 数据，完全根据它的输入存储
#define LSD_SQLBLOB     @"BLOB"
///值是一个 NULL值
#define LSD_SQLNULL     @"NULL"
///主键标志
#define LSD_PrimaryKey  @"PRIMARY KEY"
///主键id
#define LSD_PrimaryId   @"pk"


@interface LSDDataBaseModel : NSObject

#pragma mark -- 数据库表文件相关
/** 主键 id */
@property (nonatomic, assign) NSInteger  pk;
/** 列名(键名) */
@property (nullable,strong, readonly, nonatomic) NSMutableArray  *columeNames;
/** 列类型 */
@property (nullable,strong, readonly, nonatomic) NSMutableArray  *columeTypes;

/**
 *  获取该类的所有属性
 */
+ (nullable NSDictionary *)lsd_getPropertys;

/** 获取所有属性，包括主键 */
+ (nullable NSDictionary *)lsd_getAllProperties;

#pragma mark -- 创建表
/**
 * 创建表
 * 如果已经创建，返回YES
 */
+ (BOOL)lsd_createTable;

#pragma mark -- 检查数据库中是否存在表
+(BOOL)lsd_checkTableExistInDataBase;

#pragma mark -- 获取该模型表中的所有列名
/** 表中的字段*/
+ (nullable NSArray *)lsd_getColumns;

/** 保存或更新
 * 如果不存在主键，保存，
 * 有主键，则更新
 */
- (BOOL)lsd_saveOrUpdateObject;

/** 保存单个数据 */
- (BOOL)lsd_saveObject;

/** 批量保存数据 */
+ (BOOL)lsd_saveObjects:(nullable NSArray *)array;

/** 更新修改单个数据 */
- (BOOL)lsd_updateObject;

/** 批量更新修改数据*/
+ (BOOL)lsd_updateObjects:(nullable NSArray *)array;

/** 删除单个数据 */
- (BOOL)lsd_deleteObject;

/** 批量删除数据 */
+ (BOOL)lsd_deleteObjects:(nullable NSArray *)array;

/** 通过条件删除数据 */
+ (BOOL)lsd_deleteObjectsByCriteria:(nullable NSString *)criteria;

/** 清空表 */
+ (BOOL)lsd_clearTable;

/** 查询全部数据 */
+ (nullable NSArray *)lsd_findAll;

/** 通过主键查询 */
+ (nullable instancetype)lsd_findByPK:(NSInteger)inPk;

/** 查找某条数据 */
+ (nullable instancetype)lsd_findFirstByCriteria:(nullable NSString *)criteria;

/** 通过条件查找数据
 * 这样可以进行分页查询 @" WHERE pk > 5 limit 10"
 */
+ (nullable NSArray *)lsd_findByCriteria:(nullable NSString *)criteria;

/** 获取最大值 */
+ (NSInteger)lsd_getMaxOf:(nullable NSString *)columeName;


#pragma mark -如果模型中有些属性不需要在表中创建字段,则必须在子类中重写这个方法
/** 
 如果子类中有一些property不需要创建数据库字段，那么这个方法必须在子类中重写
 */
+ (nullable NSArray *)lsd_transients;



@end
