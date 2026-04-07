class Gbdk2020 < Formula
  desc "Cross-platform development kit for Game Boy, NES, SMS, and Game Gear"
  homepage "https://github.com/gbdk-2020/gbdk-2020"
  license "GPL-2.0-only"

  livecheck do
    url :homepage
    strategy :github_latest
  end

  if OS.mac?
    if Hardware::CPU.arm?
      url "https://github.com/gbdk-2020/gbdk-2020/releases/download/4.5.0/gbdk-macos-arm64.tar.gz"
      sha256 "289ee60e46c5a2785a21e35533f84a5131ed4a063b21b0dbdedc9a10af15bf78"
    else
      url "https://github.com/gbdk-2020/gbdk-2020/releases/download/4.5.0/gbdk-macos.tar.gz"
      sha256 "1aa549d12032d8f6509d11923bb28b1a453098f42597feb378e9a42541f8fd89"
    end
  elsif OS.linux?
    if Hardware::CPU.arm?
      url "https://github.com/gbdk-2020/gbdk-2020/releases/download/4.5.0/gbdk-linux-arm64.tar.gz"
      sha256 "31eb2235f0fdb60163d0b1e9574a022098d6069cd56606a1daca4478a46e0439"
    else
      url "https://github.com/gbdk-2020/gbdk-2020/releases/download/4.5.0/gbdk-linux64.tar.gz"
      sha256 "d7857a5f6d135ee4c249043ca26aad9f2ec8ab5d4106d97720d404114f42605c"
    end
  end

  def install
    libexec.install Dir["*"]

    Dir["#{libexec}/bin/*"].each do |tool|
      bin.install_symlink tool
    end

    # Patch template Makefiles to use the Homebrew install path
    Dir["#{libexec}/examples/**/Makefile"].each do |mf|
      inreplace mf, /^(\s*GBDK\s*=\s*).*$/, "\\1#{opt_libexec}/"
    rescue Utils::InreplaceError
      next
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
