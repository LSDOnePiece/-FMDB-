//
//  LSDDataBaseModel.m
//  图文混排和数据库操作
//
//  Created by ls on 16/6/17.
//  Copyright © 2016年 szrd. All rights reserved.
//

#import "LSDDataBaseModel.h"
#import <objc/runtime.h>

@implementation LSDDataBaseModel

//这个方法在类使用的时候只调用一次
+(void)initialize
{
    if (self != [LSDDataBaseModel self] ) {
        ///创建表
        [self lsd_createTable];

    }
}

-(instancetype)init
{
    
    if (self = [super init]) {
        NSDictionary *dic = [[self class] lsd_getAllProperties];
        _columeNames = [[NSMutableArray alloc] initWithArray:[dic objectForKey:@"name"]];
        _columeTypes = [[NSMutableArray alloc] initWithArray:[dic objectForKey:@"type"]];
    }
    return self;
}

#pragma mark -- 创建表
/**
 * 创建表
 * 如果已经创建，返回YES
 */
+ (BOOL)lsd_createTable
{
    ///创建数据库表
    FMDatabase *db = [FMDatabase databaseWithPath:[LSDDataBaseManager lsd_dataBasePath]];
    if (![db open]) {
        LSDLog(@"数据库打开失败!");
        return  NO;
    }
    
    ///一个model创建的表的表名就是它的类名
    NSString *tableName = NSStringFromClass([self class]);
    ///获取创建表的拼接sql语句
    NSString *columeAndType = [[self class] getColumeAndTypeString];

    ///创建表的sql语句拼接
    NSString *createSqlString = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@(%@);",tableName,columeAndType];
//    LSDLog(@"CREATE TABLE SQL语句:%@",createSqlString);
    if (![db executeUpdate:createSqlString]) {
        [db close];
        return NO;
    }
    
    #pragma mark -- 以下的操作是检查属性中不在表中作为键名的剩余属性 然后添加额外的列
    NSMutableArray *columns = [NSMutableArray array];
    ///根据表明来获取到表中的所有键名及类型
    FMResultSet *resultSet = [db getTableSchema:tableName];
    
    while ([resultSet next]) {
        NSString *column = [resultSet stringForColumn:@"name"];
//        LSDLog(@"resultSet:%@",column);
        [columns addObject:column];
    }
    
    NSDictionary *dict = [self lsd_getAllProperties];
    
    NSArray *proNames = [dict objectForKey:@"name"];
    
    ///不包含在表中的属性名
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"NOT (SELF IN %@)",columns];
    ///从属性名数组中取出不在表中作为键名的属性数组
    NSArray *resultArray = [proNames filteredArrayUsingPredicate:predicate];
    
    for (NSString *column  in resultArray) {
        NSUInteger index = [proNames indexOfObject:column];
        NSString *proType = [[dict objectForKey:@"type"] objectAtIndex:index];
        
        NSString *fieldSqlString = [NSString stringWithFormat:@"%@ %@",column,proType];
//   在 SQLite 中，除了重命名表和在已有的表中添加列，ALTER TABLE 命令不支持其他操作。
        NSString *sqlString = [NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@ ",NSStringFromClass([self class]),fieldSqlString];
        
//        LSDLog(@"ALTER TABLE SQL语句:%@",sqlString);
        if (![db executeUpdate:sqlString]) {
            [db close];
            return NO;
        }
       
    }
    
    [db close];
    return YES;
    
}

#pragma mark -- 检查数据库中是否存在表
+(BOOL)lsd_checkTableExistInDataBase
{
    ///使用__block可以修改block中的局部变量
    __block BOOL res = NO;
    
    LSDDataBaseManager *manager = [LSDDataBaseManager sharedManager];
    
    [manager.lsd_dbQueue inDatabase:^(FMDatabase *db) {
        NSString *tableName = NSStringFromClass([self class]);
        res = [db tableExists:tableName];
    }];
    
    return res;
    
}

