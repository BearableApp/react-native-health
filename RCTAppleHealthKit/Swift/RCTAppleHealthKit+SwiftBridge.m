//
//  RCTAppleHealthKit+SwiftBridge.m
//  RCTAppleHealthKit
//
//  Created by Work on 05/09/2024.
//  Copyright © 2024 Greg Wilson. All rights reserved.
//

#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(RCTAppleHealthKit, NSObject)

RCT_EXTERN_METHOD(readBucketedSteps:(NSDictionary)options
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)

@end
