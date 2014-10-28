//
//  ObjectRuntime.m
//  MobileAppProjMobileAppIpad
//
//  Created by huhao on 14-8-2.
//
//

#import "ObjectRuntime.h"
#import "DB_Header.h"

#define kDBProps @"props"
#define kDBMethods @"methods"

#define kSuperClassName_JSONModel @"JSONModel"
#define kSuperClassName_ZIMOrmModel @"ZIMOrmModel"

@interface TableDO : NSObject<NSXMLParserDelegate> {
    
@protected
    NSString *_table;
    BOOL _temporary;
    NSMutableDictionary *_columnDictionary;
    NSMutableArray *_columnArray;
    NSString *_primaryKey;
    NSString *_unique;
    NSMutableArray *_stack;
    NSUInteger _counter;
    NSError *_error;
}

@end
@implementation TableDO
- (instancetype) initWithXmlSchema: (NSData *)xml error: (NSError **)error {
	if ((self = [super init])) {
		_table = nil;
		_temporary = NO;
		_columnDictionary = [[NSMutableDictionary alloc] init];
		_columnArray = [[NSMutableArray alloc] init];
		_primaryKey = nil;
		_unique = nil;
        _stack = [[NSMutableArray alloc] init];
        _counter = 0;
        _error = *error;
        if (xml != nil) {
			NSXMLParser *parser = [[NSXMLParser alloc] initWithData: xml];
			[parser setDelegate: self];
			[parser parse];
		}
	}
	return self;
}

- (instancetype) init {
    NSError *error = nil;
    return [self initWithXmlSchema: nil error: &error];
}

- (void) table: (NSString *)table {
	[self table: table temporary: NO];
}

- (void) table: (NSString *)table temporary: (BOOL)temporary {
	//_table = [ZIMSqlExpression prepareIdentifier: table];
    _table = table;
	_temporary = temporary;
}

- (void) column: (NSString *)column type: (NSString *)type {
	column = [ZIMSqlExpression prepareIdentifier: column];
	if ([_columnDictionary objectForKey: column] == nil) {
		[_columnArray addObject: column];
	}
	[_columnDictionary setObject: [NSString stringWithFormat: @"%@ %@", column, type] forKey: column];
}

- (void) column: (NSString *)column type: (NSString *)type defaultValue: (NSString *)value {
	if ([_columnDictionary objectForKey: column] == nil) {
		[_columnArray addObject: column];
	}
	[_columnDictionary setObject: [NSString stringWithFormat: @"%@ %@ %@", column, type, value] forKey: column];
}

- (void) column: (NSString *)column type: (NSString *)type primaryKey: (BOOL)primaryKey {
	if ([_columnDictionary objectForKey: column] == nil) {
		[_columnArray addObject: column];
	}
	[_columnDictionary setObject: [NSString stringWithFormat: @"%@ %@", column, type] forKey: column];
	if (primaryKey) {
		[self primaryKey: @[column]];
	}
}

- (void) column: (NSString *)column type: (NSString *)type unique: (BOOL)unique {
	if ([_columnDictionary objectForKey: column] == nil) {
		[_columnArray addObject: column];
	}
	if (unique) {
		[_columnDictionary setObject: [NSString stringWithFormat: @"%@ %@ UNIQUE", column, type] forKey: column];
	}
	else {
		[_columnDictionary setObject: [NSString stringWithFormat: @"%@ %@", column, type] forKey: column];
	}
}

- (void) primaryKey: (NSArray *)columns {
	if (columns != nil) {
		NSMutableString *primaryKey = [[NSMutableString alloc] init];
		[primaryKey appendString: @"PRIMARY KEY ("];
		NSInteger length = [columns count];
		for (NSInteger index = 0; index < length; index++) {
			NSString *column = [ZIMSqlExpression prepareIdentifier: [columns objectAtIndex: index]];
			if ([_columnDictionary objectForKey: column] == nil) {
				@throw [NSException exceptionWithName: @"ZIMSqlException" reason: [NSString stringWithFormat: @"Must declare column '%@' before primary key can be assigned.", column] userInfo: nil];
			}
			if (index > 0) {
				[primaryKey appendString: @", "];
			}
			[primaryKey appendString: column];
		}
		[primaryKey appendString: @")"];
		_primaryKey = primaryKey;
	}
	else {
		_primaryKey = nil;
	}
}

