class Clawdbar < Formula
  desc "Cute pixel-art menu bar widget showing Claude Code usage"
  homepage "https://github.com/ParkBeomMin/claude-bar"
  url "https://github.com/ParkBeomMin/claude-bar/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "cc52bf3dcad42f3a1c25f1d6ba7bd2f078e2ad8700e727ef0428909edc0caebf"
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

      Note: after `brew upgrade`, re-enable launch-at-login in the popover
      (the app path changes on upgrade, which invalidates the login item).
    EOS
  end

  test do
    assert_predicate prefix/"ClawdBar.app/Contents/MacOS/clawdbar", :exist?
  end
end
