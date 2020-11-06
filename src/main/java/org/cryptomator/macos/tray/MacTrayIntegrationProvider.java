package org.cryptomator.macos.tray;

import org.cryptomator.integrations.tray.TrayIntegrationProvider;

public class MacTrayIntegrationProvider implements TrayIntegrationProvider {

	private final ActivationPolicy activationPolicy;

	public MacTrayIntegrationProvider() {
		this.activationPolicy = new ActivationPolicy();
	}

	@Override
	public void minimizedToTray() {
		activationPolicy.transformToAccessory();
	}

	@Override
	public void restoredFromTray() {
		activationPolicy.transformToRegular();
	}
}
