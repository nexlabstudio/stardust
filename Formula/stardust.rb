class Stardust < Formula
  desc "Dart-native documentation framework. Beautiful docs, zero config."
  homepage "https://github.com/nexlabstudio/stardust"
  version "0.1.1"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.1.1/stardust-darwin-arm64.tar.gz"
      sha256 "bfba84e97c008bb2233436acc9d4cec987b7c1ede49976b83ab3a9394821ec39"
    end
    on_intel do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.1.1/stardust-darwin-x64.tar.gz"
      sha256 "4730e771d932807cce414e27e0e044a09870ce54223d1077829a68f978d7d5bb"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.1.1/stardust-linux-arm64.tar.gz"
      sha256 "c89dc69c9bea560942f5df1930fc4beaad98e4a8a80e56babdca6e15e4db4b83"
    end
    on_intel do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.1.1/stardust-linux-x64.tar.gz"
      sha256 "d408ecb7c872988a85dab1423844935c57b3b321b118deac40c5940ae68f2a7d"
    end
  end

  def install
    bin.install "stardust"
  end

  test do
    assert_match "Stardust v0.1.1", shell_output("#{bin}/stardust --version")
  end
end