- (void) unique: (NSArray *)columns {
	if (columns != nil) {
		NSMutableString *unique = [[NSMutableString alloc] init];
		[unique appendString: @"UNIQUE ("];
		NSInteger length = [columns count];
		for (NSInteger index = 0; index < length; index++) {
			NSString *column = [ZIMSqlExpression prepareIdentifier: [columns objectAtIndex: index]];
			if ([_columnDictionary objectForKey: column] == nil) {
				@throw [NSException exceptionWithName: @"ZIMSqlException" reason: [NSString stringWithFormat: @"Must declare column '%@' before applying unique constraint.", column] userInfo: nil];
			}
			if (index > 0) {
				[unique appendString: @", "];
			}
			[unique appendString: column];
		}
		[unique appendString: @")"];
		_unique = unique;
	}
	else {
		_unique = nil;
	}
}

- (NSString *) statement {
	NSMutableString *sql = [[NSMutableString alloc] init];
	
	[sql appendString: @"CREATE"];
    
	if (_temporary) {
		[sql appendString: @" TEMPORARY"];
	}
	
	[sql appendFormat: @" TABLE IF NOT EXISTS %@ (", _table];
    
	NSInteger i = 0;
	for (NSString *column in _columnArray) {
		if (i > 0) {
			[sql appendFormat: @", %@", (NSString *)[_columnDictionary objectForKey: column]];
		}
		else {
			[sql appendString: (NSString *)[_columnDictionary objectForKey: column]];
		}
		i++;
	}
    
	if (_primaryKey != nil) {
		[sql appendFormat: @", %@", _primaryKey];
	}
    
	if (_unique != nil) {
		[sql appendFormat: @", %@", _unique];
	}
    
	[sql appendString: @");"];
	
	return sql;
}

#pragma mark -
#pragma mark Private Methods

- (void) parser: (NSXMLParser *)parser didStartElement: (NSString *)element namespaceURI: (NSString *)namespaceURI qualifiedName: (NSString *)qualifiedName attributes: (NSDictionary *)attributes {
	[_stack addObject: element];
	if (_counter < 1) {
        NSString *xpath = [_stack componentsJoinedByString: @"/"];
        if ([xpath isEqualToString: @"database/table"]) {
            NSString *name = [attributes objectForKey: @"name"];
			NSString *temporary = [attributes objectForKey: @"temporary"];
			if ((temporary != nil) && [[temporary uppercaseString] boolValue]) {
				[self table: name temporary: YES];
			}
			else {
				[self table: name];
			}
        }
        else if ([xpath isEqualToString: @"database/table/column"]) {
            NSString *columnName = [attributes objectForKey: @"name"];
            NSString *columnType = [[[attributes objectForKey: @"type"] uppercaseString] stringByReplacingOccurrencesOfString: @"_" withString: @" "];
			NSString *columnUnsigned = [attributes objectForKey: @"unsigned"];
			if ((columnUnsigned != nil) && [[columnUnsigned uppercaseString] boolValue]) {
				columnType = [NSString stringWithFormat: @"UNSIGNED %@", columnType];
            }
            NSString *columnSize = [attributes objectForKey: @"size"];
            if (columnSize != nil) {
                NSString *columnScale = [attributes objectForKey: @"scale"];
                if (columnScale != nil) {
                    columnType = [NSString stringWithFormat: @"%@(%@, %@)", columnType, columnSize, columnScale];
                }
                else {
                    columnType = [NSString stringWithFormat: @"%@(%@)", columnType, columnSize];
                }
            }
            NSString *columnValue = [attributes objectForKey: @"auto-increment"];
            if ((columnValue != nil) && [[columnValue uppercaseString] boolValue]) {
                [self column: columnName type: columnType defaultValue: ZIMSqlDefaultValueIsAutoIncremented];
            }
            else {
                NSString *columnKey = [attributes objectForKey: @"key"];
                if ((columnKey != nil) && [[columnKey lowercaseString] isEqualToString: @"primary"]) {
                    if (_primaryKey != nil) {
                        _primaryKey = [_primaryKey substringWithRange: NSMakeRange(13, [_primaryKey length] - 14)];
                        _primaryKey = [NSString stringWithFormat: @"PRIMARY KEY (%@, %@)", _primaryKey, columnName];
                    }
                    else {
                        _primaryKey = [NSString stringWithFormat: @"PRIMARY KEY (%@)", columnName];
                    }
                }
                columnValue = [attributes objectForKey: @"default"];
                if (columnValue != nil) {
                    [self column: columnName type: columnType defaultValue: ZIMSqlDefaultValue(columnValue)];
                }
                else {
                    [self column: columnName type: columnType];
                }
            }
        }
    }
}

