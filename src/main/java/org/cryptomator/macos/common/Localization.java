package org.cryptomator.macos.common;

import java.util.ResourceBundle;

public enum Localization {
	INSTANCE;

	private final ResourceBundle resourceBundle = ResourceBundle.getBundle("MacIntegrationsBundle");

	public static ResourceBundle get() {
		return INSTANCE.resourceBundle;
	}

}
