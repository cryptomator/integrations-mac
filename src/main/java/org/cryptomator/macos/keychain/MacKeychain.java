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
	 * @param serviceName Service name
	 * @param account Unique account identifier
	 * @param password Passphrase to store
	 * @see <a href="https://developer.apple.com/documentation/security/1398366-seckeychainaddgenericpassword">SecKeychainAddGenericPassword</a>
	 */
	public void storePassword(String serviceName, String account, CharSequence password) throws KeychainAccessException {
		ByteBuffer pwBuf = UTF_8.encode(CharBuffer.wrap(password));
		byte[] pwBytes = new byte[pwBuf.remaining()];
		pwBuf.get(pwBytes);
		int errorCode = Native.INSTANCE.storePassword(serviceName.getBytes(UTF_8), account.getBytes(UTF_8), pwBytes);
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
	 * @param account Unique account identifier
	 * @return password or <code>null</code> if no such keychain entry could be loaded from the keychain.
	 * @see <a href="https://developer.apple.com/documentation/security/1397301-seckeychainfindgenericpassword">SecKeychainFindGenericPassword</a>
	 */
	public char[] loadPassword(String serviceName, String account) {
		byte[] pwBytes = Native.INSTANCE.loadPassword(serviceName.getBytes(UTF_8), account.getBytes(UTF_8));
		if (pwBytes == null) {
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
	 * Deletes the password associated with the specified key from the system keychain.
	 *
	 * @param serviceName Service name
	 * @param account Unique account identifier
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

		public native int storePassword(byte[] service, byte[] account, byte[] value);

		public native byte[] loadPassword(byte[] service, byte[] account);

		public native int deletePassword(byte[] service, byte[] account);
	}

}
