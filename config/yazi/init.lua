require("full-border"):setup()
require("git"):setup()
require("zoxide"):setup {
	update_db = true,
}
require("yaziline"):setup()

-- 启动时在第二个 tab 打开 NAS（SFTP 服务定义见 vfs.toml）
ya.emit("tab_create", { "sftp://nas/", raw = true })
ya.emit("tab_switch", { 0 }) -- 切回第一个 tab（本地目录）