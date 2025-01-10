package org.cryptomator.macos.keychain;

import org.cryptomator.integrations.keychain.KeychainAccessException;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;

public class MacSystemKeychainAccessTest {

	private MacKeychain keychain;
	private MacSystemKeychainAccess keychainAccess;

	@BeforeEach
	public void setup() {
		keychain = Mockito.mock(MacKeychain.class);
		keychainAccess = new MacSystemKeychainAccess(keychain);
	}

	@Test
	@DisplayName("displayName() does not return default name")
	public void testDisplayName() {
		var displayName = keychainAccess.displayName();

		Assertions.assertNotEquals(keychainAccess.getClass().getSimpleName(), displayName);
	}

	@Test
	@DisplayName("storePassphrase() succeeds")
	public void testStoreSuccess() throws KeychainAccessException {
		keychainAccess.storePassphrase("key", "pass");

		Mockito.verify(keychain).storePassword("Cryptomator", "key", "pass", false);
	}

	@Test
	@DisplayName("storePassphrase() fails")
	public void testStoreError() throws KeychainAccessException {
		KeychainAccessException e = new KeychainAccessException("fail.");
		Mockito.doThrow(e).when(keychain).storePassword(Mockito.eq("Cryptomator"), Mockito.any(), Mockito.any(), Mockito.eq(false));

		KeychainAccessException thrown = Assertions.assertThrows(KeychainAccessException.class, () -> {
			keychainAccess.storePassphrase("key", "", "pass", false);
		});
		Assertions.assertSame(thrown, e);
	}

	@Test
	@DisplayName("loadPassphrase() succeeds")
	public void testLoadSuccess() {
		Mockito.when(keychain.loadPassword("Cryptomator", "key")).thenReturn("pass".toCharArray());

		char[] result = keychainAccess.loadPassphrase("key");

		Assertions.assertArrayEquals("pass".toCharArray(), result);
	}

	@Test
	@DisplayName("loadPassphrase() doesn't find pw")
	public void testLoadNotFound() {
		Mockito.when(keychain.loadPassword("Cryptomator", "key")).thenReturn(null);

		char[] result = keychainAccess.loadPassphrase("key");

		Assertions.assertNull(result);
	}

	@Test
	@DisplayName("deletePassphrase() succeeds")
	public void testDeleteSuccess() throws KeychainAccessException {
		keychainAccess.deletePassphrase("key");

		Mockito.verify(keychain).deletePassword("Cryptomator", "key");
	}

	@Test
	@DisplayName("deletePassphrase() fails")
	public void testDeleteError() throws KeychainAccessException {
		KeychainAccessException e = new KeychainAccessException("fail.");
		Mockito.doThrow(e).when(keychain).deletePassword(Mockito.eq("Cryptomator"), Mockito.any());

		KeychainAccessException thrown = Assertions.assertThrows(KeychainAccessException.class, () -> {
			keychainAccess.deletePassphrase("key");
		});
		Assertions.assertSame(thrown, e);
	}

	@Test
	@DisplayName("changePassphrase() succeeds")
	public void testChangeSuccess() throws KeychainAccessException {
		Mockito.when(keychain.deletePassword("Cryptomator", "key")).thenReturn(true);

		keychainAccess.changePassphrase("key", "newpass");

		Mockito.verify(keychain).storePassword("Cryptomator", "key", "newpass", false);
	}

	@Test
	@DisplayName("changePassphrase() doesn't find pw")
	public void testChangeNotFound() throws KeychainAccessException {
		Mockito.when(keychain.deletePassword("Cryptomator", "key")).thenReturn(false);

		keychainAccess.changePassphrase("key", "newpass");

		Mockito.verify(keychain, Mockito.never()).storePassword("Cryptomator", "key", "newpass", false);
	}

	@Test
	@DisplayName("changePassphrase() fails")
	public void testChangeError() throws KeychainAccessException {
		KeychainAccessException e = new KeychainAccessException("fail.");
		Mockito.doThrow(e).when(keychain).deletePassword(Mockito.eq("Cryptomator"), Mockito.any());

		KeychainAccessException thrown = Assertions.assertThrows(KeychainAccessException.class, () -> {
			keychainAccess.changePassphrase("key", "newpass");
		});
		Assertions.assertSame(thrown, e);
	}

}