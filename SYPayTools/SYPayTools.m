//
//  SYPayTools.m
//  SYPayToolsDemo
//
//  Created by 郝松岩 on 2017/2/8.
//  Copyright © 2017年 郝松岩. All rights reserved.
//
#import "SYPayTools.h"
#import "AppDelegate.h"
#import "Order.h"
#import <AlipaySDK/AlipaySDK.h>
#import "DataSigner.h"

@implementation SYPayTools

#define K_PAYSUCCESSHUD     @"支付成功"
#define K_PAYFAILHUD        @"支付失败"
#define K_PAYPROGRESSFAIL   @"发生错误"

#define K_SYAPPSCHEME       @"SYPayToolsDemo"
#define K_JXPRIVTE_KEY      @""

static id _sharedInstance;

+(instancetype) sharePay {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[SYPayTools alloc] init];
    });
    
    return _sharedInstance;
}

//回调处理
- (BOOL) handleOpenURL:(NSURL *) url{
    
    //这里进行判定是使用极简包还是使用的是支付宝钱包
    if ([url.host isEqualToString:@"safepay"]) {
        [[AlipaySDK defaultService] processOrderWithPaymentResult:url standbyCallback:^(NSDictionary *resultDic) {
            if ([self isSuccessAlipayResultWithResultDict:resultDic]) {
                self.AlipaySuccessBlock(K_PAYSUCCESSHUD);
            }else{
                self.AlipayFailBlock(K_PAYFAILHUD);
            }
        }];
    }
    if ([url.host isEqualToString:@"platformapi"]){//支付宝钱包快登授权返回authCode
        
        [[AlipaySDK defaultService] processAuthResult:url standbyCallback:^(NSDictionary *resultDic) {
            
            if ([self isSuccessAlipayResultWithResultDict:resultDic]) {
                self.AlipaySuccessBlock(K_PAYSUCCESSHUD);
            }else{
                self.AlipayFailBlock(K_PAYFAILHUD);
            }
        }];
    }
    
    return [WXApi handleOpenURL:url delegate:self];
    
}
//支付宝走后台的支付
#pragma mark -- 这里根据商品信息进行订单生成
- (void)payActionWithAlipayOrdernoHou:(NSString *)orderString  withSuccess:(SuccessPayWithNSDictBlock)success withFail:(PayActionAlipayFailBlock)fail
{
    
    NSString *appScheme = K_SYAPPSCHEME;
    self.AlipaySuccessBlock = success ;
    self.AlipayFailBlock = fail;
    
    if (orderString != nil) {
        
        [[AlipaySDK defaultService] payOrder:orderString fromScheme:appScheme callback:^(NSDictionary *resultDic) {
            
            NSLog(@"支付3 ====== %@",resultDic);
            if ([self isSuccessAlipayResultWithResultDict:resultDic]) {
                
                success(K_PAYSUCCESSHUD);
                
            }else{
                
                fail(K_PAYFAILHUD);
            }
            
        } ];
    }else{
        //显示错误HUD
        fail(K_PAYPROGRESSFAIL);
    }
    
    
}

#pragma mark -- 这里根据商品信息进行订单生成
- (void)payActionWithAlipayOrderno:(NSString *)orderno withLastMoney:(NSString *)lastMoney  andPayPrice:(NSString *)payPriceStr productName:(NSString *)productName productDescription:(NSString *)productDescription withSuccess:(SuccessPayWithNSDictBlock)success withFail:(PayActionAlipayFailBlock)fail
{
    self.AlipaySuccessBlock = success ;
    self.AlipayFailBlock = fail;
    
    
//   这里进行订单的生成或者是更改该方法 让服务端传过来相关信息
//    将商品信息赋予AlixPayOrder的成员变量
    Order *order = [[Order alloc] init];
//    关于订单信息并未增加 根据自己需求进行增加
    
    NSString *appScheme = K_SYAPPSCHEME;
    
    //将商品信息拼接成字符串
    NSString *orderSpec = [order description];
    NSLog(@"orderSpec = %@",orderSpec);
    
    id<DataSigner> signer = CreateRSADataSigner(K_JXPRIVTE_KEY);
    
    NSString *signedString = [signer signString:orderSpec];
    
    //将签名成功字符串格式化为订单字符串,请严格按照该格式
    NSString *orderString = nil;
    
    if (signedString != nil) {
        orderString = [NSString stringWithFormat:@"%@&sign=\"%@\"&sign_type=\"%@\"",
                       orderSpec, signedString, @"RSA"];
        
        [[AlipaySDK defaultService] payOrder:orderString fromScheme:appScheme callback:^(NSDictionary *resultDic) {
            
            NSLog(@"支付3 ====== %@",resultDic);
            if ([self isSuccessAlipayResultWithResultDict:resultDic]) {
                
                success(K_PAYSUCCESSHUD);
                
            }else{
                
                fail(K_PAYFAILHUD);
            }
            
        } ];
    }else{
        //显示错误HUD
        fail(K_PAYPROGRESSFAIL);
    }
    
    
}
#pragma mark -- 增加成功与失败筛选
- (BOOL )isSuccessAlipayResultWithResultDict:(NSDictionary *)result
{
    NSString *state = [NSString stringWithFormat:@"%@",result[@"resultStatus"]];
    NSLog(@"%@",result[@"resultStatus"]);
    if ([state isEqualToString:@"9000"]) {
        
        return YES;
    }else{
        
        return NO;
        
    }
    
    
    
}

#pragma mark -- 从微信支付
- (void) payActionWithWeChatDetail:(NSString *)detail orderbody:(NSString *)body orderno:(NSString *)orderno withSuccess:(PayActionWeChatSuccessBlock)success withFail:(PayActionWeChatFailBlock )fail
{
    
    if(![WXApi isWXAppInstalled]) {
        fail(@"系统未安装该软件");
        return ;
    }
 
    [WXApi registerApp:@"appid"];
    
    PayReq* req   = [[PayReq alloc] init];
    req.openID    = @"appid";
    req.partnerId = @"partnerid";
    req.prepayId  = @"prepayid";
    req.nonceStr  = @"noncestr";
    NSMutableString *stamp  = [[NSMutableString alloc]init];
    req.timeStamp = stamp.intValue;
    req.package   = @"package";
    req.sign      = @"sign";
    
    [WXApi sendReq:req];
    
    
    
}

#pragma mark - 微信回调
- (void)onResp:(BaseResp *)resp{
    
    NSLog(@"onResp = %d",resp.errCode);
    
    if ([resp isKindOfClass:[PayResp class]]) {
        
        PayResp*response=(PayResp*)resp;
        
        switch (response.errCode) {
            case WXSuccess:
                self.WeChatSuccessBlock(K_PAYSUCCESSHUD);
                break;
                
            case WXErrCodeUserCancel:
                self.WeChatFailBlock(K_PAYFAILHUD);
                break;
                
            default:
                self.WeChatFailBlock(K_PAYFAILHUD);
                break;
        }
    }
}


@end
