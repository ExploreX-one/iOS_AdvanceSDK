//
//  AdvDeviceInfoUtil.m
//  advancelib
//
//  Created by allen on 2019/9/11.
//  Copyright © 2019 Bayescom. All rights reserved.
//

#import "AdvDeviceInfoUtil.h"
#import "AdvSdkConfig.h"
#import <UIKit/UIDevice.h>
#import <UIKit/UIScreen.h>
#import <ifaddrs.h>
#import <arpa/inet.h>
#import <net/if.h>
#import <sys/utsname.h>
#import <AdSupport/AdSupport.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CommonCrypto/CommonCrypto.h>

#define IOS_CELLULAR    @"pdp_ip0"
#define IOS_WIFI        @"en0"
#define IOS_VPN         @"utun0"
#define IP_ADDR_IPv4    @"ipv4"
#define IP_ADDR_IPv6    @"ipv6"
// 永久保存
#define kTimeOutForeverKey    @"kTimeOutForeverKey"

// 一个月
#define kTimeOutOneMonthKey    @"kTimeOutOneMonth"
#define kTimeOutOneMonth 60 * 60 * 24 * 30 // 30天

#define kTimeOutOneHourKey    @"kTimeOutOneHour"
#define kTimeOutOneHour 60 * 60 // 1小时


@implementation AdvDeviceInfoUtil
+ (NSMutableDictionary *)getDeviceInfoWithMediaId:(NSString *)mediaId adspotId:(NSString *)adspotId {
    NSMutableDictionary *deviceInfo = [[NSMutableDictionary alloc] init];
    @try {
        [deviceInfo setValue:AdvanceSdkVersion forKey:@"sdk_version"];
        [deviceInfo setValue:AdvanceSdkAPIVersion forKey:@"version"];
        [deviceInfo setValue:mediaId forKey:@"appid"];
        [deviceInfo setValue:adspotId forKey:@"adspotid"];
        [deviceInfo setValue:[AdvDeviceInfoUtil getAppVersion] forKey:@"appver"];
        NSString *time = [AdvDeviceInfoUtil getTime];
        [deviceInfo setValue:time forKey:@"time"];

        //make
        [deviceInfo setValue:[AdvDeviceInfoUtil getMake] forKey:@"make"];
        //model
        [deviceInfo setValue:[AdvDeviceInfoUtil getModel] forKey:@"model"];
        //os
        [deviceInfo setValue:@1 forKey:@"os"];
        //osv
        [deviceInfo setValue:[AdvDeviceInfoUtil getOsv] forKey:@"osv"];
        //idfa
        [deviceInfo setValue:[AdvDeviceInfoUtil getIdfa] forKey:@"idfa"];
        //carrier
        [deviceInfo setValue:[AdvDeviceInfoUtil getCarrier] forKey:@"carrier"];
        //network
        [deviceInfo setValue:[AdvDeviceInfoUtil getNetwork] forKey:@"network"];
        //idfv
        [deviceInfo setValue:[AdvDeviceInfoUtil getIdfv] forKey:@"idfv"];
        // 个性化广告推送开关
        [deviceInfo setValue:[AdvSdkConfig shareInstance].isAdTrack ? @"0" : @"1" forKey:@"donottrack"];
        NSString *reqid = [AdvDeviceInfoUtil getAuctionId];
        if (reqid) {
            [deviceInfo setValue:reqid forKey:@"reqid"];
        }

        return deviceInfo;
    } @catch (NSException *exception) {
        return deviceInfo;
    }

}

+ (NSString *)getAppVersion {
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];

    NSString *appVersion = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    return appVersion;
}

+ (NSString *)getTime {
    NSString *timeString = @"";
    @try {
        NSDate *dat = [NSDate dateWithTimeIntervalSinceNow:0];
        NSTimeInterval a = [dat timeIntervalSince1970];
        timeString = [NSString stringWithFormat:@"%0.0f", a * 1000];
    } @catch (NSException *exception) {
    } @finally {
        return timeString;
    }
}

+ (NSString *)getMake {
    return @"apple";
}

+ (BOOL)isValidatIP:(NSString *)ipAddress {
    BOOL passFlag = NO;
    @try {
        if (ipAddress.length == 0) {
            passFlag = NO;
        }
        NSString *urlRegEx = @"^([01]?\\d\\d?|2[0-4]\\d|25[0-5])\\."
                             "([01]?\\d\\d?|2[0-4]\\d|25[0-5])\\."
                             "([01]?\\d\\d?|2[0-4]\\d|25[0-5])\\."
                             "([01]?\\d\\d?|2[0-4]\\d|25[0-5])$";

        NSError *error;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:urlRegEx options:0 error:&error];

        if (regex && ipAddress) {
            NSTextCheckingResult *firstMatch = [regex firstMatchInString:ipAddress options:0 range:NSMakeRange(0, [ipAddress length])];

            if (firstMatch) {
                //            NSRange resultRange = [firstMatch rangeAtIndex:0];
                //            NSString *result=[ipAddress substringWithRange:resultRange];
                //输出结果
                //           BYLog(@"%@",result);
                passFlag = YES;
            }
        }
        passFlag = NO;
    } @catch (NSException *exception) {
    } @finally {
        return passFlag;
    }
}

