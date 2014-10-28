//
//  FBDMManager.m
//  FMDBMigrationManagerTEST
//
//  Created by huhao on 14-7-25.
//  Copyright (c) 2014年 胡皓. All rights reserved.
//
#import "AppDelegate.h"
#import "FBDMManager.h"
#import "FMDatabase.h"
#import "DB_Header.h"
/**
 *  @categary 可全扩展
 *
 *  @param DES1  单匙加密
 *
 *  @return
 */

#import "FBDMManager.h"

@interface FBDMManager (DES1)

//- (NSString *)dd: (NSString *)msg;
//- (NSString *)cc: (NSString *)msg;
//+(NSString *)dd: (NSString *)msg;
//+(NSString *)cc: (NSString *)msg;

@end

@interface FBDMManager(Private)

@end

@implementation FBDMManager (DES1)
#define useDES YES
#pragma market-
#pragma mark 加密 DES 公钥 @"SHMB-P&C" 私钥 @"SHANGHAIBANK_P&C"

+(NSString *)cc:(NSString *)msg{
    id<MIHSymmetricKey> symmetricKey = [[MIHDESKey alloc]initWithKey:[@"SHMB-P&C" dataUsingEncoding:NSUTF8StringEncoding] iv:[@"SHANGHAIBANK_P&C" dataUsingEncoding:NSUTF8StringEncoding] mode:MIHDESModeCBC];
    NSError *encryptionError = nil;
    NSData *messageData = [msg dataUsingEncoding:NSUTF8StringEncoding];
    if (!useDES) return [messageData base64EncodedStringWithOptions:nil];
    NSData *encryptedData = [symmetricKey encrypt:messageData error:&encryptionError];
    return  [GTMBase64 stringByEncodingData:encryptedData];;
}

+(NSString *)dd: (NSString *)msg{
    id<MIHSymmetricKey> symmetricKey = [[MIHDESKey alloc]initWithKey:[@"SHMB-P&C" dataUsingEncoding:NSUTF8StringEncoding] iv:[@"SHANGHAIBANK_P&C" dataUsingEncoding:NSUTF8StringEncoding] mode:MIHDESModeCBC];
    NSError *encryptionError = nil;
    NSData *messageData = [GTMBase64 decodeString:msg];
    if (!useDES) return [GTMBase64 stringByEncodingData:messageData];
    NSData *encryptedData = [symmetricKey decrypt:messageData error:&encryptionError];
    return [[NSString alloc]initWithData:encryptedData encoding:NSUTF8StringEncoding];
    return nil;
}

-(NSString *)cc:(NSString *)msg{
    id<MIHSymmetricKey> symmetricKey = [[MIHDESKey alloc]initWithKey:[@"SHMB-P&C" dataUsingEncoding:NSUTF8StringEncoding] iv:[@"SHANGHAIBANK_P&C" dataUsingEncoding:NSUTF8StringEncoding] mode:MIHDESModeCBC];
    NSError *encryptionError = nil;
    NSData *messageData = [msg dataUsingEncoding:NSUTF8StringEncoding];
    if (!useDES) return [messageData base64EncodedStringWithOptions:nil];
    NSData *encryptedData = [symmetricKey encrypt:messageData error:&encryptionError];
    return  [GTMBase64 stringByEncodingData:encryptedData];;
}

-(NSString *)dd: (NSString *)msg{
    
    id<MIHSymmetricKey> symmetricKey = [[MIHDESKey alloc]initWithKey:[@"SHMB-P&C" dataUsingEncoding:NSUTF8StringEncoding] iv:[@"SHANGHAIBANK_P&C" dataUsingEncoding:NSUTF8StringEncoding] mode:MIHDESModeCBC];
    NSError *encryptionError = nil;
    NSData *messageData = [GTMBase64 decodeString:msg];
    if (!useDES) return [GTMBase64 stringByEncodingData:messageData];
    NSData *encryptedData = [symmetricKey decrypt:messageData error:&encryptionError];
    return [[NSString alloc]initWithData:encryptedData encoding:NSUTF8StringEncoding];
    return nil;
}

@end



@interface FBDMManager(){
    NSTimer *timer;
}

@property (nonatomic, retain) NSString * dbPath;
@end

@implementation FBDMManager
#pragma mark - SQL Operations

-(id)init{
   self =  [super init];
    if (self) {
        [self setUp];
    }
    return self;
}


#ifdef DEBUG
#define debugNSLog(...) NSLog(__VA_ARGS__)
#define debugLog(...)  [action addObject:__VA_ARGS__]
#define debugMethod() NSLog(@"%s", __func__)
#define debugString(...)  [NSString stringWithFormat:__VA_ARGS__]
#else
#define debugLog(...)
#define debugMethod()
#endif


