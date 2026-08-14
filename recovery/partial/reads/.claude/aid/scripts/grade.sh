TOTAL=$((CRITICAL + HIGH + MEDIUM + LOW + MINOR))

# Compute grade
if   [[ $TOTAL -eq 0 ]]; then
  GRADE="A+"
elif [[ $CRITICAL -gt 0 ]]; then
  GRADE="E$(modifier_for_count $CRITICAL)"
elif [[ $HIGH -gt 0 ]]; then
  GRADE="D$(modifier_for_count $HIGH)"
elif [[ $MEDIUM -gt 0 ]]; then
  GRADE="C$(modifier_for_count $MEDIUM)"
elif [[ $LOW -gt 0 ]]; then
  GRADE="B$(modifier_for_count $LOW)"
else
  # Only minors remain
  if [[ $MINOR -le 5 ]]; then
    GRADE="A"
  else
    GRADE="A-"
  fi
fi
