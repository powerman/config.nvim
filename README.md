# ~/.config/nvim

## Introduction

This is my Neovim config.

> [!NOTE]
> It was started as a fork of
> [dam9000/kickstart-modular.nvim](https://github.com/dam9000/kickstart-modular.nvim) and I
> highly recommend it if you like to create your own config yourself (like I did). I do not
> support this config on Windows, but it might work - check that kickstart repo for
> Windows-specific install instructions.

## Installation

### Install Neovim

Config.nvim targets _only_ the latest
['stable'](https://github.com/neovim/neovim/releases/tag/stable) Neovim.
If you are experiencing issues, please make sure you have the latest version.

### Install External Dependencies

External Requirements:

- Basic utils: `git`, `make`, `unzip`, C Compiler (`gcc`).
- [ripgrep](https://github.com/BurntSushi/ripgrep#installation).
- Clipboard tool (`xclip`/`xsel` or other depending on platform).
- You might need some extra tool (e.g. `npm`) used by Mason to auto-install formatter/LSP tools.
- A [Nerd Font](https://www.nerdfonts.com/): optional, provides various icons.
  - If you have it set `vim.g.have_nerd_font` in `init.lua` to true.
  - If you chose "Mono" font kind set `vim.g.mono_nerd_font` in `init.lua` to true.

### Install Config

> [!NOTE]
>
> [Backup](#faq) your previous configuration (if any exists)

Neovim's configurations are located under the following paths, depending on your OS:

| OS           | PATH                                      |
| :----------- | :---------------------------------------- |
| Linux, MacOS | `$XDG_CONFIG_HOME/nvim`, `~/.config/nvim` |

#### Recommended Step

[Fork](https://docs.github.com/en/get-started/quickstart/fork-a-repo) this repo
so that you have your own copy that you can modify, then install by cloning the
fork to your machine using one of the commands below, depending on your OS.

> [!NOTE]
> Your fork's URL will be something like this:
> `https://github.com/<your_github_username>/config.nvim.git`

#### Clone config.nvim

> [!NOTE]
> If following the recommended step above (i.e., forking the repo), replace
> `powerman` with `<your_github_username>` in the commands below

<details><summary> Linux and Mac </summary>

```sh
git clone https://github.com/powerman/config.nvim.git "${XDG_CONFIG_HOME:-$HOME/.config}"/nvim
```

</details>

### Post Installation

Start Neovim

```sh
nvim
```

That's it! Lazy will install all the plugins you have. Use `:Lazy` to view
the current plugin status. Hit `q` to close the window.

If you are on another machine, you can do `:Lazy restore`, to update all your plugins to the
version from the lockfile.

### Getting Started

[The Only Video You Need to Get Started with Neovim](https://youtu.be/m8C0Cq9Uv9o)

### FAQ

- What should I do if I already have a pre-existing Neovim configuration?

  - You should back it up and then delete all associated files.

  - This includes your existing init.lua and the Neovim files in `~/.local`
    which can be deleted with `rm -rf ~/.local/share/nvim/`

- Can I keep my existing configuration in parallel?

  - Yes! You can use [NVIM_APPNAME](https://neovim.io/doc/user/starting.html#_nvim_appname)`=nvim-NAME`
    to maintain multiple configurations. For example, you can install the
    configuration in `~/.config/nvim-powerman` and create an alias:

    ```sh
    alias nvim-powerman='NVIM_APPNAME="nvim-powerman" nvim'
    ```

    When you run Neovim using `nvim-powerman` alias it will use the alternative
    config directory and the matching local directory
    `~/.local/share/nvim-powerman`. You can apply this approach to any Neovim
    distribution that you would like to try out.

### Install Recipes

Below you can find OS specific install instructions for Neovim and dependencies.

After installing all the dependencies continue with the [Install Config](#install-config) step.

#### Linux Install

<details><summary>Ubuntu Install Steps</summary>

```sh
sudo add-apt-repository ppa:neovim-ppa/unstable -y
sudo apt update
sudo apt install make gcc ripgrep unzip git xclip neovim
```

</details>
<details><summary>Debian Install Steps</summary>

```sh
sudo apt update
sudo apt install make gcc ripgrep unzip git xclip curl

# Now we install nvim
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo rm -rf /opt/nvim-linux-x86_64
sudo mkdir -p /opt/nvim-linux-x86_64
sudo chmod a+rX /opt/nvim-linux-x86_64
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz

# make it available in /usr/local/bin, distro installs to /usr/bin
sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/
```

</details>
<details><summary>Fedora Install Steps</summary>

```sh
sudo dnf install -y gcc make git ripgrep fd-find unzip neovim
```

</details>

<details><summary>Arch Install Steps</summary>

```sh
sudo pacman -S --noconfirm --needed gcc make git ripgrep fd unzip neovim
```

</details>
