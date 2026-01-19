class Stardust < Formula
  desc "Dart-native documentation framework. Beautiful docs, zero config."
  homepage "https://github.com/nexlabstudio/stardust"
  version "0.2.2"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.2.2/stardust-darwin-arm64.tar.gz"
      sha256 "6866b4f340e22f2ca20cea3a9af40f457b4befa5d50772b82734317a34df5556"
    end
    on_intel do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.2.2/stardust-darwin-x64.tar.gz"
      sha256 "cbdc1ef4f7ce6768302f9ea005afcde8436013258f70acaba2419b8e93a05750"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.2.2/stardust-linux-arm64.tar.gz"
      sha256 "0c666b6e07f09477f3ae6f076f2341155f9de8fefd53ca061520bbc8380b32d4"
    end
    on_intel do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.2.2/stardust-linux-x64.tar.gz"
      sha256 "e9c4ebab745c3bc59cbecdca35de87d47ac6f8cd9e620d18689aae74ee4d742a"
    end
  end

  def install
    bin.install "stardust"
  end

  test do
    assert_match "Stardust v0.2.2", shell_output("#{bin}/stardust --version")
  end
end
