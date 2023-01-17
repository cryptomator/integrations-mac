package org.cryptomator.macos.revealpath;

import org.cryptomator.integrations.common.OperatingSystem;
import org.cryptomator.integrations.common.Priority;
import org.cryptomator.integrations.revealpath.RevealFailedException;
import org.cryptomator.integrations.revealpath.RevealPathService;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.LinkOption;
import java.nio.file.Path;
import java.nio.file.attribute.BasicFileAttributes;
import java.util.concurrent.TimeUnit;

@Priority(100)
@OperatingSystem(OperatingSystem.Value.MAC)
public class OpenCmdRevealPathService implements RevealPathService {

	@Override
	public void reveal(Path p) throws RevealFailedException {
		try {
			var attrs = Files.readAttributes(p, BasicFileAttributes.class, LinkOption.NOFOLLOW_LINKS);
			ProcessBuilder pb = new ProcessBuilder().command("open", attrs.isDirectory()?"":"-R" ,"\"" + p.toString()+"\"");
			var process = pb.start();
			if (process.waitFor(5000, TimeUnit.MILLISECONDS)) {
				int exitValue = process.exitValue();
				if (process.exitValue() != 0) {
					throw new RevealFailedException("open command exited with value " + exitValue);
				}
			}
		} catch (IOException e) {
			throw new RevealFailedException(e);
		} catch (InterruptedException e) {
			Thread.currentThread().interrupt();
			throw new RevealFailedException(e);
		}
	}

	@Override
	public boolean isSupported() {
		return true;
	}
}
