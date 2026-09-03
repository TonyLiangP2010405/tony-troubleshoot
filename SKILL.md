---
name: tony-troubleshoot
description: "对单台、带物理外设或多台 WyreStorm/IPAV/OEM 设备做证据化故障排查；启动时先让用户打开并登录相关设备 Web UI，在现有认证会话中安全调用 Web-only 只读 API；完成询问和资料审阅后先在本地知识库检索相似历史问题案例，再列出全部合理候选问题，让用户多选优先排查项，再按七类问题及参数/内部状态维度定位。用于黑屏、网络、控制、配对、无线、Web UI 独有设置和机群巡检；检查点只在同一会话续查，结案仅保留总结。"
---

# WyreStorm 分层排障与按需全量审计

在保证只读安全、证据可复核的前提下尽快定位故障。先听完并结构化记录用户已经做过的操作，再分类和选取查询；不要让用户重复无效步骤。案件文件只是当前会话的临时工作记忆，不是跨会话知识库。

## 会话隔离（强制）

- 每个新对话/新 session 必须创建新的空案件目录。优先放在会话专用临时目录，不要放进普通项目源码目录。
- 只有模型切换、上下文 compacting/压缩或同一对话内中断恢复，才属于同一 session；此时可用当前对话已经建立的准确 `CaseRoot` 和 `session_nonce` 续查。
- 新 session 不得搜索磁盘寻找旧 `checkpoint.json`、`findings.md`、账本或 `raw/`，也不得因为客户、设备或 IP 相同而自动复用旧案件。
- 如果 compacting 后无法从当前会话上下文确认准确 `CaseRoot` 和 `session_nonce`，创建新案件或向当前用户确认；不得猜路径或扫描历史目录。
- 旧的 `resolution-summary.md` 只有在用户明确要求参考历史案例时才能作为背景阅读；它不是当前故障的事实证据，不能代替本次 intake 和验证。

## 选择工作模式

开始前确定模式并写入 `checkpoint.json`。用户没有明确指定时使用 `triage`；不得静默升级为更重的模式。

- `triage`（默认）：适用于日常排障和多设备巡检。对全部范围内设备执行低成本核心健康查询，只对异常设备继续深入。
- `deep`：适用于明确的故障设备、端口、信号链或问题域。只编制和执行与症状、依赖项及反证有关的命令。
- `audit`：仅当用户明确要求“全量、全部命令、全部字段、穷尽、覆盖审计”时使用。对所有适用设备、命令和有限参数组合进行完整覆盖。

如果用户中途改变模式，记录变更原因；保留已取得的有效证据，仅扩展或收缩尚未执行的范围。

## 启动时打开并登录相关设备 Web UI（强制询问）

初始化案件后，在产品研究、分类或任何 Telnet/API 查询之前，先让用户在自己的浏览器中打开故障链路相关设备的准确 Web UI 并自行登录。用户不要把用户名、密码、Cookie 或令牌发给 agent；登录成功后只需确认：“页面已打开并登录，允许 agent 使用当前会话做只读诊断”。

- `single_physical` 至少准备故障主机的 Web UI；`fleet` 先准备受影响设备和控制器，后续只在某台设备需要深入时再打开该设备页面，避免要求用户一次打开大量无关页面。
- agent 只有在当前环境具备浏览器控制能力、能够使用用户已经登录的页面且用户已确认允许只读诊断时，才可接管该页面。先从页面核对地址、型号、序列号或设备名，防止连错机器。
- 在 `web-ui-session-ledger.csv` 逐设备记录 Web UI 地址、用户已打开/登录、agent 访问方式、页面显示的设备身份、固件/UI build、会话状态和时间；URL 必须移除 userinfo、临时签名和含令牌的查询参数，不得记录任何凭据、Cookie、授权头、CSRF token 或 WebSocket 握手秘密。
- 通过 Web UI 调用的命令必须留在该页面的同源认证会话和实际 Web 传输中。只存在于 Web/WebSocket 的 API 就走 Web，不得因为字符串相同而改从 Telnet、SSH 或其它设备会话调用。
- 只有适用文档证明只读，或满足下述 `firmware_observed_readonly` 证据条件的 Web API 才可自动调用。任何 Apply、Save、Pair、SET、路由切换、重启、复位或升级仍需对准确设备和动作逐项授权。
- Web UI 不支持、无法访问、浏览器工具不能接管现有会话或用户不愿授权时，分别记录 `not_supported|unavailable|partial|user_declined`，继续其它安全证据路径；不得索要登录凭据来绕过限制。

