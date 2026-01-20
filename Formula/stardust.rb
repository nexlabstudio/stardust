class Stardust < Formula
  desc "Dart-native documentation generator. Beautiful docs, zero config."
  homepage "https://github.com/nexlabstudio/stardust"
  version "0.3.0"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.3.0/stardust-darwin-arm64.tar.gz"
      sha256 "c9ca2ec93750dd586a11e7e12b13a44069067e0ef231d1f5278634978ea6d420"
    end
    on_intel do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.3.0/stardust-darwin-x64.tar.gz"
      sha256 "03cb5f9960ce22dafbeefe0980ff7bc951dd1908e9f9107ec34a42e46f7fea4e"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.3.0/stardust-linux-arm64.tar.gz"
      sha256 "0b41e5b4bc4b7c7af10508d4c1acf0193300cf8a830a58f5378486e7d324ac7c"
    end
    on_intel do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.3.0/stardust-linux-x64.tar.gz"
      sha256 "43b9f661fbdf0318ce38d8bc26090eaffa175b15009e846b7af76dc2c57f2770"
    end
  end

  def install
    bin.install "stardust"
  end

  test do
    assert_match "Stardust v0.3.0", shell_output("#{bin}/stardust --version")
  end
end
