//
//  SKYAppearanceNotifier.h
//  Integrations
//
//  Created by Sebastian Stenzel on 05.11.20.
//  Copyright © 2020 Cryptomator. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SKYAppearanceObserver;

@interface SKYAppearanceNotifier : NSObject

+ (instancetype)sharedInstance;
- (void)addObserver:(SKYAppearanceObserver *)observer;
- (void)removeObserver:(SKYAppearanceObserver *)observer;

@end
