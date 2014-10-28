//
//  ZIMORMManagerImp.m
//  MobileAppProjMobileAppIpad
//
//  Created by huhao on 12-7-31.

#import "ZIMORMManagerImp.h"
#import "DB_Header.h"
#import "ObjectRuntime.h"
@interface ZIMORMManagerImp()
{
    ZIMDbConnection *connection;
}
@end
@implementation ZIMORMManagerImp
-(NSMutableArray *)ScanDOC{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSMutableArray *dirArray = [[NSMutableArray alloc] init];
    BOOL isDir = NO;
    NSArray *fileList = [[NSArray alloc] init];
    NSError *error = nil;
    NSString *mainPath = [[NSBundle mainBundle] bundlePath] ;
    NSString *docPath = [mainPath stringByAppendingPathComponent:@"cn.com.yitong.db"];
    fileList = [fileManager contentsOfDirectoryAtPath:docPath error:&error];
    for (NSString *file in fileList) {
        NSString *path = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:file];
        [fileManager fileExistsAtPath:path isDirectory:(&isDir)];
        if (!isDir) {
            NSString *realPath = [docPath stringByAppendingPathComponent:file];
            [dirArray addObject:realPath];
        }
        isDir = NO;
    }
    return dirArray;
}

static NSMutableArray *dirArray;
static NSMutableArray *xmls;

/**
 *  整个orm入口方法！
 */
- (void)loadOrm
{
    dirArray = [self ScanDOC];
     xmls = [[NSMutableArray alloc]initWithCapacity:[dirArray count]];
    for (NSString *realPath in dirArray) {
        [xmls addObject:[NSData dataWithContentsOfFile:realPath]];
    }
    ObjectRuntime *theObjectRuntime = [[ObjectRuntime alloc]init];
    [theObjectRuntime buildTableDO:xmls];
    [self buildTable:xmls];
}

-(id)init{
    self = [super init];
    if (self) {
        
    }
    return self;
}

/**
 *  间表语句， dbutil可能存在缓存，具体原因我现在仍不清楚，如果存在简表不成功的话，尝试更换文件名称
 */

-(void)buildTable:(NSArray *)xmls{
    for (NSData *xml in xmls) {
        if (xml) {
            NSError *error = nil;
            ZIMSqlCreateTableStatement *create = [[ZIMSqlCreateTableStatement alloc] initWithXmlSchema:xml error:&error];
            NSLog(@"error：%@",error);
            NSString *statement = [create statement];
            NSNumber *result = [ZIMDbConnection dataSource: DB_SECHEME execute: statement];
            if (result) {
                NSLog(@"[CREATE TABLE]%@",@"success");
            }
        }
    }
}

/**
 *  orm插入操作
 *
 *  @param dict  需要插入的数据
 *  @param model 表名／类名
 */
-(void)save:(NSDictionary *)dict inModel:(NSString *)model mu:(BOOL)mu{
    [self save:dict inModel:model mu:mu];
}

/**
 *  TODO ...
 *  保存方法
 *  @update 2014-08-20
 *  @param dict  条件
 *  @param model 模型 v1.0
 
 *  TODO ...
 *  保存方法
 *  @update 2014-08-28
 *  @param dict  条件
 *  @param model 模型 v1.1
     @resean  原有方法废弃,改为单事务提交
 */
-(void)save:(id)dictOfresponse inModel:(NSString *)model{
    NSMutableArray *commandes = [[NSMutableArray alloc] init];
    for (NSDictionary *res in dictOfresponse) {
        ZIMSqlInsertStatement  *table = [[ZIMSqlInsertStatement alloc] init];
        if (table) {
            [table into: model];
            [table columns:[self pro:NSClassFromString(model)] value:res];
            NSString *statement = [table statement];
            [commandes addObject:statement];
        }
    }
    [[[FBDMManager alloc] init] insertData:commandes useTransaction:YES inmodel:model];
}

-(void)update:(id)dictOfresponse inModel:(NSString *)model{
    NSMutableArray *commandes = [[NSMutableArray alloc] init];
    for (NSDictionary *res in dictOfresponse) {
        ZIMSqlUpdateStatement  *table = [[ZIMSqlUpdateStatement alloc] init];
        if (table) {
            [table table:model];
            [table columns:[self pro:NSClassFromString(model)] value:res];
            NSString *statement = [table statement];
            [commandes addObject:statement];
        }
    }
    [[[FBDMManager alloc] init] insertData:commandes useTransaction:YES inmodel:model];
}

/*
 *  TODO ...
 *  保存方法
 *  @update 2014-09-11
 *  @param dict  条件
 *  @param model 模型 v1.1
     @resean 级联插入 没有测试
 */
-(void)save:(id)dictOfresponse inModel:(NSString *)model oneToMany:(BOOL)oneToMany{
    NSMutableArray *commandes = [[NSMutableArray alloc] init];
    for (NSDictionary *res in dictOfresponse) {
        id value = [res allValues][0];
        if ([value isKindOfClass:[NSArray class]]) {
            //oneToMany
            NSString *modelOfFirst = [model stringByAppendingString:@"OfFirst"];
            for (NSDictionary *resOfSub in value) {
                ZIMSqlInsertStatement  *table = [[ZIMSqlInsertStatement alloc] init];
                if (table) {
                    [table into: modelOfFirst];
                    [table columns:[self pro:NSClassFromString(modelOfFirst)] value:resOfSub];
                    NSString *statement = [table statement];
                    [commandes addObject:statement];
                }
            }
        }else if([[res allValues][0] isKindOfClass:[NSString class]]){
            ZIMSqlInsertStatement  *table = [[ZIMSqlInsertStatement alloc] init];
            if (table) {
                [table into: model];
                [table columns:[self pro:NSClassFromString(model)] value:res];
                NSString *statement = [table statement];
                [commandes addObject:statement];
            }
        }
    }
    [[[FBDMManager alloc] init] insertData:commandes useTransaction:YES inmodel:model];
}

-(void)save:(NSDictionary *)dict inModel:(NSString *)model inMul:(BOOL)mul{
    if (mul) {
        @synchronized(self){
            ZIMSqlInsertStatement *table = [[ZIMSqlInsertStatement alloc] init];
            if (table) {
                [table into: model];
                [table columns:[self pro:NSClassFromString(model)] value:dict];
                NSString *statement = [table statement];
                NSNumber *result = [ZIMDbConnection dataSource: DB_SECHEME execute: statement];
                if (result) {
                    // NSLog(@"[SAVE DATA]%@", statement);
                }
            }
        }
    }else{
        
    }
}
/**
 *  条件查询
 *
 *  @param dict where条件字段 exaple dict = @{@"CODE": @"123"};
 *
 *  @return 查询结果
 */
-(NSArray *)query:(NSDictionary *)dict inModel:(NSString *)model{
    /*dict = @{@"CODE": @"123"};*/
    ZIMOrmSelectStatement *select = [[ZIMOrmSelectStatement alloc] initWithModel: NSClassFromString(model)];
    return [select queryByWhere:dict];
}

-(BOOL)cleanData:(NSDictionary *)dict{
    dict = @{@"CODE": @"123"};
    ZIMOrmDeleteStatement *del = [[ZIMOrmDeleteStatement alloc] initWithModel: NSClassFromString(@"T_CACHE_BUSI")];
    return  [del deleteByWhere:dict];
}




@end