分类前必须把 `web_ui_access_status` 从 `not_started` 更新为 `ready|partial|unavailable|not_supported|user_declined`。该门禁证明 agent 已在开始阶段询问和评估 Web UI，不代表所有设备都必须可登录。

## 强制前置条件

连接设备前必须获得或明确标记为未知：

1. 用户当前看到的症状、首次出现时间、持续/间歇情况、影响范围和当前是否仍可复现。
2. 用户已执行操作的时间线，包括点过的页面/按钮、改过的设置及前后值、动过/插拔/对调/更换的线与两端端口、重启/断电/复位、固件或配置变化，以及每一步的结果和是否还原。
3. 拓扑、相关设备/端口/信号源/显示端/交换机，以及已有截图、日志、照片或指示灯现象。
4. 故障发生前的已知正常基线是否存在，包括配置导出、全量只读快照、型号/固件清单、拓扑和采集时间；不存在时明确记录，不能把故障后的首次采集冒充故障前基线。
5. 在列出常规所需文件后，再开放式询问客户：“除此之外，您是否还有任何可能帮助诊断问题的文件或资料可以提供？”可提示但不限于配置导出、完整日志、截图/录屏、拓扑图、交换机配置、事件时间点、固件信息、抓包或第三方设备报告。
6. 范围内每种型号、系列及固件/API 版本可用的命令来源：静态 API 文档、本地 IPAV/ODM 资料，以及同固件 Web UI 可被动验证的实现证据；缺少哪一类要明确记录。
7. 相关设备的 Web UI 地址；用户是否已自行打开并登录，以及是否允许 agent 使用当前页面做只读诊断。
8. 其它管理端点或发现起始地址、连接方式，以及非 Web 读取所需的已认证会话。
9. 本地案件目录和明确的设备/网络范围。

对 1–5 逐项追问，但允许用户回答“不知道/不确定/记不清/没有基线/没有其它文件”。把额外资料问题记录为 `provided`、`none`、`unknown` 或 `will_provide_later`；客户确认没有额外文件时不得反复追问，也不阻塞排查。接收前提醒客户移除或遮盖密码、令牌、私钥、会话 Cookie 和无关个人信息。当必填项已有值或被显式标记为未知，且高影响歧义已追问一次，即可把 `intake_status` 标为 `complete`；不要为了无法获得的信息无限阻塞。对 6–9 的缺口按安全规则处理，不能因为 intake 完成就绕过命令来源和访问边界。

不得凭记忆猜测命令、凭字符串名称推断安全性或拿其他型号手册代替。静态文档不是唯一命令来源，但每条可执行命令都必须有可复核的只读依据：适用文档，或同型号同固件官方 Web UI 在同一传输上被动观察到的状态读取行为。证据不足时登记阻塞；`audit` 模式存在命令来源缺口时不得声称全量完成。

新案件使用 `scripts/Initialize-WyreStormCase.ps1 -ScanMode triage|deep|audit`。脚本生成随机 `session_nonce`；在当前对话中保存返回的案件路径和 nonce。旧案件只有已确认属于当前 session 时才可续查；没有 `scan_mode` 的旧案件按旧版语义视为 `audit`。

## 用户操作采集与分类门

初始化后，先填写 `intake.md` 和 `user-actions.csv`。一项操作占一行并保持真实顺序；动作不确定时照实记录，不补猜时间、对象或结果。尤其区分：

- 用户“点击了什么”与页面随后显示了什么；
- 设置“改成了什么”与原值是否已知；
- 线缆“动过、重插、对调或更换”以及两端设备/端口；
- 操作后暂时恢复、没有变化、变差，或结果未知；
- 操作是否已还原，以及当前现场与故障发生时是否相同。

