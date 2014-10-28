实现功能
<1>根据下载自动创建表，及表关联 (cn.com.yitong.db文件夹下的所有xml文件)
<2>可扩展的多种加密方式 SQLCipher+MIHCrypto
<3>支持一般的增删改查ORM+SQL(后期可以逐步完善)
<4>可根据json直接入库，不需要任何操作，对应的可以直接查出并转成json，不需要任何操作(JsonModel+多继承+DBUtil)
<5>支持FMDB
<6>支持Cordova

未实现功能
<1>异常处理没有集成
<2>不支持数据回滚
<3>数据库没有做版本控制
<4>暂时只支持json


文档/源码
@https://github.com/MrHuhao/objective-c-sql-query-builder
@https://github.com/ziminji/objective-c-sql-query-builder/wiki/CRUD-Operations
@http://db.apache.org/ddlutils/
@https://github.com/icanzilb/JSONModel
@https://github.com/claybridges/ObjCMultInheritanceExample


日志
////////////////////////////////////////////////////////////////
<1>jsonmodel源码有修改，请不要用pod出来的jsonmodel或者下载的源码
