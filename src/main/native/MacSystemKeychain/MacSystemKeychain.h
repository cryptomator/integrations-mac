//
//  MacSystemKeychain.h
//  MacSystemKeychain
//
//  Created by Ralph Plawetzki on 10.02.24.
//

#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif

SecAccessControlRef createAccessControl(void);

int32_t addItemToKeychain(const char* kServiceName, const char* key, const char* passphrase);

const char* getItemFromKeychain(const char* kServiceName, const char* key);

int32_t deleteItemFromKeychain(const char* kServiceName, const char* key);

#ifdef __cplusplus
}
#endif
