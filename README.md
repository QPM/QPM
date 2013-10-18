QPM
===
qnap package manager

```
Copyright (C) 2013 YuTin Liu
MIT License
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
 - `qpm -l|-list` 顯示已安裝的QPKG [v0.3]
 - `qpm install ${QPKG_NAME}` 安裝QPKG [v0.3]
 - `qpm uninstall ${QPKG_NAME}` 移除QPKG [v0.3]
 - `qpm start ${QPKG_NAME}` 啓動QPKG [v0.3]
 - `qpm stop ${QPKG_NAME}` 停止QPKG [v0.3]
 - `qpm restart ${QPKG_NAME}` 重啓QPKG [v0.3]
* 操作已封裝的QPKG檔
 - `qpm -o|--output` 將QPKG封裝的Data檔直接輸出 [v0.4]
 - `qpm -s|--split` 將已封裝的QPKG拆成x86和arm兩個安裝檔 [v0.4]

- - -

Parameters
===
####Configs
* 基本資訊
 - `QPKG_NAME=""`（套件名稱，必須）
 - `QPKG_DISPLAY_NAME=""`（套件名稱顯示於QTS上的，必須）
 - `QPKG_AUTHOR=""`（製作者，預設為使用者帳號）
 - `QPKG_LICENSE="GPLv3"`（版權宣告，預設為GPLv3）
 
* 版本資訊
 - `QPKG_VER_MAJOR="0"`（版本號，重大更動）
 - `QPKG_VER_MINOR="1"`（版本號，功能微調或增加）
 - `QPKG_VER_BUILD="0"`（版本號，編譯/除錯次數，自動累加）
 - `QPKG_AUTO_UPDATE=""`（定期自動更新QPKG） [v0.5]

* 相依/相斥
 - `QPKG_REQUIRE="Python >= 2.5, Qairplay | play"`（套件相依）
 - `QPKG_CONFLICT="Python, Qairplay"`（套件相斥）

* 應用服務
 - `QPKG_WEB_PATH="/"`（WebApp目錄，http://nas-ip/[web_path]）[tip](#%E5%A6%82%E4%BD%95%E5%BB%BA%E7%AB%8Bweb%E6%9C%8D%E5%8B%99)
 - `QPKG_WEB_PORT=""`（WebApp的port number）
 - `QPKG_DESKTOP="1"`（將WebApp的頁面嵌入QTS4桌面系統）
 - `QPKG_SERVICE_SCRIPT=""`（QPKG啓動後在背景運作的script）[v0.3]

* QPKG目錄
 - `QPKG_DIR_ICONS="icon"`（Package 圖式的目錄）
 - `QPKG_DIR_ARM="arm"`（Package 檔案目錄，ARM專屬）
 - `QPKG_DIR_X86="x86"`（Package 檔案目錄，X86專屬）
 - `QPKG_DIR_SHARED="share"`（Package 檔案目錄，通用）
 - `QPKG_DIR_WEB="web"`（Package Web檔案的目錄）[tip](#%E5%A6%82%E4%BD%95%E5%BB%BA%E7%AB%8Bweb%E6%9C%8D%E5%8B%99)
 - `QPKG_DIR_BIN="bin"`（Package Bin檔案的目錄）

####Variable
* NAS目錄
 - `SYS_RSS_IMG_DIR="/home/httpd/RSS/images"`（QPKG icon的存放目錄）
 - `SYS_CONFIG_DIR="/etc/config"`（存放configs的目錄）
 - `SYS_BIN_DIR="/usr/bin"`（Bin檔的存放目錄）
 - `SYS_OPT_DIR="/mnt/ext/opt"`（軟體掛載的目錄）
 - `SYS_INIT_DIR="/etc/init.d"`（Service script存放的目錄）
 - `SYS_WEB_EXTRA="${SYS_CONFIG_DIR}/apache/extra"`（存放Apache延伸設定檔的目錄）

 - `SYS_QPKG_STORE="${SYS_BASE_DIR}/.qpkg"`（存放所有QPKG的目錄）
 - `SYS_QPKG_DIR="${SYS_QPKG_STORE}/${QPKG_NAME}"`（存放此QPKG的目錄）

 - `SYS_BASE_DIR="/share/HDA_DATA"`（主要存放檔案的目錄）
 - `SYS_PUBLIC_DIR="/share/Public"`（Public檔案目錄）
 - `SYS_DOWNLOAD_DIR="/share/Download"`（Download檔案目錄）
 - `SYS_MULTIMEDIA_DIR="/share/Multimedia"`（Multimedia檔案目錄）
 - `SYS_RECORDINGS_DIR="/share/Recordings"`（Recordings檔案目錄）
 - `SYS_WEB_DIR="/share/Web"`（Web檔案目錄）
 - `SYS_CODEBASE_DIR="/share/Codebase"`（Codebase檔案目錄）

* NAS檔案
 - `SYS_WEB_CONFIG="${SYS_CONFIG_DIR}/apache/apache.conf"`（Apache設定檔）
 - `SYS_WEB_INIT="${SYS_INIT_DIR}/Qthttpd.sh"`（Apache service script檔）
 - `SYS_QPKG_SERVICE="${SYS_INIT_DIR}/${QPKG_NAME}"`（此QPKG的service script檔案）

* NAS資訊
 - `SYS_PLATFORM="x86/arm"`（x86/arm平台）
 
* Command

`CMD_AWK`, `CMD_CAT`, `CMD_CHMOD`, `CMD_CHOWN`, `CMD_CP`, `CMD_CUT`, `CMD_DATE`, `CMD_ECHO`, `CMD_EXPR`, `CMD_FIND`, `CMD_GETCFG`, `CMD_GREP`, `CMD_HOSTNAME`, `CMD_LN`, `CMD_MD5SUM`, `CMD_MKDIR`, `CMD_MV`, `CMD_RM`, `CMD_SED`, `CMD_SETCFG`, `CMD_SLEEP`, `CMD_SORT`, `CMD_SYNC`, `CMD_TAR`, `CMD_TR`, `CMD_TOUCH`, `CMD_WGET`, `CMD_LOG_TOOL`, `CMD_XARGS`, `CMD_PRINTF`, `CMD_SH`

Function
===
* `set_qpkg_cfg`（設定QPKG配置資訊）
`set_qpkg_cfg field value [qpkg_name]`
* `get_qpkg_cfg`（取得QPKG配置資訊）
`set_qpkg_cfg field [default_value] [qpkg_name]`
 
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

- - -

Q&A
===
#### 如何建立Web服務？
1. 設定 QPKG_DIR_WEB="web" （將註解#拿掉）  
`QPKG_DIR_WEB攸關share/web的目錄，亦可設為QPKG_DIR_WEB="site"也就是/share/site`
2. ${QPKG_DIR}/share/web 為網站目錄，將網站內容放至該目錄  
`如果有分x86或arm的版本，也可將網站內容放置於 /x86/web 或 /arm/web`
3. 首頁必須為index.html / index.htm / index.php  
`當搜尋不到index.*的檔案時，將不會設定QPKG配置資訊，使用者將沒辦法透過QTS直接開啓Web`
4. 當 start service 時，會依據 QPKG_WEB_PATH 的設定建立apache虛擬目錄
`當 QPKG_WEB_PATH 沒有設定時，將使用 http://nas-ip:80/${QPKG_NAME} 目錄`

