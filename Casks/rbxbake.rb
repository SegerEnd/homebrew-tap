cask "rbxbake" do
  version "2026.10.03"
  sha256 "d475e038c81d1a156284c70c16dbf938d812e91d56560c6ccd02a22a9f0322ba"

  url "https://segerend.nl/rbxbake/cli.mjs?v=#{version}"
  name "rbxbake"
  desc "Roblox model to mesh converter, with studs"
  homepage "https://segerend.nl/rbxbake/"

  depends_on formula: "node"

  binary "rbxbake.wrapper.sh", target: "rbxbake"

  preflight_steps do
    write_file "rbxbake.wrapper.sh", <<~EOS, base: :staged_path
      #!/bin/sh
      exec node "$(dirname "$(readlink -f "$0")")/cli.mjs" "$@"
    EOS
  end
end
