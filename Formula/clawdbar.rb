class Clawdbar < Formula
  desc "Cute pixel-art menu bar widget for macOS showing Claude Code usage"
  homepage "https://github.com/ParkBeomMin/clawdbar"
  url "https://github.com/ParkBeomMin/clawdbar/releases/download/v0.1.0/ClawdBar.app.tar.gz"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000" # v0.1.0 릴리즈 후 실제 값으로 교체

  def install
    app = "ClawdBar.app"
    prefix.install app
    bin.write_exec_script "#{prefix}/#{app}/Contents/MacOS/clawdbar"
  end

  def post_install
    system("codesign", "--force", "--sign", "-", "#{prefix}/ClawdBar.app/Contents/MacOS/clawdbar") rescue nil
  end

  test do
    assert_predicate prefix/"ClawdBar.app/Contents/MacOS/clawdbar", :exist?
  end
end
