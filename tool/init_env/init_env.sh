#!/bin/bash

# 在 Ubuntu 2x.04 / Debian 13 / Fedora 42 / AlmaLinux 10 / RockyLinux 10 / Manjaro 25 上测试过
# Linux 三大主流包管理器核心命令对比表：
# | 功能场景          | apt (Debian/Ubuntu)  | dnf (Fedora/RHEL)      | pacman (Arch/Manjaro)  |
# | ----------------- | -------------------- | ---------------------- | ---------------------- |
# | 更新软件列表      | `update`             | `check-update`         | `-Sy`                  |
# | 升级所有软件      | `upgrade`            | `upgrade`              | `-Syu`                 |
# | 安装软件包        | `install <包名>`     | `install <包名>`       | `-S --needed <包名>`   |
# | 卸载软件包        | `remove <包名>`      | `remove <包名>`        | `-R <包名>`            |
# | 彻底卸载含配置    | `purge <包名>`       | 无直接等效命令         | `-Rns <包名>`          |
# | 卸载软件含依赖配置| `autoremove --purge` | `autoremove` (不含配置)| `-Rns $(pacman -Qdtq)` |
# | 搜索软件包        | `search <关键词>`    | `search <关键词>`      | `-Ss <关键词>`         |
# | 查看包信息        | `show <包名>`        | `info <包名>`          | `-Si <包名>`           |
# | 清理缓存          | `clean`              | `clean all`            | `-Sc`                  |

echo -e "\033[32m########## 获取系统ID和版本信息 ##########\033[0m"

# osid 可能是 debian / ubuntu / rhel / rocky / almalinux / fedora / manjaro ...
osid=$(cat /etc/os-release | grep '^ID=' | cut -d '=' -f 2 | xargs echo)
verid=$(cat /etc/os-release | grep '^VERSION_ID=' | cut -d '=' -f 2 | xargs echo | cut -d '.' -f 1)
pkgtools="apt dnf pacman"
pkgtool=
for tool in $pkgtools; do
    if command -v $tool > /dev/null; then
        pkgtool=$tool
    fi
done

if [ -z "$pkgtool" ]; then
    echo "Not Supported Linux OS Type."
    exit 1
fi


echo -e "\033[32m########## 设置Shell环境 ##########\033[0m"

bashcfg=/home/$USER/.bashrc
if [ $(cat $bashcfg | grep -c PIP_INDEX_URL) -eq 0 ]; then

cat <<'EOF'>> $bashcfg

# 设置Python镜像
export PIP_INDEX_URL=https://pypi.mirrors.ustc.edu.cn/simple/

# 设置npm镜像
#export NPM_CONFIG_REGISTRY=https://npm.mirrors.ustc.edu.cn/

# 设置Rust镜像
export RUSTUP_DIST_SERVER=https://mirrors.ustc.edu.cn/rust-static
export RUSTUP_UPDATE_ROOT=https://mirrors.ustc.edu.cn/rust-static/rustup
export PATH=$PATH:/home/$USER/.cargo/bin

# 设置 `ls -l` 时间使用英文显示，可能需要 `sudo locale-gen en_US.UTF-8`
# Debian13 可能时间显示为半英半中，应该注释掉 `/etc/locale.conf` 中的 `LANGUAGE="zh_CN:zh"`
#export LANGUAGE=
export LC_TIME=en_US.UTF-8
alias datestr='LC_TIME=en_US.UTF-8 date "+%Y/%m/%d %H:%M:%S"'

# CBuild 编译环境
# 本地编译SIMD加速的环境变量
#export HOST_SIMD_TYPE=avx2
# 进入 Docker 的命令别名
alias cbuild='docker run -i -t --add-host=host.docker.internal:host-gateway -v `pwd`:`pwd` -u cbuild cbuild:0.0.1'
alias cbroot='docker run -i -t --add-host=host.docker.internal:host-gateway -v `pwd`:`pwd` -u root cbuild:0.0.1'

alias vmount='sudo vmhgfs-fuse .host:/ /mnt/hgfs/ -o allow_other -o uid=1000 -o gid=1000' # VMware手动挂载
EOF

