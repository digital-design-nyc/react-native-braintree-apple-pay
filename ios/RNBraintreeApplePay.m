
#import "RNBraintreeApplePay.h"

@implementation RNBraintreeApplePay

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}
RCT_EXPORT_MODULE()

RCT_REMAP_METHOD(show,
                 showWithOptions:(NSDictionary*)options resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    self.resolve = resolve;
    self.reject = reject;
    [self setDone:NO];

    NSString* clientToken = options[@"clientToken"];
    if (!clientToken) {
        reject(@"NO_CLIENT_TOKEN", @"You must provide a client token", nil);
        return;
    }
    if (!options[@"merchantIdentifier"]) {
        reject(@"NO_MERCHANT_IDENTIFIER", @"You must provide a merchant identifier", nil);
        return;
    }
    if (!options[@"countryCode"]) {
        reject(@"NO_COUNTRY_CODE", @"You must provide a country code", nil);
        return;
    }
    if (!options[@"currencyCode"]) {
        reject(@"NO_CURRENCY_CODE", @"You must provide a currency code", nil);
        return;
    }
    if (!options[@"merchantName"]) {
        reject(@"NO_MERCHANT_NAME", @"You must provide a merchant name", nil);
        return;
    }

    BTAPIClient *apiClient = [[BTAPIClient alloc] initWithAuthorization:clientToken];
    self.dataCollector = [[BTDataCollector alloc] initWithAPIClient:apiClient];
    [self.dataCollector collectCardFraudData:^(NSString * _Nonnull deviceDataCollector) {
        // Save deviceData
        self.deviceDataCollector = deviceDataCollector;
    }];

    

    //Apple Pay
    self.braintreeClient = [[BTAPIClient alloc] initWithAuthorization:clientToken];

    self.paymentRequest = [[PKPaymentRequest alloc] init];
    self.paymentRequest.merchantIdentifier = options[@"merchantIdentifier"];
    self.paymentRequest.merchantCapabilities = PKMerchantCapability3DS;
    self.paymentRequest.countryCode = options[@"countryCode"];
    self.paymentRequest.currencyCode = options[@"currencyCode"];
    self.paymentRequest.supportedNetworks = @[PKPaymentNetworkAmex, PKPaymentNetworkVisa, PKPaymentNetworkMasterCard, PKPaymentNetworkDiscover, PKPaymentNetworkChinaUnionPay];
    self.paymentRequest.paymentSummaryItems =
        @[
            [PKPaymentSummaryItem summaryItemWithLabel:options[@"merchantName"] amount:[NSDecimalNumber decimalNumberWithString:options[@"orderTotal"]]]
        ];

    self.viewController = [[PKPaymentAuthorizationViewController alloc] initWithPaymentRequest: self.paymentRequest];
    self.viewController.delegate = self;

    [self.reactRoot presentViewController:self.viewController animated:YES completion:nil];
}

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                       didAuthorizePayment:(PKPayment *)payment
                                completion:(void (^)(PKPaymentAuthorizationStatus))completion
{
    // Example: Tokenize the Apple Pay payment
    BTApplePayClient *applePayClient = [[BTApplePayClient alloc] initWithAPIClient:self.braintreeClient];
    [applePayClient tokenizeApplePayPayment:payment
                                 completion:^(BTApplePayCardNonce *tokenizedApplePayPayment,
                                              NSError *error) {
        if (tokenizedApplePayPayment) {
            // On success, send nonce to your server for processing.
            // If applicable, address information is accessible in `payment`.
            // NSLog(@"description = %@", tokenizedApplePayPayment.localizedDescription);

            completion(PKPaymentAuthorizationStatusSuccess);


            NSMutableDictionary* result = [NSMutableDictionary new];
            [result setObject:tokenizedApplePayPayment.nonce forKey:@"nonce"];
            [result setObject:@"Apple Pay" forKey:@"type"];
            [result setObject:[NSString stringWithFormat: @"%@ %@", @"", tokenizedApplePayPayment.type] forKey:@"description"];
            [result setObject:[NSNumber numberWithBool:false] forKey:@"isDefault"];
            [result setObject:self.deviceDataCollector forKey:@"deviceData"];

            self.resolve(result);
            [self setDone:YES];

        } else {
            // Tokenization failed. Check `error` for the cause of the failure.

            // Indicate failure via the completion callback:
            completion(PKPaymentAuthorizationStatusFailure);
        }
    }];
}

// Be sure to implement -paymentAuthorizationViewControllerDidFinish:
- (void)paymentAuthorizationViewControllerDidFinish:(PKPaymentAuthorizationViewController *)controller{
    BOOL done = [self done];
    if (!done) self.reject(@"USER_CANCELLATION", @"The user cancelled", nil);
    
    [self.reactRoot dismissViewControllerAnimated:YES completion:nil];
}

- (UIViewController*)reactRoot {
    UIViewController *root  = [UIApplication sharedApplication].keyWindow.rootViewController;
    UIViewController *maybeModal = root.presentedViewController;

    UIViewController *modalRoot = root;

    if (maybeModal != nil) {
        modalRoot = maybeModal;
    }

    return modalRoot;
}

@end
  