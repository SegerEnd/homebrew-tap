cask "rbxbake" do
  version "2026.10.04"
  sha256 "b9093e6e81537a331f05fd37a4c36564ad4ec044e896ffd0796f0aeb12965a06"

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
