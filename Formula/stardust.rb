class Stardust < Formula
  desc "Dart-native documentation framework. Beautiful docs, zero config."
  homepage "https://github.com/nexlabstudio/stardust"
  version "0.2.1"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.2.1/stardust-darwin-arm64.tar.gz"
      sha256 "66f9b584b25122de14b8454f1a7939a3e6e089d6e7a828dd6c5e8dec8f4b2032"
    end
    on_intel do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.2.1/stardust-darwin-x64.tar.gz"
      sha256 "a92e3c2f5c0a36db0d2d5b18980fdf910b3a6627dce672a938962b3fa33f06ea"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.2.1/stardust-linux-arm64.tar.gz"
      sha256 "71217bf0ecc56c6afb06c7d37d35a2929df191c11c9d500904bac4daa6b49b96"
    end
    on_intel do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.2.1/stardust-linux-x64.tar.gz"
      sha256 "96af1c8f5921c514d595b672a7b31393869faadd6bfb7896213b95ab2cf069f8"
    end
  end

  def install
    bin.install "stardust"
  end

  test do
    assert_match "Stardust v0.2.1", shell_output("#{bin}/stardust --version")
  end
end