/**
 *  应用标示＋登陆用户信息 ＝ 文件名
 *
 *  文件名＋ MD5加密 ＝ 数据库文件名
 */

-(NSString *)DBName{
    NSString * doc = [[YKFile documentsDirectory] fullPath];
    NSString * fileName = [NSString stringWithFormat:@"%@_mylivedb.sqlite",
    [AresSession singleton].theAresFstLogSession.userId];
    return   self.dbPath =  [doc stringByAppendingPathComponent:fileName];
}

-(void)setUp{
    [self DBName];
}

- (void)createTable:(NSArray *)data inTable:(NSString *)model{
    NSString *sql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS [%@] ([PK] INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL ",model];
    for (NSString *col in data) {
         NSString *sqlcontent =[NSString stringWithFormat:@", [%@] VARCHAR(255) DEFAULT 'N/A'",col];
        sql = [sql stringByAppendingString:sqlcontent];
    }
    NSString *endSql =@");";
    sql = [sql stringByAppendingString:endSql];
    [self createTable:sql];
}
/**
 *  建表
 */
- (BOOL)createTable:(NSString *)aSql{
    debugMethod();
    NSMutableArray * action = [[NSMutableArray alloc]init];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL res = YES;
    if (![fileManager fileExistsAtPath:self.dbPath]) {
        FMDatabase * db = [FMDatabase databaseWithPath:self.dbPath];
        if ([db open]) {
            NSString * sql = aSql;
            debugLog(sql);
             res = [db executeUpdate:sql];
            if (!res) {
                debugLog(@"error when creating db table (when table isexist)");
            } else {
                debugLog(@"succ to creating db table");
            }
            [db close];
        } else {
            debugLog(@"error when open db");
        }
    }
    return res;
}

/**
 *   插入单条数据
 */
- (void)insertData:(NSString *)sql withArgumentsInArray:(NSArray *)arguments {
    NSMutableArray * action = [[NSMutableArray alloc]init];
    FMDatabase * db = [FMDatabase databaseWithPath:self.dbPath];
    if ([db open]) {
        BOOL res =[db executeUpdate:sql withArgumentsInArray:arguments];
        if (!res) {
            debugLog(@"error to insert data");
        } else {
            debugLog(@"succ to insert daYta");
        }
        [db close];
    }
    action = nil;
}


/**
 *  多线程查
 *
 *  全查 SQL @"select * from user"
 */

- (void)queryData:(NSString *)aSQL {
    debugMethod();
    __block  NSMutableArray * action = [[NSMutableArray alloc]init];
#if NS_BLOCKS_AVAILABLE
	MBProgressHUD *HUD = [[MBProgressHUD alloc] initWithView:[[(AppDelegate *)[UIApplication sharedApplication].delegate rootViewController] view]];
	[[[(AppDelegate *)[UIApplication sharedApplication].delegate rootViewController] view] addSubview:HUD];
	HUD.labelText = @"Loading";
	HUD.detailsLabelText = @"updating data";
	HUD.square = YES;
	[HUD show:YES];

    FMDatabase * db = [FMDatabase databaseWithPath:self.dbPath];
    dispatch_queue_t queueOfquery = dispatch_queue_create("queueOfquery", NULL);
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_async(group, queueOfquery, ^{
        if ([db open]) {
            NSString * sql = aSQL;
            FMResultSet * rs = [db executeQuery:sql];
            while ([rs next]) {
                NSMutableDictionary *dictOfRow =  (NSMutableDictionary *)  [rs resultDictionary];
                NSArray *colName = [dictOfRow allKeys];
                for (int i = 0; i<[colName count]; i++) {
                    NSString *key = colName[i];
                    if (![[dictOfRow objectForKey:colName[i]] isKindOfClass:[NSString class]]) {
                        continue;
                    }
                    NSString *val =  [self dd:[dictOfRow objectForKey:colName[i]]];
                    [dictOfRow setObject:val forKey:key];
                }
                NSError *error = nil;
                 NSString *strOfRow =[[NSString alloc]initWithData:[[CJSONSerializer serializer] serializeDictionary:dictOfRow error:&error] encoding:NSUTF8StringEncoding];
                debugLog(strOfRow);
            }
            [db close];
        }
    });
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        [HUD hide:YES];
        [HUD removeFromSuperview];
        action = nil;
    });
    
#endif

}

-(NSArray *)query:(NSString *)aSQL withArgumentsInArray:(NSArray *)arguments{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    FMDatabase * db = [FMDatabase databaseWithPath:self.dbPath];
        if ([db open]) {
            NSString * sql = aSQL;
            FMResultSet * rs = [db executeQuery:sql withArgumentsInArray:arguments];
            while ([rs next]) {
                NSMutableDictionary *dictOfRow =  (NSMutableDictionary *)  [rs resultDictionary];
                [result addObject:dictOfRow];
            }
            [db close];
        }
     return result;
}