用户操作只是时间线证据，不自动等于根因。只有时间关系、可重复性和机制证据同时支持时，才把某一步操作写成原因；否则写成“相关操作”或“待验证假设”。已经执行且结果明确的步骤不要原样重复，除非复测条件不同，并说明为什么值得复测。

## 客户文件详细审阅门（强制）

`intake_status=complete` 后，先读取 [客户文件详细审阅规则](references/customer-file-review.md)。把客户附件按 `reference_document`、`diagnostic_evidence` 或 `mixed` 登记到 `source/customer-file-index.csv`：

- 命令手册、用户手册和设计说明属于参考文档，核对版本适用性、目录及当前问题相关章节即可；`audit` 才要求完整命令编目。
- 日志、配置、截图、抓包、拓扑和现场导出属于诊断证据，继续执行严格全量审阅门。
- 混合文件对证据部分做全量审阅，对参考部分做适用性审阅。

诊断证据不能只看文件名、缩略图、摘要、搜索命中、第一页或日志尾部就声称已读完。把审阅结果写入 `customer-file-review.md`。

- 按格式选择可靠的读取方式，并核对完整范围：PDF/文档逐页及表格/批注/附件，表格逐工作表及隐藏表/公式/筛选，配置逐节及禁用项，图片按原分辨率，日志/抓包覆盖完整时间范围、结构、异常和相关事件窗口。
- 每个文件都记录哈希、总页数/工作表/时间范围等可核对单位、实际检查单位、关键事实的准确页码/表名/行号/时间戳、矛盾、无法读取部分及其影响。
- 大文件可用解析、统计、检索和分段抽查提高效率，但必须覆盖整个文件范围并回读关键上下文；搜索结果只是定位线索，不是完整阅读证明。
- 文件之间以及文件与用户描述不一致时不得擅自选一个版本；记录矛盾并向客户确认，分类前保留反证。
- 客户后续新增或替换文件时，把 `customer_file_review_status` 重新设为 `pending`，暂停新的分类结论和受其影响的设备查询，完成增量审阅后重新评估原分类与结论。

没有收到文件时标记 `customer_file_review_status=none_provided`。参考文档完成适用性/相关章节核对后记为 `reference_complete`；诊断证据和 mixed 文件满足覆盖检查后记为 `complete`。文件损坏、加密、缺页或高影响证据无法可靠读取时标记 `blocked`。只有所有已登记文件满足其角色对应的审阅条件后才能继续初始分类。

## 历史相似案例预检（tony 知识库，强制）

`intake_status=complete` 且客户文件审阅门通过后、初始分类前，先用 tony 知识库（`$tony-skill`）检索相似历史问题案例：以用户原话症状、涉及型号和信号链角色组合检索，优先留意 `file` 以 `问题案例/` 前缀（`section=问题案例`）的命中——这些是真实排查记录，含症状、拓扑、候选假设排除过程和最终根因。把结果写入 `wyrestorm-official-research.md`（或单独的 `similar-cases.md`）：相似案例清单、与本次症状/拓扑的异同、可复用的判别路径和已被排除的假设。

- 相似案例只是先验线索：用来调整候选假设的优先级和首选判别动作，不替代本次 intake、证据采集和分类；历史案例的根因不能直接当作当前故障的结论。
- 控制在 1–2 次检索内，避免过度搜索；无相似命中时如实记录 `none_found` 并继续正常流程，不要强行关联。
- tony 知识库不可用时记录 `unavailable`，不阻塞后续排查。

## 产品资料预检：本地 IPAV 优先，官网补充

`intake_status=complete` 且客户文件审阅门通过后、初始分类和设备连接前，读取 [产品资料预检规则](references/wyrestorm-official-preflight.md)，并把结果写入 `wyrestorm-official-research.md`。

- 如果当前环境提供 `$tony-skill`，先按其规则检查 health，再用准确型号搜索本地 IPAV/ODM 文档；记录源文件、locator、片段、文档性质和版本适用性。
- 再查 WyreStorm 官网补充公开产品页、固件、发行说明和兼容性。OEM/ODM、停产或官网不可达时可将 `official_research_status=unavailable`，只要本地资料和其它命令证据足以建立适用性，就不为过门禁反复访问官网。
- 本地工程资料可能是草稿或供应商资料，不能因为来自知识库就自动称为官方确认；事实、来源等级和推论必须分开。

