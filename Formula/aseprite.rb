class Aseprite < Formula
  desc "Animated sprite editor and pixel art tool"
  homepage "https://www.aseprite.org/"
  url "https://github.com/aseprite/aseprite/releases/download/v1.3.17.1/Aseprite-v1.3.17.1-Source.zip"
  sha256 "e89871e346c49f2ac6b93c847fc0f9e813316b64bb7ba8aa8250a171e3790f94"
  # Aseprite ships under a custom EULA (not an OSI license).
  # Compiling for personal use is permitted; redistributing the binary is not.
  license :cannot_represent

  livecheck do
    url :stable
    strategy :github_latest
  end

  depends_on "cmake" => :build
  depends_on "ninja" => :build
  depends_on xcode: :build
  depends_on :macos

  # Aseprite pins itself to a specific Google Skia commit. Bumping Aseprite
  # often requires bumping this too — check the release notes / INSTALL.md.
  resource "skia" do
    on_macos do
      on_arm do
        url "https://github.com/aseprite/skia/releases/download/m124-08a5439a6b/Skia-macOS-Release-arm64.zip"
        sha256 "22663000967fc2c3f1a78190082228474955de02ffd13a352b39a48b204dac9a"
      end
      on_intel do
        url "https://github.com/aseprite/skia/releases/download/m124-08a5439a6b/Skia-macOS-Release-x64.zip"
        sha256 "c11c5fbfa3f8cdefa2255d37cdd1eca823d195ff61929f457a4714f1b6db500a"
      end
    end
  end

  def install
    skia_dir = buildpath/"skia"
    resource("skia").stage skia_dir

    arch = Hardware::CPU.arm? ? "arm64" : "x64"
    skia_lib_dir = skia_dir/"out/Release-#{arch}"

    args = %W[
      -G Ninja
      -DCMAKE_BUILD_TYPE=RelWithDebInfo
      -DCMAKE_OSX_ARCHITECTURES=#{Hardware::CPU.arm? ? "arm64" : "x86_64"}
      -DCMAKE_OSX_DEPLOYMENT_TARGET=11.0
      -DLAF_BACKEND=skia
      -DSKIA_DIR=#{skia_dir}
      -DSKIA_LIBRARY_DIR=#{skia_lib_dir}
      -DSKIA_LIBRARY=#{skia_lib_dir}/libskia.a
      -DENABLE_UPDATER=OFF
      -DENABLE_NEWS=OFF
    ]
    args << "-DPNG_ARM_NEON=on" if Hardware::CPU.arm?

    mkdir "build" do
      system "cmake", *args, ".."
      system "ninja", "aseprite"
    end

    # build/bin/ contains the aseprite binary plus its runtime data/
    # (palettes, extensions, themes). They must stay together — Aseprite
    # locates data/ relative to the binary.
    libexec.install Dir["build/bin/*"]

    (bin/"aseprite").write <<~EOS
      #!/bin/bash
      exec "#{libexec}/aseprite" "$@"
    EOS
    (bin/"aseprite").chmod 0755
  end

  def caveats
    <<~EOS
      Aseprite is paid software (https://www.aseprite.org/). Building from
      source is permitted by the EULA for personal use. If you use it in
      your work, please buy a license to support the project.

      Launch with:
        aseprite [path-to-image.png|path-to.aseprite]

      First build of this formula takes longer (mostly Skia-bound, C++ compilation).
    EOS
  end

  test do
    assert_predicate bin/"aseprite", :executable?
    assert_match version.to_s, shell_output("#{bin}/aseprite --version 2>&1")
  end
end
