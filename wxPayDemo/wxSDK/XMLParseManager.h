//
//  XMLParseManager.h
//  wxPayDemo
//
//  Created by 888 on 16/8/19.
//  Copyright © 2016年 lk. All rights reserved.
//xml解析，wx返回值居然是xml，吔屎了？？？？？

#import <Foundation/Foundation.h>

typedef void(^ResultBlock)(NSMutableDictionary *resultDictionary);
@interface XMLParseManager : NSObject

- (XMLParseManager *)initWithXmlData:(NSData *)xmlData andResultBlock:(ResultBlock)resultBlock;
//开始xml解析
- (void)startParse;

@end
