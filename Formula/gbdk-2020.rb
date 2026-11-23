class Gbdk2020 < Formula
  desc "Cross-platform development kit for Game Boy, NES, SMS, and Game Gear"
  homepage "https://github.com/gbdk-2020/gbdk-2020"
  license "GPL-2.0-only"

  livecheck do
    url :stable
    strategy :github_latest
  end

  on_macos do
    on_arm do
      url "https://github.com/gbdk-2020/gbdk-2020/releases/download/4.6.0/gbdk-macos-arm64.tar.gz"
      sha256 "36bf2b005d5a87c7c343e0ddafb42f53578bf22e52a78f17c4aa74b80e71bc8a"
    end
    on_intel do
      url "https://github.com/gbdk-2020/gbdk-2020/releases/download/4.6.0/gbdk-macos.tar.gz"
      sha256 "490748e5f100ae2421aef38196ac93c76c2af86efc81edf817bc4d0af725ad44"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/gbdk-2020/gbdk-2020/releases/download/4.6.0/gbdk-linux-arm64.tar.gz"
      sha256 "003bdb93b4a46702ec04cb9758be5032431deab024dff5637171183a7cea6f5b"
    end
    on_intel do
      url "https://github.com/gbdk-2020/gbdk-2020/releases/download/4.6.0/gbdk-linux64.tar.gz"
      sha256 "c033dac026b99c080f07c2a659eb25976f65ca114cb15d1570bbb23c99c27e35"
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
