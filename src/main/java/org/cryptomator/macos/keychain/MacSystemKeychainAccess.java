package org.cryptomator.macos.keychain;

import com.sun.jna.Native;
import org.cryptomator.integrations.common.OperatingSystem;
import org.cryptomator.integrations.common.Priority;
import org.cryptomator.integrations.keychain.KeychainAccessException;
import org.cryptomator.integrations.keychain.KeychainAccessProvider;
import org.cryptomator.macos.common.Localization;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import java.util.Arrays;

/**
 * Stores passwords in the macOS system keychain.
 * <p>
 * Items are stored in the default keychain with the service name <code>Cryptomator</code>, unless configured otherwise
 * using the system property <code>cryptomator.integrationsMac.keychainServiceName</code>.
 */
@Priority(1000)
@OperatingSystem(OperatingSystem.Value.MAC)
public class MacSystemKeychainAccess implements KeychainAccessProvider {

	private static final Logger LOG = LoggerFactory.getLogger(MacSystemKeychainAccess.class);
	private static final String SERVICE_NAME = System.getProperty("cryptomator.integrationsMac.keychainServiceName", "Cryptomator");

	private static final int OSSTATUS_SUCCESS = 0;
	private static final int OSSTATUS_NOT_FOUND = -25300;
	private static final MacSystemKeychain NATIVELIB;

	static {
		NATIVELIB = Native.load("MacSystemKeychain", MacSystemKeychain.class);
	}

	@Override
	public String displayName() {
		return Localization.get().getString("org.cryptomator.macos.keychain.displayName");
	}

	@Override
	public void storePassphrase(String key, String displayName, CharSequence passphrase) throws KeychainAccessException {
		var errorCode =  NATIVELIB.addItemToKeychain(SERVICE_NAME, key, passphrase.toString());
		if (errorCode != OSSTATUS_SUCCESS) {
			throw new KeychainAccessException("Failed to store password. Error code " + errorCode);
		}
	}

	@Override
	public char[] loadPassphrase(String key) {
		String i = NATIVELIB.getItemFromKeychain(SERVICE_NAME, key);
		return null != i ? i.toCharArray() : null;
	}

	@Override
	public boolean isSupported() {
		LOG.info("is supported called");
		return true;
	}

	@Override
	public boolean isLocked() {
		return false;
	}

	@Override
	public void deletePassphrase(String key) throws KeychainAccessException {
		var errorCode = NATIVELIB.deleteItemFromKeychain(SERVICE_NAME, key);
		if (errorCode == OSSTATUS_SUCCESS) {
			LOG.debug("Password successfully deleted");
		} else if (errorCode == OSSTATUS_NOT_FOUND) {
			LOG.debug("Password was not deleted");
		} else {
			throw new KeychainAccessException("Failed to delete password. Error code " + errorCode);
		}
	}

	@Override
	public void changePassphrase(String key, String displayName, CharSequence passphrase) throws KeychainAccessException {
		deletePassphrase(key);
		storePassphrase(key, displayName, passphrase);
	}

}
