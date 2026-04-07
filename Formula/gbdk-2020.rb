class Gbdk2020 < Formula
  desc "Cross-platform development kit for Game Boy, NES, SMS, and Game Gear"
  homepage "https://github.com/gbdk-2020/gbdk-2020"
  version "4.5.0"
  license "GPL-2.0-only"

  livecheck do
    url :homepage
    strategy :github_latest
  end

  on_macos do
    url "https://github.com/gbdk-2020/gbdk-2020/releases/download/#{version}/gbdk-#{version}-macos.tar.gz"
    sha256 "REPLACE_MACOS_SHA256"
  end

  on_linux do
    url "https://github.com/gbdk-2020/gbdk-2020/releases/download/#{version}/gbdk-#{version}-linux64.tar.gz"
    sha256 "REPLACE_LINUX_SHA256"
  end

  def install
    libexec.install Dir["*"]

    Dir["#{libexec}/bin/*"].each do |tool|
      bin.install_symlink tool
    end

    # Patch template Makefiles to use the Homebrew install path
    Dir["#{libexec}/examples/**/Makefile"].each do |mf|
      inreplace mf, /^(\s*GBDK\s*=\s*).*$/, "\\1#{opt_libexec}/" rescue nil
    end
  end

  def caveats
    <<~EOS
      Quick start:
        cp -r #{opt_libexec}/examples/gb/template_minimal ./my-game
        cd my-game && make
    EOS
  end

  test do
    assert_match "lcc", shell_output("#{bin}/lcc 2>&1", 1)
  end
end
