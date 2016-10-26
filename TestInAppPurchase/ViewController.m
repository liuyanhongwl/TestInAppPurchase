//
//  ViewController.m
//  TestInAppPurchase
//
//  Created by Hong on 2016/10/25.
//  Copyright © 2016年 Hong. All rights reserved.
//

#import "ViewController.h"
#import <StoreKit/StoreKit.h>

//沙盒测试环境验证
#define SANDBOX @"https://sandbox.itunes.apple.com/verifyReceipt"
//正式环境验证
#define APPSTORE @"https://buy.itunes.apple.com/verifyReceipt"

static const NSString *product_id = @"com.lifelyus.ios.removeads";

@interface ViewController ()<SKProductsRequestDelegate, SKPaymentTransactionObserver>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
}

- (void)dealloc
{
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

- (IBAction)purchaseAction:(UIButton *)sender {
    if ([SKPaymentQueue canMakePayments]) {
        [self requestProduct:product_id];
    }else{
        NSLog(@"不允许应用内付费");
    }
}

- (IBAction)restoreAction:(UIButton *)sender {
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

///请求产品
- (void)requestProduct:(NSString *)productId
{
    NSSet *productIds = [NSSet setWithObject:productId];
    SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:productIds];
    request.delegate = self;
    [request start];
}

///验证
- (void)verifyPurchaseWithPaymentTransaction
{
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL];
    NSString *receiptString = [receiptData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    
    NSString *bodyString = [NSString stringWithFormat:@"{\"receipt-data\":\"%@\"}",receiptString];
    NSData *bodyData = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    
    NSURL *url = nil;
#if DEBUG
    url = [NSURL URLWithString:SANDBOX];
#else
    url = [NSURL URLWithString:APPSTORE];
#endif
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPBody = bodyData;
    request.HTTPMethod = @"POST";
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSDictionary *jsonDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
        NSLog(@"verify json dictionary : %@", jsonDic);
        NSNumber *status = [jsonDic objectForKey:@"status"];
        if (status.intValue == 0) {
            NSLog(@"验证通过");
            
        }else{
            NSLog(@"未验证通过");
            
        }
    }];
    [task resume];
}

- (void)completionTransaction:(SKPaymentTransaction *)transaction
{
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void)failureTransaction:(SKPaymentTransaction *)transaction
{
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void)restoreTransaction:(SKPaymentTransaction *)transaction
{
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

#pragma mark - Delegate
#pragma mark SKProductsRequestDelegate

///返回产品信息
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    NSArray<SKProduct *> *products = response.products;
    if (products.count == 0) {
        NSLog(@"没有商品");
        return;
    }
    
    NSLog(@"Product Id : %@", response.invalidProductIdentifiers);
    NSLog(@"商品数量 : %ld", products.count);
    
    SKProduct *p = nil;
    for (SKProduct *pro in products) {
        NSLog(@"商品---------start");
        NSLog(@"%@", [pro description]);
        NSLog(@"%@", [pro localizedTitle]);
        NSLog(@"%@", [pro localizedDescription]);
        NSLog(@"%@", [pro price]);
        NSLog(@"%@", [pro productIdentifier]);
        NSLog(@"商品---------end");
        if([pro.productIdentifier isEqualToString:product_id]){
            p = pro;
        }
    }
    
    //发送购买请求
    SKPayment *payment = [SKPayment paymentWithProduct:p];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

#pragma mark - SKRequestDelegate

- (void)requestDidFinish:(SKRequest *)request
{
    NSLog(@"%s",__FUNCTION__);
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    NSLog(@"%s",__FUNCTION__);
}

#pragma mark - SKPaymentTransactionObserver
///监听交易状态
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions
{
    NSLog(@"%s",__FUNCTION__);
    
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchasing:
                NSLog(@"交易中");
                break;
            case SKPaymentTransactionStatePurchased:
                [self verifyPurchaseWithPaymentTransaction];
                [self completionTransaction:transaction];
                NSLog(@"交易完成");
                break;
            case SKPaymentTransactionStateFailed:
                [self failureTransaction:transaction];
                NSLog(@"交易失败");
                break;
            case SKPaymentTransactionStateRestored:
                [self restoreTransaction:transaction];
                NSLog(@"交易已购买");
                break;
            case SKPaymentTransactionStateDeferred:
                NSLog(@"交易延迟");
                break;
            default:
                break;
        }
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
    NSLog(@"%s",__FUNCTION__);
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    NSLog(@"%s",__FUNCTION__);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
