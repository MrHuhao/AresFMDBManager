//
//  FBDMManager.h
//  FMDBMigrationManagerTEST
//  -> NSObject+Singleton (1.0.0)
//  Created by huhao on 14-7-25.
//  Copyright (c) 2014年 胡皓. All rights reserved.

/**
 *  实现 FMDB
 *  加密数据
 *  加密数据库空间
     主要功能 : 使用fmdb操作数据库
 */

#import <Foundation/Foundation.h>
#import "NSObject+Singleton.h"

@interface FBDMManager : NSObject

-(NSMutableArray *)pro:(Class )c;

- (void)createTable:(NSArray *)data inTable:(NSString *)model;
- (BOOL)createTable:(NSString *)aSql ;
- (void)insertData:(NSArray *)commandes useTransaction:(BOOL)useTransaction inmodel:(NSString *)model;
-(NSArray *)query:(NSString *)aSQL withArgumentsInArray:(NSArray *)arguments;
- (void)clearAll:(NSString *)aSQL;
- (void)clearAll:(NSDictionary *)where inModel:(NSString *)model;
@end