#pragma mark -- 获取该模型表中的所有列名
+(NSArray *)lsd_getColumns
{

    LSDDataBaseManager *manager = [LSDDataBaseManager sharedManager];
   
    NSMutableArray *columns = [NSMutableArray array];
    [manager.lsd_dbQueue inDatabase:^(FMDatabase *db) {
       
      FMResultSet *resultSet =  [db getTableSchema:NSStringFromClass([self class])];
        
        while ([resultSet next]) {
          NSString *column =  [resultSet stringForColumn:@"name"];
            [columns addObject:column];
        }
        
    }];
    return [columns copy];
}

#pragma mark -- 获取该模型类的所有属性
+ (nullable NSDictionary *)lsd_getPropertys
{
    ///存放属性名的可变数组
    NSMutableArray *proNames = [NSMutableArray array];
    ///存放属性类型的可变数组
    NSMutableArray *proTypes = [NSMutableArray array];
    NSArray *theTransients = [[self class] lsd_transients];
    ///获取当前类的所有属性
    unsigned int outCount;
    objc_property_t *properties = class_copyPropertyList([self class], &outCount);
    
    for (int i = 0; i < outCount ; i ++) {
        objc_property_t property = properties[i];
        #pragma mark - 获取属性名称(列名)
        ///获取属性名
        NSString *propertyName = [NSString stringWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
        
        if ([theTransients containsObject:propertyName]) {
            ///如果包括这个属性名
            continue;
        }
        
        [proNames addObject:propertyName];
        
        #pragma mark - 获取属性类型(列类型)
        NSString *propertyType = [NSString stringWithCString:property_getAttributes(property) encoding:NSUTF8StringEncoding];
        
//        LSDLog(@"propertyType -- %@",propertyType);
        
        /*
         c char         C unsigned char
         i int          I unsigned int
         l long         L unsigned long
         s short        S unsigned short
         d double       D unsigned double
         f float        F unsigned float
         q long long    Q unsigned long long
         B BOOL
         @ 对象类型 //指针 对象类型 如NSString 是@“NSString”
         
         64位下long 和long long 都是Tq
         SQLite 默认支持五种数据类型TEXT、INTEGER、REAL、BLOB、NULL
         */
        if ([propertyType hasPrefix:@"T@"]) {
            ///字符串类型
            [proTypes addObject:LSD_SQLTEXT];
        }
        else if([propertyType hasPrefix:@"Ti"]||[propertyType hasPrefix:@"TI"]||[propertyType hasPrefix:@"Ts"]||[propertyType hasPrefix:@"TS"]||[propertyType hasPrefix:@"TB"])
        {
            ///整数数据类型
            [proTypes addObject:LSD_SQLINTEGER];
            
        }
        else
        {
            ///浮点数数据类型
            [proTypes addObject:LSD_SQLREAL];
        }
        
    }
    
    free(properties);
    ///将这两个数组存放到一个字典中返回
    return [NSDictionary dictionaryWithObjectsAndKeys:proNames,@"name",proTypes,@"type", nil];
}

#pragma mark -- 获取所有属性 然后添加主键pk键名及类型到数组中
+(NSDictionary *)lsd_getAllProperties
{

    NSDictionary *dict = [self lsd_getPropertys];
    
    NSMutableArray *proNames = [NSMutableArray array];
    NSMutableArray *proTypes = [NSMutableArray array];
    
    [proNames addObject:LSD_PrimaryId];
    [proTypes addObject:[NSString stringWithFormat:@"%@ %@",LSD_SQLINTEGER,LSD_PrimaryKey]];
    
    [proNames addObjectsFromArray:[dict objectForKey:@"name"]];
    [proTypes addObjectsFromArray:[dict objectForKey:@"type"]];
    
    return [NSDictionary dictionaryWithObjectsAndKeys:proNames,@"name",proTypes,@"type", nil];
    
    
}


#pragma mark -- 拼接键名和类型的sql语句即()里的语句
+ (NSString *)getColumeAndTypeString
{
    NSMutableString *sqlString = [NSMutableString string];
    NSDictionary *dict = [self lsd_getAllProperties];
    
    NSMutableArray *proNames = [dict objectForKey:@"name"];
    NSMutableArray *proTypes = [dict objectForKey:@"type"];
    
    for (int i = 0; i < proNames.count ; i ++) {
        
        [sqlString appendFormat:@"%@ %@",[proNames objectAtIndex:i],[proTypes objectAtIndex:i]];
        if(i+1 != proNames.count)
        {
            [sqlString appendString:@","];
        }
    }
   
    return sqlString;
}

#pragma mark -如果模型中有些属性不需要在表中创建字段,则必须在子类中重写这个方法
/**
 如果子类中有一些property不需要创建数据库字段，那么这个方法必须在子类中重写
 */
+ (nullable NSArray *)lsd_transients
{
    return [NSArray array];
}

#pragma mark - 增删改查操作
-(BOOL)lsd_saveOrUpdateObject
{
    id primaryValue = [self valueForKey:LSD_PrimaryId];
    
    if ([primaryValue integerValue] <= 0) {
        ///根据主键的有无来判断是执行添加还是修改操作
        return [self lsd_saveObject];
    }
    return [self lsd_updateObject];
    
}

#pragma mark -- 插入保存新数据
-(BOOL)lsd_saveObject
{
    NSString *tableName = NSStringFromClass([self class]);
    
    NSMutableString *keyString = [NSMutableString string];
    NSMutableString *valueString = [NSMutableString string];
    NSMutableArray *insertValues = [NSMutableArray array];
    
    for (int i = 0; i < self.columeNames.count ; i ++) {
        NSString *proName = [self.columeNames objectAtIndex:i];
        if ([proName isEqualToString:LSD_PrimaryId]) {
            continue;
        }
        
        [keyString appendFormat:@"%@,",proName];
        [valueString appendFormat:@"?,"];
        
        id value = [self valueForKey:proName];
        if (value == nil) {
            value = @"";
        }
        
        [insertValues addObject:value];
    
    }
    
    ///移除掉多余的逗号
    [keyString deleteCharactersInRange:NSMakeRange(keyString.length - 1, 1)];
    [valueString deleteCharactersInRange:NSMakeRange(valueString.length - 1, 1)];
    
    LSDDataBaseManager *manager = [LSDDataBaseManager sharedManager];
    
    __block BOOL res = NO;
    [manager.lsd_dbQueue inDatabase:^(FMDatabase *db) {
        
        ///拼接插入数据的sql语句
        NSString *insertSqlString = [NSString stringWithFormat:@"INSERT INTO %@(%@) VALUES (%@);",tableName,keyString,valueString];
       
        LSDLog(@"插入保存数据 sql语句:%@",insertSqlString);
        
        ///执行插入语句
        res = [db executeUpdate:insertSqlString withArgumentsInArray:insertValues];
        
        self.pk = res ? [NSNumber numberWithLongLong:db.lastInsertRowId].integerValue : 0;
        
        if (res)
        {
            LSDLog(@"插入数据成功!");
        }else
        {
            LSDLog(@"插入数据失败!");
        }
        
    }];
    
    return  res;
}

#pragma mark -- 批量保存用户对象
+(BOOL)lsd_saveObjects:(NSArray *)array
{

    for (LSDDataBaseModel *model in array) {
        if (![model isKindOfClass:[LSDDataBaseModel class]]) {
            return NO;
        }
    }
    
    __block BOOL res = YES;
    LSDDataBaseManager *manager  = [LSDDataBaseManager sharedManager];
    
    [manager.lsd_dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
       
        for (LSDDataBaseModel *model in array) {
            NSString *tableName = NSStringFromClass([self class]);
            NSMutableString *keyString = [NSMutableString string];
            NSMutableString *valueString = [NSMutableString string];
            NSMutableArray *insertValues = [NSMutableArray array];
 
            for (int i = 0; i < model.columeNames.count ; i ++) {
                NSString *proName = [model.columeNames objectAtIndex:i];
                if ([proName isEqualToString:LSD_PrimaryId]) {
                    continue;
                }
                [keyString appendFormat:@"%@,",proName];
                [valueString appendFormat:@"?,"];
                
                id value = [model valueForKey:proName];
                if (value == nil) {
                    value = @"";
                }
                [insertValues addObject:value];
            }
            
            [keyString deleteCharactersInRange:NSMakeRange(keyString.length - 1, 1)];
            [valueString deleteCharactersInRange:NSMakeRange(valueString.length - 1, 1)];
            
            NSString *insertSqlString = [NSString stringWithFormat:@"INSERT INTO %@(%@) VALUES (%@);",tableName,keyString,valueString];
            
//            LSDLog(@"批量插入数据方法 sql语句:%@",insertSqlString);
            
            BOOL flag = [db executeUpdate:insertSqlString withArgumentsInArray:insertValues];
            
            ///设置主键keyid
            model.pk = flag?[NSNumber numberWithLongLong:db.lastInsertRowId].intValue : 0;
            if (flag) {
                LSDLog(@"插入成功!");
            }else
            {
                LSDLog(@"插入失败!");
            }
            
            if (!flag) {
                res = NO;
                *rollback = YES;
                return ;
            }
        }
        
    }];
    
    return YES;
    
}

