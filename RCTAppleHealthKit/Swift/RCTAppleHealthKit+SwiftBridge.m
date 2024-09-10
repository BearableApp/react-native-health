//
//  RCTAppleHealthKit+SwiftBridge.m
//  RCTAppleHealthKit
//
//  Copyright © 2024 Bearable. All rights reserved.
//

#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(RCTAppleHealthKit, NSObject)

RCT_EXTERN_METHOD(readBucketedSteps:(NSDictionary)options
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)

@end
