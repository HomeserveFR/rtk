# typed: false
# frozen_string_literal: true

# Homebrew formula for rtk - Rust Token Killer (Homeserve mirror)
# To install:
#   brew tap homeservefr/rtk https://github.com/HomeserveFR/rtk.git
#   brew install homeservefr/rtk/rtk
class Rtk < Formula
  desc "High-performance CLI proxy to minimize LLM token consumption"
  homepage "https://github.com/HomeserveFR/rtk"
  version "1.1.0"
  license all_of: ["Apache-2.0", "BUSL-1.1"]

  on_macos do
    on_intel do
      url "https://github.com/HomeserveFR/rtk/releases/download/v#{version}/rtk-x86_64-apple-darwin.tar.gz"
      sha256 "4fc56247bf4174ac598d828cae9385418dca167ffab0c941c688f381ae62bec2"
    end

    on_arm do
      url "https://github.com/HomeserveFR/rtk/releases/download/v#{version}/rtk-aarch64-apple-darwin.tar.gz"
      sha256 "74ad4f769843d6ab75419c9f670998c50ae75e5eeae4c837f86081fe62168440"
    end
  end

  on_linux do
    on_intel do
      url "https://github.com/HomeserveFR/rtk/releases/download/v#{version}/rtk-x86_64-unknown-linux-musl.tar.gz"
      sha256 "9c2fe46e1dca7b788e6a6bbe1e7096091ebcabe74239d219a3304400e7005858"
    end
  end

  def install
    bin.install "rtk"
  end

  test do
    assert_match "rtk #{version}", shell_output("#{bin}/rtk --version")
  end
end
