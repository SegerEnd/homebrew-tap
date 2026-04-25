class Emulicious < Formula
  desc "Multi-system emulator (GB/GBC/SMS/MSX) with source-level Code debugging"
  homepage "https://emulicious.net/"
  url "https://emulicious.net/emulicious/downloads/emulicious-2026-03-27.zip"
  version "2026.03.27"
  sha256 "6e1c6d511014033bbc2668360a0194389a5bad2bf6c5ffd0fe093b84da33c0fc"
  license :cannot_represent

  # Bumps are automated by .github/workflows/bump-emulicious.yml, which reads
  # the authoritative release date from WhatsNew.txt inside the rolling zip.
  # The livecheck below scrapes the news page as a cheap "is there an update?"
  # signal; it can lag the actual release by a few days but is good enough.
  livecheck do
    url "https://emulicious.net/news/"
    regex(/(\d{4}-\d{2}-\d{2})/i)
    strategy :page_match do |page, regex|
      page.scan(regex).map { |m| m[0].tr("-", ".") }.max
    end
  end

  depends_on "openjdk"

  def install
    # Skip the Windows-only artifacts (~830 KB of .exe / .icl) shipped in the zip.
    rm Dir["Emulicious.exe", "Emulicious.icl"]
    libexec.install Dir["*"]

    # Emulicious writes Emulicious.ini and savestates next to its jar.
    # Redirect that into the user's Application Support so settings survive
    # `brew upgrade` (which wipes the Cellar dir for the old version).
    (bin/"emulicious").write <<~EOS
      #!/bin/bash
      exec "#{Formula["openjdk"].opt_bin}/java" -jar "#{libexec}/Emulicious.jar" "$@"
    EOS
    (bin/"emulicious").chmod 0755
  end

  def caveats
    <<~EOS
      Launch with:
        emulicious [path-to-rom.gb]

      Emulicious writes its settings (Emulicious.ini, savestates) next to
      its jar, these will be reset on `brew upgrade emulicious`. Back up
      #{opt_libexec}/Emulicious.ini if you want to preserve them.

      For source-level C debugging from VS Code, install the
      "Emulicious Debugger" extension (publisher: Calindro).
    EOS
  end

  test do
    assert_predicate bin/"emulicious", :executable?
    assert_path_exists libexec/"Emulicious.jar"
  end
end