+ (NSDictionary *)getIPAddresses {
    NSMutableDictionary *addresses = [NSMutableDictionary dictionaryWithCapacity:8];
    @try {
        // retrieve the current interfaces - returns 0 on success
        struct ifaddrs *interfaces;
        if (!getifaddrs(&interfaces)) {
            // Loop through linked list of interfaces
            struct ifaddrs *interface;
            for (interface = interfaces; interface; interface = interface->ifa_next) {
                if (!(interface->ifa_flags & IFF_UP) /* || (interface->ifa_flags & IFF_LOOPBACK) */ ) {
                    continue; // deeply nested code harder to read
                }
                const struct sockaddr_in *addr = (const struct sockaddr_in *) interface->ifa_addr;
                char addrBuf[MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN)];
                if (addr && (addr->sin_family == AF_INET || addr->sin_family == AF_INET6)) {
                    NSString *name = [NSString stringWithUTF8String:interface->ifa_name];
                    NSString *type;
                    if (addr->sin_family == AF_INET) {
                        if (inet_ntop(AF_INET, &addr->sin_addr, addrBuf, INET_ADDRSTRLEN)) {
                            type = IP_ADDR_IPv4;
                        }
                    } else {
                        const struct sockaddr_in6 *addr6 = (const struct sockaddr_in6 *) interface->ifa_addr;
                        if (inet_ntop(AF_INET6, &addr6->sin6_addr, addrBuf, INET6_ADDRSTRLEN)) {
                            type = IP_ADDR_IPv6;
                        }
                    }
                    if (type) {
                        NSString *key = [NSString stringWithFormat:@"%@/%@", name, type];
                        addresses[key] = [NSString stringWithUTF8String:addrBuf];
                    }
                }
            }
            // Free memory
            freeifaddrs(interfaces);
        }
    } @catch (NSException *exception) {

    } @finally {
        return [addresses count] ? addresses : nil;
    }
}

+ (NSString *)getModel {
    NSString *model = @"";
    @try {
        struct utsname systemInfo;
        uname(&systemInfo);
        model = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    } @catch (NSException *exception) {

    } @finally {
        return model;
    }
}

+ (NSString *)getOsv {
    return [[UIDevice currentDevice] systemVersion];
}

+ (NSString *)getIdfa {
    NSString *idfa = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
    
    return idfa;
}

+ (NSString *)getCarrier {
    NSString *result = @"";
    @try {
        CTTelephonyNetworkInfo *netInfo = [[CTTelephonyNetworkInfo alloc] init];
        CTCarrier *carrier = [netInfo subscriberCellularProvider];
        NSString *mcc = [carrier mobileCountryCode];
        NSString *mnc = [carrier mobileNetworkCode];
        if (!mcc) {
            return @"";
        }
        result = [NSString stringWithFormat:@"%@%@", mcc, mnc];
    } @catch (NSException *exception) {

    } @finally {
        return result;
    }
}

+ (NSNumber *)getNetwork {
    NSNumber *res = @(0);
    @try {
        NSCountedSet *cset = [[NSCountedSet alloc] init];
        struct ifaddrs *interfaces;
        if (!getifaddrs(&interfaces)) {
            for (struct ifaddrs *interface = interfaces; interface; interface = interface->ifa_next) {
                if ((interface->ifa_flags & IFF_UP) == IFF_UP) {
                    [cset addObject:[NSString stringWithUTF8String:interface->ifa_name]];
                }
            }
        }
        if ([cset countForObject:@"awdl0"] > 1) {
            res = @1;
        }
        CTTelephonyNetworkInfo *info = [[CTTelephonyNetworkInfo alloc] init];
        NSString *currentStatus = info.currentRadioAccessTechnology;
        if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyGPRS"]) {
            //netconnType = @"GPRS";
            res = @2;
        } else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyEdge"]) {
            // netconnType = @"2.75G EDGE";
            res = @2;
        } else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyWCDMA"]) {
            //netconnType = @"3G";
            res = @3;
        } else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyHSDPA"]) {
            // netconnType = @"3.5G HSDPA";
            res = @3;
        } else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyHSUPA"]) {
            //  netconnType = @"3.5G HSUPA";
            res = @3;
        } else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyCDMA1x"]) {
            //  netconnType = @"2G";
            res = @2;
        } else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyCDMAEVDORev0"]) {
            //  netconnType = @"3G";
            res = @3;
        } else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyCDMAEVDORevA"]) {
            //  netconnType = @"3G";
            res = @3;
        } else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyCDMAEVDORevB"]) {
            // netconnType = @"3G";
            res = @3;
        } else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyeHRPD"]) {
            //  netconnType = @"HRPD";
            res = @3;
        } else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyLTE"]) {
            //  netconnType = @"4G";
            res = @4;
        } else {//TD-SCDMA WCDMA CDMA2000
            res = @3;
        }
    } @catch (NSException *exception) {

    } @finally {
        return res;
    }
}

+ (NSString *)getIdfv {
    return [[UIDevice currentDevice].identifierForVendor UUIDString];
}

+ (NSString *)getAuctionId {
    @try {
        NSString *uuid = [[NSUUID UUID] UUIDString];
        return [[uuid stringByReplacingOccurrencesOfString:@"-" withString:@""] lowercaseString];
    } @catch (NSException *exception) {
        return @"";
    }
}

@end
