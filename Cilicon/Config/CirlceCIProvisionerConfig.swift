import Foundation

struct CircleCIProvisionerConfig: Decodable {
    /// The runner token, can be obtained in the CircleCI UI when creating a new runner
    let runnerToken: String
    // The unique name of your choosing assigned to this particular CircleCI machine runner
    let runnerName: String
    /// Whether the latest CircleCI runner should be downloaded. Defaults to `true`
    let downloadLatest: Bool
    /// The URL where the CircleCI runner can be downloaded
    /// Only used if `downloadLatest` is set to `true`
    let downloadURL: String
    /// Optional advanced configuration for the CircleCI, will be appended to the `config.yaml` file after the preconfigured
    /// section.
    let configYaml: String?

    enum CodingKeys: CodingKey {
        case runnerToken
        case runnerName
        case downloadLatest
        case downloadURL
        case configYaml
    }

    init(from decoder: Decoder) throws {
        let defaultDownloadURL = "https://circleci-binary-releases.s3.amazonaws.com/circleci-runner/current/circleci-runner_darwin_arm64.tar.gz"
        let defaultRunnerName = "macos-runner-" + (Host.current().localizedName ?? NSUUID().uuidString)

        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.runnerToken = try container.decode(String.self, forKey: .runnerToken)
        self.runnerName = try container.decodeIfPresent(String.self, forKey: .runnerName) ?? defaultRunnerName
        self.downloadLatest = try container.decodeIfPresent(Bool.self, forKey: .downloadLatest) ?? true
        self.downloadURL = try container.decodeIfPresent(String.self, forKey: .downloadURL) ?? defaultDownloadURL
        self.configYaml = try container.decodeIfPresent(String.self, forKey: .configYaml)
    }
}
