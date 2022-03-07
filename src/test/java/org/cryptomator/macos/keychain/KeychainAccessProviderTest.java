package org.cryptomator.macos.keychain;

import org.cryptomator.integrations.keychain.KeychainAccessProvider;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

public class KeychainAccessProviderTest {

	@Test
	@DisplayName("MacSystemKeychainAccess can be loaded")
	public void testLoadMacSystemKeychainAccess() {
		var provider = KeychainAccessProvider.get().findAny();
		Assertions.assertTrue(provider.isPresent());
		Assertions.assertInstanceOf(MacSystemKeychainAccess.class, provider.get());
	}

}
