#!/bin/bash
# Проверка установки инструментов для ПР №3 (macOS).
# Запуск:  bash check_install.sh
# Результат выводится на экран и сохраняется в reports/check_install.txt

cd "$(dirname "$0")"
mkdir -p reports
OUT=reports/check_install.txt

# Homebrew может быть установлен, но не добавлен в PATH
for p in /opt/homebrew/bin /usr/local/bin; do
  case ":$PATH:" in *":$p:"*) ;; *) [ -d "$p" ] && PATH="$p:$PATH" ;; esac
done
[ -d "$HOME/.local/bin" ] && PATH="$PATH:$HOME/.local/bin"

{
echo "Дата: $(date)"
echo "macOS: $(sw_vers -productVersion 2>/dev/null)  CPU: $(uname -m)"
echo "Shell: $SHELL"
echo "PATH (в обычном терминале): $(zsh -lic 'echo $PATH' 2>/dev/null)"
echo "----------------------------------------"

check() {   # check <имя> <команда версии> <подсказка>
  if command -v "$1" >/dev/null 2>&1; then
    printf "OK      %-13s %s   (%s)\n" "$1" "$(eval "$2" 2>&1 | head -1)" "$(command -v "$1")"
  else
    printf "НЕТ     %-13s -> %s\n" "$1" "$3"
  fi
}

check brew         "brew --version"            "установите Homebrew с https://brew.sh"
check git          "git --version"             "xcode-select --install"
check docker       "docker --version"          "brew install --cask docker"
check trivy        "trivy --version"           "brew install trivy"
check checkov      "checkov --version"         "brew install checkov  (или pipx install checkov)"
check gpg          "gpg --version"             "brew install gnupg"
check pinentry-mac "echo installed"            "brew install pinentry-mac"
check gh           "gh --version"              "brew install gh"

echo "----------------------------------------"
if command -v docker >/dev/null 2>&1; then
  if docker info >/dev/null 2>&1; then
    echo "OK      Docker daemon запущен"
  else
    echo "НЕТ     Docker daemon не отвечает -> запустите Docker Desktop и дождитесь, пока кит перестанет мигать"
  fi
fi

if [ -f "$HOME/.gnupg/gpg-agent.conf" ] && grep -q pinentry-mac "$HOME/.gnupg/gpg-agent.conf"; then
  echo "OK      gpg-agent.conf настроен на pinentry-mac"
else
  echo "НЕТ     gpg-agent.conf без pinentry-mac -> см. шаг 0 в README"
fi

if grep -q GPG_TTY "$HOME/.zshrc" 2>/dev/null; then
  echo "OK      GPG_TTY прописан в ~/.zshrc"
else
  echo "НЕТ     GPG_TTY не прописан в ~/.zshrc -> echo 'export GPG_TTY=\$(tty)' >> ~/.zshrc"
fi

if command -v gh >/dev/null 2>&1; then
  if gh auth status >/dev/null 2>&1; then
    echo "OK      gh: вход в GitHub выполнен"
  else
    echo "НЕТ     gh: не выполнен вход -> gh auth login (нужно только для части 5)"
  fi
fi
} 2>&1 | tee "$OUT"

echo
echo "Результат сохранён в $OUT"
