## ADDED Requirements

### Requirement: Live Photo 检测与播放入口

媒体查看器 SHALL 在当前资产为 Live Photo（`asset.isMotionPhoto == true`）时提供「播放 Live 视频」入口，并在用户未触发播放时仅显示静态主图；SHALL 根据「当前是否在播 Live 视频」的单一状态在静态主图视图与 Live 短视频视图之间切换。

#### Scenario: 当前为 Live Photo 时显示播放按钮

- **WHEN** 媒体查看器当前页对应的资产满足 `asset.isMotionPhoto == true` 且认为有可播放的 Live 视频（如 `livePhotoVideoId != null`，或后续可加可用性检查）
- **THEN** 顶部或控制栏 SHALL 显示「播放 Live 视频」按钮（或等价入口）
- **AND** 默认展示 SHALL 为静态主图（ViewerImagePage），不在此阶段加载 Live 视频

#### Scenario: 当前非 Live Photo 或无视频时不显示播放按钮

- **WHEN** 当前资产满足 `asset.isMotionPhoto == false` 或已知 Live 视频不可用（如 404、未下载且离线）
- **THEN** 不显示播放 Live 按钮或 SHALL 显示为不可用（灰显并可提示）
- **AND** 仅展示主图，无播放入口

#### Scenario: 点击播放后切换为 Live 视频视图

- **WHEN** 用户点击「播放 Live 视频」按钮或通过长按主图触发同一动作
- **THEN** 系统 SHALL 将「当前是否在播 Live 视频」状态置为 true
- **AND** 当前页 SHALL 切换为使用 ViewerVideoPage（或同等能力），视频源由 `livePhotoVideoId` 解析（本地文件路径或远程 URL）
- **AND** Live 视频 SHALL 不循环，播完后自动切回静态主图并将播放状态置为 false

#### Scenario: 页面切换时释放 Live 播放状态

- **WHEN** 用户左右滑动离开当前页（或进入相邻页）
- **THEN** 若当前页为 Live Photo 且正在播放 Live 视频，SHALL 停止播放并释放播放器
- **AND** 「当前是否在播 Live 视频」状态 SHALL 重置为 false（或按页作用域重置）
- **AND** 滑回该页时 SHALL 默认显示静态主图，不自动续播

#### Scenario: 播放状态由单一 Provider 驱动

- **WHEN** 实现播放入口与图/视频切换
- **THEN** 系统 SHALL 使用单一状态源（如 `isPlayingMotionVideoProvider`）驱动播放按钮的显示/隐藏与图标切换、以及当前页是展示 ViewerImagePage 还是 ViewerVideoPage（Live 视频源）
- **AND** 视频播放器 SHALL 复用现有 ViewerVideoPage/ViewerVideoManager，仅传入 Live 视频源与不循环、播完回图等参数差异

#### Scenario: Live 视频源解析

- **WHEN** 需要播放 Live 视频
- **THEN** 视频源 SHALL 优先使用本地已下载的 Live 视频文件路径（若存在）
- **AND** 否则 SHALL 使用与普通视频一致的远程 URL 规则（如 `$serverUrl/assets/{livePhotoVideoId}/video/playback` 或 original），与现有播放与鉴权逻辑兼容

#### Scenario: 播放失败降级

- **WHEN** 用户点击播放后视频加载或解码失败
- **THEN** 系统 SHALL 提示失败原因并保持或切回静态主图视图
- **AND** 播放状态 SHALL 置为 false，不阻塞主图浏览
