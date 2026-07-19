class Stardust < Formula
  desc "Dart-native documentation generator. Beautiful docs, zero config."
  homepage "https://github.com/nexlabstudio/stardust"
  version "0.6.1"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.6.1/stardust-darwin-arm64.tar.gz"
      sha256 "f90e44c7ff0efb31fd14ce810aacf35d392d999bd95ddf384403757a68c8ccaa"
    end
    on_intel do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.6.1/stardust-darwin-x64.tar.gz"
      sha256 "e31e9c80d60b669c12c4c1dea89258dd6806c7f190c9d037df9a3578f336ab70"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.6.1/stardust-linux-arm64.tar.gz"
      sha256 "befca0139980435452811004813cec50e535ec645d4a383a9f0dbd18894a5f23"
    end
    on_intel do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.6.1/stardust-linux-x64.tar.gz"
      sha256 "962f3b8c774210dd56c4684e62765d60561ca691a3ac27b5745dfe3d8a2cf904"
    end
  end

  def install
    bin.install "stardust"
  end

  test do
    assert_match "Stardust v0.6.1", shell_output("#{bin}/stardust --version")
  end
end
