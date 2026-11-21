class Kestrel < Formula
  desc "Programming language with checked contracts, proofs, and a native backend"
  homepage "https://github.com/GeronimoCastano/kestrel"
  version "0.1.3"
  license "MIT"

  livecheck do
    url :stable
    strategy :github_latest
  end

  on_macos do
    on_arm do
      url "https://github.com/GeronimoCastano/kestrel/releases/download/v0.1.3/kestrel-aarch64-apple-darwin.tar.gz"
      sha256 "227953ed13a7e215dc87331bb07bf0d61971d9f8a5833b6614221813df24a314"
    end
    on_intel do
      url "https://github.com/GeronimoCastano/kestrel/releases/download/v0.1.3/kestrel-x86_64-apple-darwin.tar.gz"
      sha256 "168ae3cac20d9143e0e1237aeb0f113c5d5f623266e81aaf0defc9667a77b2d5"
    end
  end

  on_linux do
    url "https://github.com/GeronimoCastano/kestrel/releases/download/v0.1.3/kestrel-x86_64-unknown-linux-gnu.tar.gz"
    sha256 "6fd96e8ecfdcab8c7b0ac3d568e0a55bc19369320db4b969022acd17551a505a"

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
