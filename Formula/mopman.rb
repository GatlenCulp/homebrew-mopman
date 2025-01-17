require "English"
class Mopman < Formula
  include Language::Python::Virtualenv
  desc "Packet making tool for AIS University Groups (currently tailored for CBAI's AirTable)"
  homepage "https://github.com/GatlenCulp/MopMan_Packetmaker.git"
  version "0.1.0"
  # Stable release
#   url "https://github.com/GatlenCulp/MopMan_Packetmaker",
#     using:    :git
    # tag:      "v0.2.0",
    # revision: "f92973a018948a93f15a8c869c4291cddb56faf6"
  license "MIT"
  # Development release
  head "https://github.com/GatlenCulp/MopMan_Packetmaker.git",
    branch: "main"

  # Automatically check for new versions
  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  resource "airtable" do
    url "https://files.pythonhosted.org/packages/6c/e6/da9c7438fbb4100eb915fca9c431df5c60614a1debf5da899c9d2d7adb68/airtable-0.4.8.tar.gz"
    sha256 "fb667e55da3af1341e0f2946014cc29e7d0613e69f3ee20528051c4075aee75c"
  end

  # docker compose is required for running task environments, but not included in deps.
  # Check CONTRIBUTING.md for this reasoning.
  depends_on "python@3.11" => :build

  # TODO: Add bottle block for pre-built binaries
  # bottle do
  #   ...
  # end

  # Define python dependencies to be installed into the virtualenv

  def install
    # Install documentation
    doc.install "README.md"
    doc.install "LICENSE"
    # Install dependencies and the CLI in a virtualenv
    venv = virtualenv_create(libexec/"venv", "python3.11")
    venv.pip_install resources
    venv.pip_install buildpath/"src"
    # Clean up unnecessary directories
    rm_r ".vscode"
    rm_r "imgs"
    rm_r "ignore"
    # Copy remaining files to mopman directory
    src_dir = prefix/"mopman"
    src_dir.mkpath
    dot_files = [".", ".."]
    src_dir.install Dir["*", ".*"].reject { |f| dot_files.include?(File.basename(f)) }
    # Create etc directory for configuration files (none yet)
    # (etc/"mopman").mkpath
  end

  def caveats
    <<~EOS

      🧹 MopMan Packetmaker has been successfully installed.

      ℹ️ For more information, visit:
           https://www.notion.so/gatlen/MopMan-PacketMaker-a62ed64c69f2440bbde8b0212de773df?pvs=4

    EOS
  end

  # TODO: Check if this works
  test do
    # Check if the command-line tool is installed and runs without error
    system bin/"mopman", "version"
    # Check if the documentation files are installed
    assert_predicate doc/"README.md", :exist?
    assert_predicate doc/"LICENSE", :exist?
    assert_predicate doc/"CONTRIBUTING.md", :exist?
    # Check if the mopman directory is created
    assert_predicate prefix/"mopman", :directory?
    # Check if the etc directory is created
    assert_predicate etc/"mopman", :directory?
  end
end
