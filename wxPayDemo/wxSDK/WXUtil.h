//
//  WXUtil.h
//  wxPayDemo
//
//  Created by 888 on 16/8/19.
//  Copyright © 2016年 lk. All rights reserved.
//wx加密工具

#import <Foundation/Foundation.h>

@interface WXUtil : NSObject <NSXMLParserDelegate>

//加密实现和SHA1(嘻哈算法)
+ (NSString *)md5:(NSString *)str;
+ (NSString *)sha1:(NSString *)str;

//实现http GET/POST 解析返回的json数据
+ (NSData *)httSend:(NSString *)url method:(NSString *)method data:(NSString *)data;

@end
