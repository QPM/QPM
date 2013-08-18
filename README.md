QPM
===
qnap package manager

Configs
===
QPKG_NAME=""                                    # Package 名稱（必須）
QPKG_DISPLAY_NAME=""                            # Package 顯示的名稱

QPKG_VER_MAJOR="0"                              # 版本資訊
QPKG_VER_MINOR="1"
QPKG_VER_BUILD="0"                              # 第幾次編譯（自動增加）

QPKG_AUTHOR=""                                  # 作者或維護人員（預設為使用者帳號）

QPKG_LICENSE="GPL v2"                           # 授權模式

QPKG_REQUIRE="Python >= 2.5, Optware | opkg"   # Package 相依
QPKG_CONFLICT="Python, OPT/sed"                # Package 相斥

QPKG_WEBUI="/"                                 # WebApp目錄
QPKG_WEB_PORT=""                               # WebApp的Port number

QPKG_DESKTOP="1"                               # 遷入QTS4的Web桌面系統

QPKG_DIR_ICONS="icon"                          # Package 圖式的目錄
QPKG_DIR_ARM="arm"                             # Package 檔案目錄，ARM專用
QPKG_DIR_X86="x86"                             # Package 檔案目錄，X86專用
QPKG_DIR_SHARED="share"                        # Package 檔案目錄，通用
QPKG_DIR_WEB="share/web"                       # Package Web檔案的目錄
QPKG_DIR_BIN="share/bin"                       # Package Bin檔案的目錄

Usage
===
* QPM建立QPKG目錄 `qpm -c [QPKG_NAME]`
* QPM編譯QPKG `qpm`
* QPM版本資訊 `qpm --version|-ver|-V`
* QPM操作說明 `qpm -h`

Q&A
===
#### 如何建立Web服務？
- QPKG_DIR/share/web為網站目錄，只需將網站內容放至該目錄，且首頁必須為index.html/index.htm/index.php，當使用者 start service 時，會依據QPKG_WEBUI的設定建立apache虛擬目錄。
#### 如何放至Bin檔案？
- QPKG_DIR/share/bin為可執行檔的目錄，只需將可執行檔放至該目錄，並設定權限為755，當使用者 start service 時，會將可執行檔link至/usr/bin目錄內。
* Package 相依會自動到AppCenter下載安裝嗎？
- 不會，但會陸續增加功能