#pragma mark -- 修改更新单个对象数据
-(BOOL)lsd_updateObject
{

    LSDDataBaseManager *manager = [LSDDataBaseManager sharedManager];
    
    __block BOOL res = NO;
    
    
    [manager.lsd_dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        NSString *tableName = NSStringFromClass([self class]);
        
        id primaryId = [self valueForKey:LSD_PrimaryId];
        if (!primaryId || [primaryId integerValue] <= 0) {
            return ;
        }
        
        NSMutableString *keyString = [NSMutableString string];
        NSMutableArray *updateValues = [NSMutableArray array];
        
        for (int i = 0; i < self.columeNames.count ; i ++) {
            NSString *proName = [self.columeNames objectAtIndex:i];
            if ([proName isEqualToString:LSD_PrimaryId]) {
                ///跳过
                continue;
            }
            [keyString appendFormat:@" %@=?,",proName];
            
            id value = [self valueForKey:proName];
            if (value == nil) {
                value = @"";
            }
            
            [updateValues addObject:value];
            
        }
        
        [keyString deleteCharactersInRange:NSMakeRange(keyString.length - 1, 1)];
        
        ///根据主键id来定位数据进行查找修改
        NSString *updateSqlString = [NSString stringWithFormat:@"UPDATE %@ SET %@ WHERE %@ = ?;",tableName,keyString,LSD_PrimaryId];
        
        [updateValues addObject:primaryId];
        
        res = [db executeUpdate:updateSqlString withArgumentsInArray:updateValues];
        
        if (res) {
            LSDLog(@"修改数据成功!");
        }else
        {
            
            LSDLog(@"修改数据失败!");
            res = NO;
            *rollback = YES;
            return;
            
        }
        
    }];
   
    return res;

}

