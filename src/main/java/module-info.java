import org.cryptomator.integrations.autostart.AutoStartProvider;
import org.cryptomator.integrations.keychain.KeychainAccessProvider;
import org.cryptomator.integrations.revealpath.RevealPathService;
import org.cryptomator.integrations.tray.TrayIntegrationProvider;
import org.cryptomator.integrations.uiappearance.UiAppearanceProvider;
import org.cryptomator.macos.autostart.MacAutoStartProvider;
import org.cryptomator.macos.keychain.MacSystemKeychainAccess;
import org.cryptomator.macos.keychain.TouchIdKeychainAccess;
import org.cryptomator.macos.revealpath.OpenCmdRevealPathService;
import org.cryptomator.macos.tray.MacTrayIntegrationProvider;
import org.cryptomator.macos.uiappearance.MacUiAppearanceProvider;

module org.cryptomator.integrations.mac {
	requires org.cryptomator.integrations.api;
	requires org.slf4j;

	provides AutoStartProvider with MacAutoStartProvider;
	provides KeychainAccessProvider with MacSystemKeychainAccess, TouchIdKeychainAccess;
	provides RevealPathService with OpenCmdRevealPathService;
	provides TrayIntegrationProvider with MacTrayIntegrationProvider;
	provides UiAppearanceProvider with MacUiAppearanceProvider;
}