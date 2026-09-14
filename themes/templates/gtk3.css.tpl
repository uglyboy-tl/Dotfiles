/* GTK3 主题 - Auto-generated from colors.toml - do not edit manually
 * GTK3 不因 @define-color 改变 Adwaita 的窗口配色，故除命名色外，
 * 还显式覆盖控件颜色与状态（hover/active/selected/disabled）。
 * 末尾禁用 GTK CSD 自绘阴影/圆角（配合 bspwm + picom）。 */

/* --- 命名色（部分程序会用到） --- */
@define-color theme_bg_color {{ background }};
@define-color theme_base_color {{ background }};
@define-color theme_fg_color {{ foreground }};
@define-color theme_text_color {{ foreground }};
@define-color theme_selected_bg_color {{ accent }};
@define-color theme_selected_fg_color {{ background }};

@define-color theme_unfocused_bg_color {{ background }};
@define-color theme_unfocused_base_color {{ background }};
@define-color theme_unfocused_fg_color {{ dark_foreground }};
@define-color theme_unfocused_text_color {{ dark_foreground }};
@define-color theme_unfocused_selected_bg_color {{ muted }};
@define-color theme_unfocused_selected_fg_color {{ background }};

@define-color insensitive_bg_color {{ lighter_background }};
@define-color insensitive_fg_color {{ muted }};
@define-color insensitive_base_color {{ background }};

@define-color borders {{ lighter_background }};
@define-color unfocused_borders {{ muted }};
@define-color content_view_bg {{ background }};

@define-color error_color {{ red }};
@define-color warning_color {{ yellow }};
@define-color success_color {{ green }};

/* --- 窗体 / 视图 --- */
window, .background {
  background-color: {{ background }};
  color: {{ foreground }};
}

headerbar, .titlebar, .titlebar:backdrop {
  background-color: {{ dark_background }};
  color: {{ foreground }};
  border-color: {{ darker_background }};
}

view, .view, treeview.view, textview, textview text, iconview.view,
flowbox, flowboxchild, .content-view {
  background-color: {{ background }};
  color: {{ foreground }};
}

sidebar, .sidebar {
  background-color: {{ dark_background }};
  color: {{ foreground }};
}

/* --- 菜单 --- */
popover, menu, .menu, .context-menu {
  background-color: {{ lighter_background }};
  color: {{ foreground }};
}

menu menuitem:hover, menu menuitem:selected,
.menu .menuitem:hover, .context-menu menuitem:hover {
  background-color: {{ accent }};
  color: {{ background }};
}

/* --- 按钮 --- */
button, .button {
  background-color: {{ lighter_background }};
  color: {{ foreground }};
}

button:hover, .button:hover {
  background-color: shade({{ lighter_background }}, 1.12);
  color: {{ foreground }};
}

button:active, .button:active {
  background-color: shade({{ lighter_background }}, 0.82);
  color: {{ foreground }};
}

button:checked, togglebutton:checked {
  background-color: {{ accent }};
  color: {{ background }};
}

button:disabled, .button:disabled {
  background-color: {{ darker_background }};
  color: {{ muted }};
}

/* --- 输入 --- */
entry, spinbutton, searchentry {
  background-color: {{ darker_background }};
  color: {{ foreground }};
}

entry:focus, spinbutton:focus, searchentry:focus {
  border-color: {{ accent }};
  box-shadow: inset 0 0 0 1px {{ accent }};
}

/* --- 列表 / 树 --- */
row:hover, list row:hover, treeview.view:hover {
  background-color: shade({{ background }}, 1.15);
}

row:selected, list row:selected, treeview.view:selected, .view:selected {
  background-color: {{ accent }};
  color: {{ background }};
}

selection {
  background-color: {{ accent }};
  color: {{ background }};
}

/* --- 禁用 GTK CSD 自绘阴影/圆角（GTK 3.24 用 window.csd / decoration） --- */
window.csd, window.csd:backdrop,
decoration, decoration:backdrop,
.window-frame, .window-frame:backdrop {
  box-shadow: none;
  border-style: none;
  margin: 0;
  border-radius: 0;
}

headerbar, .titlebar {
  border-radius: 0;
}
