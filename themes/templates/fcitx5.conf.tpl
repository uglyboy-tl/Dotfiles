; fcitx5 候选窗/菜单主题（扁平色块，参考 XXD rime-color-scheme 风格）
; Auto-generated from colors.toml - do not edit manually
; 主题名固定为 dotfiles，classicui.conf 需一次性设 Theme=dotfiles

[Metadata]
Name=Dotfiles
Version=1
Author=dotfiles
Description=Generated from the active dotfiles theme
ScaleWithDPI=True

[InputPanel]
; 未选中候选项
NormalColor={{ foreground }}
; 选中候选项文字（品牌原色块上的深色）
HighlightCandidateColor={{ dark_background }}
; 输入串（编码）文字与底色
HighlightColor={{ accent }}
HighlightBackgroundColor={{ background }}

[InputPanel/TextMargin]
Left=10
Right=10
Top=7
Bottom=7

[InputPanel/Background]
Color={{ background }}

[InputPanel/Background/Margin]
Left=4
Right=4
Top=4
Bottom=4

[InputPanel/Highlight]
; 选中候选项背景 = 主题强调色（品牌原色块）
Color={{ accent }}

[InputPanel/Highlight/Margin]
Left=10
Right=10
Top=7
Bottom=7

[Menu]
NormalColor={{ foreground }}

[Menu/Background]
Color={{ background }}
BorderColor={{ selection }}
BorderWidth=1

[Menu/Background/Margin]
Left=4
Right=4
Top=4
Bottom=4

[Menu/Highlight]
Color={{ accent }}

[Menu/Highlight/Margin]
Left=10
Right=10
Top=5
Bottom=5

[Menu/Separator]
Color={{ selection }}
