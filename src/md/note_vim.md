# Vim使用笔记

* 学习 Vim 可参考教程 [Learn Vim](https://github.com/wsdjeg/Learn-Vim_zh_cn)
* 配置 Vim 也可使用 [YouCompleteMe](https://github.com/ycm-core/YouCompleteMe)

## 目录

[TOC]

## 主要命令

### 模式切换

* 一般模式
    * 按`Esc`回到一般模式

* 插入或取代的编辑模式
    * `i`               : 从目前光标所在处插入
    * `I`               : 在目前所在行的第一个非空格符处开始插入
    * `a`               : 从目前光标所在的下一个字符处开始插入
    * `A`               : 从光标所在行的最后一个字符处开始插入
    * `o`               : 在目前光标所在的下一行处插入新的一行
    * `O`               : 在目前光标所在处的上一行插入新的一行
    * `r`               : 只会取代光标所在的那一个字符一次
    * `R`               : 一直取代光标所在的文字直到按下`Esc`为止

* 指令列命令模式
    * 输入 `:` `/` `?` 任意一个进入

* 可视模式
    * 一般模式时输入 `v` 进入，详见 [区块选择](#区块选择)

* 帮助
    * `:help`           : 打开帮助

### 光标移动

* `Ctrl+f/b/d/u`        : 下一页PgUp/上一页PgDn/下半页/上半页
* `h(←) j(↓) k(↑) l(→)` : 光标左下上右移动，前面加数字n表示移动n个字符
* `w` / `b`             : 光标向后移动到它 后面/前面 的word的第一个首字符
* `e` / `ge`            : 光标向后移动到它 后面/前面 的word的第一个尾字符
* `W` / `B` / `E` / `gE`: 上面命令的特殊形式，以空白当作word的边界
* `+` / `-`             : 光标移动到非空格符的下一列 上一列
* `nEnter`              : 光标向下移动n行
* `nSpace`              : 光标向右移动n个字符
* `0` or `Home`         : 此行最前
* `$` or `End`          : 此行最后
* `?`                   : 此行的第一个非空白字符
* `n$`                  : 第n行行尾(^和0不能前面加数字)
* `H` / `M` / `L`       : 当前屏幕的首行/中间行/尾行的第一个字符,H L前可以加数字
* `gg` / `nG` / `G`     : 当前vim档案的首行/第n行/尾行的第一个字符
* `% `                  : 匹配括号的移动
* `数字%`               : 跳到当前文档的百分之数字
* `zz zt zb`            : 把当前行置为屏幕正中央/顶端/底端

### 搜索和取代

* `/str` `?str`         : 向下/上搜，此时可以: `n` 继续 或 `N` 反向继续
* `/\<word\>`           : 精确匹配单词搜索

* `:n1,n2s/str1/str2/g` : 在n1和n2行之间用字符串str2取代str1
* `:1,$s/str1/str2/gc`  : 全文取代需要确认（c表示需要确认）
* `:%s/\s\+$//g`        : 删除行尾空格(%指定整个文件，效果同`1,$`)

* `:g/str/d`            : 删除所有包含str的行
* `:g!/str/d`           : 保留所有包含str的行
* `:g/^\s*$/d`          : 删除空行以及只有空格的行

### 删除d 修改c 复制y 粘贴p

* 要点
    * `d` 命令可以后跟任何一个**位移命令**，它将删除从当前光标起到位移的终点处的文本内容
    * 删除的内容是否包括光标所移动到的那个字符上取决于你的位移命令。不包括该位置的操作叫做"排外的"，包括该位置的操作叫"内含的"
    * `c` 表示修改，删除命令设置的字符并进入插入模式
    * 如果你用 `c` 命令代替 `d` 这些命令就都变成更改命令，使用 `y` 就是yank命令，如此类推

* 删除 / 复制
    * `dl` or `x`       : 删除光标所在字符Del(前面可加n表示n个)
    * `dh` or `X`       : 删除光标所在的前一个字符
    * `d$` or `D`       : 删除光标所在到行尾的内容
    * `dw`              : 删除光标所在到下一个word的开头前一个字符(前面可加n表示n个单词)
    * `diw`             : 删除当前光标所在的word(不包括空白字符)
    * `daw`             : 删除当前光标所在的word(包括后面空白字符)
    * `db`              : 删除 当前光标前一个字符至前一个word的开始
    * `dd`    `yy`      : 删除/复制 光标所在行(前面可加n表示n行)(常用)
    * `d1G`   `y1G`     : 删除/复制 光标所在行到第一行的所有数据,也可以dgg ygg
    * `dG`    `yG`      : 删除/复制 光标所在行到最后一行的所有数据
    * `d0`    `y0`      : 删除/复制 光标所在处前一个字符，到该行的最前一个字符
    * `d$`    `y$`      : 删除/复制 光标所在处，到该行的最后一个字符
* 粘贴
    * `p`               : 在光标的下一行粘贴
    * `P`               : 在光标的上一行粘贴

* 取代
    * `cl` or `s`       : 删除光标所在字符，并进入插入模式
    * `cc` or `S`       : 删除当前行(保持行首的空白)，并进入插入模式
    * `c$` or `C`       : 删除光标所在到行尾的内容，并进入插入模式

* 结合
    * `J`               : 将光标所在行与下一行的数据结合成同一行

* 转换
    * `~` or `g~`       : 选定内容大小写对换
    * `gu` / `gU`       : 选定内容改为小写/改为大写
    * `guu` / `gUU`     : 选定行改为小写/改为大写

### 跳转

* `*`                   : 在文件内搜索该单词，并跳转到下一处(常用)
* `#`                   : 在文件内搜索该单词，并跳转到上一处
<p/>

* `%`                   : 跳转到配对的括号(常用)
* `x%`                  : 跳转到当前文件的百分之x处
* `''`                  : 跳转到光标上次停靠的地方，是两个'，而不是一个"
<p/>

* `fx`                  : 到当前行下一个为 x 的字符处，前面可以加数字n
* `Fx`                  : 到当前行上一个为 x 的字符处
* `tx`                  : 到当前行下一个为 x 的前一个字符处
* `Tx`                  : 到当前行上一个为 x 的后一个字符处
<p/>

* `[[`                  : 跳转到当前或者上一代码块(函数定义、类定义等)的开头去
* `]]`                  : 跳转到下一代码块(函数定义、类定义等)的开头去
* `[]`                  : 跳转到当前或者上一代码块(函数定义、类定义等)的结尾去
* `][`                  : 跳转到下一代码块(函数定义、类定义等)的结尾去
* `[/`                  : 跳到当前或者上一注释开头(只对/* */注释有效)
* `]/`                  : 跳到当前或者下一注释结尾(只对/* */注释有效)
* `(`                   : 移动到当前或者上一句的开始
* `)`                   : 移动到下一句的开始
* `{`                   : 跳转到当前或者上一段落的开始
* `}`                   : 跳转到下一段落的开始
<p/>

* `gD`                  : 跳转到当前文件内标识符首次出现的位置
* `gd`                  : 跳转到当前函数内标识符首次出现的位置
<p/>

* `mx`                  : 设置书签，`x`只能是a-z的26个字母
* 反引号(Tab键上面)     : 跳转到书签处

### 重复和撤销

* `u`                   : 撤消前一个动作(常用)
* `U`                   : 一次撤消对一行的全部操作(再次U撤销前一个U的操作)
* `Ctrl+r`              : 重做上一个动作(常用)
* `.`                   : 小数点，重复前一个动作

### 区块选择

* `v` / `V`             : 字符/行 选择，会将光标经过的行反白选择
* `Ctrl+v`              : 区块选择，可以用长方形的方式选择区块
    * 区块选择后，按 `Shift+i` 进编辑模式，修改后 `两次ESC` 即列插入
    * `y` / `d`         : 将反白的地方 复制/删除
    * `o` / `O`         : 反白的地方基准变换 对角/同一行的另一个角 的位置

### 复制到系统剪切板

* 配置文件中设置了 `set mouse=a` 会导致右键弹出的菜单中 `复制` 不可用，此时将选择的字符串复制到系统剪切板中的方法
    * 方法1：先按住 `Shift` 键不放，用鼠标左键划取字符串，右键弹出的菜单中 `复制` 暂时可用
    * 方法2：可以通过改变鼠标模式使右键弹出的菜单中 `复制` 可用，输入 `:set mouse=v`
    * 方法3：一般模式下则连续输入三个字符 `"+y` 复制到系统剪切板
* 剪切板说明[详情点击](https://github.com/ruanyf/articles/blob/master/dev/vim/operation.md):
    * 注：先安装(若没有)vim-gtk3开启系统剪贴板：`sudo apt install vim-gtk3` (老版本为 `vim-gnome`)
    * vim提供12个剪贴板，名字分别为分别是`"` `0` `1` … `9` `a`。如果开启了系统剪贴板，则会另外多出两个 `+` `*` 。使用 `:reg` 命令，可以查看各个粘贴板里的内容
    * 在vim中简单用y只是复制到 `"(双引号)粘贴板` 里，同样用p粘贴的也是这个粘贴板里的内容

### 指令列的储存、离开等指令

* `:w`                  : 写入
* `:w!`                 : 强制写入
* `:q`                  : 离开
* `:q!`                 : 强制离开不储存档案
* `:wq`                 : 储存后离开
* `:wq!`                : 则为强制储存后离开
* `:qa!`                : 关闭所有打开的文件且不保存，上面6个命令都可以加a表示所有
* `ZZ`                  : 若档案没有更动，则不储存离开，若档案已经被更动，则储存后离开
* `Ctrl+z`              : 挂起
* `fg`                  : 恢复
* `:w [filename]`       : 将编辑的数据储存成另一个档案（类似另存新档）
* `:r [filename]`       : 在编辑的数据中，读入另一个档案的数据，亦即将filename这个档案内容加到游标所在行后面
* `:n1,n2 w [filename]` : 将 n1 到 n2 的内容储存成 filename 这个档案
* `:! command`          : 暂时离开 vi 到指令列模式下执行 command 的显示结果

### 多窗口

* `:e [f2]`             : 当前vim中开始编辑另一个文件，edit简写e
* `:tabe [f2]`          : 当前vim中打开一个新标签编辑另一个文件，tabedit简写tabe
* `:sp [f2]`            : 下面新建窗口打开文件，sp为split简写
* `:vsp [f2]`           : 右边新建窗口打开文件，vsp为vsplit简写
<p/>

* `vim -o [f1] [f2]`    : 上下窗口分别打开文件(shell)
* `vim -O [f1] [f2]`    : 左右窗口分别打开文件(shell)
<p/>

* `vimdiff [f1] [f2]`   : 左右窗口比较两个文件(shell)
* `:diffsp [f2]`        : 下面新建窗口打开文件，上下比较两个文件
* `:vertical diffsp [f2]` : 右边新建窗口打开文件，左右比较两个文件
* `:diffupdate`         : 刷新比较
* `zo / zc`             : 展开/恢复折叠
* `]c / [c`             : 下/上一个不同处
* `dp / do`             : dp此处当前窗口的不同同步到另一窗口，do相反
<p/>

* `:n`                  : 编辑下一个档案
* `:N`                  : 编辑上一个档案
* `:files`              : 列出目前这个 vim 的开启的所有档案
* `Ctrl+w+h/j/k/l`      : 光标移动到左/下/上/右方的窗口，同理 `Ctrl+w+←/↓/↑/→`
* `Ctrl+w+H/J/K/L`      : 当前窗口移动到左/下/上/右方
<p/>

* `:close`              : 可以关闭当前窗口(可以阻止你关闭最后一个vim)
* `:only`               : 关闭除当前窗口外的所有其它窗口
* `:qa`                 : 关闭所有窗口，qall简写qa
<p/>

* `:f` or `Ctrl+g`      : 查看当前文件名
* `:pwd`                : 查看当前文件路径
* `g+Ctrl+g`            : 统计字数

### 格式转换

* 行首TAB替换为空格
    ```
    :set ts=4
    :set expandtab
    :%retab
    ```

* 全部TAB替换为空格
    ```
    :set ts=4
    :set expandtab
    :%retab!
    ```

* 全部空格替换为TAB
    ```
    :set ts=4
    :set noexpandtab
    :%retab!
    ```

* TAB字符显示为 `>---`
    `set list lcs=tab:>-`  // lcs 是 listchars 的缩写

* 十六进制
    * `:%!xxd`          : 将当前文本转换为16进制格式
    * `:%!od`           : 将当前文本转换为8进制格式
    * `:%!xxd -c 12`    : 将当前文本转换为16进制格式，并每行显示12个字节
    * `:%!xxd -r`       : 将当前文件转换回文本格式

* 格式替换dos->unix
    ```
    :set fileformat=unix
    :write
    ```

* 文本对齐
    * `:{range} center [width]` : 中间对齐
    * `:{range} right [width]`  : 右对齐
    * `:{range} left [margin]`  : 左对齐，缩进个margin字符
    `{range}`是一个通常的命令行范围；
    `[width]`是一个用于指定行宽的可选参数，如果不指明`[width]`, 它的默认值取自'textwidth'，如果'textwidth'的值是 0, 就取 80

* 代码格式化
    * `:{range} =`  代码格式化
        * 例子：`gg=G` / `ggvG=` 全文代码格式化，gg跳转到文件首部，然后输入=G代码就全部格式化了；或gg跳转到文件首部，然后输入v进入可视模式，输入G全部选中，最后输入=代码就全部格式化了。

* 缩进
    * `>`               : 增加缩进，n> 表示增加n倍的缩进
    * `<`               : 减少缩进，n< 表示减少n倍的缩进

### 修改配置

* `:set nu/nonu`                : 显示/取消显示 行号
* `:set ignorecase/noignorecase`: 忽略/取消忽略 大小写
* `:set hlsearch/nohlsearch`    : 高亮/取消高亮 显示搜索
* `:set list/nolist`            : 显示/取消显示 特殊字符

## vim插件说明

在你的工程下生成索引文件(根据你的情况修改)
cd 你的工程目录 (如： cd ~/project) 输入shell命令
ctags -R --c++-kinds=+p --fields=+ialS --extra=+q
注释：为C++文件增加函数原型的标签。在标签文件中加入继承信息(i)、类成员的访问控制信息(a)、源文件语言包含信息(l)、以及函数的指纹(S)。为标签增加类修饰符。
gedit ~/.vimrc    修改vim配置文件
".vimrc中文件内容改为下面内容再修改 tags的路径即可（set tags+=你的工程目录/tags）

### ctags标签跳转

* ctags可以建立源码树的标签索引，使程序员在编程时能迅速定位函数、变量、宏定义等位置去查看原型
* ubuntu下载并安装ctags : `sudo apt install ctags`
* 配置见 [.vimrc文件的内容](#vimrc)
* 进入工程的根目录后，输入命令 `ctags -R *` 建立索引，目录下多了一个tags文件
* 向vim配置文件 `~/.vimrc` 加入 `set tags+=TagPath` 注册索引文件tags的路径

* 标签跳转返回
    * `vim -t TagName`      : 终端vim打开TagName所在的文件并跳到TagName所在的位置
    * `:tag TagName`        : 当前窗口跳到TagName标签
    * `:stag TagName`       : 新窗口跳到TagName标签
    * `:tags`               : 当前窗口跳到当前光标下单词的标签
    * `Ctrl+]`              : 当前窗口跳到当前光标下单词的标签
    * `Ctrl+w+]`            : 新窗口跳到当前光标下单词的标签
    * `Ctrl+t`              : 返回上一个标签
    * `Ctrl+o`              : 返回上一个标签

* 标签间移动(一个标签有多个匹配项)
    * `:ts`                 : 查看有tag标记的在哪些文件(tagsselect)
    * `:tp`                 : 上一个tag标记文件(tagspreview)
    * `:tn`                 : 下一个tag标记文件(tagsnext)
    * `:[count]tp`          : 向前 [count] 个匹配
    * `:[count]tn`          : 向后 [count] 个匹配
    * `:tfirst`             : 到第一个匹配
    * `:tlast`              : 到最后一个匹配

* 在预览窗口显示标签
    * `:Ctrl+w+}`           : 预览窗口显示当前光标下单词的标签，光标跳到标签处
    * `:ptag TagName`       : 预览窗口显示TagName标签，光标跳到标签处
    * `:pclose`             : 关闭预览窗口
    * `:pedit file.h`       : 在预览窗口中编辑文件file.h（在编辑头文件时很有用）
    * `:psearch str`        : 查找当前文件和任何包含文件中的单词并在预览窗口中显示匹配，在使用没有标签文件的库函数时十分有用

### vim-addons插件管理

* 通过vim-addons，我们可以管理vim插件
* ubuntu下载并安装vim-addons : `sudo apt install vim-scripts `
* 查看系统中已有的vim-scripts中包含的插件及其状态 : `vim-addons status`
* 安装vim-scripts插件 `vim-addons install xxxx`

### OmniCppComplete自动补全

* vim的自动补全功能可通过其插件OmniCppComplete实现
* 安装OmniCppComplete : `vim-addons install omnicppcomplete`
* 配置见 [.vimrc文件的内容](#vimrc)
* OmniCppComplete是基于ctags数据库即tags文件实现的，所以在ctags -R生成tags时还需要一些额外的选项，这样生成的tags文件才能与OmniCppComplete配合运作。
    * `ctags -R --c++-kinds=+p --fields=+ialS --extra=+q`
        * `--c++-kinds=+p`  : 为C++文件增加函数原型的标签
        * `--fields=+ialS`  : 在标签文件中加入继承信息(i)、类成员的访问控制信息(a)、源文件语言包含信息(l)、以及函数的指纹(S)
        * `--extra=+q`      : 为标签增加类修饰符。(如果没有此选项，将不能对类成员补全)

* 当自动补全下拉窗口弹出后，一些可用的快捷键
    * `Ctrl+P`              : 向前切换成员
    * `Ctrl+N`              : 向后切换成员
    * `Ctrl+E`              : 表示退出下拉窗口, 并退回到原来录入的文字
    * `Ctrl+Y`              : 表示退出下拉窗口, 并接受当前选项
* 其他补全方式
    * `Ctrl+X Ctrl+L`       : 整行补全
    * `Ctrl+X Ctrl+N`       : 根据当前文件里关键字补全
    * `Ctrl+X Ctrl+K`       : 根据字典补全
    * `Ctrl+X Ctrl+T`       : 根据同义词字典补全
    * `Ctrl+X Ctrl+I`       : 根据头文件内关键字补全
    * `Ctrl+X Ctrl+]`       : 根据标签补全
    * `Ctrl+X Ctrl+F`       : 补全文件名
    * `Ctrl+X Ctrl+D`       : 补全宏定义
    * `Ctrl+X Ctrl+V`       : 补全vim命令
    * `Ctrl+X Ctrl+U`       : 用户自定义补全方式
    * `Ctrl+X Ctrl+S`       : 拼写建议
* 帮助文档
    * `:help omnicppcomplete`

### echofunc函数原型提示

* echofunc可以在命令行中提示当前输入函数的原型
* [echofunc下载地址](http://www.vim.org/scripts/script.php?script_id=1735)
* 下载完成后，把echofunc.vim文件放到 ~/.vim/plugin 文件夹中
* 当你在vim插入(insert)模式下紧接着函数名后输入一个"("的时候, 这个函数的声明就会自动显示在命令行中。
    * 如果这个函数有多个声明, 则可以通过按键 `Alt+-` 和 `Alt+=` 向前和向后翻页
    * 这个两个键可以通过设置 `g:EchoFuncKeyNext` 和 `g:EchoFuncKeyPrev` 参数来修改。
    * 这个插件需要tags文件的支持, 并且在创建tags文件的时候要加选项 `--fields=+lS`
* 如果你在编译vim时加上了 `+balloon_eval` 特性，那么当你把鼠标放在函数名上的时候会有一个tip窗口弹出, 该窗口中也会有函数的声明

### Taglist标签浏览器

* Taglist用于列出了当前文件中的所有标签（宏, 全局变量, 函数名等）
* 安装Taglist : `vim-addons install taglist`
* 配置见 [.vimrc文件的内容](#vimrc)
* `:Tlist` 打开/关闭Taglist
* 帮助文档 `:help taglist.txt`

### WinManager文件浏览器

* WinManager用于管理文件浏览器和缓冲区（buffer）
* 2.0以上版本的WinManager还可以管理其他IDE类型插件，不过要用户在插件中增加一些辅助变量和hook来支持WinManager（帮助文档有相关说明）
* 可以用WinManager来管理 `文件浏览器netrw` 和 `标签浏览器Taglist`
    * netrw是标准的vim插件, 已经随vim一起安装进系统里了, 不需要我们自行下载安装。
* 安装WinManager : `vim-addons install winmanager`
* 配置见 [.vimrc文件的内容](#vimrc)
    * 在变量 `g:winManagerWindowLayout` 中
        * 使用 `,` 分隔的插件，在同一个窗口中显示，使用 `Ctrl+N` 在不同插件间切换
        * 使用 `|` 分隔的插件，则在另外一个窗口中显示
* `:WMToggle` 打开/关闭WinManage
*  winmanager帮助文档 `:help winmanager`
* netrw帮助文档 `:help netrw`

* 文件浏览器命令(在文件浏览器窗口中使用)
    * `Enter` or `双击`     : 如果光标下是目录, 则进入该目录; 如果光标下文件, 则打开该文件
    * `tab`                 : 如果光标下是目录, 则进入该目录; 如果光标下文件, 则在新窗口打开该文件
    * `F5`                  : 刷新列表
    * `-`                   : 返回上一层目录
    * `c`                   : 使浏览目录成为vim当前工作目录
    * `d`                   : 创建目录
    * `D`                   : 删除当前光标下的目录或文件
    * `I`                   : 切换显示方式
    * `R`                   : 文件或目录重命名
    * `s`                   : 选择排序方式
    * `r`                   : 反向排序列表
    * `x`                   : 定制浏览方式, 使用你指定的程序打开该文件

## MiniBufferExplorer缓冲管理器

* MiniBufferExplorer用于浏览和管理buffer
    * 如果只打开一个文件，是不会显示在屏幕上的，而打开多个文件之后，会自动出现在屏幕上
    * vim也有自带的buffer管理工具，不过只有 `:ls` `:bnext` `:bdelet`e 等的命令, 既不好用, 又不直观
* 关于vim缓冲区（buffer）和窗口的概念（详见:help windows）
    * "缓冲区" 是一块内存区域，里面存储着正在编辑的文件。如果没有把缓冲区里的文件存盘，那么原始文件不会被更改。
    * "窗口" 被用来查看缓冲区里的内容。你可以用多个窗口观察同一个缓冲区，也可以用多个窗口观察不同的缓冲区。
    * "屏幕" Vim 所用的整个工作区域，可以是一个终端模拟窗口，也被叫做"Vim 窗口"。一个屏幕包含一个或多个窗口，被状态行和屏幕底部的命令行分割。
        ```
        +-------------------------------+
        | 窗口 1        | 窗口 2        |
        |               |               |
        |               |               |
        |=== 状态行  ===|==== 状态行 ===|
        | 窗口 3                        |
        |                               |
        |                               |
        |========== 状态行 =============|
        |命令行                         |
        +-------------------------------+
        ```

* 安装MiniBufferExplorer : `vim-addons install minibufexplorer`
* 配置见 [.vimrc文件的内容](#vimrc)

* 快捷键
    * `Tab`                 : 移到上一个buffer
    * `Shift-Tab`           : 移到下一个buffer
    * `Enter`               : 打开光标所在的buffer
    * `d `                  : 删除光标所在的buffer

### fold代码折叠

* 折叠用于把缓冲区内某一范围内的文本行显示为屏幕上的一行。就像一张纸，要它缩短些，可以把它折叠起来
    ```
    +------------------------+
    | 行 1                   |
    | 行 2                   |
    | 行 3                   |
    |_______________________ |
    \                        \
    \________________________\
    / 被折叠的行             /
    /________________________/
    | 行 12                  |
    | 行 13                  |
    | 行 14                  |
    +------------------------+
    ```

    * 那些文本仍然在缓冲区内而没有改变。受到折叠影响的只是文本行显示的方式
    * 折叠的好处是，通过把多行的一节折叠成带有折叠提示的一行，会使你更好地了解对文本的宏观结构
* 帮助文档`:help fold.txt`

* 配置见 [.vimrc文件的内容](#vimrc)
    * 折叠方式foldmethod(6种)
        * `manual`          : 手工定义折叠
        * `indent`          : 更多的缩进表示更高级别的折叠
        * `expr`            : 用表达式来定义折叠
        * `syntax`          : 用语法高亮来定义折叠
        * `diff`            : 对没有更改的文本进行折叠
        * `marker`          : 对文中的标志折叠
    * 折叠级别foldlevel(数值选项：数字越大则打开的折叠更多)
        * 当 foldlevel 为 0 时，所有的折叠关闭
        * 当 foldlevel 为正数时，一些折叠关闭
        * 当 foldlevel 很大时，所有的折叠打开
    * 折叠栏foldcolumn
        * 'foldcolumn'是个数字，它设定了在窗口的边上表示折叠的栏的宽度，为0时，没有折叠栏；最大是12
        * 一个打开的折叠由一栏来表示，顶端是 '-'，其下方是 '|'，这栏在折叠结束的地方结束。当折叠嵌套时，嵌套的折叠出现在被包含的折叠右方一个字符位置
        * 一个关闭的折叠由 '+' 表示。
        * 当折叠栏太窄而不能显示所有折叠时，显示一数字来表示嵌套的级别。
        * 在折叠栏点击鼠标，可以打开和关闭折叠：
            * 点击 '+' 打开在这行的关闭折叠
            * 在任何其他非空字符上点击，关闭这行上的打开折叠

* 常用命令
    * `za`                  : 打开/关闭在光标下的折叠
    * `zA`                  : 循环地打开/关闭光标下的折叠
    * `zo`                  : 打开 (open) 在光标下的折叠
    * `zO`                  : 循环打开 (Open) 光标下的折叠
    * `zc`                  : 关闭 (close) 在光标下的折叠
    * `zC`                  : 循环关闭 (Close) 在光标下的所有折叠
    * `zM`                  : 关闭所有折叠
    * `zR`                  : 打开所有的折叠

### Cscope标签工具

* Cscope是一个类似于ctags的工具，不过其功能比ctags强大很多。
* 安装cscope : `sudo apt install cscope`
* 帮助文档 `:help if_cscop`

* 配置

```ts
" --Cscope setting--
if has("cscope")
" 指定用来执行cscope的命令
set csprg=/usr/bin/cscope
" 设置cstag命令查找次序：0先找cscope数据库再找标签文件；1先找标签文件再找cscope数据库
set csto=0
" 同时搜索cscope数据库和标签文件
set cst
" 使用QuickFix窗口来显示cscope查找结果
set cscopequickfix=s-,c-,d-,i-,t-,e-
set nocsverb
" 若当前目录下存在cscope数据库，添加该数据库到vim
if filereadable("cscope.out")
    cs add cscope.out
" 否则只要环境变量CSCOPE_DB不为空，则添加其指定的数据库到vim
elseif $CSCOPE_DB != ""
    cs add $CSCOPE_DB
endif
set csverb
endif
map <F12> :cs add ./cscope.out .<CR><CR><CR> :cs reset<CR>
imap <F12> <ESC>:cs add ./cscope.out .<CR><CR><CR> :cs reset<CR>
" 将:cs find c等Cscope查找命令映射为<C-_>c等快捷键
" 按法是先按Ctrl+Shift+-, 然后很快再按下c
nmap <C-_>s :cs find s <C-R>=expand("<cword>")<CR><CR> :copen<CR><CR>
nmap <C-_>g :cs find g <C-R>=expand("<cword>")<CR><CR>
nmap <C-_>d :cs find d <C-R>=expand("<cword>")<CR><CR> :copen<CR><CR>
nmap <C-_>c :cs find c <C-R>=expand("<cword>")<CR><CR> :copen<CR><CR>
nmap <C-_>t :cs find t <C-R>=expand("<cword>")<CR><CR> :copen<CR><CR>
nmap <C-_>e :cs find e <C-R>=expand("<cword>")<CR><CR> :copen<CR><CR>
nmap <C-_>f :cs find f <C-R>=expand("<cfile>")<CR><CR>
nmap <C-_>i :cs find i <C-R>=expand("<cfile>")<CR><CR> :copen<CR><CR>
```

* cscope的主要功能是通过其"find"子命令来实现的: `cs find c|d|e|f|g|i|s|t name`
    * `0` or `s`        : 查找这个 C 符号(可以跳过注释)
    * `1` or `g`        : 查找这个定义
    * `2` or `d`        : 查找这个函数调用的函数
    * `3` or `c`        : 查找调用过这个函数的函数
    * `4` or `t`        : 查找这个字符串
    * `6` or `e`        : 查找这个 egrep 模式
    * `7` or `f`        : 查找这个文件
    * `8` or `i`        : 查找包含这个文件的文件

* 用法：
    1. 为源码建立一个cscope数据库
        ```sh
        $ cscope -Rbq
        $ ls cscope.*
        cscope.in.out  cscope.out  cscope.po.out
        ```
    2. 用vim打开某个源码文件，输入 `:cs add cscope.out`，添加cscope数据库到vim(~/.vmrc中已经加入，就不需要这一步)
    3. 完成前两步后，现在就可以用“cs find c”等Cscope查找命令查找关键字了。我们已在.vimrc中将“cs find c”等Cscope查找命令映射为<C-_>c等快捷键（按法是先按Ctrl+Shift+-, 然后很快按下c）
帮助文档: `help if_cscop`

## VIM改造成IDE

* Vim本身的系统配置文件夹是在 `/usr/share/vim/` 和 `/etc/vim/` 两个文件夹下。
    * `/etc/vim/vimrc` 是全局的环境设定配置文件，将改变所有用户的vim配置
    * `~/.vimrc` 是用户自己的环境设定配置文件，只影响该用户自己
    * 一般情况下，我们不会去改变这两个文件夹下的配置文件，而是在家目录下建立自己的配置文件`~/.vim`。

### 插件安装(Ubuntu)

1. 首先安装好Vim和Vim的基本插件和ctags
    `sudo apt install vim vim-gtk3 vim-scripts vim-doc vim-addon-manager ctags`
2. 建立插件子目录和建立插件文档子目录
    `mkdir -p ~/.vim/plugin ~/.vim/doc ~/.vim/autoload`
3. 安装插件
    * 查看系统中已有的vim-scripts中包含的插件及其状态
        `vim-addons status`
    * 安装自动补全插件omnicppcomplete、标签浏览器插件taglist、文件浏览器和缓冲区管理器插件WinManager、buffer管理器插件MiniBufferExplorer、项目目录数管理器插件Project
        `vim-addons install omnicppcomplete taglist winmanager minibufexplorer project`
    * 下载并安装提示函数原型插件echofunc
        [echofunc](http://www.vim.org/scripts/script.php?script_id=1735)
        `cp echofunc.vim ~/.vim/plugin`
    * 下载并安装提示自动弹框插件autocomplpop并解压
        [autocomplpop](http://www.vim.org/scripts/script.php?script_id=1879)
        `cp vim-autocomplpop/* ~/.vim/ -a`
4. 修改vim配置文件(内容见 [.vimrc文件的内容](#vimrc) )
    `gedit ~/.vimrc`

5. Ubuntu 22.04兼容
    * ctags包名换成了universal-ctags
    * vim-scripts打包有问题，需要使用 [低版本包](http://mirror.nju.edu.cn/debian/pool/main/v/vim-scripts/vim-scripts_20180807_all.deb)
    `sudo apt-mark hold vim-scripts`

### 插件安装(RedHat系)

1. 安装vim和ctags `sudo dnf install vim-enhanced gvim vim-common ctags` 
2. RedHat系上没有vim-scripts包，所有插件需要手动安装，然后复制到 `~/.vim` 文件夹
    * [OmniCppComplete](https://www.vim.org/scripts/script.php?script_id=1520)
    * [TagList](https://www.vim.org/scripts/script.php?script_id=273)
    * [WinManager](https://www.vim.org/scripts/script.php?script_id=95)
    * [MiniBufExplorer](https://www.vim.org/scripts/script.php?script_id=159)
    * [Project](https://www.vim.org/scripts/script.php?script_id=69)
    * [echofunc](http://www.vim.org/scripts/script.php?script_id=1735)
    * [autocomplpop](http://www.vim.org/scripts/script.php?script_id=1879)
3. 修改vim配置文件(内容见 [.vimrc文件的内容](#vimrc) )
4. RedHat系上命令行vim不支持系统剪切板，需要安装插件实现
    * 下载安装xclip： `sudo dnf install xclip`
    * 下载安装插件 [fakeclip](https://www.vim.org/scripts/script.php?script_id=2098) 然后复制到 `~/.vim` 文件夹
    * 配置文件 `.vimrc` 增加 `let g:fakeclip_providers = ['xclip']  " 指定使用 xclip 作为后端`

### vimrc

```ts
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
```
