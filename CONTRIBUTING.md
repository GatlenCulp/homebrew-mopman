# homebrew-vivaria (contributing)

## 00 TOC

- [homebrew-vivaria (contributing)](#homebrew-vivaria-contributing)
  - [00 TOC](#00-toc)
  - [01 The Source](#01-the-source)
  - [02 The Python Dependencies](#02-the-python-dependencies)
  - [03 Copying Everything Over](#03-copying-everything-over)
  - [04 Debugging](#04-debugging)
  - [06 Random Useful Notes](#06-random-useful-notes)
  - [07 Roadmap](#07-roadmap)
  - [08 Contact the Maintainer](#08-contact-the-maintainer)

## 01 The Source

Brew downloads your source and places it in a temporary build directory. This source is commonly pulled in two different ways.

**tar.gz compressed file**

GitHub generates these with each release/prerelease when you add a new tag. Add the url and the checksum to the brew install. To get the checksum you can run a command like the one below.

```bash
curl -L https://github.com/GatlenCulp/vivaria/archive/refs/tags/v0.1.0.tar.gz | shasum -a 256
```
$\rightarrow$ `2ad566ffd8836670dd5a5639b8f30efbbedf0fb76d250315aae9b38085188042`

**GitHub Repository Clone**
To use this, you simply link to the repository, include a tag, and the revision which you can get with running something like this in the vivaria repository locally:
```bash
git rev-parse v0.1.3
```
$\rightarrow$ `d67cc7894064e45f3459104c0f004fc1bd86612b`

**Why git is used instead**
Vivaria requires the `.git` repository files and GitHub does not include those in their `tar.gz` packages, so we have opted to use the git clone method.

```ruby
class Vivaria < Formula
  desc "Task environment setup tool for AI research"
  homepage "https://vivaria.metr.org/"
  # ...
  # Stable release
  url "https://github.com/GatlenCulp/vivaria.git",
      # Use git to include .git which is needed for the CLI
      using:    :git,
      tag:      "v0.1.3",
      revision: "d67cc7894064e45f3459104c0f004fc1bd86612b"
end
```

## 02 The Python Dependencies

Brew has a light policy to not allow you to use the internet during the installation process, which is a problem for pip installing the packages necessary for Vivaria. Luckily, Brew has a decent interface for managing Python packages and setting up a virtual environment. More information can be found here: [https://docs.brew.sh/Python-for-Formula-Authors](https://docs.brew.sh/Python-for-Formula-Authors).

Python packages are added as [resources](https://rubydoc.brew.sh/Formula#resource-class_method) within the formula, linking directly to their `.tar.gz` package. Luckily, you don't need to track down all the needed packages by hand and can instead add them directly to your formula from the [`mopman/pyproject.toml`](https://github.com/GatlenCulp/vivaria/tree/main/cli) with `brew update-python-resources mopman`.

```ruby
class Vivaria < Formula
  include Language::Python::Virtualenv
  desc "Task environment setup tool for AI research"
  homepage "https://vivaria.metr.org/"
  # ...
  resource "idna" do
    url "https://files.pythonhosted.org/packages/00/6f/93e724eafe34e860d15d37a4f72a1511dd37c43a76a8671b22a15029d545/idna-3.9.tar.gz"
    sha256 "e5c5dafde284f26e9e0f28f6ea2d6400abd5ca099864a67f576f3981c6476124"
  end

  resource "pydantic" do
    url "https://files.pythonhosted.org/packages/14/15/3d989541b9c8128b96d532cfd2dd10131ddcc75a807330c00feb3d42a5bd/pydantic-2.9.1.tar.gz"
    sha256 "1363c7d975c7036df0db2b4a61f2e062fbc0aa5ab5f2772e0ffc7191a4f4bce2"
  end

  resource "pydantic-core" do
    url "https://files.pythonhosted.org/packages/5c/cc/07bec3fb337ff80eacd6028745bd858b9642f61ee58cfdbfb64451c1def0/pydantic_core-2.23.3.tar.gz"
    sha256 "3cb0f65d8b4121c1b015c60104a685feb929a29d7cf204387c7f2688c7974690"
  end
  # ...
end
```

These packages are then installed by brew into the the final install path (ex: `/opt/homebrew/Cellar/vivaria/0.1.0`) and placed in the `libexec/venv` directory (`libexec` is for dependent executables not invoked directly by the installing user). The viv cli is also installed as a package into the virtual environment.

```ruby
class Vivaria < Formula
  include Language::Python::Virtualenv
  desc "Task environment setup tool for AI research"
  homepage "https://vivaria.metr.org/"
    # ...
  def install
      # Install dependencies and the CLI in a virtualenv
    venv = virtualenv_create(libexec/"venv", "python3.11")
    venv.pip_install resources
    venv.pip_install buildpath/"cli"
      # ...
  end
end
```

In making the virtual environment and building the package which will automatically make an executable called `viv` in the virtual environment's bin. We then copy this executable to `final_install_path/bin` which contain executables which are symlinked to Brew's bin (ex: `/opt/homebrew/bin/`) which is on the user's path, making the `viv` script available to the user anywhere.

## 03 Copying Everything Over

At this point, the viv-cli is essentially installed, but since the web ui relies on typescript and docker files, we need to maintain a large chunk of the original project files in `final_install_path`. In the rest of the script, we install all the docs into the folder brew expects to find them (`final_install_path/share/doc`), delete everything we no longer need, and copy the rest over from the build path to the final install path under `vivaria`.

```ruby
class Vivaria < Formula
  desc "Task environment setup tool for AI research"
  homepage "https://vivaria.metr.org/"
  # ...
  def install
    # ...
    # Install documentation
    doc.install Dir["docs/*"]
    doc.install "README.md"
    doc.install "LICENSE"
    doc.install "CONTRIBUTING.md"

    # Clean up unnecessary directories
    rm_rf ".devcontainer"
    rm_rf ".github"
    rm_rf ".vscode"
    rm_rf "cli"
    rm_rf "docs"
    rm_rf "ignore"

    # Copy remaining files to vivaria directory
    src_dir = prefix/"vivaria"
    src_dir.mkpath
    dot_files = [".", ".."]
    src_dir.install Dir["*", ".*"].reject { |f| dot_files.include?(File.basename(f)) }
    # ...
  end
end
```

## 04 Debugging

To install the formula with debug mode and receive more verbose errors during developing the formula, you can run:
```bash
brew install --formula --debug --verbose ./Formula/mopman.rb
```

Similarly for uninstalling:
```bash
brew uninstall --debug --verbose mopman
```

I was attempting to set up a Ruby debugger w/ intellisense in VSCode but it wasn't working:
```bash
gem install ruby-lsp
```

```bash
gem install debug
```

There are also a variety of tools to conform to both the Homebrew official style, Ruby's styling, and more. Here are a few of these commands:

01
```bash
brew style --fix gatlenculp/mopman
```

02
```bash
brew audit --eval-all --formula --strict --online vivaria

gatlenculp/vivaria/vivaria
  * line 8, col 3: `url` (line 8) should be put before `license` (line 5)
  * line 19, col 3: dependency "python@3.11" (line 19) should be put before dependency "rust" (line 21)
  * line 107, col 1: Trailing whitespace detected.
  * line 127, col 5: Avoid rescuing the `Exception` class. Perhaps you meant to rescue `StandardError`?
  * line 130, col 8: Trailing whitespace detected.
  * line 131, col 1: Trailing whitespace detected.
  * line 133, col 5: Use `rm` or `rm_r` instead of `rm_rf`, `rm_f`, or `rmtree`.
  * line 134, col 5: Use `rm` or `rm_r` instead of `rm_rf`, `rm_f`, or `rmtree`.
  * line 135, col 5: Use `rm` or `rm_r` instead of `rm_rf`, `rm_f`, or `rmtree`.
  * line 136, col 5: Use `rm` or `rm_r` instead of `rm_rf`, `rm_f`, or `rmtree`.
  * line 137, col 5: Use `rm` or `rm_r` instead of `rm_rf`, `rm_f`, or `rmtree`.
  * line 138, col 5: Use `rm` or `rm_r` instead of `rm_rf`, `rm_f`, or `rmtree`.
  * line 139, col 1: Trailing whitespace detected.
  * line 143, col 49: Avoid immutable Array literals in loops. It is better to extract it into a local variable or a constant.
  * line 143, col 50: Prefer double-quoted strings unless you need single quotes to avoid extra backslashes for escaping.
  * line 143, col 55: Prefer double-quoted strings unless you need single quotes to avoid extra backslashes for escaping.
  * line 148, col 1: Trailing whitespace detected.
  * line 167, col 1: Extra blank line detected.
  * line 169, col 3: Expected 1 empty line between method definitions; found 2.
  * line 190, col 1: Trailing whitespace detected.
  * line 195, col 1: Trailing whitespace detected.
  * line 198, col 1: Trailing whitespace detected.
Error: 22 problems in 1 formula detected.
```

03
```bash
brew test-bot --only-cleanup-before
```

04
```bash
brew test-bot --only-setup
```

05
```bash
brew test-bot --only-tap-syntax
```

06
```bash
brew test-bot --only-formulae
```

## 06 Random Useful Notes

`echo $(brew --prefix vivaria)` can be used to get the [opt-prefix](https://docs.brew.sh/Manpage) for Vivaria. This returns a static path to a symlinked folder pointing to the most recent version of vivaria.

The [Homebrew Ruby API documentation](https://rubydoc.brew.sh/Formula#homepage%3D-class_method) is very helpful as well as the the [higher-level Homebrew documentation](https://docs.brew.sh/).

A good man-page has yet to be written and may not ever be written but I decided to draft a simple incomplete one with a warning. This may possibly lead to more confusion, but I've decided to do it anyways for the experience and to see if it may be helpful to continue developing.

If you need to make any edits to the viv cli without editing the repo and reinstalling entirely, I recommend cloning the Vivaria repo, setting up a venv with required packages `mkdir ~/.venvs && python3 -m venv ~/.venvs/viv && source ~/.venvs/viv/bin/activate` then running `pip install -e cli` in the Vivaria project root. If you run `which viv` you should see you are not using the one in homebrew and are instead using the `viv` from your repo. Any updates to the cli will be live as you make them and commands should work normally.

To upgrade to the head (latest github main commit) as opposed to the stable tag release, use:
```bash
brew upgrade --fetch-HEAD vivaria
```

To install the latest head, use:
```bash
brew install --head vivaria
```

Caveats are info displayed after installation.

## 07 Roadmap


## 08 Contact the Maintainer

Gatlen Culp, METR Contractor
Email: gatlen.culp@metr.org
Portfolio: [gatlen.notion.site](https://gatlen.notion.site)
