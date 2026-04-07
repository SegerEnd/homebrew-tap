class Gbdk2020 < Formula
  desc "Cross-platform development kit for Game Boy, NES, SMS, and Game Gear"
  homepage "https://github.com/gbdk-2020/gbdk-2020"
  version "4.4.0"
  license "GPL-2.0-only"

  livecheck do
    url :homepage
    strategy :github_latest
  end

  on_macos do
    on_arm do
      url "https://github.com/gbdk-2020/gbdk-2020/releases/download/4.4.0/gbdk-macos-arm64.tar.gz"
      sha256 "0c67b5cafff8a617729b77f9383ea41eb864b34f52c2391686c94427936db2df"
    end
    on_intel do
      url "https://github.com/gbdk-2020/gbdk-2020/releases/download/4.4.0/gbdk-macos.tar.gz"
      sha256 "ba7ffc51c12fd1625fc99850691e0f5312cb6169691d39823c67972e685db9bc"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/gbdk-2020/gbdk-2020/releases/download/4.4.0/gbdk-linux-arm64.tar.gz"
      sha256 "4b1c2546ecdee56d622c0c48b843bd7efc2a14fc5a1ac61837c0467006b10fe2"
    end
    on_intel do
      url "https://github.com/gbdk-2020/gbdk-2020/releases/download/4.4.0/gbdk-linux64.tar.gz"
      sha256 "8a292e767610ccfa73c2c14d73e7900075b425f68329f1a8eb7697015915edad"
    end
  end

  def install
    libexec.install Dir["*"]

    Dir["#{libexec}/bin/*"].each do |tool|
      bin.install_symlink tool
    end

    # Patch template Makefiles to use the Homebrew install path.
    # Skip Makefiles without a `GBDK = …` line (some upstream examples
    # have a top-level Makefile that doesn't declare it).
    Dir["#{libexec}/examples/**/Makefile"].each do |mf|
      next unless File.read(mf).match?(/^\s*GBDK\s*=/)

      inreplace mf, /^(\s*GBDK\s*=\s*).*$/, "\\1#{opt_libexec}/"
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

    cp_r "#{opt_libexec}/examples/gb/template_minimal/.", testpath
    system "make"
    assert_predicate Dir["#{testpath}/*.gb"].first, :present?, "no .gb ROM produced"
  end
end
