class Stardust < Formula
  desc "Dart-native documentation generator. Beautiful docs, zero config."
  homepage "https://github.com/nexlabstudio/stardust"
  version "0.3.2"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.3.2/stardust-darwin-arm64.tar.gz"
      sha256 "81f3b08165822f06d42184e3d1d7b7b7a17b1f1128e28d716f037c5b388bc6d8"
    end
    on_intel do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.3.2/stardust-darwin-x64.tar.gz"
      sha256 "1bdf99e004431f0bbfbcfa698872a2955f01bd8a11c0237f6fb0046824678652"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.3.2/stardust-linux-arm64.tar.gz"
      sha256 "7028025dccbdcc7df09f491adc38c97e53bf631a3ba4764a238152cd08fc68d2"
    end
    on_intel do
      url "https://github.com/nexlabstudio/stardust/releases/download/v0.3.2/stardust-linux-x64.tar.gz"
      sha256 "91a0660e637234d85a0271c4dbff41ad295247ace03ca4d7d47bf3175ccf55ca"
    end
  end

  def install
    bin.install "stardust"
  end

  test do
    assert_match "Stardust v0.3.2", shell_output("#{bin}/stardust --version")
  end
end
