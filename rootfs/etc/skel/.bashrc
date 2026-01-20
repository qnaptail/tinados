# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
unset rc
echo 'Please type liveinst and press Enter to start the installer'

alias ga='git add'
alias gaa='git add --all'
alias gc='git commit -v'
alias gcl='git clone --recursive'
alias gd='git diff'
alias gp='git push'
alias gs='git status'

alias eza='eza --icons auto'
alias l='ls -l'
alias la='eza -a'
alias ll='eza -l'
alias lla='eza -la'
alias ls=eza
alias lst='eza --sort newest -l'
alias lt='eza --tree'

if [[ :$SHELLOPTS: =~ :(vi|emacs): ]]; then
  eval "$(fzf --bash)"
fi

if [[ $TERM != "dumb" ]]; then
  eval "$(starship init bash --print-full-init)"
  eval "$(zoxide init bash )"
fi

function yy() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXX")"
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(<"$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}