#### 如何放至Bin檔案？
1. 設定 QPKG_DIR_BIN="bin" （將註解#拿掉）  
`QPKG_DIR_BIN攸關share/bin的目錄，亦可設為QPKG_DIR_BIN="opt"也就是/share/opt`
2. ${QPKG_DIR}/share/bin 為可執行檔的目錄，將可執行檔放至該目錄  
`如果有分x86或arm的版本，也可將網站內容放置於 /x86/bin 或 /arm/bin`
3. 可執行檔必須設定權限為755  
`當檔案權限為不可執行檔時，將不會建立link至/usr/bin`
3. 當 start service 時，會將可執行檔link至/usr/bin目錄內

#### ARM和X86的檔案如何運作？
1. ARM和X86的檔案會包裝成同一個QPKG安裝檔  
```當設定qpm -ps後，QPGK將拆成x86和arm兩個檔案，x86安裝檔將無法在arm上安裝，arm安裝檔亦同```
2. 當系統是X86時，將先安裝share目錄再使用x86目錄覆蓋
3. 當系統是ARM時，將先安裝share目錄再使用arm目錄覆蓋
4. 專屬x86的bin檔可放至`x86/bin`，專屬arm的bin檔可放至`x86/bin`

#### Package 相依會自動到AppCenter下載安裝嗎？
- 不會，但會陸續增加功能  [v0.3]

#### 如有疑問或發現bug如何處理？
- 請直接建立[issue](https://github.com/yutin1987/QPM/issues)
