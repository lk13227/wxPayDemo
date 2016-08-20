//
//  XMLParseManager.m
//  wxPayDemo
//
//  Created by 888 on 16/8/19.
//  Copyright © 2016年 lk. All rights reserved.
//

#import "XMLParseManager.h"

@interface XMLParseManager () <NSXMLParserDelegate>
@property (nonatomic,strong) NSData * xmlData;
@property (nonatomic,copy) ResultBlock resultBlock;
@property (nonatomic,strong) NSXMLParser * xmlParser;
@property (nonatomic,strong) NSMutableDictionary * resultDictionary;
@property (nonatomic,strong) NSMutableString * contentString;
@end

@implementation XMLParseManager

- (XMLParseManager *)initWithXmlData:(NSData *)xmlData andResultBlock:(ResultBlock)resultBlock
{
    if (self = [super init]) {
        self.xmlData = xmlData;
        self.resultBlock = resultBlock;
    }
    return self;
}

//开始xml解析
- (void)startParse
{
    _xmlParser = [[NSXMLParser alloc] initWithData:_xmlData];
    [_xmlParser setDelegate:self];
    [_xmlParser parse];
}
//解析要开始的时候，初始化解析的内容
- (void)parserDidStartDocument:(NSXMLParser *)parser
{
    _resultDictionary = [NSMutableDictionary dictionary];
    _contentString = [NSMutableString string];
}
//记录节点内容
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    [_contentString setString:string];
}
- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if ( ![_contentString isEqualToString:@"\n"] && ![elementName isEqualToString:@"root"] ) {
        [_resultDictionary setObject:[_contentString copy] forKey:elementName];
    }
}
//解析结束之后，传入一个字典
- (void)parserDidEndDocument:(NSXMLParser *)parser
{
    _resultBlock(_resultDictionary);
}

@end
