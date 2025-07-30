# Ubuntu学习笔记

## 目录

[TOC]

## Ubuntu配置

### Ubuntu镜像烧录

* rufus : https://rufus.ie/zh/
* Ventoy : https://www.ventoy.net/cn/index.html

### 双系统引导Ubuntu

* Win7及以后系统用easybcd添加grub2引导(推荐)
    * Add New Entry(添加新条目)——Linux/BSD中[device(驱动器)选择 /boot 挂载的分区]——添加新条目
* Win7及以后系统easybcd添加neogrub引导
    * Add New Entry(添加新条目)——neogrub——先点"安装"——再点"配置"——出来一个记事本窗口，删除里面的内容，同样复制下面XP（menu.lst文件）的代码进去
* XP用dd生成配置引导Ubuntu
    * 启动U盘的Ubuntu镜像，选择使用Ubuntu，进入桌面后打开终端，输入命令
        * `sudo dd if=/dev/sda4 of=ubuntu.pbr bs=512 count=1`
        * 其中 /dev/sdaX为安装grub的地方，例如/dev/sda4
        * ubuntu.pbr 为在livecd目录生成的引导文件，名字任意
    * 将ubuntu.pbr的文件，直接将此文件复制至windows的c盘
    * 然后直接编辑xp的boot.ini，加一行
        * `C:\ubuntu.pbr="ubuntu"`
* XP用grub4dos引导ubuntu grub
    * grub4dos中取出grldr和grldr.mbr放到C盘根目录；
    * 修改xp引导盘下的boot.ini，添加 C:\grldr.mbr="ubuntu"；
    * 在C盘根目录创建menu.lst文件，根据情况添加下列条目:
        * <知道ubuntu在哪个分区> //一般采用这个
        ```
        (hd0,x)中x换成/boot所在分区
        title ubuntu 12.04
        root (hd0,x)
        kernel /boot/grub/core.img
        boot
        ```
        * <12.10版本>
        ```
        title ubuntu 12.10
        find --set-root /boot/grub/i386-pc/core.img
        kernel /boot/grub/i386-pc/core.img
        boot
        ```
            * 如果是12.04及之前版本上面请去掉路径中的 /i386-pc
            * 如果 /boot 单独分区请自行去掉路径中的 /boot
<br>

* 参数知识
    * 磁盘盘上可细分出磁区(Sector)与磁柱(Cylinder)两种单位，其中磁区每个为 512bytes 那么大。
    * 磁盘的第一个磁区主要记录了两个重要的资讯，分别是:
        * 主要启动记录区(Master Boot Record, MBR): 可以安装启动管理程序的地方，有 446bytes。
        * 分割表(partition table): 记录整颗硬盘分割的状态，有 64 bytes。在分割表所在的 64 bytes 容量中，总共分为四组记录区，每组记录区记录了该区段的启始与结束的磁柱号码。
    * IDE硬盘用hd开头，SCSI/SATA硬盘/U盘用sd开头，光盘用cd开头，软盘用fd开头。
        * (hd0,0)为第一主分区，(hd0,1)为第二主分区……
        * (hd0,4)为第一逻辑分区(通常为D盘)，(hd0,5)为第二个逻辑分区(通常为E盘)……
        * (hd0)为第一个硬盘，(hd1)为第二个硬盘……
    * /dev/sdax:一块硬盘最多只能有四个主分区(Primary)，其中一个可以为扩展分区(Extended)(最多1个扩展分区)(主分区的特殊形式)，扩展分区中可以有60个逻辑分区。
    * Linux表示分区，与顺序和类型有关:
        * /dev/sda1为第一主分区，/dev/sda2为第二主分区，/dev/sda3为第三主分区，/dev/sda4为第四主分区；
        * /dev/sda5为第一逻辑分区，/dev/sda6为第二逻辑分区……不管有几个主分区，逻辑分区都是从/dev/sda5开始的。
        * 其中/dev/sda为第一块硬盘，/dev/sdb为第二块硬盘(如果有的话)，分区表示法后面的数字一样。
    * grub中 <grub4dos最新版下载 http://download.gna.org/grub4dos/ >

### 系统目录

