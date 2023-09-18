//
//  KsFullScreenVideoAdapter.m
//  AdvanceSDK
//
//  Created by MS on 2021/4/23.
//

#import "KsFullScreenVideoAdapter.h"
#if __has_include(<KSAdSDK/KSAdSDK.h>)
#import <KSAdSDK/KSAdSDK.h>
#else
//#import "KSAdSDK.h"
#endif

#import "AdvanceFullScreenVideo.h"
#import "UIApplication+Adv.h"
#import "AdvLog.h"
@interface KsFullScreenVideoAdapter ()<KSFullscreenVideoAdDelegate>
@property (nonatomic, strong) KSFullscreenVideoAd *ks_ad;
@property (nonatomic, weak) AdvanceFullScreenVideo *adspot;
@property (nonatomic, strong) AdvSupplier *supplier;
@property (nonatomic, assign) BOOL isCached;

@end

@implementation KsFullScreenVideoAdapter

- (instancetype)initWithSupplier:(AdvSupplier *)supplier adspot:(id)adspot {
    if (self = [super initWithSupplier:supplier adspot:adspot]) {
        _adspot = adspot;
        _supplier = supplier;
        _ks_ad = [[KSFullscreenVideoAd alloc] initWithPosId:_supplier.adspotid];
        _ks_ad.showDirection = KSAdShowDirection_Vertical;
        _ks_ad.shouldMuted = _adspot.muted;
    }
    return self;
}

- (void)supplierStateLoad {
    ADV_LEVEL_INFO_LOG(@"加载快手 supplier: %@", _supplier);
    _supplier.state = AdvanceSdkSupplierStateInPull; // 从请求广告到结果确定前
    _ks_ad.delegate = self;
    [_ks_ad loadAdData];
}

- (void)supplierStateInPull {
    ADV_LEVEL_INFO_LOG(@"快手加载中...");
}

- (void)supplierStateSuccess {
    ADV_LEVEL_INFO_LOG(@"快手 成功");
    if ([self.delegate respondsToSelector:@selector(didFinishLoadingFullscreenVideoADWithSpotId:)]) {
        [self.delegate didFinishLoadingFullscreenVideoADWithSpotId:self.adspot.adspotid];
    }
    
    if (_isCached) {
        if ([self.delegate respondsToSelector:@selector(fullscreenVideoDidDownLoadForSpotId:extra:)]) {
            [self.delegate fullscreenVideoDidDownLoadForSpotId:self.adspot.adspotid extra:self.adspot.ext];
        }
    }
}

- (void)supplierStateFailed {
    ADV_LEVEL_INFO_LOG(@"快手 失败");
    [self.adspot loadNextSupplierIfHas];
}


- (void)loadAd {
    [super loadAd];
}

- (void)showAd {
    __weak typeof(self) _self = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(_self) self = _self;
        if (self.ks_ad.isValid) {
            [self.ks_ad showAdFromRootViewController:self.adspot.viewController.navigationController];
        }
    });

//    [_gdt_ad presentFullScreenAdFromRootViewController:_adspot.viewController];
}

- (BOOL)isAdValid {
    return _ks_ad.isValid;
}

- (void)dealloc {
    ADVLog(@"%s", __func__);
}

/**
 This method is called when video ad material loaded successfully.
 */
- (void)fullscreenVideoAdDidLoad:(KSFullscreenVideoAd *)fullscreenVideoAd {
    [self.adspot reportEventWithType:AdvanceSdkSupplierRepoSucceed supplier:_supplier error:nil];
//    ADVLog(@"快手全屏视频拉取成功 %@",self.ks_ad);
    _supplier.state = AdvanceSdkSupplierStateSuccess;
    if (_supplier.isParallel == YES) {
//        NSLog(@"修改状态: %@", _supplier);
        return;
    }

    if ([self.delegate respondsToSelector:@selector(didFinishLoadingFullscreenVideoADWithSpotId:)]) {
        [self.delegate didFinishLoadingFullscreenVideoADWithSpotId:self.adspot.adspotid];
    }

}
/**
 This method is called when video ad materia failed to load.
 @param error : the reason of error
 */
