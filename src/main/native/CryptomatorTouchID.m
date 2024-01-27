//
//  CryptomatorTouchID.m
//  CryptomatorTouchID
//
//  Created by Ralph Plawetzki on 27.01.24.
//

#import "CryptomatorTouchID.h"

#import <LocalAuthentication/LocalAuthentication.h>

int32_t touchid_supported(void) {
    BOOL supportsTouchID = [[LAContext new] canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:nil];
    NSLog(@"Supports TouchID: %d", supportsTouchID);
    return supportsTouchID;
}

void touchid_authenticate(const char* msg, auth_cb_t callback) {
    NSLog(@"Authenticate with biometrics");
    NSString* reason = [NSString stringWithCString:msg encoding:NSUTF8StringEncoding];
    [[LAContext new] evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
                    localizedReason:reason
                              reply:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            NSLog(@"Successfully authenticated with biometrics");
            callback(YES, 0);
        } else {
            NSLog(@"Biometric authentication failed: %@", error);
            callback(NO, (int32_t)error.code);
        }
    }];
}
