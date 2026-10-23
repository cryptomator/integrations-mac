package org.cryptomator.macos.tray;

import org.cryptomator.integrations.tray.TrayMenuController;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

public class MacTrayMenuControllerTest {

	@Test
	@DisplayName("MacTrayMenuController can be loaded")
	public void testLoadMacTrayMenuController() {
		var controller = TrayMenuController.get();
		Assertions.assertTrue(controller.isPresent());
		Assertions.assertInstanceOf(MacTrayMenuController.class, controller.get());
	}

}