#pragma mark -- 批量修改对象数据
+(BOOL)lsd_updateObjects:(NSArray *)array
{

    for (LSDDataBaseModel *model in array) {
        if (![model isKindOfClass:[LSDDataBaseModel class]]) {
            return NO;
        }
    }
    
    __block BOOL res = YES;
    
    LSDDataBaseManager *manager = [LSDDataBaseManager sharedManager];
    
    [manager.lsd_dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
       
        for (LSDDataBaseModel *model in array) {
            NSString *tableName = NSStringFromClass([self class]);
         id primaryId = [model valueForKey:LSD_PrimaryId];
        if (!primaryId || [primaryId integerValue] <= 0) {
            
            res = NO;
            *rollback = YES;
            return ;
        }
         
            NSMutableString *keyString = [NSMutableString string];
            NSMutableArray *updateValues = [NSMutableArray array];
            
            for (int i = 0; i < model.columeNames.count ; i ++) {
                NSString *proName = [model.columeNames objectAtIndex:i];
                if ([proName isEqualToString:LSD_PrimaryId]) {
                    continue;
                }
                
                [keyString appendFormat:@" %@=?,",proName];
                id value = [model valueForKey:proName];
                if (value == nil) {
                    value = @"";
                }
                
                [updateValues addObject:value];
                
            }
            
            [keyString deleteCharactersInRange:NSMakeRange(keyString.length - 1, 1)];
            
            NSString *updateSqlString = [NSString stringWithFormat:@"UPDATE %@ SET %@ WHERE %@=?;",tableName,keyString,LSD_PrimaryId];
            
            [updateValues addObject:primaryId];
            
            BOOL flag = [db executeUpdate:updateSqlString withArgumentsInArray:updateValues];
            
            if (flag) {
                LSDLog(@"更新修改数据成功!");
            }else
            {
                LSDLog(@"更新修改数据失败!");
            }
            
        }
        
    }];
    
    return res;
}

