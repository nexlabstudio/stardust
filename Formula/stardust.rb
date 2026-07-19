class Stardust < Formula
  desc "Dart-native documentation generator. Beautiful docs, zero config."
  homepage "https://github.com/nexlabstudio/stardust"
  version "0.6.2"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.6.2/stardust-darwin-arm64.tar.gz"
      sha256 "d9c58c7abe36b9800b71b4d4d3c392bc91620dfa325a079f7b69be2fc6730e19"
    end
    on_intel do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.6.2/stardust-darwin-x64.tar.gz"
      sha256 "b0d0386c991f4f6143e5495ce7c8d31620edbf02658878740a85a2b122061716"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.6.2/stardust-linux-arm64.tar.gz"
      sha256 "3153bd9738dded2a778b6c9d7f678ed13f2498b2c53d39031b081a1c299a5484"
    end
    on_intel do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.6.2/stardust-linux-x64.tar.gz"
      sha256 "ad5d1aa83b65e0ae82157f960c7dd93cc56ec13c9667f9b91135a7a5d1be487b"
    end
  end

  def install
    bin.install "stardust"
  end

  test do
    assert_match "Stardust v0.6.2", shell_output("#{bin}/stardust --version")
  end
end
