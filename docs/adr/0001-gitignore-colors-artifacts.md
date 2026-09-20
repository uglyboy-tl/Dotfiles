# `.gitignore` 用限定作用域的通配忽略主题产物

主题渲染产物（`colors.toml`、`colors.ini` 等）因目录级软链会落回仓库，必须被忽略。早期用 `**/colors.*`，它同时命中了主题源文件 `themes/colors/<theme>/colors.toml`——六个主题因此全部未纳入版本控制，克隆仓库拿不到任何主题。现改为 `desktop/*/colors.*`：只匹配 `desktop/` 下一层的产物，物理上碰不到 `themes/`。

## Considered Options

- **`**/colors.*`**：一行搞定，但无差别误伤同名源文件。已证明会静默丢数据。
- **逐条列出产物路径**（6 条）：最安全，但每新增一个渲染目标都要改 `.gitignore`，容易漏。
- **`desktop/*/colors.*`**（采用）：一条规则覆盖现状与未来的桌面产物，作用域限定在 `desktop/`，与 `themes/` 的源文件不相交。前提是"产物只落在 `desktop/<app>/` 下"这一现状成立。

## Consequences

若将来有产物落在 `desktop/` 之外（如 `config/`），需为它单独加一条规则。这也意味着规则与目录约定绑定：产物落在哪，`.gitignore` 就得覆盖到哪。
