//
//  ViewController.m
//  wxPayDemo
//
//  Created by 888 on 16/8/19.
//  Copyright © 2016年 lk. All rights reserved.
//

#define WECHAT_KEY @""
#define APP_ID @""
#define MCH_ID @""

#import "ViewController.h"

#import "WXApi.h"
#import "WXUtil.h"
#import "XMLParseManager.h"

@interface ViewController ()

@property (nonatomic,copy) NSString * prepayid;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)pay:(id)sender {
    //[self WXPay];
    
    [self xmlPostWithTitle:@"xx" andOrderNumber:@"2112213123141" andPrice:@"1"];
}


//获得微信支付参数
- (void)xmlPostWithTitle:(NSString *)title andOrderNumber:(NSString *)orderNumber andPrice:(NSString *)price
{
    //参数详解https://pay.weixin.qq.com/wiki/doc/api/app/app.php?chapter=9_1
    NSDictionary *unifiedPrderParams = @{
                                         @"appid"            : APP_ID,
                                         @"mch_id"           : MCH_ID,
                                         @"nonce_str"        : [self getARandomNumber],
                                         @"body"             : title,
                                         @"out_trade_no"     : orderNumber,
                                         @"total_fee"        : price,
                                         @"spbill_create_ip" : @"192.168.0.11",
                                         @"notify_url"       : @"http://kdbwg.ez360.cn",
                                         @"trade_type"       : @"APP",
                                         };
    NSArray *elements = [unifiedPrderParams allKeys];
    //按照字母顺序排序
    NSMutableString *elementsString= [NSMutableString string];
    NSArray *sortedElements = [elements sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [obj1 compare:obj2 options:NSForcedOrderingSearch];//按照ASCII升序
    }];
    //拼接字符串
    for (NSString *element in sortedElements) {
        if (![unifiedPrderParams[element] isEqualToString:@""] && ![element isEqualToString:@"sign"] && ![element isEqualToString:@"key"]) {
            [elementsString appendFormat:@"%@=%@&",element, unifiedPrderParams[element]];
        }
    }
    //添加key字段
    [elementsString appendFormat:@"key=%@",WECHAT_KEY];
    //MD5 sign 签名
    NSString *md5Sign = [WXUtil md5:elementsString];
    NSLog(@"******%@******",md5Sign);
    //得到xml参数字符串
    NSMutableString *unifiedOrderParamsXmlString = [NSMutableString string];
    [unifiedOrderParamsXmlString appendString:@"<xml>"];
    for (NSString *element in elements) {
        [unifiedOrderParamsXmlString appendFormat:@"<%@>%@</%@>",element, unifiedPrderParams[element], element];
    }
    [unifiedOrderParamsXmlString appendFormat:@"<sign>%@</sign></xml>",md5Sign];
    
    //创建url
    NSURL *unifiedOrderURL = [NSURL URLWithString:@"https://api.mch.weixin.qq.com/pay/unifiedorder"];
    //请求
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:unifiedOrderURL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:5];
    //设置提交方式
    [request setHTTPMethod:@"POST"];
    //设置数据类型
    [request addValue:@"text/xml" forHTTPHeaderField:@"Content-Type"];
    //设置编码
//    [request setValue:@"UTF-8" forKey:@"charset"];
    NSData *httpData = [unifiedOrderParamsXmlString dataUsingEncoding:NSUTF8StringEncoding];
    [request setHTTPBody:httpData];
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        NSLog(@"结果=%@",[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        
        XMLParseManager *xmlParser = [[XMLParseManager alloc] initWithXmlData:data andResultBlock:^(NSMutableDictionary *resultDictionary) {
            
            NSLog(@"----%@-----",resultDictionary);
            _prepayid = [[NSString alloc] init];
            //得到_prepayid
            _prepayid = [resultDictionary objectForKey:@"prepay_id"];
            //调起微信支付
            [self payWX];
        }];
        [xmlParser startParse];
    }];
    
    [task resume];
}


