#!/usr/bin/env bash
# Claude Code status line — context window + compaction proximity + rate limits
input=$(cat)

# Model display name
model=$(printf '%s' "$input" | jq -r '.model.display_name // empty')

# Context window fields
cw_size=$(printf '%s' "$input" | jq -r '.context_window.context_window_size // empty')
used_pct=$(printf '%s' "$input" | jq -r '.context_window.used_percentage // empty')

# Total context tokens = input_tokens + cache_creation_input_tokens + cache_read_input_tokens
# input_tokens alone undercounts when caching is active (cached tokens move to cache_read_input_tokens)
input_tokens=$(printf '%s' "$input" | jq -r '.context_window.current_usage.input_tokens // 0')
cache_write=$(printf '%s' "$input" | jq -r '.context_window.current_usage.cache_creation_input_tokens // 0')
cache_read=$(printf '%s' "$input" | jq -r '.context_window.current_usage.cache_read_input_tokens // 0')

# Only treat as "no data" when all three are absent (current_usage is null)
has_usage=$(printf '%s' "$input" | jq -r 'if .context_window.current_usage == null then "no" else "yes" end')

total_ctx_tokens=""
if [ "$has_usage" = "yes" ]; then
  total_ctx_tokens=$(awk "BEGIN { print $input_tokens + $cache_write + $cache_read }")
fi

# Format token count in K
tokens_k=""
if [ -n "$total_ctx_tokens" ] && [ "$total_ctx_tokens" -gt 0 ] 2>/dev/null; then
  tokens_k=$(awk "BEGIN { printf \"%.0fk\", $total_ctx_tokens / 1000 }")
fi

# Format context window size in K
cw_k=""
if [ -n "$cw_size" ]; then
  cw_k=$(awk "BEGIN { printf \"%.0fk\", $cw_size / 1000 }")
fi

# Build the context display
if [ -n "$tokens_k" ] && [ -n "$cw_k" ]; then
  ctx_part="${tokens_k} / ${cw_k}"

  if [ -n "$used_pct" ]; then
    used_int=$(printf '%.0f' "$used_pct")

    # Color the compaction proximity indicator
    # Claude Code compacts around 85-90% used; warn at >= 70%, danger at >= 85%
    if [ "$used_int" -ge 85 ]; then
      # Red — imminent compaction
      compact_label=$(printf '\033[31m(%d%% — compact soon)\033[0m' "$used_int")
    elif [ "$used_int" -ge 70 ]; then
      # Yellow — getting close
      compact_label=$(printf '\033[33m(%d%%)\033[0m' "$used_int")
    else
      # Dim — no concern
      compact_label=$(printf '\033[2m(%d%%)\033[0m' "$used_int")
    fi

    printf '\033[36mctx:\033[0m %s %s' "$ctx_part" "$compact_label"
  else
    printf '\033[36mctx:\033[0m %s' "$ctx_part"
  fi
elif [ -n "$model" ]; then
  printf '\033[2m%s\033[0m' "$model"
fi

# Rate limit section (5-hour session limit)
five_pct=$(printf '%s' "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_resets=$(printf '%s' "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')

if [ -n "$five_pct" ]; then
  five_int=$(printf '%.0f' "$five_pct")
  remaining_int=$((100 - five_int))

  # Color based on how much is used
  if [ "$five_int" -ge 90 ]; then
    limit_color='\033[31m'   # Red — nearly exhausted
  elif [ "$five_int" -ge 70 ]; then
    limit_color='\033[33m'   # Yellow — getting low
  else
    limit_color='\033[32m'   # Green — plenty left
  fi

  # Format reset time as HH:MM if available
  reset_str=""
  if [ -n "$five_resets" ]; then
    reset_str=$(date -d "@${five_resets}" +"%H:%M" 2>/dev/null || date -r "${five_resets}" +"%H:%M" 2>/dev/null)
    [ -n "$reset_str" ] && reset_str=" resets ${reset_str}"
  fi

  printf '  \033[36m5h:\033[0m '"${limit_color}"'%d%% used (%d%% left)\033[0m\033[2m%s\033[0m' \
    "$five_int" "$remaining_int" "$reset_str"
fi
