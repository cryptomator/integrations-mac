package org.cryptomator.macos.uiappearance;

import org.cryptomator.integrations.uiappearance.UiAppearanceProvider;
import org.cryptomator.macos.keychain.MacSystemKeychainAccess;
import org.cryptomator.macos.uiappearance.MacUiAppearanceProvider;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.ServiceLoader;

public class UiAppearanceProviderTest {

	@Test
	@DisplayName("MacUiAppearanceProvider can be loaded")
	public void testLoadMacUiAppearanceProvider() {
		var loadedProviders = ServiceLoader.load(UiAppearanceProvider.class);
		var provider = loadedProviders.stream()
				.filter(p -> p.type().equals(MacUiAppearanceProvider.class))
				.map(ServiceLoader.Provider::get)
				.findAny();
		Assertions.assertTrue(provider.isPresent());
	}

}
