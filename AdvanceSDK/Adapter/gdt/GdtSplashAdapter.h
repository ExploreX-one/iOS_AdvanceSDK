//
//  GdtSplashAdapter.h
//  AdvanceSDKExample
//
//  Created by CherryKing on 2020/4/8.
//  Copyright © 2020 Gdt. All rights reserved.
//

#import "AdvanceBaseAdapter.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "AdvanceSplashDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface GdtSplashAdapter : AdvanceBaseAdapter
@property (nonatomic, weak) id<AdvanceSplashDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
