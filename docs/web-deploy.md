# Web 部署（Cloudflare Pages + Google 登录）

## Cloudflare Pages

打 tag 触发 Release workflow 后，若开启部署则会自动把 web 产物部署到 Cloudflare Pages。

**开启方式**：在仓库 **Settings** → **Secrets and variables** → **Actions** → **Variables** 中新增变量 `CLOUDFLARE_DEPLOY`，值设为 `true`。

**Secrets**（同上 Settings → Secrets 中配置）：

| Secret | 说明 |
|--------|------|
| `CLOUDFLARE_ACCOUNT_ID` | Cloudflare 控制台右侧 API 区域里的 Account ID |
| `CLOUDFLARE_API_TOKEN` | [创建 API Token](https://dash.cloudflare.com/profile/api-tokens)，权限包含 **Account** → **Cloudflare Pages** → **Edit** |

首次需在本地或 Cloudflare 控制台创建 Pages 项目，例如：

```bash
npx wrangler pages project create
# 项目名填 octarq-vault（与 workflow 里 --project-name 一致）
```

部署后的地址：`https://octarq-vault.pages.dev`（或你绑定的自定义域名 vault.octarq.org）。

## Google 登录（Web Client）

Web 端 Google Drive 同步需要 OAuth 2.0 的 **Web 应用** 客户端 ID。

1. 打开 [Google Cloud Console](https://console.cloud.google.com/) → 选择/创建项目 → **API 和服务** → **凭据**。
2. **创建凭据** → **OAuth 2.0 客户端 ID**。
3. 应用类型选 **Web 应用**。
4. **已授权的 JavaScript 来源** 添加你的 Web 地址，例如：
   - `https://octarq-vault.pages.dev`
   - `https://vault.octarq.org`（若已绑定自定义域名）
5. 创建后复制 **客户端 ID**（形如 `xxx.apps.googleusercontent.com`）。

在 CI 中注入（Release 时打的 web 包会带上该 ID）：

- 在仓库 **Settings** → **Secrets and variables** → **Actions** 里新增 Secret：
  - 名称：`GOOGLE_CLIENT_ID`
  - 值：上一步复制的客户端 ID

本地调试时在运行/构建时传入：

```bash
flutter run -d chrome --dart-define=GOOGLE_CLIENT_ID=你的客户端ID.apps.googleusercontent.com
# 或
flutter build web --dart-define=GOOGLE_CLIENT_ID=你的客户端ID.apps.googleusercontent.com
```

未配置时 Web 仍可运行，但 Google Drive 同步不可用。
