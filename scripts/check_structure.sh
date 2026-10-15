#!/usr/bin/env bash
set -euo pipefail

for day in $(seq -w 1 14); do
  file=$(find days -maxdepth 1 -type f -name "day${day}_*.md" -print -quit)
  if [[ -z "${file}" ]]; then
    echo "[ERROR] missing Day ${day} file"
    exit 1
  fi
  questions=$(grep -Ec '^## Q[0-9]+\.' "${file}")
  if [[ "${questions}" -ne 10 ]]; then
    echo "[ERROR] ${file} has ${questions} questions; expected 10"
    exit 1
  fi
  for field in 'What the interviewer is testing' 'Answer' 'Example' 'Common wrong answer' 'Spoken answer'; do
    count=$(grep -Fc "**${field}:**" "${file}")
    if [[ "${count}" -ne 10 ]]; then
      echo "[ERROR] ${file} has ${count} '${field}' fields; expected 10"
      exit 1
    fi
  done
done

echo "[PASS] 14 days, 140 questions, and all explanation fields are present"