- (void) parser: (NSXMLParser *)parser didEndElement: (NSString *)element namespaceURI: (NSString *)namespaceURI qualifiedName: (NSString *)qualifiedName {
    NSString *xpath = [_stack componentsJoinedByString: @"/"];
    if ([xpath isEqualToString: @"database/table"]) {
        _counter++;
    }
	[_stack removeLastObject];
}

- (void) parser: (NSXMLParser *)parser parseErrorOccurred: (NSError *)error {
    if (_error) {
        _error = error;
    }
}

@end

/**
 *  @@@@@ 注册类
 */

@implementation ObjectRuntime

-(void)buildTableDO:(NSArray *)xmls{
    
    for (NSData *xml in xmls) {
        NSError *error = nil;
        TableDO *THETableDO= [[TableDO alloc] initWithXmlSchema:xml error:&error];
        id columnArray = [THETableDO valueForKey:@"_columnArray"];
        id table = [THETableDO valueForKey:@"_table"];
        NSDictionary *DO_props = @{kDBProps: columnArray};
        [self createJSONModelClass:[NSString stringWithFormat:@"%@_%@",table,@"JSONModel"] superClassName:kSuperClassName_JSONModel props:DO_props  methods:nil];
        NSDictionary *DO_methods=@{kDBMethods:@{@"dataSource": @"live",@"table":table,@"primaryKey":@[@"KEY"]}};
        [self createJSONModelClass:table superClassName:kSuperClassName_ZIMOrmModel props:DO_props methods:DO_methods];
    }
}

