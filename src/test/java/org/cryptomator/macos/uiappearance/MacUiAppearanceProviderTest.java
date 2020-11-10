package org.cryptomator.macos.uiappearance;

import org.cryptomator.integrations.uiappearance.UiAppearanceException;
import org.cryptomator.integrations.uiappearance.UiAppearanceListener;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class MacUiAppearanceProviderTest {

	private MacUiAppearanceProvider appearanceProvider;

	@BeforeEach
	public void setup() {
		this.appearanceProvider = new MacUiAppearanceProvider();
	}

	@Test
	public void testRegisterAndUnregisterObserver() throws UiAppearanceException {
		UiAppearanceListener listener = (theme) -> {};
		appearanceProvider.addListener(listener);
		appearanceProvider.removeListener(listener);
	}

}