只有 `official_research_status=complete|unavailable` 后才能给出初始分类。产品资料预检是只读资料核对，不授权下载后安装固件/软件，也不授权更改设备。

## 静态文档与固件实际命令集核对

建命令目录时读取 [固件 Web UI 命令发现与安全分级](references/firmware-web-command-discovery.md)，把静态 API 文档、本地知识库和同固件 Web UI 的命令差异写入 `command-source-audit.csv`。

- 优先被动检查设备自身提供的 Web UI 静态资源及正常页面加载/状态刷新产生的 WebSocket 流量；不得绕过认证、破解代码或为了“发现命令”触发 Apply/Save/Reset。
- SPA 中出现一个字符串或枚举，只能标为 `enumerated_unverified`。只有同型号同固件 UI 在同一传输上自动发出该命令来读取状态、且请求和响应已保存，才可标为 `firmware_observed_readonly`。
- `firmware_observed_readonly` 只允许在相同固件、相同传输、相同参数形态下做最小重放；WebSocket 证据不能自动授权 Telnet/SSH/HTTP 重放。异常响应或副作用迹象立即停止。
- 固件 UI 中观察到的 SET/Apply/Save 仍是写操作；必须说明目标、前后值、影响和回退，并对具体动作另行授权。
- agent 可以在用户已登录且明确允许只读诊断的页面会话中调用 Web-only 只读 API；调用前后把设备身份、同源页面、传输、请求形态和脱敏响应证据关联到 `web-ui-session-ledger.csv`、`command-source-audit.csv` 与 `progress-ledger.csv`。

## 分类门

`intake_status=complete` 后、发送设备查询前，读取 [故障分类参考](references/troubleshooting-taxonomy.md)，在 `classification.md` 和 `checkpoint.json` 中写入：

- 一个主分类：`power`、`audio`、`video`、`network`、`control`、`protocol_conflict` 或 `other`；
- 零个或多个次分类；
- `provisional` 状态、`low|medium|high` 置信度，以及支持证据、反证和仍缺信息；
- 分类与用户动作时间线的关系，但不得把先后发生误写成因果。

分类用于缩小 `diagnostic` 命令范围，不替代证据采集。新证据推翻原判断时更新分类并保留变更原因；收尾时将其更新为 `confirmed` 或 `inconclusive`。`other` 不是“信息不足”的快捷分类，必须说明为何其它六类不适用或为什么现有证据仍只能低置信度归入其它原因。

## 假设账本

在 `hypothesis-ledger.csv` 中保留可判别的候选假设。每条写明分类、诊断维度、agent 排名、支持证据、反证、状态和下一条最小判别动作；状态使用 `active|supported|weakened|rejected|confirmed|blocked`。新证据到达后更新旧行，不用纯叙述不断新增同义假设。优先执行信息增益高、风险和成本低的判别动作。

## 候选问题多选门（正式排查前强制）

当用户询问完成、所有当前已收到资料满足对应审阅门、产品预检和初始分类完成后，读取 [候选问题多选规则](references/candidate-diagnostic-selection.md)。在正式锁定问题、生成诊断执行行或发送设备查询前，列出全部有现场依据、尚未排除且互不重复的可能问题，让用户一次多选优先排查项。

- 每项使用稳定 `H-xxx` 编号，写清可能问题、分类/诊断维度、为什么仍可能、反证或缺口、当前可能性、首个最小验证动作、预计成本/影响，以及是否可能需要另行授权的写操作。
- 使用客户端原生多选控件（如果确实支持）；否则使用 Markdown 复选框，明确让用户回复多个编号，例如 `H-001,H-003,H-006`。同时提供 `全部排查` 和 `你来决定顺序` 两种回答方式。
- agent 可以标注“建议优先”的默认组合，但不能替用户勾选。用户选择只决定排查顺序，不证明所选项为根因，也不把未选项标为 `rejected`；未选项保留在 backlog。
- 把展示、选择和优先级写回 `hypothesis-ledger.csv`，并将 `diagnostic_selection_status` 依次设为 `pending_user`、`selected`；用户明确说“你来决定”时设为 `customer_deferred`，由 agent 按信息增益、风险和成本排序。
- 多选不是写操作授权。若所选路径之后需要 Pair/SET/Save/重启/复位等改变状态的动作，仍需对准确设备和动作单独授权。
- 新证据出现新的合理候选或实质改变排序时，只向用户展示增量变化并允许追加/调整选择；不要在每轮无变化时反复要求多选。