#pragma mark -- 删除单个对象数据
-(BOOL)lsd_deleteObject
{

    LSDDataBaseManager *manager = [LSDDataBaseManager sharedManager];
    __block BOOL res = NO;
    [manager.lsd_dbQueue inDatabase:^(FMDatabase *db) {
        NSString *tableName = NSStringFromClass([self class]);
        id primaryId = [self valueForKey:LSD_PrimaryId];
        if (!primaryId || [primaryId integerValue] <= 0) {
           
            return ;
        }
        
        NSString *deleteSqlString = [NSString stringWithFormat:@"DELETE * FROM %@ WHERE %@ = ?",tableName,LSD_PrimaryId];
        res = [db executeUpdate:deleteSqlString withArgumentsInArray:@[primaryId]];
        if (res) {
            LSDLog(@"删除数据成功!");
        }else
        {
            LSDLog(@"删除数据失败!");
        }
        
        
    }];
    return res;
}

#pragma mark -- 删除多个对象数据
+(BOOL)lsd_deleteObjects:(NSArray *)array
{

    for (LSDDataBaseModel *model in array) {
        if (![model isKindOfClass:[LSDDataBaseModel class]]) {
            return NO;
        }
    }
    
    __block BOOL res = YES;
    LSDDataBaseManager *manager = [LSDDataBaseManager sharedManager];
    [manager.lsd_dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        for (LSDDataBaseModel *model in array) {
         
            NSString *tableName = NSStringFromClass([model class]);
            id primaryId = [model valueForKey:LSD_PrimaryId];
            if (!primaryId || [primaryId integerValue] <= 0) {
                return ;
            }
            
            NSString *deleteSqlString = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = ?",tableName,LSD_PrimaryId];
            
            BOOL flag = [db executeUpdate:deleteSqlString withArgumentsInArray:@[primaryId]];
            
            if (flag) {
                LSDLog(@"删除数据成功!");
            }else
            {
                LSDLog(@"删除数据失败");
                ///失败后回滚
                res = NO;
                *rollback = YES;
                return;
            }
            
        }
        
    }];
    
    return res;
}

#pragma mark -- 通过条件删除数据
+(BOOL)lsd_deleteObjectsByCriteria:(NSString *)criteria
{

    LSDDataBaseManager *manager = [LSDDataBaseManager sharedManager];
    
    __block BOOL res = NO;
    
    [manager.lsd_dbQueue inDatabase:^(FMDatabase *db) {
    
        NSString *tableName = NSStringFromClass([self class]);
        NSString *deleteSqlString = [NSString stringWithFormat:@"DELETE FROM %@ %@",tableName,criteria];
        res = [db executeUpdate:deleteSqlString];
        if (res) {
            LSDLog(@"删除数据成功!");
        }else
        {
            LSDLog(@"删除数据失败!");
        }
    }];
    
    return res;
}

#pragma mark -- 查询全部数据
+(NSArray *)lsd_findAll
{
    LSDDataBaseManager *manager = [LSDDataBaseManager sharedManager];
    NSMutableArray *dataArray = [NSMutableArray array];
    [manager.lsd_dbQueue inDatabase:^(FMDatabase *db) {
       
        NSString *tableName = NSStringFromClass([self class]);
        NSString *sqlString = [NSString stringWithFormat:@"SELECT * FROM %@",tableName];
        
       FMResultSet *resultSet = [db executeQuery:sqlString];
        
        while ([resultSet next]) {
            LSDDataBaseModel *model = [[self alloc]init];
            
            for (int i = 0; i < model.columeNames.count ; i ++) {
            
                NSString *columnName = [model.columeNames objectAtIndex:i];
                NSString *columnType = [model.columeTypes objectAtIndex:i];
                if ([columnType isEqualToString:LSD_SQLTEXT]) {
                    [model setValue:[resultSet stringForColumn:columnName] forKey:columnName];
                }else
                {
                
                    [model setValue:[NSNumber numberWithLongLong:[resultSet longLongIntForColumn:columnName]] forKey:columnName];
                }
            }
            [dataArray addObject:model];
            FMDBRelease(model);
        }
        
    }];
    
    return [dataArray copy];
    
}