- (void)payWX
{
    
    //获取当前时间
    time_t now;
    time(&now);
    NSString *timestamp = [NSString stringWithFormat:@"%ld",now];
    NSString *noncestr = [WXUtil md5:timestamp];
    
    NSDictionary *dict = @{
                           @"appid"            : APP_ID,
                           @"noncestr"         : noncestr,
                           @"package"          : @"Sign=WXPay",
                           @"partnerid"        : MCH_ID,
                           @"prepayid"         : self.prepayid,
                           @"timestamp"        : timestamp,
                           };
    NSMutableString *contentString = [NSMutableString string];
    NSArray *keys = [dict allKeys];
    //按照字母顺序排序
    NSArray *sortedArray = [keys sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [obj1 compare:obj2 options:NSNumericSearch];//按照ASCII升序
    }];
    //拼接字符串
    for (NSString *categoryId in sortedArray) {
        if ( ![[dict objectForKey:categoryId] isEqualToString:@""] && ![categoryId isEqualToString:@"sign"] && ![categoryId isEqualToString:@"key"] ) {
            [contentString appendFormat:@"%@=%@&",categoryId, dict[categoryId]];
        }
    }
    //添加key字段
    [contentString appendFormat:@"key=%@",WECHAT_KEY];
    //加密生成字符串
    NSString *md5Sign = [WXUtil md5:contentString];
    
    //调起微信支付
    PayReq *req = [[PayReq alloc] init];
    req.openID = APP_ID;
    req.partnerId = MCH_ID;
    req.prepayId = self.prepayid;
    req.nonceStr = noncestr;
    req.timeStamp = timestamp.intValue;
    req.package = @"Sign=WXPay";
    req.sign = md5Sign;
    [WXApi sendReq:req];
    
}

- (NSString *)getARandomNumber
{
    static int kNumber = 15;
    
    NSString *sourceStr = @"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    NSMutableString *resultStr = [[NSMutableString alloc] init];
    srand((unsigned)time(0));
    for (int i = 0; i < kNumber; i++)
    {
        unsigned index = rand() % [sourceStr length];
        NSString *oneStr = [sourceStr substringWithRange:NSMakeRange(index, 1)];
        [resultStr appendString:oneStr];
    }
    return resultStr;
}

/*
//加密什么的在服务器进行
- (void)WXPay {
 
    NSString*urlString=@"http://wxpay.weixin.qq.com/pub_v2/app/app_pay.php?plat=ios";
    
    //解析服务端返回json数据
    
    NSError*error;
    
    //加载一个NSURL对象
    
    NSURLRequest*request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    
    //将请求的url数据放到NSData对象中
    
    NSData*response = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    
    if(response !=nil) {
        
        NSMutableDictionary*dict =NULL;
        
        //IOS5自带解析类NSJSONSerialization从response中解析出数据放到字典中
        
        dict = [NSJSONSerialization JSONObjectWithData:response options:NSJSONReadingMutableLeaves error:&error];
        
        NSLog(@"********url:%@",urlString);
        
        if(dict !=nil){
            
            NSMutableString*retcode = [dict objectForKey:@"retcode"];
            
            if(retcode.intValue==0){
                
                NSMutableString*stamp= [dict objectForKey:@"timestamp"];
                
                //调起微信支付
                
                //注意：此处的key一定要与demo中的key的字符一致，一个也不能少，一个也不能错。
                
                PayReq* req= [[PayReq alloc]init];
                
                req.partnerId= [dict objectForKey:@"partnerid"];
                
                req.prepayId= [dict objectForKey:@"prepayid"];
                
                req.nonceStr= [dict objectForKey:@"noncestr"];
                
                req.timeStamp= stamp.intValue;
                
                req.package= [dict objectForKey:@"package"];
                
                req.sign= [dict objectForKey:@"sign"];
                
                [WXApi sendReq:req];
                
                //日志输出
                
                NSLog(@"appid=%@\npartid=%@\nprepayid=%@\nnoncestr=%@\ntimestamp=%ld\npackage=%@\nsign=%@",[dict objectForKey:@"appid"],req.partnerId,req.prepayId,req.nonceStr,(long)req.timeStamp,req.package,req.sign);
                
            }else{
                
                NSLog(@"%@",[dict objectForKey:@"retmsg"]);
                
            }
            
        }else{
            
            NSLog(@"服务器返回错误，未获取json对象");
            
        }
        
    }else{
        
        NSLog(@"服务器返回错误");
        
    }
    
}
*/
@end