* 分区划分
    * 开机过程中仅有根目录会被挂载， 其他分割槽则是在开机完成之后才会持续的进行挂载的行为
    * 建议划分下列的磁盘区块(可以利用 Network File System (NFS) 服务器挂载某特定目录等)
        * `/`       : 所有目录都是由根目录(/)衍生出来, 所在分割槽应该越小越好，且应用程序所安装的软件最好不要与根目录放在同一个分割槽内
        * `/boot`   : 大约100M。这个目录主要放置inux核心文件以及开机选单与开机所需配置文件等，如/boot/grub/
        * `/usr`    : (unix software resource)，与软件安装/执行有关，所有系统默认的软件都会放置到/usr底下
        * `/home`   : 默认的用户家目录
        * `/var`    : (variable)，与系统运作过程有关，包括缓存(cache)、登录档(log file)、 程序文件(lock file, run file)、数据库文件、邮件以及某些软件运作所产生的文件
    * 不可与根目录分开的目录
        * `/etc`    : 配置文件例如人员的账号密码文件、 各种服务的启始档等。 如: /etc/passwd 账号名称信息UID || /etc/shadow 密码信息 || /etc/group 组名信息GID
            * `/etc/init.d/`    : 所有服务的预设启动 script 都是放在这里的
            * `/etc/xinetd.d/`  : 这就是所谓的 super daemon 管理的各项服务的配置文件目录
            * `/etc/X11/`       : 与 X Window 有关的各种配置文件都在这里，尤其是 xorg.conf 这个X Server 的配置文件
        * `/sbin`   : 重要的系统执行文件，系统管理员可用指令。为开机过程中所需要的，里面包括了开机、修复、还原系统所需要的指令。 至于某些服务器软件程序，一般则放置到/usr/sbin/当中。常见的指令包括:  fdisk, fsck, ifconfig, init, mkfs 等
        * `/bin`    : 重要执行档。放置的是一般用户惯用的指令，至于/sbin则是系统管理员才会使用到的指令；/bin 与/sbin都与开机、单人维护模式有关。/usr/bin则是大部分软件提供的指令放置处。/bin 放置的是在单人维护模式下还能够被操作的指令。 在/bin 底下的指令可以被 root 与一般账号所使用，主要有: cat, chmod, chown, date, mv, mkdir, cp, bash 等等常用的指令。
        * `/lib`    : 执行档所需的函式库与核心所需的模块。放置的则是在开机时会用到的函式库，以及在/bin 或/sbin 底下的指令会呼叫的函式库。如/lib/modules/ 驱动
        * `/dev`    : 装置文件。任何装置与接口设备都是以文件的型态存在于这个目录当中。 比要重要的文件有/dev/null, /dev/zero, /dev/tty, /dev/lp*, /dev/hd*, /dev/sd*等
        * `/root`   : 系统管理员(root)的家目录，希望 root 的家目录与根目录放置在同一个分割槽中

* FHS建议目录 (Filesystem Hierarchy Standard)
    |                    | 可分享的(shareable)        | 不可分享的(unshareable) |
    | ------------------ | -------------------------- | -------------------- |
    | 不变的(static)     | /usr (软件放置处)          | /etc (配置文件)      |
    |                    | /opt (第三方协力软件)      | /boot (开机与核心档) |
    | 可变动的(variable) | /var/mail (使用者邮件信箱) | /var/run (程序相关)  |
    |                    | /var/spool/news (新闻组)   | /var/lock (程序相关) |

* 其他目录
    * `/media`      : 放置可移除的装置， 包括软盘、光盘、DVD等装置都暂时挂载于此
    * `/mnt`        : 暂时挂载某些额外的装置
    * `/opt`        : 第三方协力软件放置的目录如桌面环境
    * `/srv`        : service的缩写，是一些网络服务启动之后，这些服务所需要取用的数据目录，常见的服务例如 WWW, FTP 等
    * `/tmp`        : 正在执行的程序暂时放置文件的地方这个目录是任何人都能够存取的，重要数据不可放置在此目录

* 非FHS建议，但常用目录
    * `/lost+found` : 使用标准的 ext2/ext3 文件系统格式才会产生的一个目录，目的在于当文件系统发生错误时， 将一些遗失的片段放置到这个目录下。这个目录通常会在分割槽的最顶层存在， 例如你加装一颗硬盘于/disk 中，那在这个系统下就会自动产生一个这样的目录/disk/lost+found
    * `/proc`       : 虚拟文件系统(virtual filesystem)]喔！他放置的数据都是在内存当中， 例如系统核心、行程信息(process)、周边装置的状态及网络状态等等。因为这个目录下的数据都是在内存当中，所以本身不占任何硬盘空间啊！
    * `/sys`        : 也是一个虚拟的文件系统，主要也是记录与核心相关的信息。 包括目前已加载的核心模块与核心侦测到的硬件装置信息等等。这个目录同样不占硬盘容量