fi


echo -e "\033[32m########## 设置Git环境 ##########\033[0m"

gitcfg=/home/$USER/.gitconfig
if [ ! -e $gitcfg ]; then

cat <<'EOF'> $gitcfg
[user]
	name = Jing Leng
	email = 3090101217@zju.edu.cn
[alias]
	co = checkout
	br = branch
	ci = commit
	st = status
[core]
	editor = vim
[diff]
	tool = bc3
[difftool "bc3"]
	path = /usr/bin/bcompare
[sendemail]
	smtpserver = smtp.zju.edu.cn
	smtpserverport = 994
	smtpencryption = ssl
	smtpuser = 3090101217@zju.edu.cn
	smtppass = xxxxxxxx
EOF

fi


echo -e "\033[32m########## 设置Debian环境 ##########\033[0m"

if [ "$osid" = "debian" ] && [ $(cat /etc/apt/sources.list | grep -c '^ *deb cdrom') -ne 0 ] ; then

# 1. sudo提示未出现在sudoers文件中： `/etc/sudoers` 文件添加 `lengjing        ALL=(ALL:ALL) ALL`
# 2. apt安装提示更换介质，插入cdrom：需要修改 `/etc/apt/sources.list`
aptcfg=/etc/apt/sources.list
vername=$(cat /etc/os-release | grep '^VERSION_CODENAME=' | cut -d '=' -f 2 | xargs echo)

sudo cat <<EOF> $aptcfg
deb http://mirrors.ustc.edu.cn/debian/ $vername main non-free-firmware
deb-src http://mirrors.ustc.edu.cn/debian/ $vername main non-free-firmware

deb http://security.debian.org/debian-security $vername-security main non-free-firmware
deb-src http://security.debian.org/debian-security $vername-security main non-free-firmware

# $vername-updates, to get updates before a point release is made;
# see https://www.debian.org/doc/manuals/debian-reference/ch02.en.html#_updates_and_backports
deb http://mirrors.ustc.edu.cn/debian/ $vername-updates main non-free-firmware
deb-src http://mirrors.ustc.edu.cn/debian/ $vername-updates main non-free-firmware
EOF

fi


echo -e "\033[32m########## 设置RedHat系环境 ##########\033[0m"

if  [ "$pkgtool" = "dnf" ] && [ "$osid" != "fedora" ] ; then

# 启用开发仓库、附加仓库、非开源仓库
sudo dnf config-manager --set-enabled crb
sudo dnf install epel-release
sudo dnf config-manager --set-enabled epel
sudo dnf install --nogpgcheck https://mirrors.rpmfusion.org/free/el/rpmfusion-free-release-$(rpm -E %rhel).noarch.rpm -y
sudo dnf install --nogpgcheck https://mirrors.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-$(rpm -E %rhel).noarch.rpm -y

if [ "$osid" = "almalinux" ]; then
# 替换基础源
sudo sed -i -e 's|^mirrorlist=|#mirrorlist=|g' \
    -e 's|^# *baseurl=https://repo.almalinux.org|baseurl=https://mirrors.aliyun.com|g' \
    /etc/yum.repos.d/almalinux*.repo
# 替换EPEL源
sudo sed -i -e 's|^metalink=|#metalink=|g' \
    -e 's|^# *baseurl=https://download.example/pub|baseurl=https://mirrors.aliyun.com|g' \
    /etc/yum.repos.d/epel*.repo
fi

if [ "$osid" = "rocky" ]; then
# 替换基础源
sudo sed -i -e 's|^mirrorlist=|#mirrorlist=|g' \
    -e 's|^# *baseurl=http://dl.rockylinux.org/$contentdir|baseurl=https://mirrors.aliyun.com/rockylinux|g' \
    /etc/yum.repos.d/[Rr]ocky*.repo
# 替换EPEL源
sudo sed -i -e 's|^metalink=|#metalink=|g' \
    -e 's|^# *baseurl=https://download.example/pub|baseurl=https://mirrors.aliyun.com|g' \
    /etc/yum.repos.d/epel*.repo
fi

fi


