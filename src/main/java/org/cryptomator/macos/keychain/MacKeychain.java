package org.cryptomator.macos.keychain;

import org.cryptomator.integrations.keychain.KeychainAccessException;
import org.cryptomator.macos.common.NativeLibLoader;

import java.nio.ByteBuffer;
import java.nio.CharBuffer;
import java.util.Arrays;

import static java.nio.charset.StandardCharsets.UTF_8;

class MacKeychain {

	private static final int OSSTATUS_SUCCESS = 0;
	private static final int OSSTATUS_NOT_FOUND = -25300;

	/**
	 * Associates the specified password with the specified key in the system keychain.
	 *
	 * @param serviceName             Service name
	 * @param account                 Unique account identifier
	 * @param password                Passphrase to store
	 * @param requireOsAuthentication Defines, whether the user needs to authenticate to store a passphrase
	 * @see <a href="https://developer.apple.com/documentation/security/1398366-seckeychainaddgenericpassword">SecKeychainAddGenericPassword</a>
	 */
	public void storePassword(String serviceName, String account, CharSequence password, boolean requireOsAuthentication) throws KeychainAccessException {
		ByteBuffer pwBuf = UTF_8.encode(CharBuffer.wrap(password));
		byte[] pwBytes = new byte[pwBuf.remaining()];
		pwBuf.get(pwBytes);
		int errorCode = Native.INSTANCE.storePassword(serviceName.getBytes(UTF_8), account.getBytes(UTF_8), pwBytes, requireOsAuthentication);
		Arrays.fill(pwBytes, (byte) 0x00);
		Arrays.fill(pwBuf.array(), (byte) 0x00);
		if (errorCode != OSSTATUS_SUCCESS) {
			throw new KeychainAccessException("Failed to store password. Error code " + errorCode);
		}
	}

	/**
	 * Loads the password associated with the specified key from the system keychain.
	 *
	 * @param serviceName Service name
	 * @param account     Unique account identifier
	 * @return password or <code>null</code> if no such keychain entry could be loaded from the keychain.
	 * @see <a href="https://developer.apple.com/documentation/security/1397301-seckeychainfindgenericpassword">SecKeychainFindGenericPassword</a>
	 */
	public char[] loadPassword(String serviceName, String account) {
		byte[] pwBytes = Native.INSTANCE.loadPassword(serviceName.getBytes(UTF_8), account.getBytes(UTF_8));
		if (pwBytes == null) {
			// this if-statement is a workaround for https://github.com/cryptomator/integrations-mac/issues/13:
			if ("Cryptomator".equals(serviceName) && tryMigratePassword(account)) {
				// on success: retry
				return loadPassword(serviceName, account);
			}
			return null;
		} else {
			CharBuffer pwBuf = UTF_8.decode(ByteBuffer.wrap(pwBytes));
			char[] pw = new char[pwBuf.remaining()];
			pwBuf.get(pw);
			Arrays.fill(pwBytes, (byte) 0x00);
			Arrays.fill(pwBuf.array(), (char) 0x00);
			return pw;
		}
	}

	/**
	 * Fix for <a href="https://github.com/cryptomator/integrations-mac/issues/13">Issue 13</a>.
	 * Attempts to find the account with the old hard-coded service name 'Cryptomator\0'
	 *
	 * @param account Unique account identifier
	 * @return <code>true</code> on success
	 */
	private boolean tryMigratePassword(String account) {
		byte[] oldServiceName = {'C', 'r', 'y', 'p', 't', 'o', 'm', 'a', 't', 'o', 'r', '\0'};
		byte[] newServiceName = {'C', 'r', 'y', 'p', 't', 'o', 'm', 'a', 't', 'o', 'r'};
		byte[] pwBytes = Native.INSTANCE.loadPassword(oldServiceName, account.getBytes(UTF_8));
		if (pwBytes == null) {
			return false;
		}
		int errorCode = Native.INSTANCE.storePassword(newServiceName, account.getBytes(UTF_8), pwBytes, false);
		Arrays.fill(pwBytes, (byte) 0x00);
		if (errorCode != OSSTATUS_SUCCESS) {
			return false;
		}
		Native.INSTANCE.deletePassword(oldServiceName, account.getBytes(UTF_8));
		return true;
	}

	/**
	 * Deletes the password associated with the specified key from the system keychain.
	 *
	 * @param serviceName Service name
	 * @param account     Unique account identifier
	 * @return <code>true</code> if the passwords has been deleted, <code>false</code> if no entry for the given key exists.
	 * @see <a href="https://developer.apple.com/documentation/security/1395547-secitemdelete">SecKeychainItemDelete</a>
	 */
	public boolean deletePassword(String serviceName, String account) throws KeychainAccessException {
		int errorCode = Native.INSTANCE.deletePassword(serviceName.getBytes(UTF_8), account.getBytes(UTF_8));
		if (errorCode == OSSTATUS_SUCCESS) {
			return true;
		} else if (errorCode == OSSTATUS_NOT_FOUND) {
			return false;
		} else {
			throw new KeychainAccessException("Failed to delete password. Error code " + errorCode);
		}
	}

	// initialization-on-demand pattern, as loading the .dylib is an expensive operation
	private static class Native {
		static final Native INSTANCE = new Native();

		private Native() {
			NativeLibLoader.loadLib();
		}

		public native int storePassword(byte[] service, byte[] account, byte[] value, boolean requireOsAuthentication);

		public native byte[] loadPassword(byte[] service, byte[] account);

		public native int deletePassword(byte[] service, byte[] account);
	}

}
