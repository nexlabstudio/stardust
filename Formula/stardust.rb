class Stardust < Formula
  desc "Dart-native documentation generator. Beautiful docs, zero config."
  homepage "https://github.com/nexlabstudio/stardust"
  version "0.6.4"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.6.4/stardust-darwin-arm64.tar.gz"
      sha256 "b0078dc41c528146726e8ce37761317e61dc16b61395dff872b4a753a6f2fc09"
    end
    on_intel do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.6.4/stardust-darwin-x64.tar.gz"
      sha256 "8158fa3aef1ee5a3cf82d2626c8e518e99b32840775209c559b4e16915bbaf5d"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.6.4/stardust-linux-arm64.tar.gz"
      sha256 "11b1801d7faae9d95a5708cd78593473deaf48eb9935846afffd32ca805b7b51"
    end
    on_intel do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.6.4/stardust-linux-x64.tar.gz"
      sha256 "d4f04b7c36c6b82579ec062ec689d6b97e9e1562beb0fea7d5c8f71bfdcc3ca7"
    end
  end

  def install
    bin.install "stardust"
  end

  test do
    assert_match "Stardust v0.6.4", shell_output("#{bin}/stardust --version")
  end
end
