class Kestrel < Formula
  desc "Programming language with checked contracts, proofs, and a native backend"
  homepage "https://github.com/GeronimoCastano/kestrel"
  version "0.3.0"
  license "MIT"

  livecheck do
    url :stable
    strategy :github_latest
  end

  on_macos do
    on_arm do
      url "https://github.com/GeronimoCastano/kestrel/releases/download/v0.3.0/kestrel-aarch64-apple-darwin.tar.gz"
      sha256 "76b18d067969009f946ca35d49ea72ef0695e2a34952a145026f39ebc3ff6e45"
    end
    on_intel do
      url "https://github.com/GeronimoCastano/kestrel/releases/download/v0.3.0/kestrel-x86_64-apple-darwin.tar.gz"
      sha256 "447ac3038b130acb0cd9f8627f1a050f43083b7cb979f5633ce452075e568181"
    end
  end

  on_linux do
    url "https://github.com/GeronimoCastano/kestrel/releases/download/v0.3.0/kestrel-x86_64-unknown-linux-gnu.tar.gz"
    sha256 "e064374998d5d98c54479571fbfffd3346e0be6b81287c15893c3d9559693db5"

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
