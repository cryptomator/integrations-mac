import org.cryptomator.integrations.autostart.AutoStartProvider;
import org.cryptomator.integrations.keychain.KeychainAccessProvider;
import org.cryptomator.integrations.revealpath.RevealPathService;
import org.cryptomator.integrations.secondfactor.SecondFactorProvider;
import org.cryptomator.integrations.tray.TrayIntegrationProvider;
import org.cryptomator.integrations.uiappearance.UiAppearanceProvider;
import org.cryptomator.macos.autostart.MacAutoStartProvider;
import org.cryptomator.macos.keychain.MacSystemKeychainAccess;
import org.cryptomator.macos.revealpath.OpenCmdRevealPathService;
import org.cryptomator.macos.secondfactor.MacTouchIDProvider;
import org.cryptomator.macos.tray.MacTrayIntegrationProvider;
import org.cryptomator.macos.uiappearance.MacUiAppearanceProvider;

module org.cryptomator.integrations.mac {
	requires org.cryptomator.integrations.api;
	requires org.slf4j;
	requires com.sun.jna;

	provides AutoStartProvider with MacAutoStartProvider;
	provides KeychainAccessProvider with MacSystemKeychainAccess;
	provides RevealPathService with OpenCmdRevealPathService;
	provides SecondFactorProvider with MacTouchIDProvider;
	provides TrayIntegrationProvider with MacTrayIntegrationProvider;
	provides UiAppearanceProvider with MacUiAppearanceProvider;
}