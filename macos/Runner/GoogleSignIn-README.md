# Google Sign-In（macOS）配置

## 所需配置

1. **GIDClientID**：macOS OAuth 客户端 ID（形如 `xxxxx.apps.googleusercontent.com`）。
2. **CFBundleURLTypes**：OAuth 回调用的 URL scheme，必须为 **反转的客户端 ID**：  
   取客户端 ID 中 `@` 前的部分（即 `xxxxx`）， scheme 为 `com.googleusercontent.apps.xxxxx`。  
   例如客户端 ID 为 `157306094891-xxx.apps.googleusercontent.com`，则 scheme 为 `com.googleusercontent.apps.157306094891-xxx`。

## 步骤

1. 打开 [Google Cloud Console](https://console.cloud.google.com/) → 你的项目 → **API 和凭据**。
2. **创建凭据** → **OAuth 客户端 ID**，应用类型选 **macOS**，创建。
3. 复制 **客户端 ID**（如 `AAAA-BBBB.apps.googleusercontent.com`）。
4. 在 `macos/Runner/Info.plist` 中：
   - 将 `GIDClientID` 设为该客户端 ID。
   - 在 `CFBundleURLTypes` → `CFBundleURLSchemes` 中设一条：`com.googleusercontent.apps.AAAA-BBBB`（把 `AAAA-BBBB` 换成你客户端 ID 中 `.apps.googleusercontent.com` 前面的那一段，注意大小写与 Console 中一致）。

若仅使用 Web 端登录，可不配置上述两项。
