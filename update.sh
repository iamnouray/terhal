#!/bin/bash
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'
echo ""; echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}          🚀 Terhal — Git Update Tool          ${RESET}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"; echo ""
if ! git rev-parse --git-dir > /dev/null 2>&1; then echo -e "${RED}❌ مش git repository!${RESET}"; exit 1; fi
BRANCH=$(git branch --show-current)
echo -e "📍 Branch: ${CYAN}${BRANCH}${RESET}"; echo ""
BEFORE=$(git rev-parse HEAD)
echo -e "${YELLOW}⏳ جاري السحب...${RESET}"
git fetch origin
BEHIND=$(git rev-list HEAD..origin/${BRANCH} --count 2>/dev/null)
if [ "$BEHIND" = "0" ] || [ -z "$BEHIND" ]; then echo -e "${GREEN}✅ المشروع محدّث${RESET}"; exit 0; fi
echo -e "${CYAN}📦 في ${BEHIND} تحديثات جديدة!${RESET}"; echo ""
echo -e "${BOLD}━━━ التعديلات ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
git log HEAD..origin/${BRANCH} --pretty=format:"  ${CYAN}%h${RESET} │ ${YELLOW}%an${RESET} │ %s │ ${GREEN}%cr${RESET}"; echo ""; echo ""
echo -e "${BOLD}━━━ الملفات ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
git diff HEAD..origin/${BRANCH} --name-status | while IFS= read -r line; do
  STATUS=$(echo "$line" | cut -c1); FILE=$(echo "$line" | cut -c3-)
  case "$STATUS" in A) echo -e "  ${GREEN}[أضيف]${RESET} $FILE" ;; M) echo -e "  ${YELLOW}[عُدِّل]${RESET} $FILE" ;; D) echo -e "  ${RED}[حُذف]${RESET} $FILE" ;; esac
done; echo ""
echo -e "تطبق التحديثات؟ ${CYAN}(y/n)${RESET}"; read -r ANSWER
if [[ "$ANSWER" == "y" || "$ANSWER" == "Y" ]]; then
  git pull origin "$BRANCH"
  PY=$(git diff "${BEFORE}"..HEAD --name-only | grep -c "\.py$" || true)
  DART=$(git diff "${BEFORE}"..HEAD --name-only | grep -c "\.dart$" || true)
  [ "$PY" -gt 0 ] && echo -e "${YELLOW}⚠️  أعد تشغيل السيرفر: ${CYAN}uvicorn main:app --reload${RESET}"
  [ "$DART" -gt 0 ] && echo -e "${YELLOW}⚠️  أعد تشغيل Flutter: ${CYAN}flutter run${RESET}"
else echo -e "${YELLOW}⏸️  تم الإلغاء${RESET}"; fi
