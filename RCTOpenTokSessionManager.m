/**
 * Copyright (c) 2015-present, Callstack Sp z o.o.
 * All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "RCTOpenTokSessionManager.h"
#import "React/RCTEventDispatcher.h"
#import <OpenTok/OpenTok.h>

@implementation RCTOpenTokSessionManager

@synthesize bridge = _bridge;

//- (dispatch_queue_t)methodQueue {
//  return dispatch_get_main_queue();
//}

/*
 onSessionConnected
 onSessionDisconnected
 onMessageReceived
 onReceivingFound
 onReceivingLost
 onPublishingStarted
 onPublishingEnded
 onSessionError
 onReceivingConnected
 onReceivingReconnected
 onReceivingDisconnected
*/

#pragma mark REACT 

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(connect:(NSString *)apiKey sessionId:(NSString *)sessionId token:(NSString *)token) {
  NSLog(@"RCTOpenTokSessionManager.connect %@,%@,%@",apiKey,sessionId,token);
  
  RCTOpenTokSharedInfo *sharedInfo = [RCTOpenTokSharedInfo sharedInstance];
  sharedInfo.session = [[OTSession alloc] initWithApiKey:apiKey sessionId:sessionId delegate:self];
  
  NSError *error;
  [sharedInfo.session connectWithToken:token error:&error];
  if (error) {
    NSLog(@"RCTOpenTokSessionManager.connect failed with error: %@",error);
  } else {
    NSLog(@"RCTOpenTokSessionManager.connect connected. session: %@",sharedInfo.session);
  }
}

RCT_EXPORT_METHOD(sendMessage:(NSString *)message) {
  RCTOpenTokSharedInfo *sharedInfo = [RCTOpenTokSharedInfo sharedInstance];
  
  if (sharedInfo.session != nil) {

    OTError* error = nil;
    NSLog(@"RCTOpenTokSessionManager.sendMessage %@ %@", message,sharedInfo.session);
    
    [sharedInfo.session signalWithType:@"message" string:message connection:nil error:&error];
    if (error) {
      NSLog(@"RCTOpenTokSessionManager.sendMessage error %@", error);
    } else {
      NSLog(@"RCTOpenTokSessionManager.sendMessage sent");
    }
  } else {
    NSLog(@"RCTOpenTokSessionManager.sendMessage session was nil");
  }
}

RCT_EXPORT_METHOD(clearSession) {
  RCTOpenTokSharedInfo *sharedInfo = [RCTOpenTokSharedInfo sharedInstance];
  if (sharedInfo.session != nil) {
    
    OTError *error = nil;
    [sharedInfo.session disconnect:&error];
    
    if (error) {
      NSLog(@"RCTOpenTokSessionManager.clearSession failed with error: (%@)", error);
    } else {
      sharedInfo.session = nil;
      NSLog(@"RCTOpenTokSessionManager.clearSession cleared");
    }
    
  } else {
    NSLog(@"RCTOpenTokSessionManager.clearSession was already nil");
  }

}

RCT_EXPORT_METHOD(startPublishing) {
  RCTOpenTokSharedInfo *sharedInfo = [RCTOpenTokSharedInfo sharedInstance];
  
  if (sharedInfo.session) {
    sharedInfo.outgoingVideoPublisher = [[OTPublisher alloc] initWithDelegate:self];
    OTError* error = nil;
    [sharedInfo.session publish:sharedInfo.outgoingVideoPublisher error:&error];
    if (error) {
      NSLog(@"RCTOpenTokSessionManager.startPublishing failed with error: (%@)", error);
    } else {
      NSLog(@"RCTOpenTokSessionManager.startPublishing done");
    }
  } else {
    NSLog(@"RCTOpenTokSessionManager.startPublishing session was nil");
  }

}

RCT_EXPORT_METHOD(stopPublishing) {
  RCTOpenTokSharedInfo *sharedInfo = [RCTOpenTokSharedInfo sharedInstance];

  if (sharedInfo.session && sharedInfo.outgoingVideoPublisher) {
    OTError* error = nil;
    [sharedInfo.session unpublish:sharedInfo.outgoingVideoPublisher error:&error];
    if (error) {
      NSLog(@"RCTOpenTokSessionManager.stopPublishing failed with error: (%@)", error);
    } else {
      NSLog(@"RCTOpenTokSessionManager.stopPublishing done");
    }
  } else {
    if (sharedInfo.session == nil) NSLog(@"RCTOpenTokSessionManager.stopPublishing session was nil");
    if (sharedInfo.outgoingVideoPublisher == nil) NSLog(@"RCTOpenTokSessionManager.stopPublishing publisher was nil");
    
  }
  
}

RCT_EXPORT_METHOD(startReceiving) {
  RCTOpenTokSharedInfo *sharedInfo = [RCTOpenTokSharedInfo sharedInstance];

  if (sharedInfo.session && sharedInfo.latestIncomingVideoStream) {
    sharedInfo.incomingVideoSubscriber = [[OTSubscriber alloc] initWithStream:sharedInfo.latestIncomingVideoStream delegate:self];
    OTError* error = nil;    
    [sharedInfo.session subscribe:sharedInfo.incomingVideoSubscriber error:&error];
    if (error) {
      NSLog(@"RCTOpenTokSessionManager.startReceiving failed with error: (%@)", error);
    } else {
      NSLog(@"RCTOpenTokSessionManager.startReceiving done");
    }
  } else {
    if (sharedInfo.session == nil) NSLog(@"RCTOpenTokSessionManager.startReceiving session was nil");
    if (sharedInfo.latestIncomingVideoStream == nil) NSLog(@"RCTOpenTokSessionManager.startReceiving videostream was nil");
  }
  
}