#pragma mark -- 通过条件查找数据
+(NSArray *)lsd_findByCriteria:(NSString *)criteria
{

    LSDDataBaseManager *manager = [LSDDataBaseManager sharedManager];
    NSMutableArray *dataArray = [NSMutableArray array];
   
    [manager.lsd_dbQueue inDatabase:^(FMDatabase *db) {
       
        NSString *tableName = NSStringFromClass([self class]);
        
        NSString *sqlString = [NSString stringWithFormat:@"SELECT * FROM %@ %@",tableName,criteria];
        
        FMResultSet *resultSet = [db executeQuery:sqlString];
        
        while ([resultSet next]) {
            LSDDataBaseModel *model = [[self alloc]init];
            
            for (int i = 0; i < model.columeNames.count ; i ++) {
                NSString *columnName = [model.columeNames objectAtIndex:i];
                NSString *columnType = [model.columeTypes objectAtIndex:i];
                
                if ([columnType isEqualToString:LSD_SQLTEXT]) {
                     [model setValue:[resultSet stringForColumn:columnName] forKey:columnName];
                }else
                {
              
                    [model setValue:[NSNumber numberWithLongLong:[resultSet longLongIntForColumn:columnName]] forKey:columnName];
                }
                
            }
            
            [dataArray addObject:model];
            FMDBRelease(dataArray);
            
        }
        
    }];
    
    return [dataArray copy];
    
}

#pragma mark -- 查找某条数据
+(instancetype)lsd_findFirstByCriteria:(NSString *)criteria
{

    NSArray *results = [self lsd_findByCriteria:criteria];
    if (results.count < 1) {
        return  nil;
    }
    return [results firstObject];
    
}

#pragma mark -- 根据主键来查找某条数据
+(instancetype)lsd_findByPK:(NSInteger)inPk
{
    NSString *condition = [NSString stringWithFormat:@"WHERE %@=%zd",LSD_PrimaryId,inPk];
    
    return [self lsd_findFirstByCriteria:condition];
}


#pragma mark -- 获取最大值
+(NSInteger)lsd_getMaxOf:(NSString *)columeName
{

    __block int max = 0;
    
    LSDDataBaseManager *manager = [LSDDataBaseManager sharedManager];
    [manager.lsd_dbQueue inDatabase:^(FMDatabase *db) {
    
        NSString *tableName = NSStringFromClass([self class]);
        NSString *sqlString = [NSString stringWithFormat:@"SELECT max(%@) FROM %@",columeName,tableName];
        
        FMResultSet *resultSet = [db executeQuery:sqlString];
        
        while ([resultSet next]) {
            
            
            if (max < [resultSet intForColumnIndex:0]) {
                max = [resultSet intForColumnIndex:0];
            }
        }
    }];
    
    return max;
}


#pragma mark -- 清空表
+(BOOL)lsd_clearTable
{

    LSDDataBaseManager *manager = [LSDDataBaseManager sharedManager];
    __block BOOL res = NO;
    [manager.lsd_dbQueue inDatabase:^(FMDatabase *db) {
        NSString *tableName = NSStringFromClass([self class]);
        NSString *clearTableSqlString =[NSString stringWithFormat:@"DELETE FROM %@",tableName];
        res = [db executeUpdate:clearTableSqlString];
        
        if (res) {
            LSDLog(@"清空表成功!");
        }else
        {
        
            LSDLog(@"清空表失败!");
        }
    }];
    
    return  res;
    
}

#pragma mark -- description方法辅助打印
-(NSString *)description
{
    NSString *result = @"{";
    NSDictionary *dict = [[self class] lsd_getAllProperties];
    NSMutableArray *proNames = [dict objectForKey:@"name"];
    for (int i = 0; i < proNames.count ; i ++) {
        NSString *proName = [proNames objectAtIndex:i];
        ///kvc取值
        id proValue = [self valueForKey:proName];
        result = [result stringByAppendingFormat:@"\n%@:%@",proName,proValue];
    }
    
    return  [result stringByAppendingString:@"\n}"];
}

@end



















