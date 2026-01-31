class Stardust < Formula
  desc "Dart-native documentation generator. Beautiful docs, zero config."
  homepage "https://github.com/nexlabstudio/stardust"
  version "0.4.0"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.4.0/stardust-darwin-arm64.tar.gz"
      sha256 "bb9e246ed08e5f19ad2296a390d5b1ae23d52aaaf54471ad8aa15da7aba3a957"
    end
    on_intel do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.4.0/stardust-darwin-x64.tar.gz"
      sha256 "e4c1638c3f1fd7a4fcbcb72ab7e444ecb5508aa6e5831ef93fa38a6aa6f2d4ef"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.4.0/stardust-linux-arm64.tar.gz"
      sha256 "e7dde9537b8be8e1356a9cfea82d3c3c6b8b715874e3455a64bd17f719c1808c"
    end
    on_intel do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.4.0/stardust-linux-x64.tar.gz"
      sha256 "e59e20a6b55a9263d4561afb4b00b15351d3224b592b1dbf595899feb1ded774"
    end
  end

  def install
    bin.install "stardust"
  end

  test do
    assert_match "Stardust v0.4.0", shell_output("#{bin}/stardust --version")
  end
end