* usr下目录
    * `/usr/X11R6/` : X Window System 重要数据所放置的目录，之所以取名为 X11R6 是因为最后的 X 版本为第 11 版，且该版的第 6 次释出之意
    * `/usr/bin/`   : 绝大部分的用户可使用指令都放在这里！请注意到他与/bin 的不同之处。 (是否与开机过程有关)
    * `/usr/include/` : c/c++等程序语言的档头(header)与包含档(include)放置处
    * `/usr/lib/`   : 包含各应用软件的函式库、目标文件(object file)，以及不被一般使用者惯用的执行档或脚本(script)
    * `/usr/local/` : 系统管理员在本机自行安装自己下载的软件(非 distribution 默认提供者)，建议安装到此目录， 这样会比较便于管理
    * `/usr/sbin/`  : 非系统正常运作所需要的系统指令。最常见的就是某些网络服务器软件的服务指令
    * `/usr/share/` : 放置共享文件的地方，在这个目录下放置的数据几乎是不分硬件架构均可读取的数据，几乎都是文本文件
        * `/usr/share/man`      : 联机帮助文件
        * `/usr/share/doc`      : 软件杂项的文件说明
        * `/usr/share/zoneinfo` : 与时区有关的时区文件
    * `/usr/src/`   : 一般原始码建议放置到这里， src 有 source 的意思。至于核心原始码则建议放置到/usr/src/linux/目录下

* var下目录
    * `/var/cache/` : 应用程序本身运作过程中会产生的一些暂存档
    * `/var/lib/`   : 程序本身执行的过程中，需要使用到的数据文件放置的目录
    * `/var/lock/`  : 某些装置或者是文件资源一次只能被一个应用程序所使用，如果同时有两个程序使用该装置时， 就可能产生一些错误的状况，因此就得要将该装置上锁(lock)，以确保该装置只会给单一软件所使用
    * `/var/log/`   : 重要到不行！这是登录文件放置的目录！里面比较重要的文件如/var/log/messages,/var/log/wtmp(记录登入者的信息)等
    * `/var/mail/`  : 放置个人电子邮件信箱的目录，不过这个目录也被放置到/var/spool/mail/目录中！ 通常这两个目录是互为链接文件啦
    * `/var/run/`   : 某些程序或者是服务启动后，会将他们的 PID 放置在这个目录下喔
    * `/var/spool/` : 这个目录通常放置一些队列数据， 所谓的[队列]就是排队等待其他程序使用的数据啦！这些数据被使用后通常都会被删除

### 开机自动挂载win分区

* sudo fdisk -l                 # 查看磁盘
* sudo blkid /dev/sda2          # 获取分区(例如D盘)的uuid
* sudo mkdir /home/ntfspd       # 建立一个空目录用于挂载
* sudo chmod 777 /home/ntfspd   # 修改权限，任何人都可以访问
* sudo vim /etc/fstab           # 修改文件加入下面一句话(注意对应修改)
    ```
    UUID=AD8E697F8FFFFBD0   /home/lengjing/antfspd  ntfs    defaults,utf8,uid=1000,gid=1000                     0   2
    UUID=21FB-517B          /home/lengjing/asdcard  vfat    defaults,utf8,uid=1000,gid=1000                     0   2
    UUID=21FB-517B          /home/lengjing/asdcard  vfat    rw,exec,auto,nouser,sync,iocharset=utf8             0   2
    UUID=21FB-517B          /home/lengjing/asdcard  vfat    defaults,utf8,uid=1000,gid=1000,dmask=022,fmask=133 0   2
    ```

* 每条条目有6列: 要挂载的设备或伪文件系统  挂载点  文件系统类型  挂载选项 转储频率 自检次序
    1. 要挂载的设备或伪文件系统：设备文件(/dev/sda1等)、LABEL(LABEL=xxx)、UUID(UUID=xxx)、伪文件系统名称(proc, sysfs)
    2. 挂载点：指定的文件夹，一般为空文件夹
    3. 文件系统类型: ext4、ntfs、swap，也可以自动探测使用 auto
    4. 挂载选项：defaults(rw, suid, dev, exec, auto, nouser, async)
        * rw/ro         是否以以只读或者读写模式挂载
        * suid/nosuid   是否允许SUID的存在
        * exec/noexec   是否能够进行"执行"的操作
        * auto/noauto   当运行 `mount -a` 的命令时，此文件系统是否被主动挂载
        * user/nouser   是否允许用户使用mount命令挂载
        * sync/async    同步/异步方式运行(异步 写入内存效率高，安全稍低)
    5. 转储频率：0 不做备份；1 每天转储；2 每隔一天转储
    6. 自检次序(数值大的晚自检)：0 不自检；1 首先自检(一般只有rootfs才用1)

### 美化Ubuntu

* 安装 gnome-tweaks 用于设置桌面
    * `sudo apt install gnome-tweak-tool gnome-shell-extensions`
* "Ubuntu软件 -> 附加组件"安装插件 `User themes` 才可以修改顶栏(shell样式)
* 主题网站选择主题下载，例如Yaru/Budgie10.5
    * https://www.gnome-look.org/
    * https://www.opendesktop.org/
* 复制主题到对应目录
    ```
    /usr/share/themes or ~/.themes      # 主题存放目录
    /usr/share/icons  or ~/.icons       # 图标存放目录
    /usr/share/fonts  or ~/.fonts       # 字体存放目录
    /usr/share/backgrounds/             # 背景存放目录
    ```
