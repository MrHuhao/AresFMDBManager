//
//  DB_Header.h
//  MobileAppProjMobileAppIpad
//
//  Created by huhao on 12-7-31.

/**
 *  所有依赖第三方的库文件引入
 */

#ifndef MobileAppProjMobileAppIpad_DB_Header_h
#define MobileAppProjMobileAppIpad_DB_Header_h

#import "ZIMORMManagerImp.h"
#import "FBDMManager.h"
/**
 *  数据库
 */

#define YT_IS_ENCRYPT_DATA NO //数据是否加密
#define YT_IS_ENCRYPT_SCHEME NO //数据是否加密
#define DB_SECHEME @"live" //默认数据文件名
#define NEED_LOGIN YES //应用是否要登陆

#import "FMDB.h"
#import "ZIMDbSdk.h"
#import "ZIMOrmSdk.h"
#import "ZIMSqlSdk.h"
/**
 *  JSON
 */
#import "JSONModelLib.h"
/**
 *  加密
 */
#import "MIHDESKey.h"
#import "GTMBase64.h"
/**
 *  RUNTIME
 */
#import <objc/runtime.h>
/**
 *  FILE
 */
#import "YKFile.h"
#import "YKFile+NSDirectories.h"
/**
 *  WAIT
 */
#import "MBProgressHUD.h"
/**
 *  JSON
 */
#import "CJSONSerializer.h"
#endif
