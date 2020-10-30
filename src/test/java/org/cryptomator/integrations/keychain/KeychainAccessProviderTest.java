package org.cryptomator.integrations.keychain;

import org.cryptomator.macos.keychain.MacSystemKeychainAccess;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.ServiceLoader;

public class KeychainAccessProviderTest {

	@Test
	@DisplayName("MacSystemKeychainAccess can be loaded")
	public void testLoadMacSystemKeychainAccess() {
		var loadedProviders = ServiceLoader.load(KeychainAccessProvider.class);
		var macSystemKeychainAccess = loadedProviders.stream()
				.filter(provider -> provider.type().equals(MacSystemKeychainAccess.class))
				.map(ServiceLoader.Provider::get)
				.findAny();
		Assertions.assertTrue(macSystemKeychainAccess.isPresent());
	}

}