* 运行gnome-tweaks启用插件，切换主题

<br>

* 解决两个dock的问题
    ```
    cd /usr/share/gnome-shell/extensions
    sudo mv ubuntu-dock@ubuntu.com ubuntu-dock@ubuntu.com-bak
    ```
* 更强功能的dock软件 `cairo-dock`
    * `sudo apt install cairo-dock`

## 常用快捷键

* Ubuntu自带截图工具的快捷键 screenshot
```
        [PrtScr] 全屏截取并保存         [Ctrl]+        [PrtScr] 全屏截取到剪切板
[Alt]  +[PrtScr] 窗口截取并保存         [Ctrl]+[Alt]  +[PrtScr] 窗口截取到剪切板
[Shift]+[PrtScr] 矩形截取并保存         [Ctrl]+[Shift]+[PrtScr] 矩形截取到剪切板
```

* Linux下其他截屏软件 shutter, flameshot; 其中flameshot可以添加注释、文本或者特效
```
sudo apt install shutter flameshot
```

* 切换命令行窗口与图形窗口
    * tty7 终端机没有运行时，可以使用 startx 启动 X 窗口
    * run level : 0 关机；3 纯文本模式；5 含有图形接口模式；6 重新启动
```
[Ctrl]+[Alt]+[F7] 图形窗口登录tty7      [Ctrl]+[Alt]+[F1~F6] 命令行窗口登录tty1~tty6终端机
```

* 切换程序和窗口
```
[Alt]+[Tab] 切换不同程序                [Alt]+[`] 切换程序的不同窗口
[Alt]+[数字] 切换到对应标签页           [Ctrl]+PgUp/PgDn 切换标签页
```

* 通用快捷键
    * 查看快捷键: 按住[Win]键不放 或 "右上角->系统设置->键盘->快捷键"
```
[F1] 打开帮助       [F11] 全屏切换      [Alt]+字母 打开某个菜单
```

* 终端(terminal)快捷键
```
[Ctrl]+[Alt]+t      打开终端快捷键，或按[Win]键打开的搜索中输入 terminal 后，按[Enter]键打开终端
nautilus .          从终端打开当前文件夹

[Tab] 自动补全(命令补全或文件补齐: 两次[Tab])
[Ctrl]+r 搜索前面输入过的命令           history 输入的命令历史
[Ctrl]+c 终止进程/命令                  [Ctrl]+z 暂停并后台目前的命令
jobs 查看当前有多少在后台运行的命令     Command & 任务或者程序还后台执行可以使用
bg 将一个在后台暂停的命令，变成继续执行 fg 将后台中的命令调至前台继续运行

[Ctrl]+b 向前移动光标(←键)              [Ctrl]+f 向后移动光标(→键)
[Ctrl]+a 光标移动到最前(Home键)         [Ctrl]+e 光标移动到最后(End键)

[Ctrl]+d 删除当前字符(Del键)            [Ctrl]+h 删除当前字符的前一个字符(Back键)
[Ctrl]+k 删除此处至末尾的所有内容       [Ctrl]+u 删除此处至开始的所有内容
[Ctrl]+w 删除此处到左边的单词           [Ctrl]+l 清屏(clear命令)
[Ctrl]+s 暂停屏幕的输出                 [Ctrl]+q 恢复屏幕的输出

