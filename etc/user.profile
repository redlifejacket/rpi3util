alias ll='ls -l'
alias l='ls -l'
alias la='ls -la'
alias lat='ls -lat'
alias c=clear
alias md=mkdir
alias rd=rmdir
alias s='sudo -i'
alias gita='git add -A .'
alias gits='git status'
alias gitc='git commit -m'

#[[ -f /etc/bash.profile ]] && . /etc/bash.profile

export PATH=$PATH::/home/pi/bin:.
export EDITOR=vi

PS1="\[\033[0;32m\]✔ \[\033[0;33m\]\w\[\033[0;0m\] \n\[\033[0;37m\]$(date +%H:%M)\[\033[0;0m\] "
function setPrompt {
  if [ $(whoami) == "root" ]
  then
    PS1="${PS1}# "
  else
    PS1="${PS1}$ "
  fi
}

setPrompt

export PS1
