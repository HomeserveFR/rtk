# typed: false
# frozen_string_literal: true

# Homebrew formula for rtk - Rust Token Killer (Homeserve mirror)
# To install:
#   brew tap homeservefr/rtk https://github.com/HomeserveFR/rtk.git
#   brew install homeservefr/rtk/rtk
class Rtk < Formula
  desc "High-performance CLI proxy to minimize LLM token consumption"
  homepage "https://github.com/HomeserveFR/rtk"
  version "1.0.0"
  license "Apache 2.0"

  on_macos do
    on_intel do
      url "https://github.com/HomeserveFR/rtk/releases/download/v#{version}/rtk-x86_64-apple-darwin.tar.gz"
      sha256 "98b2c6e7e43c24d7bcf9b8624177f49fc25e0a0252e42f4c9a60ea328c60da18"
    end

    on_arm do
      url "https://github.com/HomeserveFR/rtk/releases/download/v#{version}/rtk-aarch64-apple-darwin.tar.gz"
      sha256 "31a092b020da84d1935dc70569e6ad46b0a0e9568947e9aa52c4666b9c2e04f0"
    end
  end

  on_linux do
    on_intel do
      url "https://github.com/HomeserveFR/rtk/releases/download/v#{version}/rtk-x86_64-unknown-linux-musl.tar.gz"
      sha256 "cfbf25c2949bcaff7d8979f1a300fed4199ffeacb3304fa39eb025e40a21f958"
    end
  end

  def install
    bin.install "rtk"
  end

  test do
    assert_match "rtk #{version}", shell_output("#{bin}/rtk --version")
  end
end
