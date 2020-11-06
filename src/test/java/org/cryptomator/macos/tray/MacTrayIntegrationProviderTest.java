package org.cryptomator.macos.tray;

import org.cryptomator.integrations.tray.TrayIntegrationProvider;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.ServiceLoader;

public class MacTrayIntegrationProviderTest {

	@Test
	@DisplayName("MacTrayIntegrationProvider can be loaded")
	public void testLoadMacTrayIntegrationProvider() {
		var loadedProviders = ServiceLoader.load(TrayIntegrationProvider.class);
		var provider = loadedProviders.stream()
				.filter(p -> p.type().equals(MacTrayIntegrationProvider.class))
				.map(ServiceLoader.Provider::get)
				.findAny();
		Assertions.assertTrue(provider.isPresent());
	}

}
