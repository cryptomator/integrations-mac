//
//  SKYLaunchService.h
//  Integrations
//
//  Created by Tobias Hagemann on 26.05.24.
//  Copyright © 2024 Cryptomator. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SKYLaunchService : NSObject

+ (BOOL)isLoginItemEnabled;
+ (BOOL)enableLoginItem;
+ (BOOL)disableLoginItem;

@end
