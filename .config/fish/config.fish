source /usr/share/cachyos-fish-config/cachyos-config.fish

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end

# быстрые команды для управления zapret
alias zapret-config='$HOME/zapret-configs/install.sh'
alias zapret-utils='$HOME/zapret-configs/utils-zapret.sh'
alias vi='nvim'

# Added by LM Studio CLI (lms)
set -gx PATH $PATH /home/dreaght/.lmstudio/bin
# End of LM Studio CLI section

fish_add_path $HOME/.cargo/bin
set -Ux CARGO_HOME $HOME/.cargo
