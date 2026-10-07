# Практическая работа №3 — инструкция по воспроизведению на macOS

> Отчёт о выполнении — в [README.md](README.md).

## Что лежит в папке

| Файл | Назначение |
|---|---|
| `Dockerfile`, `package.json`, `server.js`, `deployment.yaml` (корень) | Текущая (исправленная) версия, её собирает CI |
| `vulnerable/` | Приложение и манифест **до исправления** (node:18, express 4.16.0, lodash 4.17.15, privileged: true) |
| `secure/` | Исправленные версии: Dockerfile, package.json, server.js, deployment.yaml |
| `.github/workflows/security-scan.yml` | Пайплайн GitHub Actions (часть 5) |
| `run_scans.sh` | Части 2–3 одной командой, результаты пишутся в `reports/` |
| `.gitignore`, `.dockerignore` | Чтобы секреты и мусор не попали в git и в образ |

---

## Шаг 0. Установка (один раз)

```bash
# Homebrew, если его нет (после установки выполните 2 команды, которые он выведет в конце)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

xcode-select --install
brew install --cask docker
brew install trivy checkov gnupg pinentry-mac gh

# Окно ввода пароля для GPG
mkdir -m 700 -p ~/.gnupg
echo "pinentry-program $(brew --prefix)/bin/pinentry-mac" >> ~/.gnupg/gpg-agent.conf
gpgconf --kill gpg-agent
echo 'export GPG_TTY=$(tty)' >> ~/.zshrc && source ~/.zshrc
```

Запустите **Docker Desktop** из «Программ» и дождитесь, пока кит в строке меню перестанет мигать.

Проверка (скриншот для отчёта):
```bash
docker --version && trivy --version && checkov --version && gpg --version | head -1
```

Перейдите в папку проекта:
```bash
cd ~/Documents/Uni/Master2_1/Защита/Lab3
```

---

## Шаги 1–3. Trivy и Checkov

```bash
bash run_scans.sh
```

Скрипт выполнит пункты 2.1–2.5 и 3.2–3.4 и сохранит каждый вывод в `reports/`. В конце он покажет итог «до/после». Первый запуск Trivy скачивает базу уязвимостей, это несколько минут.

Ожидаемый результат Checkov: **до** — 20 нарушений, **после** — 1 (`CKV_K8S_43`, образ по digest; допустимо, так как образ не публикуется в реестр).

Для отчёта сделайте скриншоты таблиц Trivy (Cmd+Shift+4) или возьмите текст из `reports/`.

Если хотите выполнять команды по одной, как в методичке:
```bash
docker build -t demo-app:vulnerable vulnerable/
trivy image demo-app:vulnerable
trivy image --severity CRITICAL,HIGH demo-app:vulnerable
trivy image --format json --output trivy-report.json demo-app:vulnerable
docker build -t demo-app:secure secure/
trivy image --severity CRITICAL,HIGH demo-app:secure
checkov -f vulnerable/deployment.yaml --framework kubernetes
checkov -f secure/deployment.yaml --framework kubernetes
```

---

## Шаг 4. GnuPG (вручную — нужны скриншоты)

```bash
# 4.1 Основной ключ: RSA and RSA, 4096, срок 1y, имя "Security Lab", email lab@example.com
gpg --full-generate-key

# 4.2 Просмотр ключей  → скриншот
gpg --list-keys
gpg --list-secret-keys

# 4.3 Шифрование
echo "DB_PASSWORD=SuperSecret123" > secrets.txt
gpg --encrypt --recipient lab@example.com secrets.txt
rm secrets.txt              # shred на macOS нет
ls -l secrets.txt.gpg
cat secrets.txt.gpg         # нечитаемые данные — скриншот

# 4.4 Расшифровка
gpg --decrypt secrets.txt.gpg > secrets_decrypted.txt
cat secrets_decrypted.txt

# 4.5 Ротация: второй ключ с email new-lab@example.com
gpg --full-generate-key
gpg --decrypt secrets.txt.gpg | gpg --encrypt --recipient new-lab@example.com -o secrets_new.gpg
gpg --decrypt secrets_new.gpg
gpg --list-keys             # видно оба ключа — скриншот

# (дополнительно) сертификат отзыва старого ключа
gpg --gen-revoke lab@example.com > revoke-old-key.asc
```

В окне pinentry **не** ставьте галочку «Сохранить в связке ключей», иначе пароль не будет запрашиваться при расшифровке.

`secrets*.txt` и `*.gpg` занесены в `.gitignore` и в репозиторий не попадут.

---

## Шаг 5. GitHub Actions

```bash
gh auth login                     # вход через браузер

# 1) Публикуем УЯЗВИМУЮ версию → пайплайн должен упасть
cp vulnerable/Dockerfile vulnerable/package.json vulnerable/deployment.yaml .
git init -b main
git add .
git commit -m "Vulnerable version"
gh repo create lab3-devsecops --public --source=. --push
```

Откройте репозиторий → вкладка **Actions** → дождитесь красного статуса → скриншот (и скриншот лога шага Trivy с таблицей).

```bash
# 2) Переносим исправленные файлы в корень → пайплайн должен пройти
cp secure/Dockerfile secure/package.json secure/deployment.yaml .
git add .
git commit -m "Fix vulnerabilities: update base image, deps, harden manifest"
git push
```

Дождитесь зелёного статуса → скриншот. Результаты Trivy также появятся во вкладке **Security → Code scanning**.

Если пайплайн остался красным из-за Trivy — откройте лог шага, посмотрите, какой пакет даёт HIGH/CRITICAL, и обновите его версию (это и есть цикл «обнаружили → исправили → проверили»).

---

## Что куда в отчёте

| Пункт отчёта | Откуда взять |
|---|---|
| 1. Описание приложения | `Dockerfile`, `package.json`, `server.js` (+ исправленные из `secure/`) |
| 2. Trivy до/после | `reports/2.3_trivy_vulnerable_high.txt`, `reports/2.5_trivy_secure_high.txt` |
| 3. Checkov до/после | `reports/3.2_checkov_before.txt`, `reports/3.4_checkov_after.txt` |
| 4. GnuPG | скриншоты из шага 4 |
| 5. CI/CD | скриншоты красного и зелёного запуска в Actions |
| 6. Выводы | см. ниже |

**Идеи для выводов (трудности и улучшения):**
- основной источник CVE — устаревший базовый образ `node:18`, а не код приложения; переход на `node:22-alpine` и удаление npm из рантайма дали наибольший эффект;
- исправленный по методичке манифест закрывал лишь часть нарушений Checkov; потребовались лимиты ресурсов, пробы, drop capabilities, seccomp, NetworkPolicy;
- в исходном workflow не было установки Checkov и прав `security-events: write`;
- на macOS (APFS/SSD) нет `shred` — надёжное удаление файла не гарантируется, поэтому важно шифрование всего диска (FileVault);
- улучшения: закреплять actions по SHA-коммиту, сканировать `trivy fs` ещё до сборки, автоматизировать обновление зависимостей (Dependabot).