echo -e "\033[32m########## 刷新缓存 ##########\033[0m"

if [ "$pkgtool" = "apt" ]; then
sudo apt update
elif [ "$pkgtool" = "dnf" ]; then
sudo dnf clean all && sudo dnf makecache
elif [ "$pkgtool" = "pacman" ]; then
sudo pacman-mirrors -i -c China -m rank # 设置国内镜像
sudo pacman -Syu
fi


echo -e "\033[32m########## 安装中文输入法 ##########\033[0m"

# gnome ibus 输入法安装配置
# 1. 需要“运行ibus-setup --> 输入法 --> 添加拼音输入法”
# 2. 输入“设置 --> 键盘 --> 输入源 --> 添加输入源 --> 汉语(中国) --> 添加拼音输入法”
# 3. 修改候选框的字体大小
#    - `gnome-shell --version` 命令得到gnome版本
#    - 下载 `https://extensions.gnome.org/extension/1121/ibus-font-setting/` 对应版本(metadata.json中有适配版本信息，可能要改)
#    - 解压到 `/home/$USER/.local/share/gnome-shell/extensions/ibus-font-setting@ibus.github.com` 后重启
#      - `ibus-font-setting@ibus.github.com` 取自metadata.json的uuid

if [ "$pkgtool" != "pacman" ]; then

if [ "$pkgtool" = "apt" ]; then
sudo apt install ibus ibus-libpinyin
elif [ "$pkgtool" = "dnf" ]; then
sudo dnf install ibus ibus-libpinyin ibus-setup wqy-zenhei-fonts
fi

font_setting_plugin=assets/ibus-font-setting@ibus.github.com.tar.xz
font_setting_dir=/home/$USER/.local/share/gnome-shell/extensions/ibus-font-setting@ibus.github.com
if [ -e $font_setting_plugin ] && [ ! -e $font_setting_dir ]; then
mkdir -p $(dirname $font_setting_dir)
tar -xvf $font_setting_plugin -C $(dirname $font_setting_dir)
fi

fi

# Manjaro KDE 输入法安装配置
# 1. 左下角点击菜单找到 `Manjaro Application Utility` 程序打开
# 2. 找到 `Extended language support` 选中其中一个子选项
# 3. 点击右上部的 `UPDATE SYSTEM` 更新，完成后重启即可
# 4. 设置字体大小：左左下角点击菜单找到 `系统设置` 程序打开，左侧找到 `输入法` 进入，下方找到 `配置附加组件` 进入，点击 `经典用户界面` 右侧的配置图标去设置


echo -e "\033[32m########## 安装Gnome插件 ##########\033[0m"

if [ "$pkgtool" != "pacman" ]; then

# gnome-shell-extensions
# gnome-shell-extension-just-perfection 可能需要高版本，例如 Fedora42
if [ "$pkgtool" = "apt" ]; then
if [ "$osid" = "ubuntu" ]; then
sudo apt install gnome-tweaks dconf-editor
else
sudo apt install gnome-tweaks dconf-editor gnome-extensions-app gnome-shell-extension-dash-to-panel
#sudo apt install gnome-shell-extension-just-perfection
fi
elif [ "$pkgtool" = "dnf" ]; then
sudo dnf install gnome-tweaks dconf-editor gnome-extensions-app gnome-shell-extension-dash-to-panel
fi

fi

echo -e "\033[32m########## 设置CBuild环境 ##########\033[0m"

if [ "$pkgtool" = "apt" ]; then
# CBuild编译环境基础依赖
sudo apt install gcc binutils gdb clang llvm cmake automake autotools-dev autoconf \
    pkg-config bison flex yasm libncurses-dev libtool graphviz python3-pip \
    time git subversion curl wget rsync vim gawk texinfo gettext autopoint openssl libssl-dev
# 编译 sdl/valgrind/util-linux 等需要
sudo apt install gcc-multilib g++-multilib libc6-dev-i386

elif [ "$pkgtool" = "dnf" ]; then

