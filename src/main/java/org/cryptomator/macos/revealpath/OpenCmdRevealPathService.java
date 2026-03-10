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
import java.util.List;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;

@Priority(100)
@OperatingSystem(OperatingSystem.Value.MAC)
public class OpenCmdRevealPathService implements RevealPathService {

	@Override
	public void reveal(Path p) throws RevealFailedException {
		Process process = null;
		try {
			var cmd = createCommandAsList(p);
			process = new ProcessBuilder().command(cmd).start();
			try (var reader = process.errorReader()) {
				if (process.waitFor(5000, TimeUnit.MILLISECONDS)) {
					int exitValue = process.exitValue();
					if (exitValue != 0) {
						String error = reader.lines().collect(Collectors.joining());
						throw new RevealFailedException("open command exited with value " + exitValue + " and error message: " + error);
					}
				} else {
					throw new IOException("Command %s not completed after 5s.".formatted(cmd.toString()));
				}
			}
		} catch (IOException e) {
			throw new RevealFailedException(e);
		} catch (InterruptedException e) {
			Thread.currentThread().interrupt();
			throw new RevealFailedException(e);
		} finally {
			if (process != null) {
				process.destroyForcibly();
			}
		}
	}

	private List<String> createCommandAsList(Path p) throws IOException {
		var pathIsADirectory = Files.readAttributes(p, BasicFileAttributes.class, LinkOption.NOFOLLOW_LINKS).isDirectory();
		if (pathIsADirectory) {
			return List.of("open", p.toString());
		} else {
			return List.of("open", "-R", p.toString());
		}
	}

	@Override
	public boolean isSupported() {
		return true;
	}

}