RCT_EXPORT_METHOD(stopReceiving) {
  RCTOpenTokSharedInfo *sharedInfo = [RCTOpenTokSharedInfo sharedInstance];

  if (sharedInfo.session && sharedInfo.incomingVideoSubscriber) {
    OTError* error = nil;
    [sharedInfo.session unsubscribe:sharedInfo.incomingVideoSubscriber error:&error];
    if (error) {
      NSLog(@"RCTOpenTokSessionManager.stopReceiving failed with error: (%@)", error);
    } else {
      NSLog(@"RCTOpenTokSessionManager.stopReceiving done");
    }
  } else {
    if (sharedInfo.session == nil) NSLog(@"RCTOpenTokSessionManager.stopReceiving session was nil");
    if (sharedInfo.incomingVideoSubscriber == nil) NSLog(@"RCTOpenTokSessionManager.stopReceiving subscriber was nil");
  }

}


# pragma mark - OTSession delegate
- (void)sessionDidConnect:(OTSession*)session {
  NSLog(@"RCTOpenTokSessionManager.session.sessionDidConnect");
  [self.bridge.eventDispatcher sendAppEventWithName:@"onSessionConnected" body:@{}];
}

- (void)sessionDidDisconnect:(OTSession*)session {
  NSLog(@"RCTOpenTokSessionManager.session.sessionDidDisconnect");
  [self.bridge.eventDispatcher sendAppEventWithName:@"onSessionDisconnected" body:@{}];
}

- (void)session:(OTSession*)session streamCreated:(OTStream *)stream {
  NSLog(@"RCTOpenTokSessionManager.session.streamCreated");
  RCTOpenTokSharedInfo *sharedInfo = [RCTOpenTokSharedInfo sharedInstance];
  sharedInfo.latestIncomingVideoStream = stream;
  [self.bridge.eventDispatcher sendAppEventWithName:@"onReceivingFound" body:@{}];
}

- (void)session:(OTSession*)session streamDestroyed:(OTStream *)stream {
  NSLog(@"RCTOpenTokSessionManager.session.streamDestroyed");
  RCTOpenTokSharedInfo *sharedInfo = [RCTOpenTokSharedInfo sharedInstance];
  sharedInfo.latestIncomingVideoStream = stream;
  [self.bridge.eventDispatcher sendAppEventWithName:@"onReceivingLost" body:@{}];
}

- (void)session:(OTSession*)session connectionCreated:(OTConnection *)connection {
  NSLog(@"RCTOpenTokSessionManager.session.connectionCreated");
  //what could we do here?
}

- (void)session:(OTSession*)session connectionDestroyed:(OTConnection *)connection{
  NSLog(@"RCTOpenTokSessionManager.session.connectionDestroyed");
  //what could we do here?
}

- (void)session:(OTSession*)session didFailWithError:(OTError*)error {
  NSLog(@"RCTOpenTokSessionManager.session.didFailWithError %@",error);
  [self.bridge.eventDispatcher sendAppEventWithName:@"onSessionError" body:@"session.didFailWithError"];
}

- (void)session:(OTSession*)session receivedSignalType:(NSString*)type fromConnection:(OTConnection*)connection withString:(NSString*)string {
  NSLog(@"Received signal %@ %@ %@", type, string, session);
  [self.bridge.eventDispatcher sendAppEventWithName:@"onMessageReceived" body:string];
}

# pragma mark - OTPublisher delegate

- (void)publisher:(OTPublisherKit *)publisher didFailWithError:(OTError *)error {
  NSLog(@"RCTOpenTokSessionManager.publisher.didFailWithError %@",error);
  [self.bridge.eventDispatcher sendAppEventWithName:@"onSessionError" body:@"publisher.didFailWithError"];
}

- (void)publisher:(OTPublisherKit *)publisher streamCreated:(OTStream *)stream {
  NSLog(@"RCTOpenTokSessionManager.publisher.streamCreated");
  [self.bridge.eventDispatcher sendAppEventWithName:@"onPublishingStarted" body:@{}];
}

- (void)publisher:(OTPublisherKit *)publisher streamDestroyed:(OTStream *)stream {
  NSLog(@"RCTOpenTokSessionManager.publisher.streamDestroyed");
  [self.bridge.eventDispatcher sendAppEventWithName:@"onPublishingEnded" body:@{}];
}

#pragma mark - OTSubscribe delegate

- (void)subscriber:(OTSubscriberKit *)subscriber didFailWithError:(OTError *)error {
  NSLog(@"RCTOpenTokSessionManager.subscriber.didFailWithError %@",error);
  [self.bridge.eventDispatcher sendAppEventWithName:@"onSessionError" body:@"subscriber.didFailWithError"];
}

- (void)subscriberDidConnectToStream:(OTSubscriberKit *)subscriber {
  NSLog(@"RCTOpenTokSessionManager.subscriber.connected");
  [self.bridge.eventDispatcher sendAppEventWithName:@"onReceivingConnected" body:@{}];
}

- (void)subscriberDidReconnectToStream:(OTSubscriberKit *)subscriber {
  NSLog(@"RCTOpenTokSessionManager.subscriber.reconnected");
  [self.bridge.eventDispatcher sendAppEventWithName:@"onReceivingReconnected" body:@{}];
}

- (void)subscriberDidDisconnectFromStream:(OTSubscriberKit *)subscriber {
  NSLog(@"RCTOpenTokSessionManager.subscriber.disconnected");
  [self.bridge.eventDispatcher sendAppEventWithName:@"onReceivingDisconnected" body:@{}];
}

@end