class Stardust < Formula
  desc "Dart-native documentation generator. Beautiful docs, zero config."
  homepage "https://github.com/nexlabstudio/stardust"
  version "0.6.3"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.6.3/stardust-darwin-arm64.tar.gz"
      sha256 "2d26f34242985e5d99c3837f5a3fa483b3bc5b970bdb415d2e5eb56cd22ed64b"
    end
    on_intel do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.6.3/stardust-darwin-x64.tar.gz"
      sha256 "87e41bbdd1fefe575d00f9a3f14a45ec61b9a1c6f19622f75876a906cbf4477c"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.6.3/stardust-linux-arm64.tar.gz"
      sha256 "fb10f3a797a13b845da752ad9db68990698953e3737fde4f5cafb8bee493ceb7"
    end
    on_intel do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.6.3/stardust-linux-x64.tar.gz"
      sha256 "b34cb1ad3464f518153837589a39006e9339c4abc2a4ca1bbb674db343b2ebfe"
    end
  end

  def install
    bin.install "stardust"
  end

  test do
    assert_match "Stardust v0.6.3", shell_output("#{bin}/stardust --version")
  end
end
