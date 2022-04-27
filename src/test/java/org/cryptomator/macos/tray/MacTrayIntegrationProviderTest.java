package org.cryptomator.macos.tray;

import org.cryptomator.integrations.tray.TrayIntegrationProvider;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

public class MacTrayIntegrationProviderTest {

	@Test
	@DisplayName("MacTrayIntegrationProvider can be loaded")
	public void testLoadMacTrayIntegrationProvider() {
		var provider = TrayIntegrationProvider.get();
		Assertions.assertTrue(provider.isPresent());
		Assertions.assertInstanceOf(MacTrayIntegrationProvider.class, provider.get());
	}

}
