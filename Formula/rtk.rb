# typed: false
# frozen_string_literal: true

# Homebrew formula for rtk - Rust Token Killer (Homeserve mirror)
# To install:
#   brew tap homeservefr/rtk https://github.com/HomeserveFR/rtk.git
#   brew install homeservefr/rtk/rtk
class Rtk < Formula
  desc "High-performance CLI proxy to minimize LLM token consumption"
  homepage "https://github.com/HomeserveFR/rtk"
  version "0.40.0"
  license "MIT"

  on_macos do
    on_intel do
      url "https://github.com/HomeserveFR/rtk/releases/download/v#{version}/rtk-x86_64-apple-darwin.tar.gz"
      sha256 "0c5195f94b82106f53501c765879253ea28945149d11c5e0b22543fe5df77edd"
    end

    on_arm do
      url "https://github.com/HomeserveFR/rtk/releases/download/v#{version}/rtk-aarch64-apple-darwin.tar.gz"
      sha256 "a65655e0ee2a7b3eb5257d34e63b4e7e954dc7b1b11dcdceeed1edd308b2def7"
    end
  end

  on_linux do
    on_intel do
      url "https://github.com/HomeserveFR/rtk/releases/download/v#{version}/rtk-x86_64-unknown-linux-musl.tar.gz"
      sha256 "2eb4db271a8eb4a6441ed66674b4bd6c1c5f956e2537c466ddfc7a0f3d6e30d5"
    end
  end

  def install
    bin.install "rtk"
  end

  test do
    assert_match "rtk #{version}", shell_output("#{bin}/rtk --version")
  end
end
