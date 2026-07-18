class Stardust < Formula
  desc "Dart-native documentation generator. Beautiful docs, zero config."
  homepage "https://github.com/nexlabstudio/stardust"
  version "0.5.0"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.5.0/stardust-darwin-arm64.tar.gz"
      sha256 "405df7b2524d6bc360e04afa6792c7a35d23a757a0e743c964ed2ef5401d7013"
    end
    on_intel do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.5.0/stardust-darwin-x64.tar.gz"
      sha256 "d42e4d256c33983e456883bb4d56ad036b16df82b244449225f9be2e6ba914fb"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.5.0/stardust-linux-arm64.tar.gz"
      sha256 "a0d6abf61cdcd62419a3e4564730e69343f948177ecca4284752f0b451f6c3af"
    end
    on_intel do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.5.0/stardust-linux-x64.tar.gz"
      sha256 "c575415a1f4281a06da2869fb8e5ac49d872afc8fa09fe587093b903a2795d2d"
    end
  end

  def install
    bin.install "stardust"
  end

  test do
    assert_match "Stardust v0.5.0", shell_output("#{bin}/stardust --version")
  end
end