`diagnostic_selection_status` 未达到 `selected|customer_deferred` 时，不得向 `progress-ledger.csv` 添加执行行或开始设备诊断。用户暂不选择且不委托 agent 排序时，保持 `pending_user` 并等待，不擅自继续。

## 基线、无痕改动与设备本体状态

读取 [基线、设备持久化状态与版本兼容规则](references/device-state-baseline-compatibility.md)。把已知正常、故障前、会话开始、动作后和解决后快照分别登记到 `baseline-index.csv`，并把字段差异写入 `baseline-comparison.csv`。

- 只有来源和时间证明早于故障的快照才能称为 `known_good|pre_fault`；首次只读普查只能称为 `session_start`，用于此后的变化对比，不能证明故障前配置。
- 客户记忆不完整或声称“配置问题”但参数层没有差异时，不要逐项猜测和逆推操作；改走“可靠基线对比 → 外部链路排除 → 设备运行态/持久化状态假设”的证据路径。
- 当适用参数与可靠基线一致、症状仍绑定同一设备、软重启无效且外部依赖已有反证时，把 `persistent_internal_state` 记为诊断维度；它不是第八个故障分类，也不等于已证明存储区损坏。
- `reboot` 用于检验易失运行态/服务状态，`restorefactory` 会清除或重建持久化配置；两者都改变现场且会中断服务，必须依据准确型号文档并对具体动作单独授权。
- 工厂复位只能在备份/恢复计划、业务影响、访问恢复方式和验证步骤明确后提出。复位后恢复正常只支持“持久化配置或内部状态相关”，不能单凭结果断言物理存储损坏；恢复旧备份或再次复现需要另行授权和证据。

## API 文档版本兼容性探测

文档与设备仅为同型号、同 API 主版本下的小版本差异时，先查官网兼容声明或发行说明。没有明确声明时，可按上述参考执行最多 2–3 条低成本、无参数或固定参数、文档明确只读的身份/版本/状态命令做有界探测，并保存响应。

探测只证明已测试命令的经验兼容性，不证明整份 API 文档兼容；遇到未知响应、认证/传输差异、主版本差异、型号差异或任何状态改变可能性立即停止并登记阻塞。不得用成功探测解锁未测试写命令或宣称 `audit` 完整覆盖。

## 安全边界

- 只有适用文档证明为只读，或满足 `firmware_observed_readonly` 严格条件的命令才可自动执行；命令名以 `GET` 开头不是安全证明。
- 写入、路由切换、重启、恢复出厂、升级、上传、清除和测试图案等命令只登记、不执行；必须获得用户对具体动作、目标设备和预期影响的另行授权。恢复出厂前还必须完成可验证备份、恢复访问方案和业务中断确认。
- 遵守文档规定的认证、会话、速率限制、分页和连接规则。只有文档或已验证接口明确支持并发时才并发；按控制器和设备分别设置有界并发，遇到限流、超时或负载异常立即降速。
- 不把密码、令牌、私钥或完整会话 Cookie 写入案件文件。值写为 `[REDACTED]`，并在字段审计中登记脱敏。
- Web UI 用户名、密码、Cookie、授权头和 WebSocket 握手凭据只在内存或现有认证会话中使用，不写入案件文件、命令历史、抓包导出或浏览器存档；记录时只写 `[REDACTED]` 和凭证来源类型。

## 选择案件形态

初始化时用 `-CaseShape auto|single_physical|fleet`。`auto` 在 intake 后解析成以下一种并写入 checkpoint：

