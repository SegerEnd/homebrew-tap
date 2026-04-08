class Gbdk2020 < Formula
  desc "Cross-platform development kit for Game Boy, NES, SMS, and Game Gear"
  homepage "https://github.com/gbdk-2020/gbdk-2020"
  version "4.5.0"
  license "GPL-2.0-only"

  livecheck do
    url :stable
    strategy :github_latest
  end

  on_macos do
    on_arm do
      url "https://github.com/gbdk-2020/gbdk-2020/releases/download/4.5.0/gbdk-macos-arm64.tar.gz"
      sha256 "289ee60e46c5a2785a21e35533f84a5131ed4a063b21b0dbdedc9a10af15bf78"
    end
    on_intel do
      url "https://github.com/gbdk-2020/gbdk-2020/releases/download/4.5.0/gbdk-macos.tar.gz"
      sha256 "1aa549d12032d8f6509d11923bb28b1a453098f42597feb378e9a42541f8fd89"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/gbdk-2020/gbdk-2020/releases/download/4.5.0/gbdk-linux-arm64.tar.gz"
      sha256 "31eb2235f0fdb60163d0b1e9574a022098d6069cd56606a1daca4478a46e0439"
    end
    on_intel do
      url "https://github.com/gbdk-2020/gbdk-2020/releases/download/4.5.0/gbdk-linux64.tar.gz"
      sha256 "d7857a5f6d135ee4c249043ca26aad9f2ec8ab5d4106d97720d404114f42605c"
    end
  end

  def install
    libexec.install Dir["*"]

    bin.install_symlink Dir["#{libexec}/bin/*"].select { |f| File.executable?(f) }

    # Patch example Makefiles so `cp -r .../template_minimal my-game && make`
    # works out of the box. Upstream defaults `GBDK_HOME` to `../../../`,
    # which only resolves correctly when building inside the gbdk source tree.
    pattern = %r{^(\s*GBDK_HOME\s*=\s*)\.\./\.\./\.\./?$}
    Dir["#{libexec}/examples/**/Makefile"].each do |mf|
      next unless File.read(mf).match?(pattern)

      inreplace mf, pattern, "\\1#{opt_libexec}"
      unless File.read(mf).match?(/^\s*GBDK_HOME\s*=\s*#{Regexp.escape(opt_libexec)}\s*$/)
        odie "Failed to patch #{mf}"
      end
    end
  end

  def caveats
    <<~EOS
      Quick start:
        cp -r #{opt_libexec}/examples/gb/template_minimal ./my-game
        cd my-game && make

      To use GBDK-2020 with tools that expect environment variables,
      add the following to your shell profile:
        export GBDK=#{opt_libexec}
        export GBDK_HOME=$GBDK
    EOS
  end

  test do
    assert_match "lcc [ option | file ]", shell_output("#{bin}/lcc 2>&1")

    cp_r "#{opt_libexec}/examples/gb/template_minimal/.", testpath
    ENV["GBDK_HOME"] = opt_libexec
    system "make"
    assert_predicate Dir["#{testpath}/*.gb"].first, :present?, "no .gb ROM produced"
  end
end
