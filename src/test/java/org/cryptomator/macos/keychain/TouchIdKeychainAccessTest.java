package org.cryptomator.macos.keychain;

import org.cryptomator.integrations.keychain.KeychainAccessException;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;

public class TouchIdKeychainAccessTest {

	private MacKeychain keychain;
	private TouchIdKeychainAccess keychainAccess;

	@BeforeEach
	public void setup() {
		keychain = Mockito.mock(MacKeychain.class);
		keychainAccess = new TouchIdKeychainAccess(keychain);
	}

	@Test
	@DisplayName("loadPassphrase() returns protected pw")
	public void testLoadProtected() throws KeychainAccessException {
		Mockito.when(keychain.loadPassword("Cryptomator", "key")).thenReturn(new MacKeychain.StoredPassword("pass".toCharArray(), true));

		char[] result = keychainAccess.loadPassphrase("key");

		Assertions.assertArrayEquals("pass".toCharArray(), result);
		Mockito.verify(keychain, Mockito.never()).storePassword(Mockito.any(), Mockito.any(), Mockito.any(), Mockito.anyBoolean());
	}

	@Test
	@DisplayName("loadPassphrase() protects unprotected pw before returning it")
	public void testLoadUnprotected() throws KeychainAccessException {
		char[] unprotectedPw = "pass".toCharArray();
		Mockito.when(keychain.loadPassword("Cryptomator", "key")).thenReturn( //
				new MacKeychain.StoredPassword(unprotectedPw, false), //
				new MacKeychain.StoredPassword("pass".toCharArray(), true));
		var storedPw = new StringBuilder();
		Mockito.doAnswer(invocation -> storedPw.append(invocation.getArgument(2, CharSequence.class))).when(keychain).storePassword(Mockito.eq("Cryptomator"), Mockito.eq("key"), Mockito.any(), Mockito.eq(true));

		char[] result = keychainAccess.loadPassphrase("key");

		Assertions.assertArrayEquals("pass".toCharArray(), result);
		Assertions.assertEquals("pass", storedPw.toString());
		Assertions.assertArrayEquals(new char[4], unprotectedPw);
		var inOrder = Mockito.inOrder(keychain);
		inOrder.verify(keychain).loadPassword("Cryptomator", "key");
		inOrder.verify(keychain).storePassword(Mockito.eq("Cryptomator"), Mockito.eq("key"), Mockito.any(), Mockito.eq(true));
		inOrder.verify(keychain).loadPassword("Cryptomator", "key");
	}

	@Test
	@DisplayName("loadPassphrase() fails if pw stays unprotected")
	public void testLoadStaysUnprotected() throws KeychainAccessException {
		char[] reloadedPw = "pass".toCharArray();
		Mockito.when(keychain.loadPassword("Cryptomator", "key")).thenReturn( //
				new MacKeychain.StoredPassword("pass".toCharArray(), false), //
				new MacKeychain.StoredPassword(reloadedPw, false));

		Assertions.assertThrows(KeychainAccessException.class, () -> {
			keychainAccess.loadPassphrase("key");
		});
		Assertions.assertArrayEquals(new char[4], reloadedPw);
	}

	@Test
	@DisplayName("loadPassphrase() fails if protected pw vanished")
	public void testLoadVanished() throws KeychainAccessException {
		Mockito.when(keychain.loadPassword("Cryptomator", "key")).thenReturn( //
				new MacKeychain.StoredPassword("pass".toCharArray(), false), //
				null);

		Assertions.assertThrows(KeychainAccessException.class, () -> {
			keychainAccess.loadPassphrase("key");
		});
	}

	@Test
	@DisplayName("loadPassphrase() fails if unprotected pw cannot be protected")
	public void testLoadProtectError() throws KeychainAccessException {
		KeychainAccessException e = new KeychainAccessException("fail.");
		char[] unprotectedPw = "pass".toCharArray();
		Mockito.when(keychain.loadPassword("Cryptomator", "key")).thenReturn(new MacKeychain.StoredPassword(unprotectedPw, false));
		Mockito.doThrow(e).when(keychain).storePassword(Mockito.eq("Cryptomator"), Mockito.eq("key"), Mockito.any(), Mockito.eq(true));

		KeychainAccessException thrown = Assertions.assertThrows(KeychainAccessException.class, () -> {
			keychainAccess.loadPassphrase("key");
		});
		Assertions.assertSame(thrown, e);
		Assertions.assertArrayEquals(new char[4], unprotectedPw);
	}

	@Test
	@DisplayName("loadPassphrase() doesn't find pw")
	public void testLoadNotFound() throws KeychainAccessException {
		Mockito.when(keychain.loadPassword("Cryptomator", "key")).thenReturn(null);

		char[] result = keychainAccess.loadPassphrase("key");

		Assertions.assertNull(result);
	}

}
