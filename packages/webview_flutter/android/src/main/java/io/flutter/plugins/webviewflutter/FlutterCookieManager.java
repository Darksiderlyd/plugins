// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.webviewflutter;

import android.os.Build;
import android.os.Build.VERSION_CODES;
import android.webkit.CookieManager;
import android.webkit.ValueCallback;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

class FlutterCookieManager implements MethodCallHandler {
  private final MethodChannel methodChannel;

  FlutterCookieManager(BinaryMessenger messenger) {
    methodChannel = new MethodChannel(messenger, "plugins.flutter.io/cookie_manager");
    methodChannel.setMethodCallHandler(this);
  }

  @Override
  public void onMethodCall(MethodCall methodCall, Result result) {
    switch (methodCall.method) {
      case "getCookies":
        getCookies(methodCall, result);
        break;
      case "setCookies":
        setCookies(methodCall, result);
        break;
      case "clearCookies":
        clearCookies(result);
        break;
      default:
        result.notImplemented();
    }
  }

  void dispose() {
    methodChannel.setMethodCallHandler(null);
  }

  private void getCookies(final MethodCall methodCall, final Result result) {
    String url = getUrlArgument(methodCall, result);
    if (url == null) {
      return;
    }

    CookieManager cookieManager = CookieManager.getInstance();
    final String cookie = cookieManager.getCookie(url);
    result.success(cookie != null ? cookie : "");
  }

  private void setCookies(final MethodCall methodCall, final Result result) {
    String url = getUrlArgument(methodCall, result);
    if (url == null) {
      return;
    }

    final List<String> cookies = methodCall.argument("cookies");
    if (cookies == null) {
      result.error("Missing cookies argument", null, null);
      return;
    }

    final CookieManager cookieManager = CookieManager.getInstance();
    for (String cookie : cookies) {
      cookieManager.setCookie(url, cookie);
    }

    if (Build.VERSION.SDK_INT >= VERSION_CODES.LOLLIPOP) {
      cookieManager.flush();
    }

    result.success(true);
  }

  private static void clearCookies(final Result result) {
    CookieManager cookieManager = CookieManager.getInstance();
    final boolean hasCookies = cookieManager.hasCookies();
    if (Build.VERSION.SDK_INT >= VERSION_CODES.LOLLIPOP) {
      cookieManager.removeAllCookies(
          new ValueCallback<Boolean>() {
            @Override
            public void onReceiveValue(Boolean value) {
              result.success(hasCookies);
            }
          });
    } else {
      cookieManager.removeAllCookie();
      result.success(hasCookies);
    }
  }
}
