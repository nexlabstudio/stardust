class Stardust < Formula
  desc "Dart-native documentation framework. Beautiful docs, zero config."
  homepage "https://github.com/nexlabstudio/stardust"
  version "0.1.0"
  license "MIT"

  on_macos do
    on_arm do
      url "https://github.com/nexlabstudio/stardust/releases/download/v#{version}/stardust-darwin-arm64.tar.gz"
      # sha256 will be updated by release workflow
      sha256 "PLACEHOLDER"
    end
    on_intel do
      url "https://github.com/nexlabstudio/stardust/releases/download/v#{version}/stardust-darwin-x64.tar.gz"
      sha256 "PLACEHOLDER"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/nexlabstudio/stardust/releases/download/v#{version}/stardust-linux-arm64.tar.gz"
      sha256 "PLACEHOLDER"
    end
    on_intel do
      url "https://github.com/nexlabstudio/stardust/releases/download/v#{version}/stardust-linux-x64.tar.gz"
      sha256 "PLACEHOLDER"
    end
  end

  def install
    bin.install "stardust"
  end

  test do
    assert_match "Stardust v#{version}", shell_output("#{bin}/stardust --version")
  end
end
