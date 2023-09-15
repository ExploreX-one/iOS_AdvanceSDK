//
//  BdInterstitialAdapter.m
//  AdvanceSDK
//
//  Created by MS on 2022/6/21.
//

#import "BdInterstitialAdapter.h"

#if __has_include(<BaiduMobAdSDK/BaiduMobAdExpressInterstitial.h>)
#import <BaiduMobAdSDK/BaiduMobAdExpressInterstitial.h>
#else
#import "BaiduMobAdSDK/BaiduMobAdExpressInterstitial.h"
#endif

#import "AdvanceInterstitial.h"
#import "AdvLog.h"
#import "AdvanceAdapter.h"

@interface BdInterstitialAdapter ()<BaiduMobAdExpressIntDelegate, AdvanceAdapter>
@property (nonatomic, strong) BaiduMobAdExpressInterstitial *bd_ad;
@property (nonatomic, weak) AdvanceInterstitial *adspot;
@property (nonatomic, strong) AdvSupplier *supplier;

@end

@implementation BdInterstitialAdapter

- (instancetype)initWithSupplier:(AdvSupplier *)supplier adspot:(id)adspot {
    if (self = [super init]) {
        _adspot = adspot;
        _supplier = supplier;
        self.bd_ad = [[BaiduMobAdExpressInterstitial alloc] init];
        self.bd_ad.publisherId = _supplier.mediaid;
        self.bd_ad.adUnitTag = _supplier.adspotid;
        self.bd_ad.delegate = self;
    }
    return self;
}

- (void)loadAd {
    [self.bd_ad load];
}

- (void)showAd {
    [self.bd_ad showFromViewController:self.adspot.viewController];
}

- (void)winnerAdapterToShowAd {
    if ([self.delegate respondsToSelector:@selector(didFinishLoadingInterstitialADWithSpotId:)]) {
        [self.delegate didFinishLoadingInterstitialADWithSpotId:self.adspot.adspotid];
    }
}

- (void)dealloc {
    ADV_LEVEL_INFO_LOG(@"%s", __func__);
}


- (void)interstitialAdLoaded:(BaiduMobAdExpressInterstitial *)interstitial {
    [self.adspot.manager setECPMIfNeeded:[[interstitial getECPMLevel] integerValue] supplier:_supplier];
    [self.adspot.manager reportEventWithType:AdvanceSdkSupplierRepoSucceed supplier:_supplier error:nil];
    [self.adspot.manager checkTargetWithResultfulSupplier:_supplier loadAdState:AdvanceSupplierLoadAdSuccess];
}

- (void)interstitialAdLoadFailCode:(NSString *)errCode
                           message:(NSString *)message
                    interstitialAd:(BaiduMobAdExpressInterstitial *)interstitial {
    NSError *error = [[NSError alloc]initWithDomain:@"BDAdErrorDomain" code:errCode.intValue userInfo:@{@"msg":message}];
    [self.adspot.manager reportEventWithType:AdvanceSdkSupplierRepoFailed supplier:_supplier error:error];
    [self.adspot.manager checkTargetWithResultfulSupplier:_supplier loadAdState:AdvanceSupplierLoadAdFailed];
}

- (void)interstitialAdDownloadSucceeded:(BaiduMobAdExpressInterstitial *)interstitial {
    ADV_LEVEL_INFO_LOG(@"ExpressInterstitial downloadSucceeded 缓存成功");
}


- (void)interstitialAdExposure:(BaiduMobAdExpressInterstitial *)interstitial {
    ADV_LEVEL_INFO_LOG(@"ExpressInterstitial exposure 曝光成功");
    [self.adspot.manager reportEventWithType:AdvanceSdkSupplierRepoImped supplier:_supplier error:nil];
    if ([self.delegate respondsToSelector:@selector(interstitialDidShowForSpotId:extra:)]) {
        [self.delegate interstitialDidShowForSpotId:self.adspot.adspotid extra:self.adspot.ext];
    }
}


- (void)interstitialAdDidClick:(BaiduMobAdExpressInterstitial *)interstitial {
    ADV_LEVEL_INFO_LOG(@"ExpressInterstitial click 发生点击");
    [self.adspot.manager reportEventWithType:AdvanceSdkSupplierRepoClicked supplier:_supplier error:nil];
    if ([self.delegate respondsToSelector:@selector(interstitialDidClickForSpotId:extra:)]) {
        [self.delegate interstitialDidClickForSpotId:self.adspot.adspotid extra:self.adspot.ext];
    }
}

- (void)interstitialAdDidLPClose:(BaiduMobAdExpressInterstitial *)interstitial {
    ADV_LEVEL_INFO_LOG(@"ExpressInterstitial lpClose 落地页关闭");
}

- (void)interstitialAdDidClose:(BaiduMobAdExpressInterstitial *)interstitial {
    ADV_LEVEL_INFO_LOG(@"ExpressInterstitial close 点击关闭");
    if ([self.delegate respondsToSelector:@selector(interstitialDidCloseForSpotId:extra:)]) {
        [self.delegate interstitialDidCloseForSpotId:self.adspot.adspotid extra:self.adspot.ext];
    }
}


@end
