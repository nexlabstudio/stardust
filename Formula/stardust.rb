class Stardust < Formula
  desc "Dart-native documentation generator. Beautiful docs, zero config."
  homepage "https://github.com/nexlabstudio/stardust"
  version "0.7.0"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.7.0/stardust-darwin-arm64.tar.gz"
      sha256 "ff5d2fbd416d5141dced9d0a1e703e846ccdca35df09f8114f307011f1c3a76b"
    end
    on_intel do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.7.0/stardust-darwin-x64.tar.gz"
      sha256 "c10dc6b4dacf4c1a53f1b54bc16c8129de9fc54fa2ce62235727b8a22be3c5c2"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.7.0/stardust-linux-arm64.tar.gz"
      sha256 "a6ce04b813116d472a601fee47e480f76675980680b83bd2fac9419a9dfef5f3"
    end
    on_intel do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.7.0/stardust-linux-x64.tar.gz"
      sha256 "16b71ab75d5e49e36bd0c0a969c8c85b9d4bdb5d9e153cd179dcc54a5a4afa8e"
    end
  end

  def install
    bin.install "stardust"
  end

  test do
    assert_match "Stardust v0.7.0", shell_output("#{bin}/stardust --version")
  end
end
