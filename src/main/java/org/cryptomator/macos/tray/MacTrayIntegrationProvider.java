package org.cryptomator.macos.tray;

import org.cryptomator.integrations.common.OperatingSystem;
import org.cryptomator.integrations.common.Priority;
import org.cryptomator.integrations.tray.TrayIntegrationProvider;

@Priority(1000)
@OperatingSystem(OperatingSystem.Value.MAC)
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
