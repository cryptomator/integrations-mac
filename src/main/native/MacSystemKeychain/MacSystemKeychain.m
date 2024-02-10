//
//  MacSystemKeychain.m
//  MacSystemKeychain
//
//  Created by Ralph Plawetzki on 10.02.24.
//

#import "MacSystemKeychain.h"
#import <Foundation/Foundation.h>
#import <Security/Security.h>

// the kServiceName must be the same as in the project settings > Keychain Sharing > Keychain Groups

SecAccessControlRef createAccessControl(void) {
    SecAccessControlCreateFlags flags = kSecAccessControlUserPresence;
    
    SecAccessControlRef accessControl = SecAccessControlCreateWithFlags(
        kCFAllocatorDefault,
        kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
        flags,
        NULL // Ignore any error
    );
    
    return accessControl;
}

// Method to add an item to the keychain with access control
int32_t addItemToKeychain(const char* kServiceName, const char* key, const char* passphrase) {
    // Create a dictionary of keychain attributes
    NSDictionary *keychainAttributes = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: [NSString stringWithCString:kServiceName encoding:NSUTF8StringEncoding],
        (__bridge id)kSecAttrAccessControl: (__bridge_transfer id)createAccessControl(),
        (__bridge id)kSecAttrAccount: [NSString stringWithCString:key encoding:NSUTF8StringEncoding],
        (__bridge id)kSecValueData:  [NSString stringWithCString:passphrase encoding:NSUTF8StringEncoding] // Convert password string to data
    };

    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)keychainAttributes, NULL);
    if (status == errSecSuccess) {
        NSLog(@"Item added to keychain successfully.");
    } else {
        NSLog(@"Error adding item to keychain. Status code: %d", (int)status);
    }

    return (int)status;
}

// Method to retrieve an item from the keychain
const char* getItemFromKeychain(const char* kServiceName, const char* key) {
    // Create a dictionary of search attributes to find the item in the keychain
    NSDictionary *searchAttributes = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: [NSString stringWithCString:kServiceName encoding:NSUTF8StringEncoding],
        (__bridge id)kSecAttrAccount: [NSString stringWithCString:key encoding:NSUTF8StringEncoding],
        (__bridge id)kSecReturnAttributes: @YES,
        (__bridge id)kSecReturnData: @YES,
        (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitOne
    };
    
    CFDictionaryRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)searchAttributes, (CFTypeRef *)&result);
    
    if (status == errSecSuccess && result != NULL) {
        NSDictionary *attributes = (__bridge_transfer NSDictionary *)result;
        
        NSData *passwordData = attributes[(__bridge id)kSecValueData];
        NSLog(@"Item found in keychain.");
        NSString *password = [[NSString alloc] initWithData:passwordData encoding:NSUTF8StringEncoding];
        const char *charString = [password UTF8String];

        return charString;

    } else if (status == errSecItemNotFound) {
        NSLog(@"No matching item found in the keychain.");
    } else {
        NSLog(@"Error retrieving item from keychain. Status code: %d", (int)status);
    }
    return NULL; // empty
}

int32_t deleteItemFromKeychain(const char* kServiceName, const char* key) {
    NSDictionary *searchAttributes = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: [NSString stringWithCString:kServiceName encoding:NSUTF8StringEncoding],
        (__bridge id)kSecAttrAccount: [NSString stringWithCString:key encoding:NSUTF8StringEncoding]
    };
    
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)searchAttributes);
    if (status == errSecSuccess) {
        NSLog(@"Item deleted from keychain successfully.");
    } else if (status == errSecItemNotFound) {
        NSLog(@"No matching item found in the keychain.");
    } else {
        NSLog(@"Error deleting item from keychain. Status code: %d", (int)status);
    }

    return (int)status;
}

