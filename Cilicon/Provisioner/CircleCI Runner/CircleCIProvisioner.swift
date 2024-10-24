import Citadel
import Foundation

class CircleCIProvisioner: Provisioner {
    let config: CircleCIProvisionerConfig

    init(config: CircleCIProvisionerConfig) {
        self.config = config
    }

    func provision(bundle: VMBundle, sshClient: SSHClient) async throws {
        var downloadCommands: [String] = []

        await SSHLogger.shared.log(string: "Configuring CircleCI Runner...".magentaBold)
        let copyConfigYamlCommand = """
        mkdir ~/circleci
        rm -rf ~/circleci-runner-config.yaml
        cat <<'EOF' >> ~/circleci-runner-config.yaml
        runner:
          name: "\(config.runnerName)"
          mode: single-task
          working_directory: "~/circleci"
          cleanup_working_directory: true
        api:
          auth_token: "\(config.runnerToken)"
        \(config.configYaml ?? "")
        EOF
        exit 0
        """
        try await executeCommand(command: copyConfigYamlCommand, sshClient: sshClient)
        await SSHLogger.shared.log(string: "Successfully configured CircleCI Runner".greenBold)

        if config.downloadLatest {
            await SSHLogger.shared.log(string: "Downloading CircleCI Runner".magentaBold)
            downloadCommands = [
                "rm -rf ~/circleci-runner",
                "curl -so circleci-runner.tar.gz -L \(config.downloadURL)",
                "tar -xzf circleci-runner.tar.gz  --directory ~/circleci"
            ]
            try await executeCommand(command: downloadCommands.joined(separator: " && "), sshClient: sshClient)
            await SSHLogger.shared.log(string: "Downloaded CircleCI Runner successfully".magentaBold)
        } else {
            await SSHLogger.shared.log(string: "Skipped downloading CircleCI because downloadLatest is false".magentaBold)
        }

        let runCommand = "~/circleci/circleci-runner machine --config ~/circleci-runner-config.yaml"
        await SSHLogger.shared.log(string: "Starting CircleCI Runner...".magentaBold)
        try await executeCommand(command: runCommand, sshClient: sshClient)
    }

    private func executeCommand(command: String, sshClient: SSHClient) async throws {
        let streamOutput = try await sshClient.executeCommandStream(command, inShell: true)
        for try await blob in streamOutput {
            switch blob {
            case let .stdout(stdout):
                await SSHLogger.shared.log(string: String(buffer: stdout))
            case let .stderr(stderr):
                await SSHLogger.shared.log(string: String(buffer: stderr))
            }
        }
    }
}

/// Shell output color values
private extension String {
    var greenBold: String { "\u{001B}[1;32m\(self)\u{001B}[0m\n" }
    var magentaBold: String { "\u{001B}[1;35m\(self)\u{001B}[0m\n" }
}
