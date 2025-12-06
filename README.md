# 学习笔记 by 冷静

本工程是个人学习时的笔记，其中 `C/C++编程笔记` `Makefile编程笔记` `Markdown使用笔记` 等较为深入，其它笔记可能浅尝辄止。

## Linux环境配置方法

在 Ubuntu 2x.04 / Debian 13 / Fedora 42 / AlmaLinux 10 / RockyLinux 10 / Manjaro 25 上测试过的个人 Linux 开发环境 [一键安装脚本](./tool/init_env/init_env.sh) 。

## 生成文档方法

有以下两种生成文档的方式。

### 使用 rust 的 `mdbook` 生成

```sh
$ mdbook build
```

- 运行上面命令前需要安装一些工具，见Markdown使用笔记的章节 [mdbook使用](./src/md/note_markdown.md#mdbook使用)
- 生成html书籍，位于 `book/index.html`

### 使用 nodejs 的 `crossnote` 生成

```sh
$ cd src && ./md_auto_gen.sh
```

- 运行上面命令前需要安装一些工具，见Markdown使用笔记的章节 [crossnote脚本](./src/md/note_markdown.md#crossnote脚本)
- 生成html/pdf/epub书籍，位于 `books` 的相应文件夹下

## 笔记类型

### 编程笔记

- [C/C++编程笔记](./src/md/programming_c_cxx.md)
- [Linux应用编程笔记](./src/md/programming_app.md)
- [Linux驱动编程笔记](./src/md/programming_driver.md)
- [Python编程笔记](./src/md/programming_python.md)
- [Shell编程笔记](./src/md/programming_shell.md)
- [Makefile编程笔记](./src/md/programming_makefile.md)
- [Kconfig编程笔记](./src/md/programming_kconfig.md)

### 调试笔记

- [编译与调试笔记](./src/md/compile_debug.md)

### 学习笔记

- [SIMD学习笔记](./src/md/note_simd.md)
- [USB/UVC学习笔记](./src/md/note_usb_uvc.md)
- [Ubuntu学习笔记](./src/md/note_ubuntu.md)

### 工具笔记

- [Vim使用笔记](./src/md/note_vim.md)
- [Markdown使用笔记](./src/md/note_markdown.md)

### 源码学习

- [Linux IPC示例代码](./code/linux_ipc)
- [FFmpeg批量压制脚本](./code/video_convert/video_convert.sh)

## 版权声明

本项目采用 **知识共享署名-非商业性使用 4.0 国际许可协议 (CC BY-NC 4.0)** 进行授权。

- 您可以自由地：
    - **共享** — 在任何媒介以任何形式复制、发行本作品
    - **演绎** — 修改、转换或以本作品为基础进行创作

- 惟须遵守以下条件：
    - **署名(BY)** — 必须注明原作者和来源(如项目链接)，提供指向本许可协议的链接，并说明是否对作品作了修改。不得以任何方式暗示许可人为您或您的使用背书。
    - **非商业性使用(NC)** — 不得将本作品用于商业目的(包括但不限于直接销售、广告营销、商业服务等)。

- 完整协议内容请访问：https://creativecommons.org/licenses/by-nc/4.0/deed.zh

## 联系方式

* Phone: +86 18368887550
* wx/qq: 1083936981
* Email: lengjingzju@163.com 3090101217@zju.edu.cn