[Ctrl]+d 关闭终端                       [Ctrl]+[Shift]+w 关闭标签页
[Ctrl]+[Shift]+n 新终端                 [Ctrl]+[Shift]+t 新标签页
[Ctrl]+[Shift]+c 复制                   [Ctrl]+[Shift]+v 粘贴
```

## 安装卸载软件

* 命令行安装、卸载
```
sudo snap install packagename           # 安装snap软件，强制退出snap安装 sudo snap abort 5
sudo apt install packagename            # 安装软件(带 -f 参数为强制安装)
sudo apt remove packagename             # 卸载软件(依赖包没有删除)(带 --purge 参数为连配置文档也删除)
sudo apt autoremove packagename         # 卸载软件(连依赖包也删除)(带 --purge 参数为连配置文档也删除)
sudo apt update                         # 更新软件数据库
sudo apt upgrade                        # 更新软件包(更新软件包前先要更新数据库) 下载目录为 /var/cache/apt/archives
sudo apt dist-upgrade                   # 升级系统
sudo dpkg -i/r/P package.deb            # -i 为安装deb包；-r为移除式卸载；-P为清除式卸载
sudo gdebi package.deb                  # 根据软件仓库这一实用的特性，来解算依赖关系安装(建议)
locate libname                          # 使用locate命令查找libname库
aptitude search libname                 # 使用aptitude search搜索软件包libname
```

* 清理垃圾命令(或清理工具bleachbit)
```
sudo apt purge indicator-messages       # 去除邮件图标上社交软件的消息状态
sudo apt autoclean                      # 清理旧版本的软件缓存
sudo apt autoremove                     # 删除系统不再使用的孤立软件
dpkg -l |grep ^rc |awk '{print $2}' |sudo xargs dpkg -P # 清除所有已删除包的残余配置文件
```

* 删除旧的内核版本
    * 注意不要删除不带版本号的任何内核，不要误删除
```
sudo dpkg --get-selections |grep ^linux # 列出所有已安装的内核映像
uname -r                                # 查看当前正在运行的内核版本
sudo apt purge 版本                     # 卸载不需要的内核版本
```

* 源码编译安装
    * 解压源码压缩包后，进入解压后文件夹运行以下命令
```
./configure --prefix=/home/tmp          # 安装到指定路径，可以省略
make;make install                       # 编译并安装
```

### 安装ppa软件

* 基本格式
    * ppa是是ubuntu Launchpad网站提供的一项服务，允许个人用户作为apt源供其他用户下载和更新
    ```
    sudo add-apt-repository ppa:user/name   # 添加源
    sudo apt update                         # 更新软件数据库
    sudo apt install packagename            # 安装
    sudo add-apt-repository -r ppa:user/name# 删除源
    ```

* GPG签名验证错误
    ```
    W: GPG签名验证错误:  http://ppa.launchpad.net intrepid Release: 由于没有公钥，下列签名无法进行验证:  NO_PUBKEY 5A9BF3BB9D1A0061
    出现以上错误提示时，只要把后八位拷贝一下来，并在[终端]里输入以下命令并加上这八位数字回车即可！
    sudo apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 9D1A0061
    ```

* LibreOffice
    * 通过PPA升级你的LibreOffice
    ```
    sudo add-apt-repository ppa:libreoffice/ppa
    sudo apt update
    sudo apt dist-upgrade
    ```
    * 删除LibreOffice源
    ```
    sudo add-apt-repository -r ppa:libreoffice/ppa
    ```
    * 卸载LibreOffice
    ```
    sudo apt purge libreoffice?
    ```

* typora
    * 通过PPA安装https://typora.io/
    ```
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys BA300B7755AFCFAE
    wget -qO - https://typora.io/linux/public-key.asc | sudo apt-key add -
    ```
    * add Typora's repository
    ```
    sudo add-apt-repository 'deb https://typora.io/linux ./'
    sudo apt-get update
    ```
    * install typora
    ```
    sudo apt-get install typora
    ```

### wine最新版

* 安装WineHQ
    1. If your system is 64 bit, enable 32 bit architecture (if you have not already):
        ```
        sudo dpkg --add-architecture i386
        ```
    2. Add the key:
        ```
        wget -O - https://dl.winehq.org/wine-builds/winehq.key | sudo apt-key add -
        ```
    3. Add the repository:
        ```
        # Ubuntu 20.04
        sudo add-apt-repository 'deb https://dl.winehq.org/wine-builds/ubuntu/ focal main'
        # Ubuntu 19.10
        sudo add-apt-repository 'deb https://dl.winehq.org/wine-builds/ubuntu/ eoan main'
        # Ubuntu 18.04 / Linux Mint 19.x
        sudo add-apt-repository 'deb https://dl.winehq.org/wine-builds/ubuntu/ bionic main'
        # Ubuntu 16.04 / Linux Mint 18.x
        sudo add-apt-repository 'deb https://dl.winehq.org/wine-builds/ubuntu/ xenial main'
        ```
    4. Update packages:
        ```
        sudo apt update
        ```
    5. Then install one of the following packages:
        ```
        # Stable branch
        sudo apt install --install-recommends winehq-stable
        # Development branch
        sudo apt install --install-recommends winehq-devel
        # Staging branch
        sudo apt install --install-recommends winehq-staging
        ```

* 运行依赖
    ```
    sudo add-apt-repository ppa:cybermax-dexter/sdl2-backport
    sudo apt update
    sudo apt install libfaudio0
    ```

* 彻底卸载wine
    * 终端中执行sudo apt autoremove wine --purge
    * 删除wine的目录文件: sudo rm -rf ~/.wine
    * 清理wine模拟运行的windows程序:sudo rm -rf ~/.local/share/applications
    * 清理残余的windows程序:sudo rm -rf ~/.config/menus/applications-merged/wine*

* 解决最新版wine中文乱码
    * 把window系统中的C:\WINDOWS\Fonts文件夹直接复制到~/.wine/drive_c/windows/Fonts/

### 开源工具

#### 图片工具

* gimp(推荐)
    * 强大的图片编辑(代替Photoshop): 强大的图片编辑gimp的外观和快捷键和Photoshop不同，需要调整。
* gimpshop
    * 基于gimp，而又有Photoshop风格的免费的应用程序。
* krita
    * KDE桌面环境下强大的免费图像处理(CG绘画)软件。
* converseen
    * 是一个批量的图片转换和缩略图生成工具，支持超过100种图像格式。
* shotwell
    * 最流行的各种Linux发行版中默认内置的照片管理工工具。提供了一些最基本的编辑功能。
* gthumb
    * 照片管理工具gthumb 主要功能如下:
    * 图片查看: 支持所有主流的图片格式(包括 gif)和元数据(EXIF、 XMP 等)。
    * 图片浏览: 所有基础的浏览操作(缩略图、移动、复制、删除等)以及书签支持。
    * 图片管理: 使用标签、目录和库来组织图片。从数码相机导入图片，集成了网络相册(Picasa，Flickr，Facebook等)。
    * 图片编辑: 基本图像编辑操作、滤镜、格式转换、文件批处理等。
* digiKam
    * digiKam照片管理工具。主要为 KDE 桌面环境设计，主要功能如下:
    * 图片管理: 相册、子相册、标签、评论、元数据、排序支持。
    * 图片导入: 支持从数码相机、USB设备、网络相册(包括 Picasa 和 Facebook)导入，以及另外一些功能。
    * 图片输出: 支持输出至很多网络在线平台，以及格式转换。
    * 图片编辑: 支持很多图像编辑的操作。
* xpaint
    * 为X11编写的画图程序，适合制作简单的图片。
    * 它不提供诸如图片处理和梯度扩充等功能。xpaint的界面以一个工具栏方式呈现，用来选择当前图片操作、修改绘制图片，每一个绘制窗口都可以选择颜色和图片类型。
    * 提供桌面截图、图片缩放、图片大小转换、筛选、颜色编辑、脚本处理、图层、矢量格式导入、矢量字体和字体反锯齿等功能。
* mypaint(推荐)
    * 小巧实用的画图工具。
* whyteboard
    * 文档图片注释工具。用来对包括PDF、PostScript文档和各种图片进行注释。
    * 可绘制各种图形，包括长方形、椭圆、文本、画笔等。
    * 支持一些常用的图形处理功能。

#### pdf工具

* evince
    * 轻量级的文档浏览器，在Gnome桌面环境中是默认安装的。
    * 它同样支持包括PDF、tiff、XPS、djvu、dvi、Postscript在内的多种文档格式。
* FoxitReader
    * 官网可以下载。提供文档笔记功能。推荐使用。
* diffpdf
    * 一个图形化应用程序，用于对两个PDF文件进行对比。
    * 默认情况下，它只会对比两个相关页面的文字，但是也支持对图形化页面进行对比(例如，如果图表被修改过，或者段落被重新格式化过)。
    * 它也可以对特定的页面或者页面范围进行对比。
* pdfmod
    * 一个简单的PDF文档编辑器软件。能够对页面进行重新排序、旋转和删除操作，能够对文档的标题、作者等元素进行编辑，也能够将图片导出或者导入到PDF文档里。
* okular
    * KDE环境下的pdf阅读工具。兼容多种格式包括 PDFs, EPUB ebooks, CBR and CBZ comic books, DjVu,images...
    * 能对 PDF进行多种标记注解: 评论, 高亮, 画图, 贴图(类似加上水印), 导出文本, 加入书签等。
* pdfcrack
    * PDF密码破解工具。
* xournal
    * 笔记素材工具xournal 是一个用于书写备忘笔记、草图的编辑工具。
    * 但它有一个特色功能，就是可以导入及导出 PDF 文件，所以我们也可以把它当作 PDF 批注工具，
    * xournal 提供文字输入、画笔、橡皮擦等一系列工具，并完全支持中文。
    * 勾上“形状识别”(Shape Recognizer)，这样可以自动把高亮部分显示为一条直线。
* gpdftext
    * pdf转换成text，没有换行

#### 其他工具

* geany
    * 强大的跨平台编辑器.它支持基本的语法高亮、代码自动完成、调用提示、插件扩展。支持文件类型:` C,CPP，Java,Python，PHP, HTML, DocBook, Perl, LateX 和 Bash脚本`。该软件小巧、启动迅速，主要缺点是界面简陋、运行速度慢、功能简单。
* dia
    * 流程图工具
    * 默认可以输入中文方法
        *  ~/.bashrc上定义别名:  `alias dia="env GTK_IM_MODULE=xim dia"`
        * 修改 `/usr/share/applications/dia.desktop` 文件，把 `Exec=dia %F` 改为 `Exec=env GTK_IM_MODULE=xim dia %F`
    * 或手动修改输入中文
        * 手动修改:  `选定任一图形 ---> F2键(即菜单 --> 工具 --> 编辑文本) ---> 右键 ---> Input Methods ---> X输入法`
        *
* p7zip unrar
    * 解压工具(7zip的Linux版，只能使用命令行，没有独立的图形界面，但集成在归档管理器中)
    * unrar 解压rar压缩文件
* xchm
    * chm查看(另: kchmviewer，体积比较大，但功能更好)
* qgit
    * Git客户端
* qbittorrent
    * BT下载
* bleachbit
    * 清理工具
* unity-tweak-tool
    * 高级设置工具
* dconf-editor
    * 参数修改工具
* qmmp
    * 基于Qt的音频播放器(类似Winamp)
* acetoneiso
    * 是一个功能丰富的开源图形化应用程序(代替DaemonTools)，用来挂载和管理CD/DVD镜像。
* furiusisomount
    * 挂载镜像文件，它支持直接打开ISO, IMG, BIN, MDF和NRG格式的镜像而不用把他们烧录到磁盘。
* gedit-plugins插件
    * ubuntu自带文本编辑器的常用插件
* gedit 主题文件
    * 网站  https://github.com/mig/gedit-themes
    * 路径  `/usr/share/gtksourceview-X.0/styles`   (X为2或3)
    * 添加  `<style name="line-numbers"  foreground="black" background="blue"/>`
* thunderbird插件
    * MinimizeToTray 后台运行插件，插件的首选项选择“替代关闭和最小化时”。
    * ImportExportTools 导入导出插件
    * keep in taskbar 最小化取代关闭插件

*  evolution邮件客户端
    * 删除出错信息：`rm ~/.cache/evolution/mail/<account_uid>/folders.db`

* ultraedit
    * `rm -rf ~/.idm/uex/uex.conf` : 旧版重新30天试用
    * `rm -rfd ~/.idm/uex ; rm -rf ~/.idm/*.spl ; rm -rf /tmp/*.spl` : 新版重新30天试用
    * `sudo dpkg -P uex` : 卸载

* atom
    * 类似vscode的IDE软件

## 环境简单配置

* firefox在高分屏调整默认字体大小
    * `about:config layout.css.devPixelsPerPx`

* 修改或删除SSH的密码
    * `ssh-keygen -p [-P old_passphrase] [-N new_passphrase] [-f keyfile]`
    * 例如：`ssh-keygen -p -P 123456 -N '' -f ~/.ssh/id_rsa`

* scp简单命令
    * `scp local_file remote_username@remote_ip:remote_file` 上传文件
    * `scp -r local_folder remote_username@remote_ip:remote_folder` 上传文件夹
    * `scp remote_username@remote_ip:remote_file local_file` 下载文件
    * `scp -r remote_username@remote_ip:remote_folder local_folder` 下载文件夹
    * 需要ssh的支持
        * `sudo apt install openssh-server` : 装ssh的服务端(默认情况下，ssh客户端也一并安装了)
        * `sudo apt install openssh-client` : 安装ssh的客户端

* 设置ibus输入法
    * 终端输入 `/usr/lib/ibus-pinyin/ibus-setup-pinyin`

* 转换字符集iconv
    * `iconv -f from-encoding -t to-encoding inputfile -o outputfile`
    * `--list`  : 列出 iconv 支持的语系数据
    * `-f`      : from亦即来源之意，后接原本的编码格式
    * `-t`      : to亦即后来的新编码要是什么格式
    * `-o file` : 如果要保留原本的档案，那么使用 -o 新档名，可以建立新编码档案。
    * `iconv -f gb18030 -t utf8 a.txt -o -b.txt` : GB18030 是最新的国家标准，包含了 27,564 个汉字，而且向下兼容 GB2312 和 GBK

* ubuntu 将中文目录名改成英文
    ```
    echo $LANG                              # 显示目前所支持的语系(中文: zh_CN.UTF-8)
    export LANG=en_US                       # 注意等号两边没有空格符
    xdg-user-dirs-gtk-update                # 在弹出的窗口中询问是否将目录转化为英文路径，同意并关闭。
    export LANG=zh_CN.UTF-8                 # 关闭终端，并注销或重启。
            # 下次进入系统，系统会提示是否把转化好的目录改回中文，选择不需要并且勾上不再提示，并取消修改。
    env LC_TIME=en_US.UTF-8 date "+%a %b %d %H:%M:%S %Z %Y"     # 显示英文时间
    ```

* 修改语言环境变量
    ```
    locale -a                               # 查看系统内安装的local，若没有支持包，请先安装
    sudo locale-gen en_US.UTF-8             # 安装英文支持包
    sudo locale-gen zh_CN.UTF-8             # 安装中文支持包
    sudo gedit /etc/default/locale          # 编辑配置文件

    # 改为英文修改后的内容如下:              # 改为中文修改后的内容如下:
    # LANG="en_US.UTF-8"                     LANG="zh_CN.UTF-8"
    # LANGUAGE="en_US:en"                    LANGUAGE="zh_CN:zh"
    ```

* txt文件乱码
    * 方法1，通过终端输入命令修改
        * `gsettings set org.gnome.gedit.preferences.encodings auto-detected "['UTF-8','GB18030','GB2312','GBK','BIG5','UTF-16']"`       : 低版本ubuntu
        * `gsettings set org.gnome.gedit.preferences.encodings candidate-encodings "['UTF-8','GB18030','GB2312','GBK','BIG5','UTF-16']"` : 高版本ubuntu
    * 方法2，通过参数修改工具dconf-editor修改
        * 安装打开dconf-editor，展开org/gnome/gedit/preferences/encodings
        * auto-detected or candidate-encodings的value中'uft-8'后面加入 'GB18030', 按回车
        * show-in-menu的value中前面加入 'GB18030', 按回车

* vi中文乱码
    * 在~/.vimrc种增加下面内容
    ```
    " fileencodings表示vim读取文件时，采用的编码识别序列，从左往右匹配
    set fileencodings=UTF-8,GB18030,GB2312,GBK,BIG5,UTF-16
    * " fileencoding表示保存文件时的默认文件编码
    set fileencoding=UTF-8
    ```

* 解决 terminal 的中文乱码
    * 主要文件
        * /usr/share/i18n/SUPPORTED     : 目前支持的语言编码文件
        * /var/lib/locales/supported.d/ : 目前配置的语言编码文件
        * /etc/environment              : 手动配置locale环境变量
        * locale                        : 查看现在的locale配置环境
        * localepurge                   : 配置需要的locale(如果没有这个命令，用apt install localepurge安装)
        * locale-gen                    : 生成需要的locale文件(参数 --purge用来删除所有旧的配置，在出现问题时很有用)
    * 先配置自己想要的locale。普遍推荐的方法是拷贝所有ubuntu支持的locale到自己的配置文件里，然后编辑。
    ```sh
    sudo -i                             # 切换到roots身份
    cp /usr/share/i18n/SUPPORTED /var/lib/locales/supported.d/local
    vi /var/lib/locales/supported.d/local   # 用dd命令删除不需要的行，只留下en_系列和zh_系列, 或者其它你要的locale
    rm /var/lib/locales/supported.d/en*
    rm /var/lib/locales/supported.d/zh*     # 这两个文件跟local一样功能，就是把en系列写在en文件里，zh系列写在zh文件里，分类方便。
    ```
    * 再重新生成locale支持文件
        * 这一步会将/usr/lib/locale/里面的locale支持文件删掉，重新生成。如果设置的locale没有生成过，或者设置的时候拼写错误，在这个目录找不到同名的支持文件就会提示No such file了。
    ```sh
    locale-gen --purge
    ```
    * 然后配置locale环境。
        * 敲locale把输出的那些环境变量拷贝到/etc/environment里面，自己手工修改。可以设的值就是/var/lib/locales/supported.d/local里面包括的值，或者生成在/usr/lib/locale/里面的文件夹名称。
    * 退出重新登录，再敲locale看看，没错误了。

* 安装windows字体(高级设置工具unity-tweak-tool / gnome-tweak)
    * 到windows系统中去拷贝一份字体(windows系统的字体都在C:\Windows\Fonts中)放在了ubuntu系统中的~/WinFonts中
    * 在/usr/share/fonts/中创建一个新的文件夹winfonts，创建这个文件夹的主要目的是存放windows字体，免得和ubuntu字体混淆了
    `sudo mkdir /usr/share/fonts/winfonts`
    * 将 ~/WinFonts 的字体复制到/usr/share/fonts/winfonts中
    `sudo cp  ~/WinFonts/* /usr/share/fonts/winfonts`
    * 修改新植入的字体的访问权限
    `cd /usr/share/fonts/winfonts ; sudo chmod 744 *`
    * 生成核心字体信息
        * `sudo mkfontscale`    : 创建用来控制字体旋转缩放的fonts.scale文件
        * `sudo mkfontdir`      : 创建用来控制字体粗斜体的fonts.dir文件
        * `sudo fc-cache -f -v` : 建立字体缓存信息，让系统识别到
    * 注销系统之后，就可以使用windows系统中的字体了

## 关机 重启

* `shutdown`                    : 可以依据目前已启动的服务来逐次关闭各服务后才关机
* `halt`                        : 在不理会目前系统状况下，进行硬件关机的特殊功能
* `who`                         : 查看谁在线
* `sync `                       : 将数据同步写入硬盘中的命令(目前的 shutdown/reboot/halt 等命令均已经在关机前进行了 sync 这个工具的呼叫)
* `shutdown -t seconds`         : 几秒后关机
* `shutdown -h now或8:00或+10 '提示信息'` : 立即或8点或10分后关机
* `shutdown -r now或8:00或+10`  : 立即或8点或10分后重启
