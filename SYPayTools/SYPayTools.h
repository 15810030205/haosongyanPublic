//
//  SYPayTools.h
//  SYPayToolsDemo
//
//  Created by 郝松岩 on 2017/2/8.
//  Copyright © 2017年 郝松岩. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WXApi.h"

typedef NS_ENUM(NSInteger,PayToJavaType) {
    PayToJavaTypeSuccess = 0,
    PayToJavaTypeConfirmation = 39,//确认中
    PayToJavaTypePayTimeOut = 40 //支付超时订单
};

typedef NS_ENUM(NSInteger,PayToPythonType) {
    
    PayToPythonTypeSuccess = 1
    
};

//支付宝中支付成功后回调
typedef void (^SuccessPayWithNSDictBlock)(NSString *result);
typedef void (^PayActionAlipayFailBlock) (NSString *error);

//微信支付中的回调 成功与失败
typedef void (^PayActionWeChatSuccessBlock)(NSString *result);
typedef void (^PayActionWeChatFailBlock) (NSString *error);

@interface SYPayTools : NSObject <WXApiDelegate>

+(instancetype) sharePay ;

//微信支付相关blcok
@property (nonatomic,copy)PayActionWeChatSuccessBlock WeChatSuccessBlock;
@property (nonatomic,copy)PayActionWeChatFailBlock WeChatFailBlock;

//支付宝支付相关回调
@property (nonatomic,copy)SuccessPayWithNSDictBlock AlipaySuccessBlock;
@property (nonatomic,copy)PayActionAlipayFailBlock AlipayFailBlock;

/**
 orderno             需要转化的orderno
 payPriceStr         支付价格
 productName         产品名称
 productDescription  商品描述
 lastMoney           最终要提交的金额
 */
- (void) payActionWithAlipayOrderno:(NSString *)orderno withLastMoney:(NSString *)lastMoney andPayPrice:(NSString *)payPriceStr productName:(NSString *)productName productDescription:(NSString *)productDescription withSuccess:(SuccessPayWithNSDictBlock)success withFail:(PayActionAlipayFailBlock )fail;

//支付宝的后台入口
- (void)payActionWithAlipayOrdernoHou:(NSString *)orderString  withSuccess:(SuccessPayWithNSDictBlock)success withFail:(PayActionAlipayFailBlock)fail;
/**
 微信支付
 orderno             订单编号
 detail              支付价格
 body                标题
 */
- (void) payActionWithWeChatDetail:(NSString *)detail orderbody:(NSString *)body orderno:(NSString *)orderno withSuccess:(PayActionWeChatSuccessBlock)success withFail:(PayActionWeChatFailBlock )fail;

/**
 *  回调入口
 */
- (BOOL) handleOpenURL:(NSURL *) url;

@end
