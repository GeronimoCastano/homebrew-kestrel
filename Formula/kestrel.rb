class Kestrel < Formula
  desc "Programming language with checked contracts, proofs, and a native backend"
  homepage "https://github.com/GeronimoCastano/kestrel"
  version "0.2.0"
  license "MIT"

  livecheck do
    url :stable
    strategy :github_latest
  end

  on_macos do
    on_arm do
      url "https://github.com/GeronimoCastano/kestrel/releases/download/v0.2.0/kestrel-aarch64-apple-darwin.tar.gz"
      sha256 "62989935ac141be7d2cce67454209061a4ea72b156fb8f5d63525b6fa5a3349c"
    end
    on_intel do
      url "https://github.com/GeronimoCastano/kestrel/releases/download/v0.2.0/kestrel-x86_64-apple-darwin.tar.gz"
      sha256 "bd4b6c5d5318f48d55da2e423269fc0adbe19159eb93ca6aace13fafea3fcb64"
    end
  end

  on_linux do
    url "https://github.com/GeronimoCastano/kestrel/releases/download/v0.2.0/kestrel-x86_64-unknown-linux-gnu.tar.gz"
    sha256 "5b39e5e3e7cf9b8c5b8e36cd4ac056e2c30c19a10799bec6be4e5e6294468d10"

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
