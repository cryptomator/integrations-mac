//
//  SKYAppearanceObserver.h
//  Integrations
//
//  Created by Sebastian Stenzel on 05.11.20.
//  Copyright © 2020 Cryptomator. All rights reserved.
//

#include <jni.h>
#import <Foundation/Foundation.h>

@interface SKYAppearanceObserver : NSObject

@property (nonatomic, readonly) jobject listener;

- (instancetype)initWithListener:(jobject)listener vm:(JavaVM *)vm NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
- (void)interfaceThemeChangedNotification:(NSNotification *)notification;

@end