# CBuild编译环境基础依赖
sudo dnf install glibc-static libstdc++-static \
    gcc gcc-c++ binutils gdb clang llvm cmake autoconf automake \
    pkg-config bison flex yasm ncurses-devel libtool graphviz python3-pip \
    time git subversion curl wget rsync vim gawk texinfo gettext gettext-devel openssl openssl-devel
# 编译 sdl/valgrind/util-linux 等需要
sudo dnf install glibc-devel.i686 libstdc++-devel.i686

elif [ "$pkgtool" = "pacman" ]; then

sudo pacman -S --needed base-devel gcc binutils gdb clang llvm cmake automake autoconf \
    pkgconf bison flex yasm ncurses libtool graphviz python-pip \
    time git subversion curl wget rsync vim gawk texinfo gettext openssl  \
    lib32-gcc-libs lib32-glibc

fi

# 安装python包，注意Ubuntu24.04/Debian13/manjaro25需要加上参数 `--break-system-packages` (Python3.11引入PEP668)

if [ $(python3 --version | cut -d '.' -f 2) -gt 10 ]; then
pip3_flags="--break-system-packages -i https://pypi.tuna.tsinghua.edu.cn/simple"
else
pip3_flags="-i https://pypi.tuna.tsinghua.edu.cn/simple"
fi
sudo pip3 install meson    $pip3_flags
sudo pip3 install ninja    $pip3_flags
sudo pip3 install requests $pip3_flags

echo -e "\033[32m########## 设置Vim环境 ##########\033[0m"

