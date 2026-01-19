class Stardust < Formula
  desc "Dart-native documentation framework. Beautiful docs, zero config."
  homepage "https://github.com/nexlabstudio/stardust"
  version "0.2.0"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.2.0/stardust-darwin-arm64.tar.gz"
      sha256 "17c83f170f8c1808dbc8f1155ced4100bddf3de114cb6ee4003120875edeb597"
    end
    on_intel do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.2.0/stardust-darwin-x64.tar.gz"
      sha256 "879352c86369cb1faf3a92ae9c846e87ca467a2b702a9510091b859c24550783"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.2.0/stardust-linux-arm64.tar.gz"
      sha256 "e0d1d973c78edb976bb66c94d8fb520962c27f3bdb83812ad4e519c8cd41f1f6"
    end
    on_intel do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.2.0/stardust-linux-x64.tar.gz"
      sha256 "3c99b0ab186aba48f825ad463684a1cc8cd05d498b4fbe9e06e12f33643dbeee"
    end
  end

  def install
    bin.install "stardust"
  end

  test do
    assert_match "Stardust v0.2.0", shell_output("#{bin}/stardust --version")
  end
end