-(id)init{
    self = [super init];
    if (self) {
//        NSDictionary *bocopReportType = @{kDBProps: @[@"PK",@"CODE",@"ID",@"NAME"]};
//        [self createJSONModelClass:@"bocopReportType_JSONModel" superClassName:kSuperClassName_JSONModel props:bocopReportType  methods:nil];
//        NSDictionary *bocopReportType_methods=@{kDBMethods:@{@"dataSource": @"live",@"table":@"bocopReportType",@"primaryKey":@[@"KEY"]}};
//        [self createJSONModelClass:@"bocopReportType" superClassName:kSuperClassName_ZIMOrmModel props:bocopReportType methods:bocopReportType_methods];
//        /* --------------------------------------神奇的分割线---------------------------------------------*/
//        NSDictionary *bocopRetApDay = @{kDBProps: @[@"PK",@"CRNDAT",@"CURBAL",@"CURRAT",@"LSTDAYBAL",@"LSTDAYYTD",@"LSTMTHBAL",@"LSTMTHYTD",@"LSTYEARBAL",@"LSTYEARYTD",@"ORGIDT",@"REPCDE",@"YTDBAL",@"BRPLAN1",@"CREATETIME"]};
//        [self createJSONModelClass:@"bocopRetApDay_JSONModel" superClassName:kSuperClassName_JSONModel props:bocopRetApDay  methods:nil];
//        NSDictionary *bocopRetApDay_methods=@{kDBMethods:@{@"dataSource": @"live",@"table":@"bocopRetApDay",@"primaryKey":@[@"KEY"]}};
//        [self createJSONModelClass:@"bocopRetApDay" superClassName:kSuperClassName_ZIMOrmModel props:bocopRetApDay methods:bocopRetApDay_methods];
//        /* --------------------------------------神奇的分割线---------------------------------------------*/
//        NSDictionary *bocopRetApDayAllBWB = @{kDBProps: @[@"PK",@"CRNDAT",@"CURBAL",@"CURRAT",@"LSTDAYBAL",@"LSTDAYYTD",@"LSTMTHBAL",@"LSTMTHYTD",@"LSTYEARBAL",@"LSTYEARYTD",@"ORGIDT",@"REPCDE",@"YTDBAL",@"BRPLAN1",@"CREATETIME"]};
//        [self createJSONModelClass:@"bocopRetApDayAllBWB_JSONModel" superClassName:kSuperClassName_JSONModel props:bocopRetApDayAllBWB  methods:nil];
//        NSDictionary *bocopRetApDayAllBWB_methods=@{kDBMethods:@{@"dataSource": @"live",@"table":@"bocopRetApDayAllBWB",@"primaryKey":@[@"KEY"]}};
//        [self createJSONModelClass:@"bocopRetApDayAllBWB" superClassName:kSuperClassName_ZIMOrmModel props:bocopRetApDayAllBWB methods:bocopRetApDayAllBWB_methods];
//        /* --------------------------------------神奇的分割线---------------------------------------------*/
//        NSDictionary *bocopRetApDayAllRWB = @{kDBProps: @[@"PK",@"CRNDAT",@"CURBAL",@"CURRAT",@"LSTDAYBAL",@"LSTDAYYTD",@"LSTMTHBAL",@"LSTMTHYTD",@"LSTYEARBAL",@"LSTYEARYTD",@"ORGIDT",@"REPCDE",@"YTDBAL",@"BRPLAN1",@"CREATETIME"]};
//        [self createJSONModelClass:@"bocopRetApDayAllRWB_JSONModel" superClassName:kSuperClassName_JSONModel props:bocopRetApDayAllRWB  methods:nil];
//        NSDictionary *bocopRetApDayAllRWB_methods=@{kDBMethods:@{@"dataSource": @"live",@"table":@"bocopRetApDayAllRWB",@"primaryKey":@[@"KEY"]}};
//        [self createJSONModelClass:@"bocopRetApDayAllRWB" superClassName:kSuperClassName_ZIMOrmModel props:bocopRetApDayAllRWB methods:bocopRetApDayAllRWB_methods];
//        /* --------------------------------------神奇的分割线---------------------------------------------*/
//        NSDictionary *bocopRetApDayAllPUb = @{kDBProps: @[@"PK",@"CRNDAT",@"CURBAL",@"CURRAT",@"LSTDAYBAL",@"LSTDAYYTD",@"LSTMTHBAL",@"LSTMTHYTD",@"LSTYEARBAL",@"LSTYEARYTD",@"ORGIDT",@"REPCDE",@"YTDBAL",@"BRPLAN1",@"CREATETIME"]};
//        [self createJSONModelClass:@"bocopRetApDayAllPUb_JSONModel" superClassName:kSuperClassName_JSONModel props:bocopRetApDayAllPUb  methods:nil];
//        NSDictionary *bocopRetApDayAllPUb_methods=@{kDBMethods:@{@"dataSource": @"live",@"table":@"bocopRetApDayAllPUb",@"primaryKey":@[@"KEY"]}};
//        [self createJSONModelClass:@"bocopRetApDayAllPUb" superClassName:kSuperClassName_ZIMOrmModel props:bocopRetApDayAllPUb methods:bocopRetApDayAllPUb_methods];
//
//        /* --------------------------------------神奇的分割线---------------------------------------------*/
//        
//        NSDictionary *bocopReportOffice = @{kDBProps: @[@"PK",@"CODE",@"CREATE_DATE",@"DEL_FLAG",@"ID",@"NAME",@"PARENT_ID",@"PARENT_IDS",@"UPDATE_DATE",@"IS_LEAVE",@"ORG_TYP"]};
//        [self createJSONModelClass:@"bocopReportOffice_JSONModel" superClassName:kSuperClassName_JSONModel props:bocopReportOffice  methods:nil];
//        NSDictionary *bocopReportOffice_methods=@{kDBMethods:@{@"dataSource": @"live",@"table":@"bocopReportOffice",@"primaryKey":@[@"KEY"]}};
//        [self createJSONModelClass:@"bocopReportOffice" superClassName:kSuperClassName_ZIMOrmModel props:bocopReportOffice methods:bocopReportOffice_methods];
//         /* --------------------------------------神奇的分割线---------------------------------------------*/
//        NSDictionary *bocopRetLagbalChg = @{kDBProps: @[@"PK",@"CRNDAT",@"CUSNAM",@"CUSTNO",@"CUSTYP",@"ORGIDT",@"REPCDE",@"TRNAMT",@"TRNCDT",@"RANKID"]};
//        [self createJSONModelClass:@"bocopRetLagbalChg_JSONModel" superClassName:kSuperClassName_JSONModel props:bocopRetLagbalChg  methods:nil];
//        NSDictionary *bocopRetLagbalChg_methods=@{kDBMethods:@{@"dataSource": @"live",@"table":@"bocopRetLagbalChg",@"primaryKey":@[@"KEY"]}};
//        [self createJSONModelClass:@"bocopRetLagbalChg" superClassName:kSuperClassName_ZIMOrmModel props:bocopRetLagbalChg methods:bocopRetLagbalChg_methods];
//        /* --------------------------------------神奇的分割线---------------------------------------------*/
//        NSDictionary *bocopRetLagbalChgPub = @{kDBProps: @[@"PK",@"CRNDAT",@"CUSNAM",@"CUSTNO",@"CUSTYP",@"ORGIDT",@"REPCDE",@"TRNAMT",@"TRNCDT",@"RANKID"]};
//        [self createJSONModelClass:@"bocopRetLagbalChgPub_JSONModel" superClassName:kSuperClassName_JSONModel props:bocopRetLagbalChgPub  methods:nil];
//        NSDictionary *bocopRetLagbalChgPub_methods=@{kDBMethods:@{@"dataSource": @"live",@"table":@"bocopRetLagbalChgPub",@"primaryKey":@[@"KEY"]}};
//        [self createJSONModelClass:@"bocopRetLagbalChgPub" superClassName:kSuperClassName_ZIMOrmModel props:bocopRetLagbalChgPub methods:bocopRetLagbalChgPub_methods];
//        /* --------------------------------------神奇的分割线---------------------------------------------*/
//        NSDictionary *RetApDayHome = @{kDBProps: @[@"PK",@"CRNDAT",@"INDCDE",@"ORGIDT",@"PER",@"VAL1",@"VAL2",@"VAL3",@"VAL4"]};
//        [self createJSONModelClass:@"RetApDayHome_JSONModel" superClassName:kSuperClassName_JSONModel props:RetApDayHome  methods:nil];
//        NSDictionary *RetApDayHome_methods=@{kDBMethods:@{@"dataSource": @"live",@"table":@"RetApDayHome",@"primaryKey":@[@"KEY"]}};
//        [self createJSONModelClass:@"RetApDayHome" superClassName:kSuperClassName_ZIMOrmModel props:RetApDayHome methods:RetApDayHome_methods];
//        /* --------------------------------------神奇的分割线---------------------------------------------*/
//        NSDictionary *ZHJYWHome = @{kDBProps: @[@"PK",@"CRNDAT",@"INDCDE",@"ORGIDT",@"VAL1",@"PER",@"VAL2",@"VAL3",@"VAL4"]};
//        [self createJSONModelClass:@"ZHJYWHome_JSONModel" superClassName:kSuperClassName_JSONModel props:ZHJYWHome  methods:nil];
//        NSDictionary *ZHJYWHome_methods=@{kDBMethods:@{@"dataSource": @"live",@"table":@"ZHJYWHome",@"primaryKey":@[@"KEY"]}};
//        [self createJSONModelClass:@"ZHJYWHome" superClassName:kSuperClassName_ZIMOrmModel props:ZHJYWHome methods:ZHJYWHome_methods];
//        /* --------------------------------------神奇的分割线---------------------------------------------*/
//        NSDictionary *CunDaiBiHome = @{kDBProps: @[@"PK",@"CRNDAT",@"INDCDE",@"ORGIDT",@"PER",@"VAL1",@"VAL2",@"VAL3",@"VAL4"]};
//        [self createJSONModelClass:@"CunDaiBiHome_JSONModel" superClassName:kSuperClassName_JSONModel props:CunDaiBiHome  methods:nil];
//        NSDictionary *CunDaiBiHome_methods=@{kDBMethods:@{@"dataSource": @"live",@"table":@"CunDaiBiHome",@"primaryKey":@[@"KEY"]}};
//        [self createJSONModelClass:@"CunDaiBiHome" superClassName:kSuperClassName_ZIMOrmModel props:CunDaiBiHome methods:CunDaiBiHome_methods];
//        /* --------------------------------------神奇的分割线---------------------------------------------*/
//        NSDictionary *ReportHeadList = @{kDBProps: @[@"PK",@"CANORDER",@"COLSPAN",@"FORMAT",@"HEADFIXED",@"HEADNAME",@"ID",@"ISLEAFHEAD",@"LINENO",@"NUMORDER",@"PARENTID",@"TITLE",@"TYPECODE",@"WIDTH"]};
//        [self createJSONModelClass:@"ReportHeadList_JSONModel" superClassName:kSuperClassName_JSONModel props:ReportHeadList  methods:nil];
//        NSDictionary *ReportHeadList_methods=@{kDBMethods:@{@"dataSource": @"live",@"table":@"ReportHeadList",@"primaryKey":@[@"KEY"]}};
//        [self createJSONModelClass:@"ReportHeadList" superClassName:kSuperClassName_ZIMOrmModel props:ReportHeadList methods:ReportHeadList_methods];
//        /* --------------------------------------神奇的分割线---------------------------------------------*/
//        NSDictionary *ReportHeadTable = @{kDBProps: @[@"PK",@"DISPLAY",@"HEADLIST",@"HEADNUM",@"ID",@"TITLE",@"UNIT"]};
//        [self createJSONModelClass:@"ReportHeadTable_JSONModel" superClassName:kSuperClassName_JSONModel props:ReportHeadTable  methods:nil];
//        NSDictionary *ReportHeadTable_methods=@{kDBMethods:@{@"dataSource": @"live",@"table":@"ReportHeadTable",@"primaryKey":@[@"KEY"]}};
//        [self createJSONModelClass:@"ReportHeadTable" superClassName:kSuperClassName_ZIMOrmModel props:ReportHeadTable methods:ReportHeadTable_methods];
        /* --------------------------------------神奇的分割线---------------------------------------------*/

    }
    return self;
}

