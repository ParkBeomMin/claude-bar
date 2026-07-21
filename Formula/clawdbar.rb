class Clawdbar < Formula
  desc "Cute pixel-art menu bar widget showing Claude Code usage"
  homepage "https://github.com/ParkBeomMin/clawdbar"
  url "https://github.com/ParkBeomMin/clawdbar/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000" # v0.1.0 릴리즈 후 실제 값으로 교체
  license "MIT"

  depends_on xcode: ["15.0", :build]
  depends_on macos: :ventura

  def install
    system "make", "bundle"
    prefix.install "ClawdBar.app"
    (bin/"clawdbar").write <<~EOS
      #!/bin/bash
      exec "#{prefix}/ClawdBar.app/Contents/MacOS/clawdbar" "$@"
    EOS
  end

  def caveats
    <<~EOS
      Start ClawdBar with:
        clawdbar &
      Then enable "로그인 시 자동 시작" in the popover to launch at login.
    EOS
  end

  test do
    assert_predicate prefix/"ClawdBar.app/Contents/MacOS/clawdbar", :exist?
  end
end
