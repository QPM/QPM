QPM
===
qnap package manager

平台：`OSX`, `Ubuntu`, `Linux`, `NAS for x86`, `NAS for arm`

Configs
===
* Package name
 - `QPKG_NAME=""` （套件名稱，必須）
 - `QPKG_DISPLAY_NAME=""` （顯示名稱）

* 版本資訊
 - `QPKG_VER_MAJOR="0"`
 - `QPKG_VER_MINOR="1"`
 - `QPKG_VER_BUILD="0"` 第幾次編譯（自動增加）

* 作者或維護人員
 - `QPKG_AUTHOR=""`（預設為使用者帳號）

* 授權模式
 - `QPKG_LICENSE="GPL v2"`

* 相依/相斥
 - `QPKG_REQUIRE="Python >= 2.5, Optware | opkg"` 相依
 - `QPKG_CONFLICT="Python, OPT/sed"` 相斥

* Web Application
 - `QPKG_WEBUI="/"` WebApp目錄
 - `QPKG_WEB_PORT=""` WebApp的Port number

* Package 相斥
 - `QPKG_DESKTOP="1"` 嵌入QTS4的Web桌面系統

* QPKG目錄
 - `QPKG_DIR_ICONS="icon"` Package 圖式的目錄
 - `QPKG_DIR_ARM="arm"` Package 檔案目錄，ARM專屬
 - `QPKG_DIR_X86="x86"` Package 檔案目錄，X86專屬
 - `QPKG_DIR_SHARED="share"` Package 檔案目錄，通用
 - `QPKG_DIR_WEB="web"` Package Web檔案的目錄
 - `QPKG_DIR_BIN="bin"` Package Bin檔案的目錄

Usage
===
* QPM建立QPKG目錄 `qpm -c [QPKG_NAME]`
* QPM編譯QPKG `qpm`
* QPM版本資訊 `qpm --version|-ver|-V`
* QPM操作說明 `qpm -h`
* QPM顯示NAS上已安裝的QPKG `qpm -l`
* QPM在NAS上安裝QPKG `qpm install ${QPKG_NAME}`
* QPM在NAS上移除QPKG `qpm uninstall ${QPKG_NAME}`
* QPM在NAS上啓動QPKG `qpm start ${QPKG_NAME}`
* QPM在NAS上停止QPKG `qpm stop ${QPKG_NAME}`
* QPM在NAS上重啓QPKG `qpm restart ${QPKG_NAME}`

Q&A
===
#### 如何建立Web服務？
- `${QPKG_DIR}/share/web`為網站目錄，將網站內容放至該目錄
- 首頁必須為`index.html` / `index.htm` / `index.php`
- 當 start service 時，會依據QPKG_WEBUI的設定建立apache虛擬目錄

#### 如何放至Bin檔案？
- `${QPKG_DIR}/share/bin`為可執行檔的目錄，將可執行檔放至該目錄
- 可執行檔必須設定權限為755
- 當 start service 時，會將可執行檔link至/usr/bin目錄內

#### ARM和X86的檔案如何運作？
- ARM和X86的檔案會包裝成同一個QPKG
- 安裝時會將SHARED目錄和ARM/X86目錄內的檔案合併
- 當系統是X86時，將先安裝shared目錄再使用x86目錄覆蓋
- 專屬x86的bin檔可放至`x86/bin`，專屬arm的bin檔可放至`x86/bin`

#### Package 相依會自動到AppCenter下載安裝嗎？
- 不會，但會陸續增加功能
