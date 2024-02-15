package org.cryptomator.macos.keychain;

import org.cryptomator.integrations.keychain.KeychainAccessException;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

public class MacSystemKeychainAccessTest {

	private MacSystemKeychainAccess keychainAccess;

	@BeforeEach
	public void setup() {
		keychainAccess = new MacSystemKeychainAccess();
	}

	@Test
	@DisplayName("displayName() does not return default name")
	public void testDisplayName() {
		var displayName = keychainAccess.displayName();

		Assertions.assertNotEquals(keychainAccess.getClass().getSimpleName(), displayName);
	}

	@Test
	@DisplayName("storePassphrase() succeeds")
	public void testStoreSuccess() {
		Assertions.assertDoesNotThrow(() -> keychainAccess.storePassphrase("key", "displayName", "pass"));
	}

	@Test
	@DisplayName("storePassphrase() fails")
	public void testStoreError() {
		KeychainAccessException e = new KeychainAccessException("fail.");

		KeychainAccessException thrown = Assertions.assertThrows(KeychainAccessException.class, () -> {
			keychainAccess.storePassphrase("key", "displayName", "pass");
		});

		Assertions.assertSame(e, thrown.getMessage());
	}

	@Test
	@DisplayName("loadPassphrase() succeeds")
	public void testLoadSuccess() {
		char[] result = keychainAccess.loadPassphrase("key");

		Assertions.assertArrayEquals("pass".toCharArray(), result);
	}

	@Test
	@DisplayName("loadPassphrase() does find pw")
	public void testLoadNotFound() {
		char[] result = keychainAccess.loadPassphrase("key");

		Assertions.assertNull(result);
	}

	@Test
	@DisplayName("deletePassphrase() succeeds")
	public void testDeleteSuccess() {
		Assertions.assertDoesNotThrow(() -> keychainAccess.deletePassphrase("key"));
	}

	@Test
	@DisplayName("deletePassphrase() fails")
	public void testDeleteError() {
		KeychainAccessException e = new KeychainAccessException("fail.");

		KeychainAccessException thrown = Assertions.assertThrows(KeychainAccessException.class, () -> {
			keychainAccess.deletePassphrase("key");
		});

		Assertions.assertSame(e, thrown.getMessage());
	}

	@Test
	@DisplayName("changePassphrase() succeeds")
	public void testChangeSuccess() throws KeychainAccessException {
		keychainAccess.storePassphrase("key", "displayName", "pass");

		Assertions.assertDoesNotThrow(() -> keychainAccess.changePassphrase("key", "displayName", "newpass"));
	}

	@Test
	@DisplayName("changePassphrase() fails")
	public void testChangeError() throws KeychainAccessException {
		keychainAccess.deletePassphrase("key");
		KeychainAccessException e = new KeychainAccessException("fail.");
		KeychainAccessException thrown = Assertions.assertThrows(KeychainAccessException.class, () -> {
			keychainAccess.changePassphrase("key", "displayName", "newpass");
		});

		Assertions.assertSame(thrown, e);
	}

}