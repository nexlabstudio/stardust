class Stardust < Formula
  desc "Dart-native documentation generator. Beautiful docs, zero config."
  homepage "https://github.com/nexlabstudio/stardust"
  version "0.6.5"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.6.5/stardust-darwin-arm64.tar.gz"
      sha256 "5e407364627f9345195542cffdd26e14db54ea9b30fa9652813210a1e9daee7e"
    end
    on_intel do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.6.5/stardust-darwin-x64.tar.gz"
      sha256 "930e9c995b8fc27b6365b6452022784c35a58baf96eb5f581bddfa721908dfd6"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.6.5/stardust-linux-arm64.tar.gz"
      sha256 "3da517e79a0b2b98cc15b2ac368f119799050fe14bf5493ad2cd86e64ddac298"
    end
    on_intel do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.6.5/stardust-linux-x64.tar.gz"
      sha256 "c5dcaa3608d98e92c437858f3ccb33c20861440b160fcce440ff613ed02e19ca"
    end
  end

  def install
    bin.install "stardust"
  end

  test do
    assert_match "Stardust v0.6.5", shell_output("#{bin}/stardust --version")
  end
end