- (void)fullscreenVideoAd:(KSFullscreenVideoAd *)fullscreenVideoAd didFailWithError:(NSError *_Nullable)error {
    [self.adspot reportEventWithType:AdvanceSdkSupplierRepoFailed  supplier:_supplier error:error];
    _supplier.state = AdvanceSdkSupplierStateFailed;
    if (_supplier.isParallel == YES) {
        return;
    }
}

/**
 This method is called when cached successfully.
 */
- (void)fullscreenVideoAdVideoDidLoad:(KSFullscreenVideoAd *)fullscreenVideoAd {
    if (_supplier.isParallel == YES) {
        _isCached = YES;
        return;
    }
    if ([self.delegate respondsToSelector:@selector(fullscreenVideoDidDownLoadForSpotId:extra:)]) {
        [self.delegate fullscreenVideoDidDownLoadForSpotId:self.adspot.adspotid extra:self.adspot.ext];
    }
}
/**
 This method is called when video ad slot will be showing.
 */
- (void)fullscreenVideoAdWillVisible:(KSFullscreenVideoAd *)fullscreenVideoAd {
    
}
/**
 This method is called when video ad slot has been shown.
 */
- (void)fullscreenVideoAdDidVisible:(KSFullscreenVideoAd *)fullscreenVideoAd {
    [self.adspot reportEventWithType:AdvanceSdkSupplierRepoImped supplier:_supplier error:nil];
}
/**
 This method is called when video ad is about to close.
 */
- (void)fullscreenVideoAdWillClose:(KSFullscreenVideoAd *)fullscreenVideoAd {
    
}
/**
 This method is called when video ad is closed.
 */
- (void)fullscreenVideoAdDidClose:(KSFullscreenVideoAd *)fullscreenVideoAd {
    if ([self.delegate respondsToSelector:@selector(fullscreenVideoDidCloseForSpotId:extra:)]) {
        [self.delegate fullscreenVideoDidCloseForSpotId:self.adspot.adspotid extra:self.adspot.ext];
    }
}

/**
 This method is called when video ad is clicked.
 */
- (void)fullscreenVideoAdDidClick:(KSFullscreenVideoAd *)fullscreenVideoAd {
    [self.adspot reportEventWithType:AdvanceSdkSupplierRepoClicked supplier:_supplier error:nil];
    if ([self.delegate respondsToSelector:@selector(fullscreenVideoDidClickForSpotId:extra:)]) {
        [self.delegate fullscreenVideoDidClickForSpotId:self.adspot.adspotid extra:self.adspot.ext];
    }
}
/**
 This method is called when video ad play completed or an error occurred.
 @param error : the reason of error
 */
- (void)fullscreenVideoAdDidPlayFinish:(KSFullscreenVideoAd *)fullscreenVideoAd didFailWithError:(NSError *_Nullable)error {
    if (!error) {
        if ([self.delegate respondsToSelector:@selector(fullscreenVideoDidEndPlayingForSpotId:extra:)]) {
            [self.delegate fullscreenVideoDidEndPlayingForSpotId:self.adspot.adspotid extra:self.adspot.ext];
        }
    }
}
/**
 This method is called when the video begin to play.
 */
- (void)fullscreenVideoAdStartPlay:(KSFullscreenVideoAd *)fullscreenVideoAd {
    if ([self.delegate respondsToSelector:@selector(fullscreenVideoDidStartPlayingForSpotId:extra:)]) {
        [self.delegate fullscreenVideoDidStartPlayingForSpotId:self.adspot.adspotid extra:self.adspot.ext];
    }
}
/**
 This method is called when the user clicked skip button.
 */
- (void)fullscreenVideoAdDidClickSkip:(KSFullscreenVideoAd *)fullscreenVideoAd {
    if ([self.delegate respondsToSelector:@selector(fullscreenVideoDidClickSkipForSpotId:extra:)]) {
        [self.delegate fullscreenVideoDidClickSkipForSpotId:self.adspot.adspotid extra:self.adspot.ext];
    }
}



@end
