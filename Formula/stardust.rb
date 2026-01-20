class Stardust < Formula
  desc "Dart-native documentation framework. Beautiful docs, zero config."
  homepage "https://github.com/nexlabstudio/stardust"
  version "0.2.3"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.2.3/stardust-darwin-arm64.tar.gz"
      sha256 "a6ff070c94eb4c26e63d286242b55517d95d63da415592c8a39d7b209e78b4da"
    end
    on_intel do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.2.3/stardust-darwin-x64.tar.gz"
      sha256 "79233ea65f2f6be12a0e41e807c8bffa344bfc1ac6338d5b91a01a17602be896"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.2.3/stardust-linux-arm64.tar.gz"
      sha256 "0d321be7d1e18041b65463805b561e8c748587454e19cd8cd0113657938c7217"
    end
    on_intel do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.2.3/stardust-linux-x64.tar.gz"
      sha256 "6f682ee9d0aa4359959abc65ce14396380783a723ba6e81dffe2b32506bb2912"
    end
  end

  def install
    bin.install "stardust"
  end

  test do
    assert_match "Stardust v0.2.3", shell_output("#{bin}/stardust --version")
  end
end