-(void)createJSONModelClass:(NSString *)className superClassName:(NSString *)superClassName props:(NSDictionary *)props methods:(NSDictionary *)methods{
    const char *char_className = [className cStringUsingEncoding:NSUTF8StringEncoding];
    objc_allocateClassPair(NSClassFromString(superClassName), char_className, 0);
    Class myDynClassEmpty = objc_allocateClassPair(NSClassFromString(superClassName), char_className, 0);
    objc_registerClassPair(myDynClassEmpty);
    id instDynClassEmpty = [[myDynClassEmpty alloc] init];
    for ( int i = 0 ; i<[props[@"props"] count]; i++) {
        
        
        NSString * iVar = props[@"props"][i];
        NSString * setterName = [NSString stringWithFormat:@"set%@",[[props[@"props"][i] lowercaseString] capitalizedString]];
        NSString *getterName =props[@"props"][i];
        
        objc_property_attribute_t type = { "T", "@\"NSString\"" };
        objc_property_attribute_t ownership = { "C", "" }; // C = copy
        objc_property_attribute_t backingivar  = { "V", "_privateName" };
        objc_property_attribute_t attrs[] = { type, ownership, backingivar };
        const char *char_getterName = [getterName cStringUsingEncoding:NSUTF8StringEncoding];
        class_addProperty(myDynClassEmpty, char_getterName, attrs, 3);
        
         BOOL isOk = NO;
        IMP getPropperty = imp_implementationWithBlock(^(id inst){
            return objc_getAssociatedObject(inst, [iVar cStringUsingEncoding:NSUTF8StringEncoding]);
        });
        
        IMP setPropperty = imp_implementationWithBlock(^(id inst,id val){
            objc_setAssociatedObject(inst, [iVar cStringUsingEncoding:NSUTF8StringEncoding], val, OBJC_ASSOCIATION_COPY);
        });
        
        isOk = class_addMethod(myDynClassEmpty, NSSelectorFromString(getterName), getPropperty, "@@:");
        isOk = class_addMethod(myDynClassEmpty, NSSelectorFromString(setterName), setPropperty, "v@:@");
        
        sel_registerName([getterName cStringUsingEncoding:NSUTF8StringEncoding]);
        sel_registerName([setterName cStringUsingEncoding:NSUTF8StringEncoding]);
/* 测试
        NSLog(@"Setter was call returns %@",[instDynClassEmpty performSelector:sel_getUid([setterName cStringUsingEncoding:NSUTF8StringEncoding]) withObject:@"\"Hello from code!\""]);
        
        NSLog(@"Getter was call returns %@",[instDynClassEmpty performSelector:sel_getUid([getterName cStringUsingEncoding:NSUTF8StringEncoding])]);
    */
        
        /*测试
        NSString *setterName1 = [NSString stringWithFormat: @"set%@", [NSString capitalizeFirstCharacterInString: @"PK"]];
        id instDynClassEmpty = [[NSClassFromString(@"T_CACHE_BUSI") alloc] init];
        BOOL isok = [instDynClassEmpty respondsToSelector:sel_getUid([setterName cStringUsingEncoding:NSUTF8StringEncoding])];
        if (isok) {
            NSLog(@"%@",setterName);
        } 
 */
    }
    if (methods==nil) {
        return;
    }
    
    NSArray *methodName =  [methods[@"methods"] allKeys];
     for ( int i = 0 ; i<[methodName count]; i++) {
         NSString * iVar = methodName[i];
         NSString * getterName =methodName[i];
         NSString * setterName = [NSString stringWithFormat:@"set%@",[[methodName[i] lowercaseString] capitalizedString]];
         
         IMP setPropperty = imp_implementationWithBlock(^(id inst,id val){
             objc_setAssociatedObject(instDynClassEmpty, [iVar cStringUsingEncoding:NSUTF8StringEncoding], val, OBJC_ASSOCIATION_COPY);
         });
         IMP getPropperty = imp_implementationWithBlock(^(id inst){
             return methods[@"methods"][methodName[i]];
//             return objc_getAssociatedObject(instDynClassEmpty, [iVar cStringUsingEncoding:NSUTF8StringEncoding]);
         });
        class_addMethod(myDynClassEmpty, NSSelectorFromString(setterName), setPropperty, "v@:@");
         class_addMethod(myDynClassEmpty, NSSelectorFromString(getterName), getPropperty, "@@:");
         sel_registerName([getterName cStringUsingEncoding:NSUTF8StringEncoding]);
         sel_registerName([setterName cStringUsingEncoding:NSUTF8StringEncoding]);
    
         
         /*测试
         NSLog(@"Setter was call returns %@",[instDynClassEmpty performSelector:sel_getUid([setterName cStringUsingEncoding:NSUTF8StringEncoding]) withObject:@"\"Hello from code!\""]);
         
         NSLog(@"Getter was call returns %@",[instDynClassEmpty performSelector:sel_getUid([getterName cStringUsingEncoding:NSUTF8StringEncoding])]);
          */
     }
}

-(void)logggg:(NSString *)accc{
//    unsigned int outCount, i;
//    objc_property_t *properties = class_copyPropertyList(NSClassFromString(accc), &outCount);
//    for (i=0; i<outCount; i++) {
//        objc_property_t property = properties[i];
//        NSString * key = [[NSString alloc]initWithCString:property_getName(property)  encoding:NSUTF8StringEncoding];
////        NSLog(@"property[%d] :%@ \n", i, key);
//    }
}

-(void)logggg2:(NSString *)accc{
//    unsigned int outCount, i;
//    Method*    methods= class_copyMethodList([UIView class], &outCount);
//    for (i = 0; i < outCount ; i++)
//    {
//        SEL name = method_getName(methods[i]);
//        NSString *strName = [NSString  stringWithCString:sel_getName(name) encoding:NSUTF8StringEncoding];
////        NSLog(@"%@",strName);
//    }
}

@end
