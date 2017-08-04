/**
 * Copyright (c) 2015-present, Callstack Sp z o.o.
 * All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "React/RCTBridgeModule.h"
#import "React/RCTEventDispatcher.h"
#import "RCTOpenTokSharedInfo.h"

@interface RCTOpenTokSessionManager : NSObject <RCTBridgeModule, OTSessionDelegate, OTPublisherDelegate, OTSubscriberDelegate>

@property RCTOpenTokSharedInfo *sharedInfo;

@end
