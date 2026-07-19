class Stardust < Formula
  desc "Dart-native documentation generator. Beautiful docs, zero config."
  homepage "https://github.com/nexlabstudio/stardust"
  version "0.6.0"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.6.0/stardust-darwin-arm64.tar.gz"
      sha256 "e6c753831bb8509d4675febc15666cafe8808302700ee1ceca892b75db421911"
    end
    on_intel do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.6.0/stardust-darwin-x64.tar.gz"
      sha256 "2e078692916d64124006eabfb570444f7c73804d4aa8df6389e11dc3fef475cd"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.6.0/stardust-linux-arm64.tar.gz"
      sha256 "b1b0bc362d01b15b0cdaf3b8748f1551ad4f9ea19734ae4c55b2c04bfef166b9"
    end
    on_intel do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.6.0/stardust-linux-x64.tar.gz"
      sha256 "eab5975e7b2ca258e2f40ad2fcd3e1fb881c88ea9b62d998c24d89a18bc7bc22"
    end
  end

  def install
    bin.install "stardust"
  end

  test do
    assert_match "Stardust v0.6.0", shell_output("#{bin}/stardust --version")
  end
end