- (void)queryData:(NSString *)aSQL withArgumentsInArray:(NSArray *)arguments{
    debugMethod();
    __block  NSMutableArray * action = [[NSMutableArray alloc]init];
#if NS_BLOCKS_AVAILABLE
	MBProgressHUD *HUD = [[MBProgressHUD alloc] initWithView:[[(AppDelegate *)[UIApplication sharedApplication].delegate rootViewController] view]];
	[[[(AppDelegate *)[UIApplication sharedApplication].delegate rootViewController] view] addSubview:HUD];
	HUD.labelText = @"Loading";
	HUD.detailsLabelText = @"updating data";
	HUD.square = YES;
	[HUD show:YES];
    
    FMDatabase * db = [FMDatabase databaseWithPath:self.dbPath];
    dispatch_queue_t queueOfquery = dispatch_queue_create("queueOfquery", NULL);
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_async(group, queueOfquery, ^{
        if ([db open]) {
            NSString * sql = aSQL;
            FMResultSet * rs = [db executeQuery:sql withArgumentsInArray:arguments];
            while ([rs next]) {
                NSMutableDictionary *dictOfRow =  (NSMutableDictionary *)  [rs resultDictionary];
                NSArray *colName = [dictOfRow allKeys];
                for (int i = 0; i<[colName count]; i++) {
                    NSString *key = colName[i];
                    if (![[dictOfRow objectForKey:colName[i]] isKindOfClass:[NSString class]]) {
                        continue;
                    }
                    NSString *val =  [self dd:[dictOfRow objectForKey:colName[i]]];
                    [dictOfRow setObject:val forKey:key];
                }
                NSError *error = nil;
                NSString *strOfRow =[[NSString alloc]initWithData:[[CJSONSerializer serializer] serializeDictionary:dictOfRow error:&error] encoding:NSUTF8StringEncoding];
                debugLog(strOfRow);
            }
            [db close];
        }
    });
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        [HUD hide:YES];
        [HUD removeFromSuperview];
        action = nil;
    });
    
#endif
    
}

- (void)clearAll:(NSDictionary *)where inModel:(NSString *)model{
    NSString *statement = [NSString stringWithFormat:@"delete from %@",model];
    NSArray *allKeys = [where allKeys];
    for(int i = 0 ;i<[allKeys count];i++){
      
        NSString *key =  allKeys[i];
        NSString *val = where[key];
        NSString *where  = [NSString stringWithFormat:@"%@=%@",key,val];
        if (where) {
            if (i==0) {
                statement = [NSString stringWithFormat:@"%@ where %@",statement,where];
                continue;
            }else{
                statement = [NSString stringWithFormat:@"%@ and %@",statement,where];
                continue;
            }
            
        }
    }
    [self clearAll:statement];
}
/**
 *  清空数据
 *
 *  @param sql @"delete from user";
 */
- (void)clearAll:(NSString *)aSQL {
     debugMethod();
    NSMutableArray * action = [[NSMutableArray alloc]init];
    FMDatabase * db = [FMDatabase databaseWithPath:self.dbPath];
    if ([db open]) {
        [db beginTransaction];
        NSString * sql = aSQL;
        BOOL res = [db executeUpdate:sql];
        if (!res) {
            debugLog(@"error to delete db data");
        } else {
            debugLog(@"succ to deleta db data");
        }
        [db commit];
        [db close];
    }
      action = nil;
}
/**
 *  清空数据
 *
 *  @param sql @"delete from user";
 */
- (void)clearByID:(NSString *)aSQL withArgumentsInArray:(NSArray *)arguments {
    debugMethod();
    NSMutableArray * action = [[NSMutableArray alloc]init];
    FMDatabase * db = [FMDatabase databaseWithPath:self.dbPath];
    if ([db open]) {
        [db beginTransaction];
        NSString * sql = aSQL;
        BOOL res =[db executeUpdate:sql withArgumentsInArray:arguments];
        if (!res) {
            debugLog(@"error to delete db data");
        } else {
            debugLog(@"succ to deleta db data");
        }
        [db commit];
        [db close];
    }
    action = nil;
}

/**
 *  多条数据插入
 *
 *  @param 缺省 1个线程  单事务提交
 *
 *  @return
 */
#define YT_async_AVAILABLE 1
#define YT_sync_AVAILABLE 0