- `single_physical`：一台可查询主机，加零个或多个无 API 的 dongle、显示器、线缆或配对口。跳过 cohort 和机群矩阵，只保留身份、症状相关命令、假设和实际执行行。
- `fleet`：多台可查询设备，使用分组、核心普查和异常深入策略。

`single_physical` 使用 `physical-action-ledger.csv` 执行循环：“分析员说明一个具体物理动作及观察点 → 用户明确执行并报告 → 分析员做只读复测 → 记录结果并更新假设”。分析员不得声称自己插线、看 LED 或读 OSD；一次循环只改变一个主要变量。

## 面向大量设备的执行策略（仅 `fleet`）

### 命令目录按 API 配置复用

用文档哈希、型号系列和固件/API 版本形成稳定 `api_profile_id`。`command-catalog.csv` 的一行代表某个 API 配置中的一条命令，不代表某台设备；相同配置的设备共用目录。

为命令标记：

- `scan_tier`：`core`、`diagnostic` 或 `audit`
- `cost_class`：例如 `low`、`medium`、`high`
- `parameter_strategy`：固定、按能力展开、按异常展开或分页
- 只读/会改变状态/含义不明，以及适用范围、参数、响应字段和文档位置
- `source_authority`、`source_evidence`、`observed_transport`、`readonly_basis` 和 `verification_status`

`triage` 只需先编制身份、发现、在线状态、告警、核心链路和用户症状相关命令；后续按异常懒加载 `diagnostic` 命令。`deep` 只编制问题域及其依赖命令。只有 `audit` 必须读取文档全部页面并完整编目。

### 先分组，再普查，再深入

1. 先发现设备，并按 `api_profile_id`、能力签名和控制器归属形成 `cohort_id`。
2. 对所有在线设备执行 `core` 普查，不能用代表设备的健康状态代替其他设备的状态。
3. 可在每个组选择代表设备验证响应结构和参数展开方式；该结果只复用架构知识，不复用设备状态。
4. 将离线、告警、固件偏差、能力不一致、响应字段异常、用户症状命中或核心指标偏差标记为深入理由。
5. 只为这些设备生成 `diagnostic` 执行行；只有 `audit` 为全部设备生成完整执行矩阵。
6. 同一 session 内的后续运行优先做增量：新增设备、身份/固件/能力变化、上次失败项和未解决异常。新 session 必须重新 intake，不得继承这些状态。

建立大矩阵前估算 `设备 × 命令 × 参数 × 页数`。`triage` 和 `deep` 应通过分层选择避免无关组合；`audit` 则以可续查批次执行并如实报告预计规模。

## 案件文件

以下文件只是当前 session 的临时事实来源；不得被其它 session 自动发现或继承：

- `source/api-docs/`、`source/api-doc-index.csv`：文档副本或 URL、哈希及适用版本。
- `source/customer-files/`、`source/customer-file-index.csv`、`customer-file-review.md`：客户文件临时副本、完整清单、阅读覆盖、定位证据、矛盾和无法读取部分。
- `source/baselines/`、`baseline-index.csv`、`baseline-comparison.csv`：不同时间语义的快照、来源可靠性和标准化字段差异；会话开始快照不得标成故障前基线。
- `source/firmware-evidence/`、`command-source-audit.csv`：静态文档、本地资料和同固件 Web UI 命令集差异及只读依据。
- `web-ui-session-ledger.csv`：相关设备 Web UI 的打开/登录确认、agent 访问方式、设备身份核对、同源传输、固件/UI build 和会话状态；不含任何凭据或会话秘密。
- `intake.md`、`user-actions.csv`：用户症状、现场信息、未知项和按顺序记录的已执行操作。
- `wyrestorm-official-research.md`：当前型号/固件/症状的本地 IPAV/ODM 知识库与官网补充预检状态、来源、适用性、事实和诊断影响。
- `classification.md`：主/次分类、置信度、支持证据、反证、变更历史和分类状态。
- `command-catalog.csv`：按 `api_profile_id` 去重的命令目录和扫描层级。
- `device-inventory.csv`：设备、子设备、稳定 ID、版本、能力、组别、在线状态和发现证据。
- `progress-ledger.csv`：每个实际选择的 `(device_id, command_id, 标准化参数集合)` 一行，并记录模式、层级和选择理由。
- `physical-action-ledger.csv`：单设备/物理外设场景中由用户完成的动作、观察、随后只读复测和结果。
- `hypothesis-ledger.csv`：按优先级维护假设、支持/反证、状态和下一条最小判别动作，并记录候选是否已展示、用户多选结果、客户优先级、选择原话和更新时间；未选择不等于排除。
- `coverage-audit.csv`：预期/实际字段以及缺失、条件性、脱敏、不支持和额外字段。
- `raw/`：逐字响应和脱敏后的请求元数据；每次尝试单独保存，不覆盖历史。
- `findings.md`、`checkpoint-log.md`、`session-handoff.md`、`checkpoint.json`、`final-report.md`：结论、检查点、续查状态和报告。

