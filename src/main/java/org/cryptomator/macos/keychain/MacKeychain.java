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
	 * @return password or <code>null</code> if no such keychain entry exists.
	 * @throws KeychainAccessException If loading fails for any reason other than a missing entry, e.g. because authentication was cancelled
	 * @see <a href="https://developer.apple.com/documentation/security/secitemcopymatching(_:_:)">SecItemCopyMatching</a>
	 */
	public char[] loadPassword(String serviceName, String account) throws KeychainAccessException {
		return toPassword(Native.INSTANCE.loadPassword(serviceName.getBytes(UTF_8), account.getBytes(UTF_8)));
	}

	// visible for testing
	static char[] toPassword(LoadResult result) throws KeychainAccessException {
		if (result.status() == OSSTATUS_NOT_FOUND) {
			return null;
		} else if (result.status() != OSSTATUS_SUCCESS || result.password() == null) {
			throw new KeychainAccessException("Failed to load password. Error code " + result.status());
		}
		byte[] pwBytes = result.password();
		CharBuffer pwBuf = UTF_8.decode(ByteBuffer.wrap(pwBytes));
		char[] pw = new char[pwBuf.remaining()];
		pwBuf.get(pw);
		Arrays.fill(pwBytes, (byte) 0x00);
		Arrays.fill(pwBuf.array(), (char) 0x00);
		return pw;
	}

	/**
	 * Deletes the password associated with the specified key from the system keychain.
	 *
	 * @param serviceName Service name
	 * @param account     Unique account identifier
	 * @return <code>true</code> if the passwords has been deleted, <code>false</code> if no entry for the given key exists.
	 * @see <a href="https://developer.apple.com/documentation/security/secitemdelete(_:)">SecItemDelete</a>
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

	/**
	 * Tests whether biometric authentication via Touch ID is supported and allowed on the device
	 *
	 * @return <code>true</code> if biometric authentication is available, <code>false</code> otherwise
	 */
	public boolean isTouchIDavailable() {
		return Native.INSTANCE.isTouchIDavailable();
	}

	// constructed via JNI by class name and constructor signature, so renaming or reordering its components breaks the native loadPassword
	record LoadResult(int status, byte[] password) {
	}

	// initialization-on-demand pattern, as loading the .dylib is an expensive operation
	private static class Native {
		static final Native INSTANCE = new Native();

		private Native() {
			NativeLibLoader.loadLib();
		}

		public native int storePassword(byte[] service, byte[] account, byte[] value, boolean requireOsAuthentication);

		public native LoadResult loadPassword(byte[] service, byte[] account);

		public native int deletePassword(byte[] service, byte[] account);

		public native boolean isTouchIDavailable();
	}

}
