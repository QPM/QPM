QPM
===
qnap package manager

```
Copyright (C) 2013 YuTin Liu
License GPLv3
```

Run on：`OSX`, `Ubuntu`, `Linux`, `NAS for x86`, `NAS for arm`

Programming language：`Shell`

Usage
===
####Install
- 至[release](https://github.com/QPM/QPM/tree/master/release)下載最新版的qpm
- 上傳qpm至NAS的/usr/bin目錄 or 將qpm放置於PC的/usr/bin目錄
- chmod 755 /usr/bin/qpm
- qpm [option] [qpkg_name]

####Base
```
> qpm -c [QPKG_NAME]
> cd [QPKG_NAME]
> qpm -nas=[NAS_IP]
> ls ./build/[QPKG_NAME].qpkg
```
####Advanced
* QPM的基本操作
 - `qpm --version|-ver|-V` QPM的版本資訊
 - `qpm --help|-h|-\?` QPM的操作說明
 - `qpm --push-key` 透過QPM上傳SSH公開金鑰至NAS
* 製作/封裝QPKG
 - `qpm -c|--create [QPKG_NAME]` 建立QPKG目錄
 - `qpm -n|--nas=[NAS_IP]` 封裝QPKG，省略`--nas`參數
 - `qpm -bs|--build-script=[file...]` 指定封裝前/後要執行的script [v0.4]
 - `qpm -nv|--no-version` 封裝QPKG後，不自動增加版號
 - `qpm -ps|--platform-split` 將QPKG封裝成x86和arm兩個安裝檔
 - `qpm -p|--platform=[x86/arm]` 指定只封裝x86/arm的安裝檔 
* NAS上管理QPKG
 - `qpm -l|-list` 顯示已安裝的QPKG [v0.2]
 - `qpm install ${QPKG_NAME}` 安裝QPKG [v0.2]
 - `qpm uninstall ${QPKG_NAME}` 移除QPKG [v0.2]
 - `qpm start ${QPKG_NAME}` 啓動QPKG [v0.2]
 - `qpm stop ${QPKG_NAME}` 停止QPKG [v0.2]
 - `qpm restart ${QPKG_NAME}` 重啓QPKG [v0.2]
* 操作已封裝的QPKG檔
 - `qpm -o|--output` 將QPKG封裝的Data檔直接輸出 [v0.4]
 - `qpm -s|--split` 將已封裝的QPKG拆成x86和arm兩個安裝檔 [v0.4]

Parameters
===
####Configs
* 基本資訊
 - `QPKG_NAME=""` （套件名稱，必須）
 - `QPKG_DISPLAY_NAME=""` （顯示名稱）
 - `QPKG_AUTHOR=""`（預設為使用者帳號）
 - `QPKG_LICENSE="GPL v2"`
 
* 版本資訊
 - `QPKG_VER_MAJOR="0"`
 - `QPKG_VER_MINOR="1"`
 - `QPKG_VER_BUILD="0"` 第幾次編譯（自動增加）
 - `QPKG_AUTO_UPDATE=""` 自動更新QPKG

* 相依/相斥
 - `QPKG_REQUIRE="Python >= 2.5, Optware | opkg"` 相依
 - `QPKG_CONFLICT="Python, OPT/sed"` 相斥

* 應用服務
 - `QPKG_WEB_PATH="/"` WebApp目錄
 - `QPKG_WEB_PORT=""` WebApp的Port number
 - `QPKG_DESKTOP="1"` 嵌入QTS4的Web桌面系統
 - `QPKG_SERVICE_SCRIPT=""` QPKG啓動後在背景運作的script [v0.3]

* QPKG目錄
 - `QPKG_DIR_ICONS="icon"` Package 圖式的目錄
 - `QPKG_DIR_ARM="arm"` Package 檔案目錄，ARM專屬
 - `QPKG_DIR_X86="x86"` Package 檔案目錄，X86專屬
 - `QPKG_DIR_SHARED="share"` Package 檔案目錄，通用
 - `QPKG_DIR_WEB="web"` Package Web檔案的目錄
 - `QPKG_DIR_BIN="bin"` Package Bin檔案的目錄

####Variable
* NAS目錄
 - `SYS_CONFIG_DIR="/etc/config"` QPKG資訊檔的存放位置
 - `SYS_RSS_IMG_DIR="/home/httpd/RSS/images"` QPKG icon的存放目錄
 - `SYS_BIN_DIR="/usr/bin"` bin檔的存放位置
 - `SYS_OPT_DIR="/mnt/ext/opt"` 
 - `SYS_INIT_DIR="/etc/init.d"` service script存放的目錄

 - `SYS_BASE_DIR="/share/HDA_DATA"`
 - `SYS_PUBLIC_DIR="/share/Public"`
 - `SYS_DOWNLOAD_DIR="/share/Download"`
 - `SYS_MULTIMEDIA_DIR="/share/Multimedia"`
 - `SYS_RECORDINGS_DIR="/share/Recordings"`
 - `SYS_WEB_DIR="/share/Web"`

 - `SYS_QPKG_STORE="${SYS_BASE_DIR}/.qpkg"`
 - `SYS_QPKG_DIR="${SYS_QPKG_STORE}/${QPKG_NAME}"`

 - `SYS_WEB_EXTRA="${SYS_CONFIG_DIR}/apache/extra"`
 - `SYS_WEB_CONFIG="${SYS_CONFIG_DIR}/apache/apache.conf"`
 - `SYS_WEB_INIT="${SYS_INIT_DIR}/Qthttpd.sh"`

 - `SYS_QPKG_CONFIG="${SYS_CONFIG_DIR}/qpkg.conf"`
 - `SYS_QPKG_SERVICE="${SYS_INIT_DIR}/${QPKG_NAME}"`


 - `SYS_PLATFORM="x86/arm"`
 
Package Icons
===
- 當QPKG啓動時（64x64） `icon/qpkg_icon.png`
- 當QPKG停止時（64x64） `icon/qpkg_icon_gray.png`
- 較高解析度的圖示（80x80） `icon/qpkg_icon_80.png`
- 介紹圖（184x115） `icon/qpkg_184x115.png`
- 較高解析度的介紹圖（640x400） `icon/qpkg_640x400.png`

Service Script
===
- 當start service時 `service.sh >-> start`
- 當stop service時 `service.sh >-> start` 
- 當install QPKG前 `service.sh >-> pre_install`
- 當install QPKG後 `service.sh >-> post_install`
- 當uninstall QPKG前 `service.sh >-> pre_uninstall`
- 當uninstall QPKG後 `service.sh >-> post_uninstall`

Q&A
===
#### 如何建立Web服務？
- `${QPKG_DIR}/share/web`為網站目錄，將網站內容放至該目錄
- 首頁必須為`index.html` / `index.htm` / `index.php`
- 當 start service 時，會依據QPKG_WEB_PATH的設定建立apache虛擬目錄

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
- 不會，但會陸續增加功能  [v0.3]

#### 如何取得Package的系統設定值？
- 設定 `set_qpkg_cfg field value [qpkg_name]`
- 取得 `get_qpkg_cfg field [default_value] [qpkg_name]`

#### 如有疑問或發現bug如何處理？
- 請直接建立issue https://github.com/yutin1987/QPM/issues
