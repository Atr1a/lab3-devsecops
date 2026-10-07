#!/bin/bash
# Части 2–3: сборка обоих образов, сканирование Trivy и Checkov "до" и "после".
# Все результаты сохраняются в папку reports/ — их можно вставлять в отчёт.
# Запуск:  bash run_scans.sh
set -u
cd "$(dirname "$0")"
mkdir -p reports

echo "=== 2.1 Сборка уязвимого образа ==="
docker build -t demo-app:vulnerable . || { echo "Ошибка сборки. Запущен ли Docker Desktop?"; exit 1; }

echo "=== 2.2 Trivy: полный скан (до) ==="
trivy image demo-app:vulnerable | tee reports/2.2_trivy_vulnerable_all.txt

echo "=== 2.3 Trivy: только CRITICAL,HIGH (до) ==="
trivy image --severity CRITICAL,HIGH demo-app:vulnerable | tee reports/2.3_trivy_vulnerable_high.txt

echo "=== 2.4 Trivy: JSON-отчёт ==="
trivy image --format json --output reports/trivy-report.json demo-app:vulnerable
echo "Сохранено: reports/trivy-report.json"

echo "=== 2.5 Сборка исправленного образа и повторный скан (после) ==="
docker build -t demo-app:secure secure/ || exit 1
trivy image --severity CRITICAL,HIGH demo-app:secure | tee reports/2.5_trivy_secure_high.txt

echo "=== 3.2 Checkov: небезопасный манифест (до) ==="
checkov -f deployment.yaml --framework kubernetes --compact | tee reports/3.2_checkov_before.txt

echo "=== 3.4 Checkov: исправленный манифест (после) ==="
checkov -f secure/deployment.yaml --framework kubernetes --compact | tee reports/3.4_checkov_after.txt

echo
echo "================ ИТОГ ================"
echo "Trivy до  (CRITICAL,HIGH): $(grep -m1 '^Total' reports/2.3_trivy_vulnerable_high.txt)"
echo "Trivy после (CRITICAL,HIGH): $(grep -m1 '^Total' reports/2.5_trivy_secure_high.txt)"
echo "Checkov до:    $(grep -m1 'Failed checks' reports/3.2_checkov_before.txt)"
echo "Checkov после: $(grep -m1 'Failed checks' reports/3.4_checkov_after.txt)"
echo "Все выводы лежат в папке reports/"
