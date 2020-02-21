// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "FLTCookieManager.h"

@implementation FLTCookieManager {
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  FLTCookieManager *instance = [[FLTCookieManager alloc] init];

  FlutterMethodChannel *channel =
      [FlutterMethodChannel methodChannelWithName:@"plugins.flutter.io/cookie_manager"
                                  binaryMessenger:[registrar messenger]];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
  if ([[call method] isEqualToString:@"clearCookies"]) {
    [self clearCookies:result];
  } else {
    result(FlutterMethodNotImplemented);
  }
}

- (NSURL *)getUrlArgument:(FlutterMethodCall *)call result:(FlutterResult)result {
    if(![call.arguments isKindOfClass:[NSDictionary class]]) {
        result([FlutterError errorWithCode:[NSString stringWithFormat:@"Invalid argument. Expected NSDictionary, received %@", [call.arguments class]] message:nil details:nil]);
        return nil;
    }
    NSString *url = call.arguments[@"url"];
    if(url == nil) {
        result([FlutterError errorWithCode:@"Missing url argument" message:nil details:nil]);
        return nil;
    }
    return [[NSURL alloc] initWithString:url];
}

- (void)getCookies:(FlutterMethodCall *)call result:(FlutterResult)result {
    if (@available(iOS 9.0, *)) {
        NSURL *url = [self getUrlArgument:call result:result];
        if(url == nil){
            return;
        }

        WKWebsiteDataStore *dataStore = [WKWebsiteDataStore defaultDataStore];
        WKHTTPCookieStore *cookieStore = [dataStore httpCookieStore];
        [cookieStore getAllCookies:^(NSArray<NSHTTPCookie *> *cookies) {
            NSArray *filtered = [cookies filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary * bindings) {
                return [((NSHTTPCookie *)object).domain isEqualToString:url.host];
            }]];
            NSDictionary<NSString *, NSString *> *headers = [NSHTTPCookie requestHeaderFieldsWithCookies:filtered];
            result(headers[@"Cookie"]);
        }];
    } else {
       // support for iOS8 tracked in https://github.com/flutter/flutter/issues/27624.
       NSLog(@"get cookies is not supported for Flutter WebViews prior to iOS 9.");
    }

}

- (void)setCookies:(FlutterMethodCall *)call result:(FlutterResult)result {
    if (@available(iOS 9.0, *)) {
         NSURL *url = [self getUrlArgument:call result:result];
         if(url == nil){
             return;
         }

         NSArray<NSString *> *headers = call.arguments[@"cookies"];
         NSMutableArray<NSHTTPCookie *> *cookies = [[NSMutableArray alloc] init];
         for(int i = 0; i < headers.count; i++) {
             [cookies addObjectsFromArray:[NSHTTPCookie cookiesWithResponseHeaderFields:@{@"Set-Cookie": headers[i]} forURL:url]];
         }

         WKWebsiteDataStore *dataStore = [WKWebsiteDataStore defaultDataStore];
         WKHTTPCookieStore *cookieStore = [dataStore httpCookieStore];
         for(int i = 0; i < cookies.count; i++) {
             [cookieStore setCookie:cookies[i] completionHandler:nil];
         }
         result(nil);
    } else {
        // support for iOS8 tracked in https://github.com/flutter/flutter/issues/27624.
        NSLog(@"set cookies is not supported for Flutter WebViews prior to iOS 9.");
    }

}

- (void)clearCookies:(FlutterResult)result {
  if (@available(iOS 9.0, *)) {
    NSSet<NSString *> *websiteDataTypes = [NSSet setWithObject:WKWebsiteDataTypeCookies];
    WKWebsiteDataStore *dataStore = [WKWebsiteDataStore defaultDataStore];

    void (^deleteAndNotify)(NSArray<WKWebsiteDataRecord *> *) =
        ^(NSArray<WKWebsiteDataRecord *> *cookies) {
          BOOL hasCookies = cookies.count > 0;
          [dataStore removeDataOfTypes:websiteDataTypes
                        forDataRecords:cookies
                     completionHandler:^{
                       result(@(hasCookies));
                     }];
        };

    [dataStore fetchDataRecordsOfTypes:websiteDataTypes completionHandler:deleteAndNotify];
  } else {
    // support for iOS8 tracked in https://github.com/flutter/flutter/issues/27624.
    NSLog(@"Clearing cookies is not supported for Flutter WebViews prior to iOS 9.");
  }
}

@end