账本状态固定为 `not_started`、`in_progress`、`completed`、`failed`、`unsupported` 或 `blocked`。只有取得规定响应并完成当前模式要求的轻量或完整字段检查后才是 `completed`。

## 仅在同一 session 恢复进度

仅在当前对话发生模型切换、compacting 或中断恢复后：

1. 从当前对话上下文取得准确 `CaseRoot` 和 `session_nonce`；不得通过目录搜索恢复它们。
2. 读取该目录的 `session-handoff.md`、`checkpoint.json`、`intake.md`、`user-actions.csv`、`web-ui-session-ledger.csv`、`source/customer-file-index.csv`、`customer-file-review.md`、`baseline-index.csv`、`baseline-comparison.csv`、`command-source-audit.csv`、`physical-action-ledger.csv`、`hypothesis-ledger.csv`、`wyrestorm-official-research.md`、`classification.md`、文档索引、各 CSV 和 `checkpoint-log.md` 末尾。
3. 核对 checkpoint 中的 nonce 与当前会话保存的值一致，再核对 intake、Web UI 会话仍属于用户当前打开的同一设备页面、客户文件清单及阅读覆盖、产品资料预检、命令来源核对、分类、候选问题多选状态、`scan_mode`、`case_shape`、目标范围、文档指纹、设备身份和 API 配置；不一致时停止续查。compacting 后不得假设旧 Cookie/会话仍有效，调用前重新核对页面身份和登录状态。
4. 若用户补充了操作、文件或现场发生变化，先更新时间线或文件审阅状态，再重新评估分类和已完成证据的有效性。
5. 将 `in_progress` 行与原始尝试文件核对；证据和当前模式要求的字段检查均完成才改为 `completed`，否则保留旧尝试并继续。
6. 选择当前模式下第一个适用且未完成的记录，不重复仍有效的已完成记录。

范围、固件、能力或文档变化时，只让受影响的命令和进度行失效。

## 工作流

### `triage`：默认快速排障

1. 先让用户打开并登录相关 Web UI，确认 agent 是否可使用当前会话做只读诊断；再完成 intake、按角色审阅文件、历史相似案例预检、本地优先的产品预检和命令来源核对，登记已有基线并建立候选假设清单。
2. 把全部合理候选以多选形式交给用户；只有 `diagnostic_selection_status=selected|customer_deferred` 后，才按选择顺序建立诊断执行行。
3. `single_physical` 只查询主机身份和症状相关状态；无 API 外设进入“用户动作—观察—只读复测”循环，不建立 cohort 或全员 core 矩阵。
4. `fleet` 才发现设备、形成 API 配置组，对所有在线设备运行核心健康普查。
5. 保存首次动作前的 `session_start` 快照；根据用户选择、假设、时间线和异常信号只加载需要的诊断命令。
6. 每轮更新假设状态和最小判别动作；证据足够或明确阻塞时停止，列出未执行范围，不能宣称全量覆盖。

### `deep`：定向深挖

先完成相关 Web UI 打开/登录与只读会话确认，再完成 intake、按角色审阅客户文件、历史相似案例预检、本地优先的产品资料预检、命令来源核对和初始分类。列出全部合理候选让用户多选；随后围绕所选设备或问题域建立最小充分命令集，优先使用同源 Web 会话中的 Web-only 只读 API。未选候选保留在 backlog，不写成已排除。

