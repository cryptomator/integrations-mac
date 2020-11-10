//
//  SKYAppearanceNotifier.m
//  Integrations
//
//  Created by Sebastian Stenzel on 05.11.20.
//  Copyright © 2020 Cryptomator. All rights reserved.
//

#import "SKYAppearanceNotifier.h"
#import "SKYAppearanceObserver.h"

@interface SKYAppearanceNotifier ()
@property (nonatomic, strong) NSMutableArray<SKYAppearanceObserver *> *observers;
@end

@implementation SKYAppearanceNotifier

+ (instancetype)sharedInstance {
    static SKYAppearanceNotifier *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SKYAppearanceNotifier alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    if (self = [super init]) {
        self.observers = [NSMutableArray array];
    }
    return self;
}

- (void)addObserver:(SKYAppearanceObserver *)observer {
    [self.observers addObject:observer];
    [[NSDistributedNotificationCenter defaultCenter] addObserver:observer selector:@selector(interfaceThemeChangedNotification:) name:@"AppleInterfaceThemeChangedNotification" object:nil];
}

- (void)removeObserver:(SKYAppearanceObserver *)observer {
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:observer];
    [self.observers removeObject:observer];
}

@end
