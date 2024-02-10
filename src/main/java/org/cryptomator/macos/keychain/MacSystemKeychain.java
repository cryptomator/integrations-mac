package org.cryptomator.macos.keychain;

import com.sun.jna.Library;

public interface MacSystemKeychain extends Library {

	int addItemToKeychain(String kServiceName, String key, String passphrase);

	String getItemFromKeychain(String kServiceName, String key);

	int deleteItemFromKeychain(String kServiceName, String key);
}
