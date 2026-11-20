class Kestrel < Formula
  desc "Programming language with checked contracts, proofs, and a native backend"
  homepage "https://github.com/GeronimoCastano/kestrel"
  url "https://github.com/GeronimoCastano/kestrel/archive/refs/tags/v0.1.1.tar.gz"
  sha256 "817edd07d41e11e5033b33c83644d1a543f74eb46b673a5079442a51d4fa8fac"
  license "MIT"
  head "https://github.com/GeronimoCastano/kestrel.git", branch: "main"

  livecheck do
    url :stable
    strategy :github_latest
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  def caveats
    <<~EOS
      `kestrel build` and `kestrel run` need Clang. macOS supplies it with the
      Xcode Command Line Tools:

        xcode-select --install
    EOS
  end

  test do
    assert_match "kestrel #{version}", shell_output("#{bin}/kestrel --version")
    (testpath/"hello.kes").write 'print("Hello, Kestrel!")'
    assert_equal "Hello, Kestrel!", shell_output("#{bin}/kestrel run #{testpath}/hello.kes").strip
  end
end