if [ "$pkgtool" = "apt" ]; then
sudo apt install vim vim-gtk3 vim-doc universal-ctags
elif [ "$pkgtool" = "dnf" ]; then
sudo dnf install vim-enhanced gvim vim-common ctags
if [ "$osid" = "fedora" ]; then
sudo dnf install xclip
else
# almalinux上找不到此包，需要手动编译https://github.com/astrand/xclip.git，安装下面依赖：
sudo dnf install libXmu-devel
xclip_bin=assets/xclip-bin.tar.xz
if [ -e $xclip_bin ] && [ "$verid" = "10" ] ; then
tar -xvf $xclip_bin -C . && sudo mv xclip/* /usr/bin/ && rmdir xclip
fi
fi
elif [ "$pkgtool" = "pacman" ]; then
sudo pacman -S --needed vim vim-runtime universal-ctags xclip
fi

vimplugins=assets/vim-plugins.tar.xz
if [ -e $vimplugins ] && [ ! -e /home/$USER/.vim ]; then
# [OmniCppComplete](https://www.vim.org/scripts/script.php?script_id=1520)
# [TagList](https://www.vim.org/scripts/script.php?script_id=273)
# [WinManager](https://www.vim.org/scripts/script.php?script_id=95)
# [MiniBufExplorer](https://www.vim.org/scripts/script.php?script_id=159)
# [Project](https://www.vim.org/scripts/script.php?script_id=69)
# [echofunc](http://www.vim.org/scripts/script.php?script_id=1735)
# [autocomplpop](http://www.vim.org/scripts/script.php?script_id=1879)
tar -xvf $vimplugins -C /home/$USER
fi

vimcfg=/home/$USER/.vimrc
if [ ! -e $vimcfg ]; then

cat <<'EOF'> $vimcfg
""""""""""""""""""""""""""""""""
" 配置文件中，以单个双引号开头的文字为注释。
" --环境设置--

" 设置字体，ubuntumono为字体名，16为字号，注意\和空格
" set guifont=ubuntumono\ 16
set guifont=DejaVuSansMono\ 16
" compatible 兼容模式就是让vim关闭所有扩展的功能, nocompatible 相反
set nocompatible
" 语法高亮
if has("syntax")
syntax on
endif
" 设置配色方案，vim自带的配色方案保存在/usr/share/vim/vim*/colors目录下
colorscheme evening " evening elflord industry koehler pablo ron ...
" 打开文件类型检测功能，执行的是$vimRUNTIME/filetype.vim脚本
filetype on
" 加载文件类型插件，执行的是$vimRUNTIME/ftplugin.vim脚本
filetype plugin on
" 为不同类型的文件定义不同的缩进格式，执行的是$vimRUNTIME/indent.vim脚本
filetype indent on
" 背景使用黑色
set background=dark
" 用autocmd命令自动插入最后修改日期
if has("autocmd")
au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
endif
" --必要设置--
" 搜索模式里忽略大小写
set ignorecase
" 如果搜索模式包含大写字符，不使用 'ignorecase' 选项。搜索模式要打开 'ignorecase' 选项
set smartcase
" 跳转时自动把内容写回文件
" set autowrite
" 跳转时放在buffer中不保存
set hidden
" 设置自动对齐(缩进)；使用 noautoindent 取消设置
set autoindent
" 智能对齐
" set smartindent
"设置编码自动识别
set fileencodings=utf-8,gbk
" 设置制表符(tab键)的宽度
set tabstop=4
" 设置软制表符的宽度
set softtabstop=4
" 显示tab为>---
set list lcs=tab:>-
" 缩进使用的4个空格
set shiftwidth=4
" 使用 C/C++ 语言的自动缩进方式
" set cindent
" 设置C/C++语言的具体缩进方式
" :N case相对于switch的缩进，默认为shiftwidth
" +N 语句内的续行的缩进，如果有'\'，则为2N，默认为shiftwidth
" (N 括号内的续行的缩进，默认为2*shiftwidth
" uN 深层括号内的续行的缩进，默认为shiftwidth
set cinoptions=:0,(1s,u1s,U1s
" 设置退格键可用，插入模式中为 2 时，就是可以删除任意值；0 或 1 时，仅可删除刚刚输入的字符
" set backspace=2
" 设置匹配模式，显示匹配的括号
set showmatch
" 整词换行
set linebreak
" 光标从行首和行末时可以跳到另一行去
set whichwrap=b,s,<,>,[,]
" 什么模式下可以使用鼠标:n普通模式;v可视模式;i插入模式;c命令行模式;a以上所有的模式
set mouse=a
" 显示/不显示行号set nu/nonu
set number
" 标识预览窗口
" set previewwindow
" 历史记录50条
set history=50
" 总显示最后一个窗口的状态行；设为1则窗口数多于一个的时候显示最后一个窗口的状态行；0不显示
set laststatus=2
" 标尺，用于显示光标位置的行号和列号，逗号分隔。每个窗口都有自己的标尺。
" 如果窗口有状态行，标尺在那里显示。否则，它显示在屏幕的最后一行上。
set ruler
" 命令行显示输入的命令
set showcmd
" 命令行显示vim当前模式
set showmode
" --搜索设置--
" 输入字符串就显示匹配点
set incsearch
" 高亮度搜寻
set hlsearch
" 显示十字光标 cuc列 | cul行
set cuc cul
" cterm 表示原生vim设置样式, 设置为NONE表示可以自定义设置，更多高亮颜色设置 :highlight
highlight CursorLine   cterm=NONE ctermbg=242 ctermfg=NONE guibg=NONE guifg=NONE
highlight CursorColumn cterm=NONE ctermbg=242 ctermfg=NONE guibg=NONE guifg=NONE
" 可视模式下按下F2复制到系统剪切板
map <F2> "+y
" 可视和插入模式下按下F3复制到系统剪切板
map <F3> "+p
imap <F3> <ESC> "+p i
" 按下F4替换行首TAB键为空格并删除行尾空格
set expandtab
" map <F4> :set expandtab<CR> :%retab<CR> :1,$s/\s\+$//g<CR>
" imap <F4> <ESC> :set expandtab<CR> :%retab<CR> :1,$s/\s\+$//g<CR>
map <F4> :1,$s/\s\+$//g<CR>
imap <F4> <ESC> :1,$s/\s\+$//g<CR>
" 保存时自动删除下列类型文件的行尾空格
"autocmd FileType c,cpp,python,ruby,java,sh,html,javascript autocmd BufWritePre <buffer> :%s/\s\+$//e
" 按下F12，关闭所有窗口
map <F12> :qall<CR>
imap <F12> <ESC> :qall<CR>
""""""""""""""""""""""""""""""""
" --ctags setting--
" 按下F7，tag标记的前一个文件
map <F7> :tp<CR>
" 按下F8，tag标记的后一个文件
map <F8> :tn<CR>
" 按下F9，tag标记的所有文件
map <F9> :ts<CR>
" 按下F10重新生成tag文件，并更新taglist
map <F10> :!ctags -R --c++-kinds=+p --fields=+ialS --extra=+q .<CR><CR> :TlistUpdate<CR>
imap <F10> <ESC>:!ctags -R --c++-kinds=+p --fields=+ialS --extra=+q .<CR><CR> :TlistUpdate<CR>
set tags=tags
" 在当前工作目录下搜索tags文件
set tags+=./tags
""""""""""""""""""""""""""""""""
" --omnicppcomplete setting--
" 按下F5自动补全代码，注意该映射语句后不能有其他字符，包括tab；否则按下F5会自动补全一些乱码
imap <F5> <C-X><C-O>
" 按下F6根据头文件内关键字补全
imap <F6> <C-X><C-I>
" 关掉智能补全时的预览窗口
set completeopt=menu,menuone
" autocomplete with .
let OmniCpp_MayCompleteDot = 1
" autocomplete with ->
let OmniCpp_MayCompleteArrow = 1
" autocomplete with ::
let OmniCpp_MayCompleteScope = 1
" select first item (but don't insert)
let OmniCpp_SelectFirstItem = 2
" search namespaces in this and included files
let OmniCpp_NamespaceSearch = 2
" show function prototype in popup window
let OmniCpp_ShowPrototypeInAbbr = 1
" enable the global scope search
let OmniCpp_GlobalScopeSearch=1
" Class scope completion mode: always show all members
let OmniCpp_DisplayMode=1
"let OmniCpp_DefaultNamespaces=["std"]
" show scope in abbreviation and remove the last column
let OmniCpp_ShowScopeInAbbr=1
let OmniCpp_ShowAccess=1
""""""""""""""""""""""""""""""""
" --Taglist setting--
" 启动vim自动打开Taglist
let Tlist_Auto_Open=1
" 因为我们放在环境变量里，所以可以直接执行
let Tlist_Ctags_Cmd='ctags'
" 让窗口显示在右边，0的话就是显示在左边
let Tlist_Use_Right_Window=1
" 让taglist可以同时展示多个文件的函数列表
let Tlist_Show_One_File=0
" 非当前文件，函数列表折叠隐藏
let Tlist_File_Fold_Auto_Close=1
" 当taglist是最后一个分割窗口时，自动退出vim
let Tlist_Exit_OnlyWindow=1
" 是否一直处理tags.1:处理;0:不处理
let Tlist_Process_File_Always=1
let Tlist_Inc_Winwidth=0
nmap wt :Tlist<CR>
""""""""""""""""""""""""""""""""
" --WinManager setting--
" 设置我们要管理的插件
let g:winManagerWindowLayout='FileExplorer|TagList'
" 设置winmanager的宽度，默认为25
let g:winManagerWidth = 32
" 如果所有编辑文件都关闭了，退出vim
" let g:persistentBehaviour=0
nmap wm :WMToggle<CR>
""""""""""""""""""""""""""""""""
" --MiniBufferExplorer--
" 按下Ctrl+h/j/k/l，可以切换到当前窗口的上下左右窗口
let g:miniBufExplMapWindowNavVim = 1
" 按下Ctrl+箭头，可以切换到当前窗口的上下左右窗口
let g:miniBufExplMapWindowNavArrows = 1
" 启用以下两个功能：Ctrl+tab移到下一个buffer并在当前窗口打开；
" Ctrl+Shift+tab移到上一个buffer并在当前窗口打开；ubuntu好像不支持
let g:miniBufExplMapCTabSwitchBufs = 1
" 启用以下两个功能：Ctrl+tab移到下一个窗口；
" Ctrl+Shift+tab移到上一个窗口；ubuntu好像不支持
" let g:miniBufExplMapCTabSwitchWindows = 1
" 不要在不可编辑内容的窗口（如TagList窗口）中打开选中的buffer
let g:miniBufExplModSelTarget = 1
""""""""""""""""""""""""""""""""
" --fold setting--
" 用语法高亮来定义折叠
" set foldmethod=syntax
" 启动vim时不要自动折叠代码
" set foldlevel=100
" 设置折叠栏宽度
" set foldcolumn=5
""""""""""""""""""""""""""""""""
EOF

if [ "$pkgtool" = "dnf" ] || [ "$pkgtool" = "pacman" ] ; then
cat <<'EOF'>> $vimcfg
" 指定使用xclip作为后端
let g:fakeclip_providers = ['xclip']
""""""""""""""""""""""""""""""""
EOF
fi

fi

echo -e "\033[32m########## 安装vmware工具 ##########\033[0m"

if [ $(lscpu | grep -ci VMware) -ne 0 ]; then

if [ "$pkgtool" = "apt" ]; then
sudo apt install open-vm-tools open-vm-tools-desktop
sudo systemctl enable --now vmtoolsd
elif [ "$pkgtool" = "dnf" ]; then
sudo dnf install open-vm-tools open-vm-tools-desktop
sudo systemctl enable --now vmtoolsd
elif [ "$pkgtool" = "pacman" ]; then
sudo pacman -S --needed open-vm-tools gtkmm3 fuse
sudo systemctl enable --now vmtoolsd vmware-vmblock-fuse
fi
fi


echo -e "\033[32m########## 安装其他组件 ##########\033[0m"

if [ "$pkgtool" = "apt" ]; then
sudo apt install gedit gedit-plugins tree ffmpeg
elif [ "$pkgtool" = "dnf" ]; then
sudo dnf install gedit gedit-plugins tree ffmpeg ffmpeg-devel
elif [ "$pkgtool" = "pacman" ]; then
sudo dnf install bash-completion tree ffmpeg
fi


echo -e "\033[32m########## 将中文目录名改成英文 ##########\033[0m"

if [ "$osid" = "debian" ] || [ "$osid" = "manjaro" ]; then

mkdir -p /home/$USER/.config
cat <<EOF > /home/$USER/.config/user-dirs.dirs
XDG_DESKTOP_DIR="\$HOME/Desktop"
XDG_DOWNLOAD_DIR="\$HOME/Downloads"
XDG_TEMPLATES_DIR="\$HOME/Templates"
XDG_PUBLICSHARE_DIR="\$HOME/Public"
XDG_DOCUMENTS_DIR="\$HOME/Documents"
XDG_MUSIC_DIR="\$HOME/Music"
XDG_PICTURES_DIR="\$HOME/Pictures"
XDG_VIDEOS_DIR="\$HOME/Videos"
EOF

rmdir /home/$USER/*
mkdir -p /home/$USER/Desktop /home/$USER/Downloads /home/$USER/Templates /home/$USER/Public /home/$USER/Documents /home/$USER/Music /home/$USER/Pictures /home/$USER/Videos
LANG=en_US xdg-user-dirs-update

else

echo $LANG
export LANG=en_US
xdg-user-dirs-gtk-update
export LANG=zh_CN.UTF-8

fi


echo -e "\033[32m########## 设置mdbook环境 ##########\033[0m"

cargocfg=/home/$USER/.cargo/config.toml
if [ ! -e $cargocfg ] || [ $(cat $cargocfg | grep -c 'mirrors.ustc.edu.cn') -eq 0 ]; then
mkdir -p $(dirname $cargocfg)
cat <<'EOF'> $cargocfg
[source.crates-io]
replace-with = 'ustc'
[source.ustc]
registry = "sparse+https://mirrors.ustc.edu.cn/crates.io-index/"
EOF
fi

if command -v rustc > /dev/null; then
echo 'rustc has already been installed.'
else
#sudo apt install rustc cargo
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh  # 或 rustup self update
. "$HOME/.cargo/env"
fi

if command -v mdbook > /dev/null; then
echo 'mdbook has already been installed.'
else
cargo install mdbook
cargo install mdbook-katex
cargo install mdbook-mermaid
cargo install mdbook-pdf
cargo install mdbook-toc
cargo install mdbook-admonish
fi
