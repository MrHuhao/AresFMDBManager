//
//  FBDMManagerImp.h
//  MobileAppProjMobileAppIpad
//
//  Created by huhao on 12-7-31.

/**
 *  实现 ZIMORM  ZIMSQL
 *  动态建表
 *  完成基本 增删改查功能
 */

@protocol ZIMORMManagerImpProtocol
-(void)loadOrm;//reset
-(void)save:(id)dictOfresponse inModel:(NSString *)model;//保存
-(void)save:(id)dictOfresponse inModel:(NSString *)model oneToMany:(BOOL)oneToMany;//保存
-(NSArray *)query:(NSDictionary *)dict inModel:(NSString *)model;//全查
-(void)update:(id)dictOfresponse inModel:(NSString *)model;//更新
@end

#import "ZIMORMManagerImp.h"
#import "FBDMManager.h"
@interface ZIMORMManagerImp : FBDMManager<ZIMORMManagerImpProtocol>

@end
