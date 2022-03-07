package org.cryptomator.macos.uiappearance;

import org.cryptomator.integrations.uiappearance.UiAppearanceProvider;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

public class UiAppearanceProviderTest {

	@Test
	@DisplayName("MacUiAppearanceProvider can be loaded")
	public void testLoadMacUiAppearanceProvider() {
		var provider = UiAppearanceProvider.get();
		Assertions.assertTrue(provider.isPresent());
		Assertions.assertInstanceOf(MacUiAppearanceProvider.class, provider.get());
	}

}
