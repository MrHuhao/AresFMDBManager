/*
 * Copyright 2011-2013 Ziminji
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at:
 * 
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
#import "ZIMSqlInsertStatement.h"
#import "ZIMORMManagerImp.h"
#import "DB_Header.h"
@implementation ZIMSqlInsertStatement

#pragma mark -
#pragma mark Public Methods

- (instancetype) init {
	if ((self = [super init])) {
		_table = nil;
		_column = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (void) into: (NSString *)table {
	_table = [ZIMSqlExpression prepareIdentifier: table];
}


//add by huhao
- (void) columns: (NSArray *)columns value: (NSDictionary *)values {
    for (int i = 0; i<[columns count]; i++) {
        NSString *key = columns[i];
        id value = values[key];
        if ([value isKindOfClass:[NSString class]]) {
            if (YT_IS_ENCRYPT_DATA) {
                value = [self encryptDES:value];
            }
        }
        [self column:key value:value];
    }
}

- (void) columnObjectAndKey: (NSDictionary *) columnANDvalue{
    [self columns:[columnANDvalue allKeys] value:columnANDvalue];
}

- (void) column: (NSString *)column value: (id)value {
    
	[_column setObject: [ZIMSqlExpression prepareValue: value] forKey: [ZIMSqlExpression prepareIdentifier: column]];
}

- (NSString *) statement {
	NSMutableString *sql = [[NSMutableString alloc] init];
	
	[sql appendFormat: @"INSERT INTO %@ ", _table];

	if ([_column count] > 0) {
		[sql appendFormat: @"(%@) VALUES (%@)", [[_column allKeys] componentsJoinedByString: @", "], [[_column allValues] componentsJoinedByString: @", "]];
	}

	[sql appendString: @";"];

	return sql;
}

#define useDES YES
#pragma market-
#pragma mark 加密 DES 公钥 @"SHMB-P&C" 私钥 @"SHANGHAIBANK_P&C"
-(NSString *)encryptDES:(NSString *)msg{
    id<MIHSymmetricKey> symmetricKey = [[MIHDESKey alloc]initWithKey:[@"SHMB-P&C" dataUsingEncoding:NSUTF8StringEncoding] iv:[@"SHANGHAIBANK_P&C" dataUsingEncoding:NSUTF8StringEncoding] mode:MIHDESModeCBC];
    NSError *encryptionError = nil;
    NSData *messageData = [msg dataUsingEncoding:NSUTF8StringEncoding];
    if (!useDES) return [messageData base64EncodedStringWithOptions:nil];
    NSData *encryptedData = [symmetricKey encrypt:messageData error:&encryptionError];
    return  [GTMBase64 stringByEncodingData:encryptedData];;
}

-(NSString *)decryptDES: (NSString *)msg{
    
    id<MIHSymmetricKey> symmetricKey = [[MIHDESKey alloc]initWithKey:[@"SHMB-P&C" dataUsingEncoding:NSUTF8StringEncoding] iv:[@"SHANGHAIBANK_P&C" dataUsingEncoding:NSUTF8StringEncoding] mode:MIHDESModeCBC];
    NSError *encryptionError = nil;
    NSData *messageData = [GTMBase64 decodeString:msg];
    if (!useDES) return [GTMBase64 stringByEncodingData:messageData];
    NSData *encryptedData = [symmetricKey decrypt:messageData error:&encryptionError];
    return [[NSString alloc]initWithData:encryptedData encoding:NSUTF8StringEncoding];
    return nil;
}

@end