### `audit`：全量覆盖

先完成相关 Web UI 打开/登录与只读会话确认，再完成 intake、按角色审阅客户文件、历史相似案例预检、本地优先的产品资料预检、命令来源核对和初始分类；列出全部合理候选并允许用户多选排查顺序。`audit` 的选择只改变顺序，不缩减用户明确要求的全量范围。完整读取适用命令资料并编制每条命令，对每台适用在线设备穷尽所有有限参数、页码和游标。

收尾时重复发现，直到连续两次没有未扫描的新在线设备。存在任何 `not_started`、`in_progress`、失败、阻塞或字段缺口时，结果必须标记为部分完成/未完成。

## 采集与检查点

发送命令前把账本行置为 `in_progress`。保存时间戳、端点、传输、命令 ID、标准化参数、尝试号、超时和文档引用；执行后先保存原始响应，再按模式完成字段检查后更新账本。

`triage` 对所有设备的 `core` 响应只做轻量字段检查：确认可解析，并核对身份、在线/健康和当前异常判断依赖的必要字段；完整字段审计只用于被选中深入的设备、异常/畸形响应和全部 `diagnostic` 行。`deep` 审计问题域内用于结论的字段。只有 `audit` 对所有适用响应执行完整预期字段覆盖审计。三种模式都必须保留原始响应，轻量检查不得伪装成完整覆盖。

为减少大量设备时的磁盘开销，不必在每条成功查询后重写汇总检查点。按单台设备、一个分页序列或有界批次调用 `scripts/Update-WyreStormCheckpoint.ps1 -SessionNonce <current_nonce>`；发生错误、限流、设备清单变化、模式变化或即将中断时立即写检查点。每条命令的原始证据和账本仍必须及时落盘。

重试必须有上限，每次尝试使用独立证据文件。失败、无权限、格式错误和超时都要保留为明确缺口，不得猜测。

## 诊断完成与结案清理

`findings.md` 先写有证据路径的确认事实，再写诊断判断和反证。`final-report.md` 必须包含用户已执行操作摘要、候选问题完整清单与用户多选结果（包括未选但未排除项）、Web UI 会话与 Web-only API 依据、客户文件阅读覆盖、关键资料来源、最终分类与置信度、模式、范围、执行统计、脱敏情况和未解决缺口。

- `triage` 完成表示核心普查和所选异常的诊断范围完成，不表示所有 API 字段已采集。
- `deep` 完成表示指定问题域已有充分证据或明确阻塞，不表示设备全量覆盖。
- `audit` 只有满足完整命令、设备、参数、分页和字段覆盖条件时才能标记完整完成。

诊断看似恢复正常不等于结案。只有客户在当前会话中明确确认问题已解决，才能执行以下结案流程：

1. 使用 `assets/resolution-summary.template.md` 在案件根目录写成 `resolution-summary.md`。它必须自包含：客户原始问题、已做操作、环境与范围、初始/最终分类、关键排查步骤与结果、根因或未确定项、实际解决动作、验证方法、客户确认、时间线和后续风险都要写进正文。
2. 不得只链接 `raw/`、CSV、`findings.md` 或 `final-report.md`；这些文件即将删除。必要证据要摘要进总结，并继续脱敏凭据。
3. 检查总结没有模板占位符，且即使其余案件文件全部消失也能独立读懂。
4. 运行 `scripts/Close-WyreStormCase.ps1 -CaseRoot <exact_path> -SessionNonce <current_nonce> -CustomerConfirmed -DeleteTemporaryArtifacts -CustomerConfirmation <客户确认原话或准确转述>`。
5. 脚本成功后，案件目录只能剩 `resolution-summary.md`。说明已删除哪些临时材料，并明确这些删除不可通过 Skill 恢复；案件外的原始 API 文档不受影响。

客户未明确确认、问题只是暂时恢复、仍需观察或结论被标为阻塞时，不得运行清理脚本。新 session 也不得替上一 session 推断客户已经确认。
