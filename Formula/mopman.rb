require "English"
class Vivaria < Formula
  include Language::Python::Virtualenv
  desc "Task environment setup tool for AI research"
  homepage "https://vivaria.metr.org/"
  # Stable release
  url "https://github.com/GatlenCulp/vivaria.git",
    using:    :git,
    tag:      "v0.2.0",
    revision: "f92973a018948a93f15a8c869c4291cddb56faf6"
  license "MIT"
  # Development release
  head "https://github.com/GatlenCulp/vivaria.git",
    branch: "main"

  # Automatically check for new versions
  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  # docker compose is required for running task environments, but not included in deps.
  # Check CONTRIBUTING.md for this reasoning.
  depends_on "python@3.11" => :build
  depends_on "rust" => :build # Needed for pydantic

  # TODO: Add bottle block for pre-built binaries
  # bottle do
  #   ...
  # end

  # Define python dependencies to be installed into the virtualenv

  def install
    # Install documentation
    doc.install Dir["docs/*"]
    doc.install "README.md"
    doc.install "LICENSE"
    doc.install "CONTRIBUTING.md"
    # Install dependencies and the CLI in a virtualenv
    venv = virtualenv_create(libexec/"venv", "python3.11")
    venv.pip_install resources
    venv.pip_install buildpath/"cli"
    # bin.install libexec / "venv/bin/viv"
    # Clean up unnecessary directories
    rm_r ".devcontainer"
    rm_r ".github"
    rm_r ".vscode"
    rm_r "cli"
    rm_r "docs"
    rm_r "ignore"
    # Copy remaining files to vivaria directory
    src_dir = prefix/"mopman"
    src_dir.mkpath
    dot_files = [".", ".."]
    src_dir.install Dir["*", ".*"].reject { |f| dot_files.include?(File.basename(f)) }
    # Create etc directory for configuration files (none yet)
    # (etc/"vivaria").mkpath
  end

  def style_command(text)
    "\e[31m\e[40m#{text}\e[0m"
  end

  def style_shortcut(text)
    "\e[94m#{text}\e[0m"
  end

  def viv_setup
    # NOTE: Brew does not have permissions to edit or remove files outside of the Homebrew prefix
    # This function does not work, but could be fixed if config.json is moved to the Homebrew prefix
    config_file_path = File.expand_path("~/.config/viv-cli/config.json")
    brew_prefix = HOMEBREW_PREFIX.to_s

    loop do
      config_exists = File.exist?(config_file_path)

      if config_exists
        ohai "⚙️ A viv-cli configuration file already exists at #{config_file_path}."
        ohai "Brew does not have permissions to edit or remove files outside of #{brew_prefix}."
        ohai "Please delete or rename this file manually. You can use one of the following commands:"
        puts "  To delete: #{style_command("rm #{config_file_path}")}"
        puts "  To rename: #{style_command("mv #{config_file_path} #{config_file_path}.backup")}"
        ohai "Once you have done so, press Enter to continue or Ctrl+C to abort the post-install process."

        $stdin.gets # Wait for user input

        if File.exist?(config_file_path)
          opoo "The configuration file still exists. Please remove or rename it before continuing."
        else
          ohai "No existing viv-cli configuration found. Continuing with installation"
          break # Exit the loop if the file no longer exists
        end
      else
        ohai "No existing viv-cli configuration found."
        ohai "Would you like to run 'viv setup' to create a new configuration? [y/N]"
        response = $stdin.gets.chomp.downcase
        break if response == "y"

        ohai "Exiting viv setup. You can run it manually later with 'viv setup'."
        return
      end
    end

    config_dir = File.dirname(config_file_path)
    mkdir_p(config_dir) unless File.directory?(config_dir)
    system "sudo", "chown", "-R", ENV["USER"], config_dir
    system "sudo", "chmod", "755", config_dir

    api_key = prompt_for_api_key

    setup_command = "viv setup --openai-api-key #{api_key}"
    ohai "Running: #{style_command(setup_command)}"

    output = `#{setup_command} 2>&1`
    status = $CHILD_STATUS.success?

    if status
      ohai "viv setup completed successfully."
    else
      opoo "viv setup encountered an error. Output:"
      puts output
    end
  end

  def build_docker_images
    # Prompt user to build Docker images
    ohai "🐳 Would you like to build the required Vivaria Docker images now? (This may take 3-8 minutes) [y/N]"
    response = $stdin.gets.chomp.downcase

    if response == "y"
      ohai "Opening Docker..."
      case RUBY_PLATFORM
      when /darwin/
        system "open", "-a", "Docker"
      when /linux/
        system "systemctl", "--user", "start", "docker-desktop"
      when /mingw|mswin/
        system "start", "Docker Desktop"
      else
        opoo "Unsupported platform for automatic Docker startup. Please ensure Docker is running manually."
      end

      # Wait for Docker to start
      ohai "Waiting for Docker to start..."
      30.times do
        break if system("docker info > /dev/null 2>&1")

        sleep 1
      end

      ohai "Building Docker images..."
      system "viv", "docker", "compose", "build"

      if $CHILD_STATUS.success?
        ohai "Docker images built successfully."
      else
        opoo "Failed to build Docker images. You can try building them later with 'viv docker compose build'."
      end

    else
      ohai "Skipping Docker image build. You can build them later with 'viv docker compose build'."
    end
  end

  def post_install
    # Run 'viv setup' (Note: This does not work due to permissions)
    # viv_setup
    # Build Docker images (Note: This requires viv setup to have run successfully)
    # build_docker_images
  end

  def caveats
    <<~EOS

      🧹 MopMan Packetmaker has been successfully installed.

      🛠️ To complete setup, run
          #{style_command("viv setup")}

      ℹ️ For more information, visit:
           https://www.notion.so/gatlen/MopMan-PacketMaker-a62ed64c69f2440bbde8b0212de773df?pvs=4

    EOS
  end

  # TODO: Check if this works
  test do
    # Check if the command-line tool is installed and runs without error
    system bin/"viv", "version"
    # Check if the documentation files are installed
    assert_predicate doc/"README.md", :exist?
    assert_predicate doc/"LICENSE", :exist?
    assert_predicate doc/"CONTRIBUTING.md", :exist?
    # Check if the Vivaria directory is created
    assert_predicate prefix/"vivaria", :directory?
    # Check if the etc directory is created
    assert_predicate etc/"vivaria", :directory?
  end
end
