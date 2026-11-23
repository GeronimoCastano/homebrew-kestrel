class Kestrel < Formula
  desc "Programming language with checked contracts, proofs, and a native backend"
  homepage "https://github.com/GeronimoCastano/kestrel"
  version "0.3.1"
  license "MIT"

  livecheck do
    url :stable
    strategy :github_latest
  end

  on_macos do
    on_arm do
      url "https://github.com/GeronimoCastano/kestrel/releases/download/v0.3.1/kestrel-aarch64-apple-darwin.tar.gz"
      sha256 "853722e4f0480c4eb5d0f0befd715046c1432ed07e3a6ddac02e42d56ef69b65"
    end
    on_intel do
      url "https://github.com/GeronimoCastano/kestrel/releases/download/v0.3.1/kestrel-x86_64-apple-darwin.tar.gz"
      sha256 "d8617f78059c4d64d18c4d9d0dde99810ed99e75f19250f87015ed2c96602638"
    end
  end

  on_linux do
    url "https://github.com/GeronimoCastano/kestrel/releases/download/v0.3.1/kestrel-x86_64-unknown-linux-gnu.tar.gz"
    sha256 "3f4c31ec748c2b193fe140e9239e4df6e246b7e8b7558a16f0bddc21cd9e9594"

    # macOS supplies Clang with the Command Line Tools and LAPACK with Accelerate.
    depends_on "llvm"
    depends_on "openblas"
  end

  # Z3 decides the `smt` steps in proofs.
  depends_on "z3"

  def install
    if OS.linux?
      # Homebrew's Clang and OpenBLAS are not on the default search paths, so the
      # wrapper names them.
      libexec.install "kestrel"
      (bin/"kestrel").write_env_script libexec/"kestrel",
        KESTREL_CC:     Formula["llvm"].opt_bin/"clang",
        KESTREL_LAPACK: Formula["openblas"].opt_lib/shared_library("libopenblas")
    else
      bin.install "kestrel"
    end

    generate_completions_from_executable(bin/"kestrel", "completions", shells: [:bash, :zsh, :fish])
  end

  test do
    assert_match "kestrel #{version}", shell_output("#{bin}/kestrel --version")
    (testpath/"hello.kes").write 'print("Hello, Kestrel!")'
    assert_equal "Hello, Kestrel!", shell_output("#{bin}/kestrel run #{testpath}/hello.kes").strip
    (testpath/"batteries.kes").write <<~KES
      import std.linalg
      let A := Tensor([2.0, 1.0, 1.0, 3.0], shape = (2, 2))
      print((A @ linalg.inverse(A) - Tensor([1.0, 0.0, 0.0, 1.0], shape = (2, 2))).norm() < 1e-12)
      theorem positive(n : Int) : n > 0 requires h : n >= 1 {smt}
    KES
    assert_equal "true", shell_output("#{bin}/kestrel run #{testpath}/batteries.kes").strip
  end
end
