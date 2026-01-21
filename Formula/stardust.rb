class Stardust < Formula
  desc "Dart-native documentation generator. Beautiful docs, zero config."
  homepage "https://github.com/nexlabstudio/stardust"
  version "0.3.3"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.3.3/stardust-darwin-arm64.tar.gz"
      sha256 "0304f46ca6f042c9f97a8d176144fbbbe1418a749dc8c9da51f7838e77f2a053"
    end
    on_intel do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.3.3/stardust-darwin-x64.tar.gz"
      sha256 "0b92ed7ab000f3ab57bbcf58b3b5aaf92bb68e1b6e4115f9e1ca2986f586c9f6"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.3.3/stardust-linux-arm64.tar.gz"
      sha256 "600ac4d778c43dc444baa5ce80f6dbb3305fb59457107353ffa9d956081315dc"
    end
    on_intel do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.3.3/stardust-linux-x64.tar.gz"
      sha256 "b4d81f8d1e2ce2cfac3215a8e488c84821202caeba128ac3c5a789fe3eb9a6c0"
    end
  end

  def install
    bin.install "stardust"
  end

  test do
    assert_match "Stardust v0.3.3", shell_output("#{bin}/stardust --version")
  end
end