- (void)multithread:(NSArray *)aryOfSQL withNumberOfDatabaseQueue:(NSInteger)numberOfDatabaseQueue{
    debugMethod();
    __block NSMutableArray *action = [[NSMutableArray alloc]init];
    
    FMDatabaseQueue * queue = [FMDatabaseQueue databaseQueueWithPath:self.dbPath];
    
    
#if NS_BLOCKS_AVAILABLE
	MBProgressHUD *HUD = [[MBProgressHUD alloc] initWithView:[[(AppDelegate *)[UIApplication sharedApplication].delegate rootViewController] view]];
	[[[(AppDelegate *)[UIApplication sharedApplication].delegate rootViewController] view] addSubview:HUD];
	HUD.labelText = @"Loading";
	HUD.detailsLabelText = @"updating data";
	[HUD show:YES];
    dispatch_group_t group = dispatch_group_create();
    NSInteger numberOfq = 0;
    while (numberOfq<numberOfDatabaseQueue) {
        dispatch_queue_t q = dispatch_queue_create("q", NULL);
        dispatch_group_async(group, q, ^{
            [queue inTransaction:^(FMDatabase *db, BOOL *rollback){
                for (int i = numberOfq*[aryOfSQL count]/numberOfDatabaseQueue; i<(numberOfq+1)*[aryOfSQL count]/numberOfDatabaseQueue; i++) {
                    NSArray *arguments = aryOfSQL[i][@"arguments"];
                    NSString *SQL = aryOfSQL[i][@"SQL"];
                    BOOL res =[db executeUpdate:SQL withArgumentsInArray:arguments];
                    if (!res) {
                        debugLog(debugString(@"error to add db data: %@", q.description));
                    } else {
                        debugLog(debugString(@"succ to add db data: %d row", i));
                    }
                    if (rollback) {
                        
                    }
                }
            }];
        });
        numberOfq =  1+ numberOfq;
    }
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        [HUD hide:YES];
        [HUD removeFromSuperview];
        action = nil;
    });
    
#endif
}

- (void)multithread:(NSString *)sql withArgumentsInArray:(NSArray *)arguments {

     debugMethod();
    __block NSMutableArray *action = [[NSMutableArray alloc]init];
    
    FMDatabaseQueue * queue = [FMDatabaseQueue databaseQueueWithPath:self.dbPath];
    
    
#if NS_BLOCKS_AVAILABLE
	MBProgressHUD *HUD = [[MBProgressHUD alloc] initWithView:[[(AppDelegate *)[UIApplication sharedApplication].delegate rootViewController] view]];
	[[[(AppDelegate *)[UIApplication sharedApplication].delegate rootViewController] view] addSubview:HUD];
	HUD.labelText = @"Loading";
	HUD.detailsLabelText = @"updating data";
	HUD.square = YES;
	[HUD show:YES];
    dispatch_group_t group = dispatch_group_create();
        dispatch_queue_t q = dispatch_queue_create("q", NULL);
        dispatch_group_async(group, q, ^{
            // do somthing
                [queue inTransaction:^(FMDatabase *db, BOOL *rollback){
                    BOOL res =[db executeUpdate:@"insert into user (name, password) values(?,?) " withArgumentsInArray:arguments];
                    if (!res) {
                        debugLog(debugString(@"error to add db data: %@", q.description));
                    } else {
                        debugLog(debugString(@"succ to add db data: %@",  q.description));
                    }
                    if (rollback) {
                        
                    }
                    
                }];
        });
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        [HUD hide:YES];
        [HUD removeFromSuperview];
        action = nil;
    });
    
#endif
}

-(NSMutableArray *)pro:(Class )c{
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList(c, &outCount);
    NSMutableArray *ps = [[NSMutableArray alloc]init];
    for (i=0; i<outCount; i++) {
        objc_property_t property = properties[i];
        NSString * key = [[NSString alloc] initWithCString:property_getName(property)  encoding:NSUTF8StringEncoding];
        [ps addObject:key];
    }
    return ps;
}

/**
 *  单事务提交
 *
 *  @param commandes      sql语句
 *  @param useTransaction  是否使用：这里默认使用
 *  @param model          插入模型
 */
- (void)insertData:(NSArray *)commandes useTransaction:(BOOL)useTransaction inmodel:(NSString *)model
{
    FMDatabase * db = [FMDatabase databaseWithPath:self.dbPath];
    [db open];
    if (useTransaction) {
        [db beginTransaction];
        BOOL isRollBack = NO;
        @try {
            for (int i = 0; i<[commandes count]; i++) {
                NSString *sql = commandes[i];
                BOOL a = [db executeUpdate:sql];
                if (!a) {
                    NSLog(@"[DATABASES 异常] 插入失败%@",sql);
                }
            }
        }
        @catch (NSException *exception) {
            isRollBack = YES;
            [db rollback];
        }
        @finally {
            if (!isRollBack) {
                [db commit];
            }
        }
    }
    [db close];
}

@end