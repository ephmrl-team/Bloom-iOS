#!/usr/bin/env bash
# Repo-level static security checks from AGENTS.md §8.8.
# Exits non-zero when a rule is violated. Reviews (not failures) are prefixed with REVIEW.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail=0

check() { # description, pattern, paths...
  local description="$1" pattern="$2"
  shift 2
  local hits
  hits=$(grep -rnE --include='*.swift' --include='*.m' --include='*.h' -- "$pattern" "$@" 2>/dev/null)
  if [ -n "$hits" ]; then
    echo "SECURITY CHECK FAILED: $description"
    echo "$hits"
    fail=1
  fi
}

review() { # description, pattern, paths...
  local description="$1" pattern="$2"
  shift 2
  local hits
  hits=$(grep -rnE --include='*.swift' --include='*.m' --include='*.h' -- "$pattern" "$@" 2>/dev/null)
  if [ -n "$hits" ]; then
    echo "REVIEW: $description"
    echo "$hits"
  fi
}

check "print() in app code"                          '\bprint\('                     Bloom
check "NSLog in app code"                            '\bNSLog\('                     Bloom
check "arbitrary loads / ATS exceptions"             'NSAllowsArbitraryLoads|NSExceptionDomains' Bloom Bloom.xcodeproj
check "iCloud-synced keychain items"                 'kSecAttrSynchronizable.*(true|kCFBooleanTrue)' Bloom
check "force try / force cast in app code"           'try!|[^a-zA-Z]as!\s'           Bloom
check "secrets-looking literals"                     '(api[_-]?key|secret|token|password)[[:space:]]*[:=][[:space:]]*"[^"]+"' Bloom

# Every SecItemAdd call site must set kSecAttrAccessible explicitly.
while IFS= read -r file; do
  if grep -qE 'SecItemAdd' "$file"; then
    if ! grep -qE 'kSecAttrAccessible' "$file"; then
      echo "SECURITY CHECK FAILED: SecItemAdd without kSecAttrAccessible in $file"
      fail=1
    fi
  fi
done < <(find Bloom -name '*.swift' -o -name '*.m' -o -name '*.h')

review "keychain writes (confirm accessibility)"     'SecItemAdd' Bloom

exit $fail
