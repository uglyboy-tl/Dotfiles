; dunst 颜色配置（drop-in）
; Auto-generated from colors.toml - do not edit manually
; 注意: dunst 要求颜色值必须用引号括起来, 否则 # 会被当作注释

[global]
    frame_color = "{{ foreground }}33"
    separator_color = frame
    highlight = "{{ accent }}"

[urgency_low]
    background = "{{ background }}"
    foreground = "{{ dark_foreground }}"
    frame_color = "{{ foreground }}33"

[urgency_normal]
    background = "{{ background }}"
    foreground = "{{ foreground }}"
    frame_color = "{{ foreground }}33"

[urgency_critical]
    background = "{{ background }}"
    foreground = "{{ red }}"
    frame_color = "{{ red }}80"
