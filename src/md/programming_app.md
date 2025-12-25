# Linux应用编程笔记

## 目录

[TOC]

## tlpi/apue 源码编译

* tlpi-dist 编译库

```
http://man7.org/tlpi/code/faq.html
error sys/capability.h: No such file or directory
$ sudo apt install libcap-dev
error sys/acl.h: No such file or directory
$ sudo apt install libacl1-dev
```

* apue 编译库

```
/usr/bin/ld cannot find -lbsd
sudo apt install libbsd-dev
```

## main函数和getopt

* 头文件

```c
#include <unistd.h>
#include <getopt.h>
```

### main函数

```c
int main(int argc, char *argv[], ... /* char *envp[] */)
    argc : 命令+命令行参数的总个数
    argv : 指针数组的成员指针则逐一指向每个命令行的参数项。argv[0] 标识程序名本身; argv[argc] 的值是 NULL。
    envp : 环境变量字符串数组，最后一个项为 NULL。
```

### 替换库函数

* 假设xxxx是我们需要替换的库函数名
* __wrap_xxxx是我们实现的替换库的函数
* 链接时加上链接选项-Wl,--wrap=xxxx
* 例如 LDFLAGS += -Wl,--wrap=malloc -Wl,--wrap=free
* 此时我们可以使用__real_xxxx调用实际的库函数
* 代码中使用xxxx的函数实际调用我们替换的库函数__wrap_xxxx
* -Wl选项告诉编译器将后面的参数传递给链接器

### getopt - 短命令行选项处理

```c
/*
 * 功能: 短命令行选项处理
 * 返回:
 *    1. 如果短选项找到，那么将返回短选项对应的字符
 *    2. 如果所有命令行选项都解析完毕，返回-1
 *    3. 如果遇到选项字符不在optstring中，返回字符'?'
 *    4. 如果遇到丢失参数，那么返回值依赖于optstring中第一个字符，如果第一个字符是':'则返回':'；否则返回'?'并提示出错误信息
 * IN  : argc       main函数的argc
 * IN  : argv       main函数的argv
 * IN  : optstring  要解析短选项命令串(短选项类似 -h)
 * 说明: 循环调用此函数，直到返回-1
 *   返回值  命令参数名称字符
 *   optarg  指向当前选项参数值(如果有)的指针，optarg = argv[optind - 1]
 *   optind  下一个将被处理到的参数在argv数组中的索引值
 *   opterr  如果opterr=0，在getoptxxx遇到错误将不会输出错误信息到标准输出流，opterr在非0时，向屏幕输出错误
 *   optopt  (如果有)最后一个未知选项
 * optstring("a:b::cd:") 分别表示程序支持的命令行短选项有-a、-b、-c、-d，冒号含义如下:
 *   不带冒号: 只表示选项，如-c
 *   带1个冒号: 选项后面带一个参数，如-a 100
 *   带2个冒号: 表示选项后面带一个可选参数，如果带参数，则选项与参数直接不能有空格，如-b 或-b200
 */
#include <unistd.h>
extern char *optarg;
extern int optind, opterr, optopt;
int getopt(int argc, char * const argv[],
          const char *optstring);
```

### getopt_long / getopt_long_only - 长命令行选项处理

```c
/*
 * 功能: 长命令行选项处理
 * 返回:
 *    1. 如果短选项找到，那么将返回短选项对应的字符
 *    2. 如果长选项找到，如果flag为NULL，返回val；如果flag不为NULL，返回0
 *    3. 如果所有命令行选项都解析完毕，返回-1
 *    4. 如果遇到一个选项没有在短字符、长字符里面，或者在长字符里面存在二义性的，返回'?'
 *    5. 如果选项需要参数，忘了添加参数，返回值取决于optstring，如果其第一个字符是':'，则返回':'，否则返回'?'
 * IN  : argc       main函数的argc
 * IN  : argv       main函数的argv
 * IN  : optstring  要解析短选项命令串，方法同getopt
 * IN  : longopts   见struct option说明
 * OUT : longindex  非空时指向当前解析符合的longopts数组的索引值
 * 说明: 循环调用此函数，直到返回-1
 * 区别：
 *   getopt_long只将--name当作长参数，但getopt_long_only会将--name和-name两种选项都当作长参数来匹配
 *   在getopt_long在遇到-name时，会拆解成-n -a -m -e到optstring中进行匹配
 *   而getopt_long_only只在-name不能在longopts中匹配时才将其拆解成-n -a -m -e这样的参数到optstring中进行匹配
 * 注意：
 *   longopts的最后一个元素必须是全0填充，否则会报段错误
 *   短选项中每个选项都是唯一的，而长选项如果简写，也需要保持唯一性
 */
#include <getopt.h>
struct option {
   const char *name;    // 长参数的名称(即形如--name的长参数名称name)
   int         has_arg; // 是否带参数(0: no_argument 不带[ --参数 ]，1: required_argument 必带[ --参数 值 或 --参数=值]，2 optional_argument: 可[ --参数=值 ])
   int        *flag;    // 空时getopt_xxx返回val，否则getopt_xxx返回0且将val的值赋给flag指针指向的整数中
   int         val;     // 表示找到该选项时getopt_xxx的返回值，或者当flag非空时指定flag指向的数据的值val
};
int getopt_long(int argc, char * const argv[],
          const char *optstring,
          const struct option *longopts, int *longindex);
int getopt_long_only(int argc, char * const argv[],
          const char *optstring,
          const struct option *longopts, int *longindex);
```

### 时间

* 头文件

```c
#include <time.h>
#include <sys/time.h>
```

### gettimeofday / time / settimeofday / adjtime - 获取/设置utc时间

```c
/*
 * 功能: 获取/设置utc时间
 * 返回: gettimeofday成功返回0，失败返回-1
 * tv    返回/设置的时间，tv_sec是秒，tv_usec是微秒
 * tz    时区，已废弃，应该置为 NULL
 * timep 不为NULL时放置返回的时间，可以为NULL
 * delta 需要调整的时间，系统时间 = 原来的系统时间 + delta。
 * olddelta 按delta调整的时间可能未调整完成，剩下未调整的放入olddelta，可以为NULL
 */
struct timeval {
    time_t      tv_sec;     /* Seconds since 00:00:00, 1 Jan 1970 UTC */
    suseconds_t tv_usec;    /* Additional microseconds (long int) */
};
int gettimeofday(struct timeval *tv, struct timezone *tz);
time_t time(time_t *timep);
int settimeofday(const struct timeval *tv, const struct timezone *tz);
int adjtime(struct timeval *delta, struct timeval *olddelta);
```

### gmtime / localtime / mktime - 秒数和分解时间转换

```c
/*
 * 功能: 秒数和分解时间转换
 * 返回: gmtime/localtime 成功返回静态分配的UTC/本地分解时间指针，失败返回NULL
 *       mktime 成功返回时间秒数，失败返回-1
 * 说明: gmtime_r() 和 localtime_r()为对应的可重入版本。
 * tm_sec可以为60是考虑闰秒，DST表示夏令时，= 0不考虑夏令时，> 0，总是夏令时; < 0，按日期是否设置夏令时。
 * mktime的timeptr不需要遵循tm限制，超过显示会自动计算进位。
 */
struct tm {
    int tm_sec;     /* Seconds (0-60) */7
    int tm_min;     /* Minutes (0-59) */
    int tm_hour;    /* Hours (0-23) */
    int tm_mday;    /* Day of the month (1-31) */
    int tm_mon;     /* Month (0-11) */
    int tm_year;    /* Year since 1900 */
    int tm_wday;    /* Day of the week (Sunday = 0)*/
    int tm_yday;    /* Day in the year (0-365; 1 Jan = 0)*/
    int tm_isdst;   /* Daylight saving time flag*/
};
struct tm *gmtime(const time_t *timep);
struct tm *localtime(const time_t *timep);
time_t mktime(struct tm *timeptr);
```

### ctime / asctime / strftime/ strptime - 格式化日期时间

```c
/*
 * 功能: 格式化日期时间
 * 返回: ctime/asctime 成功返回静态分配的时间字符串指针，失败返回NULL
 *       strftime tm时间到字符串，成功返回字节长度，并将时间字符串写入outstr，失败返回0
 *       strptime 字符串到tm时间，成功返回str的下一个未被处理的字符，并将分解时间写入timeptr，失败返回NULL
 * 说明: ctime_r()为对应的可重入版本。
 * ctime/asctime返回字符串类似 "Wen Jun  8 18:00:00 2011\n"
 * ctime是本地时间，format格式化选项见(P158表10-1)
 */
char *ctime(const time_t *timep);
char *asctime(struct tm *timeptr);
size_t strftime(char *outstr, size_t maxsize, const char *format, const struct tm *timeptr);
char *strptime(const char *str, const char *format, struct tm *timeptr);
```

### times / clock - 检索进程时间信息

```c
/*
 * 功能: 检索进程时间信息
 * 返回: 成功返回进程的总的时钟数，失败返回-1
 * 说明: clock_t 单位为 CLOCKS_PER_SEC(如10000)，
 * 系统定时器时钟频率(节拍率)HZ(用户空间为USER_Hz) <asm/param.h>: X86中默认100，新版默认1000，可调。
 * 全局变量jiffies(jiffies_64和jiffies分别是64位和32位的全局变量)用来记录自系统启动以来产生的节拍的总数。注意处理节拍回绕(溢出)。
 * 提高时间节拍率会带来更高的时间中断解析度，可提高时间驱动事件的解析度和准确度(平均误差为半个时钟周期)。
 */
struct tms {
    clock_t tms_utime;  /* User CPU time used by caller */
    clock_t tms_stime;  /* System CPU time used by caller */
    clock_t tms_cutime; /* User CPU time of all (waited for) children */
    clock_t tms_cstime; /* System CPU time of all (waited for) children */
};
clock_t times(struct tms *buf);
clock_t clock(void);
```

## 文件I/O

### 文件基本知识

* 文件描述符为非负整数。
* 文件结束符EOF(End Of File): 在UNIX中，EOF表示能从交互式shell(终端)送出 Ctrl+D (习惯性标准)。在微软的DOS与Windows中送出 Ctrl+Z 。EOF的值通常为-1，但它依系统有所不同。
* 系统提供/dev/fd/目录，Unix打开/dev/fd/n 相当于复制文件描述符n(有些os可以会忽略mode给的值，有些要求mode是实际mode的子集)。Linux表现不同，Linux把/dev/fd/n当做符号链接。有些系统提供/dev/fd/stdin, /dev/fd/stdout, /dev/fd/stderr 文件。
    * STDIN_FILENO  标准输入(stdin) : 文件描述符为 0, 使用 < 或 <<
    * STDOUT_FILENO 标准输出(stdout): 文件描述符为 1, 使用 > 或 >> (> 覆盖 / >>累加)
    * STDERR_FILENO 标准错误输出(stderr): 文件描述符为 2, 使用 2> 或 2>>

* 内核维护的文件层次
    * 进程级的文件描述符表(文件描述符): 文件描述符标志(目前只有O_CLOEXEC标志); 对打开文件句柄的引用
    * 系统级的打开文件表(打开文件句柄): 文件标志; 当前文件的偏移量; 对文件i-node对象的引用
        * 注: 两个不同的文件描述符，可能指向同一文件句柄，他们共享文件偏移量和文件标志。
    * 文件系统的i-node表: 文件类型和访问权限; 文件的各种属性(文件大小和时间戳等); 指向文件持有锁列表的指针

### open()函数 flags 标志

* 文件描述符标志(F_GETFD / F_SETFD):
    * O_CLOEXEC     : 设置close-on-exec标志，exec()会关闭文件描述符。dup族函数得到新的文件描述符会清除此标志。

* 创建文件标志(无)
    * O_CREAT       : 文件不存在则创建，需要指定mode参数
    * O_EXCL        : 与O_CREAT参数结合使用(O_CREAT | O_EXCL)，文件如果已经存在(或是符号链接)则调用失败，错误号 EEXIST
    * O_TRUNC       : 清空已有文件，文件长度变为0，需要写或读写模式打开文件
    * O_NOFOLLOW    : 文件名字如果是符号链接则调用失败，错误号 ELOOP
    * O_DIRECTORY   : 文件名字如果不是目录则调用失败，错误号 ENOTDIR
    * O_NOCTTY      : 不让指向终端设备的文件名字成为控制终端，非终端设备此标志无效
    * O_LARGEFILE   : 32位系统使用此标志打开大文件，64位系统无效，Linux不支持此标志，而是定义宏_FILE_OFFSET_BITS值为64

* 文件状态标志(打开模式)(F_GETFL):
    * O_RDONLY      : 0 只读打开
    * O_WRONLY      : 1 只写打开
    * O_RDWR        : 2 读写打开
    * O_EXEC        : 只执行打开
    * O_SEARCH      : 只搜索打开目录(还没有实现支持)
        * 注: 上面5种模式只能指定其中1种，判断模式 accessMode = flag & OACCMODE, 将 accessMode 与上面的某1种模式比较。

* 文件状态标志(F_GETFL / F_SETFL)
    * O_APPEND      : 追加写，每次写操作之前，将文件偏移量设置在当前文件结尾处。
    * O_NONBLOCK    : 以非阻塞方式打开(终端、管道、FIFO、socket等)，普通文件忽略此标志。
        * open类调用(非FIFO)未能立即打开文件则返回错误，而不是阻塞。
        * 后续I/O操作未能立即完成，则可能只传输部分数据，或者系统调用失败(错误号 EAGAIN 或 EWOULDBLOCK )
    * O_SYNC        : 等待写完成(数据和属性)，每次write()调用会自动将文件数据和元数据刷新到磁盘，类似fsync()
    * O_DSYNC       : 等待写完成(仅数据)，每次write()调用会自动将文件数据刷新到磁盘，类似fdatasync()
    * O_RSYNC       : 同步读和写，和O_SYNC或O_DSYNC联用，每次read()前会自动将“文件数据和元数据”或“文件数据”刷新到磁盘。
    * O_FSYNC       : 等待写完成
    * O_ASYNC/FASYNC: 信号驱动I/O，I/O操作可行时，产生信号通知进程，只对特定类型文件(终端、FIFO、socket等)有效
        * Linux中open()设置此标志无效，必须调用fcntl()的F_SETFL操作设置O_ASYNC标志
    * O_DIRECT      : 直接I/O，无缓冲输入/输出，不使用内核缓冲，直接写磁盘。
        * 直接I/O的传递数据的缓冲区内存边界(memalign分配)、传递数据长度、数据传输开始点(文件偏移量)必须是块大小的整数倍。
    * O_NOATIME     : 调用read()不修改最近访问时间，需要特权进程或进程的有效用户ID与文件uid匹配，否则调用失败，错误号 EPERM

* open() 的 mode 标志
    * S_ISUID 保存用户ID
    * S_ISGID 保存组ID

    | 所有者  | 所有组  | 其它人   | 权限说明 |
    | ---     | ---     | ---     | ---  |
    | S_IRUSR | S_IRGRP | S_IROTH | 可读 |
    | S_IWUSR | S_IWGRP | S_IWOTH | 可写 |
    | S_IXUSR | S_IXGRP | S_IXOTH | 可执行 |
    | S_IRWXU | S_IRWXG | S_IRWXO | 可读/写/执行 |

    * 除了可以通过上述宏进行“或”逻辑产生标志以外，我们也可以自己用数字来表示，Linux用5个数字来表示文件的各种权限
    * 第1位表示保存用户ID；第2位表示保存组ID；第3位表示用户自己的权限位；第4位表示组的权限；最后2位表示其他人的权限
    * 设置用保存ID 保存组ID的数字可以取1或0
    * 其他位的每个数字可以取1（执行权限）、2（写权限）、4（读权限）、0（无）或者是这些值的和

* 错误指示
* ENOENT  : 文件不存在却未设置O_CREAT，或设置了O_CREAT但文件路径的目录不存在或是空链接
* EEXIST  : 文件存在却设置了O_CREAT | O_EXCL
* EAGAIN  : 操作不成功(O_NONBLOCK标志)不阻塞立即返回的错误
* ESPIPE  : lseek()用于管道、FIFO、socket、终端。
* EACCES  : 权限限制无法访问或创建文件
* EISDIR  : 文件是目录却试图写，文件不是目录却设置了O_DIRECTORY
* EMFILE  : 文件描述符数量达到进程资源上限
* ENFILE  : 文件描述符数量达到系统允许上限
* EROFS   : 只读文件系统却试图写打开
* ETXTBSY : 可执行文件正在运行却试图写
* EINVAL  : 文件系统不支持O_DIRECT，O_DIRECT不符合块大小的整数倍。

## I/O 系统调用

* 头文件

```c
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <unistd.h>
```

### open / openat / creat - 新建或打开文件

```c
/*
 * 功能: 新建或打开文件
 * 返回: 成功返回进程的未用文件描述符中数值最小者(SUSv3规定)，失败返回-1
 * IN  : pathname   文件名字，默认符号链接会解引用
 * IN  : flags      访问标志
 * IN  : mode       访问权限，flags未指定O_CREAT时可省略mode
 * 说明: 不推荐使用creat(pathname, mode)新建文件，creat是只写模式，并且文件存在会清空文件内容
 * openat() 如果pathname是绝对路径，fd忽略，否则如果fd是 AT_FDCWD，则pathname相对当前工作目录路径，否则pathname相对fd文件所在目录路径。
 * 文件访问权限受 访问权限mode 、进程的umask、父目录默认访问控制共同影响。
 */
#include <sys/stat.h>
#include <fcntl.h>
int open(const char *pathname, int flags, ... /* mode_t mode */);
int openat(int fd, const char *pathname, int flags, ... /* mode_t mode */);
int creat(const char *pathname, mode_t mode);  // ==> open(pathname, O_CREAT | O_WRONLY | O_TRUNC, mode);
```

### read / pread / readv / preadv - 读取文件内容

```c
/*
 * 功能: 读取文件内容
 * 返回: 成功返回读取字节数(EOF返回0)，失败返回-1
 * IN  : fd         文件描述符
 * OUT : buffer     读取的数据存放的缓冲区
 * IN  : count      要读取数据的最大字节数，返回的读取字节数可能小于count
 * pread() 为指定偏移处读，且不会改变文件的当前偏移量
 * readv() 分散输入，从文件描述符位置读取一片连续的字节，散置于iov指定的缓冲区中，原子操作
 * preadv() 为指定偏移处分散输入
 * 从终端读取数据，默认遇到换行符'\n'调用终止，返回数据包括换行符。
 * read()不会在字符串末尾自动添加空字符'\0'。
 */
struct iovec {
    void   *iov_base;
    size_t  iov_len;
};
#include <unistd.h>
ssize_t read(int fd, void *buffer, size_t count);
ssize_t pread(int fd, void *buffer, size_t count, off_t offset);
#include <sys/uio.h>
ssize_t readv(int fd, const struct iovec *iov, int iovcnt);
ssize_t preadv(int fd, const struct iovec *iov, int iovcnt, off_t offset);
```

### write / pwrite / writev / pwritev - 写入文件内容

```c
/*
 * 功能: 写入文件内容
 * 返回: 成功返回写入字节数，失败返回-1
 * IN  : fd         文件描述符
 * IN  : buffer     要写入的数据存放的缓冲区
 * IN  : count      要写入的字节数，返回的写入字节数可能小于count
 * pwrite() 为指定偏移处写，且不会改变文件的当前偏移量
 * writev() 集中输出，将iov指定的缓冲区中数据连续写入文件，原子操作
 * pwritev() 为指定偏移处集中输出
 */
#include <unistd.h>
ssize_t write(int fd, void *buffer, size_t count);
ssize_t pwrite(int fd, void *buffer, size_t count, off_t offset);
#include <sys/uio.h>
ssize_t writev(int fd, const struct iovec *iov, int iovcnt);
ssize_t pwritev(int fd, const struct iovec *iov, int iovcnt, off_t offset);
```

### lseek - 改变文件偏移量

```c
/*
 * 功能: 改变文件偏移量
 * 返回: 成功返回新的偏移字节数，失败返回-1
 * IN  : fd         文件描述符
 * IN  : offset     相对偏移量
 * IN  : whence     参考位置，SEEK_SET 0 文件开头; SEEK_CUR 1 当前位置; SEEK_END 2 文件结尾。
 * 说明: 文件偏移量指的是当前位置相对文件头部的偏移字节数，文件第一个字节的偏移量为0。
 * 文件打开时，会将文件偏移量指向文件开始(未设置O_APPEND标志)。每次read() / write()调用会自动对偏移量进行调整，指向已读已写数据后的下一字节。
 * cur_offset = lseek(fd, 0, SEEK_CUR); //当前文件偏移量
 * lseek()不能用于管道、FIFO、socket、终端，否则返回错误，错误码 ESPIPE。
 * SEEK_CUR和SEEK_END时，offset可以为正负数; SEEK_SET时，offset只能为正数。
 * 文件偏移可以跨越文件结尾，在跨越结尾的偏移处写数据会在文件结尾到跨越结尾的偏移处形成文件空洞，读取空洞会以0填充buffer。
 * 一般不允许seek到文件头之前(有些设备支持负的偏移量)。
 */
#include <unistd.h>
off_t lseek(int fd, off_t offset, int whence);
```

### close - 关闭文件

```c
/*
 * 功能: 关闭文件
 * 返回: 成功返回0，失败返回-1
 * IN  : fd         文件描述符
 * 说明: 关闭一个文件会自动释放该进程加在该文件上的所有记录锁。进程关闭会自动关闭其打开的文件描述符。
 */
#include <unistd.h>
int close(int fd);
```

### fcntl - 文件控制操作

```c
/*
 * 功能: 文件控制操作
 * 返回: 成功返回取决于cmd，失败返回-1
 * IN  : fd         文件描述符
 * IN  : cmd        命令，F_GETFL 检索; F_SETFL 修改
 * fcntl函数作用:
 * F_DUPFD / F_DUPFD_CLOEXEC    复制文件描述符号，说明见dup
 * F_GETFD / F_SETFD            获取/设置文件描述符标志，只有O_CLOEXEC标志
 * F_GETFL / F_SETFL            获取/设置文件状态标志
 * F_GETOWN / F_SETOWN          获取/设置异步IO(SIGIO SIGURG)所有权(进程ID(正值)和进程组ID(负值))
 * F_GETLK / F_SETLK / F_SETLKW 获取/设置文件锁
 * 说明: 除F_GETLK外，F_GETXXX 不需要填写第3个参数，函数返回值是特定值。
 */
#include <fcntl.h>
int fcntl(int fd, int cmd, ... /* int arg */);
```

### ioctl - I/O 万能控制

```c
/*
 * 功能: I/O 万能控制
 * 返回: 成功返回依赖request，失败返回-1
 * IN  : fd         文件描述符
 * IN  : request    请求
 */
#include <sys/ioctl.h>
int ioctl(int fd, int request, ... /* argp */);
```

### dup / dup2 / dup3 - 复制文件描述符

```c
/*
 * 功能: 复制文件描述符
 * 返回: 成功返回新的文件描述符(和oldfd指向同一文件句柄)，失败返回-1
 * IN  : oldfd      旧的文件描述符，若oldfd无效，返回错误且不关闭newfd，错误号 EBADF
 * IN  : newfd      新的的文件描述符，若newfd之前已经打开，会首先将其关闭，若oldfd == newfd，直接返回newfd，且不将其关闭。
 * IN  : flags      设置的标志，仅支持 O_CLOEXEC。
 * 说明: dup() 返回编号最低的未使用的文件描述符，dup2() dup3()返回指定的文件描述符newfd
 * newfd = fcntl(oldfd, F_DUPFD, startfd) 返回“>=startfd”的编号最低的未使用的文件描述符
 * newfd = fcntl(oldfd, F_DUPFD_CLOEXEC, startfd) 返回“>=startfd”的编号最低的未使用的文件描述符，并设置O_CLOEXEC标志。
 * 2 > &1  <==> dup2(1, 2) : 将标准错误重定向到标准输出
 * dup类函数得到的新文件描述符默认会关闭O_CLOEXEC标志。
 */
#include <unistd.h>
int dup(int oldfd);
int dup2(int oldfd, int newfd);
int dup3(int oldfd, int newfd, int flags);
```

### truncate / ftruncate - 设置文件长度

```c
/*
 * 功能: 设置文件长度
 * 返回: 成功返回0，失败返回-1
 * IN  : pathname   文件名字，truncate()需要写权限，无需事先open文件，会对符号链接解引用。
 * IN  : fd         文件描述符，ftruncate()需要可写打开，不会改变当前文件偏移量。
 * IN  : length     设置的文件长度，小于当前文件长度则截断文件，大于当前文件长度则文件尾部填0形成空洞
 */
#include <unistd.h>
int truncate(const char *pathname, off_t length);
int ftruncate(int fd, off_t length);
```

### fsync / fdatasync / sync - 强制刷新内核缓冲到磁盘

```c
/*
 * 功能: 强制刷新内核缓冲到磁盘
 * 返回: 成功返回0，失败返回-1，
 * IN  : fd         文件描述符
 * 说明:
 * fsync()将文件数据和元数据刷新到磁盘，fdatasync()只将文件数据刷新到磁盘。
 * fsync()和fdatasync()需要等待刷新磁盘完成调用才会返回。
 * sync()将包含更新文件信息的所有内核缓冲区(数据块、指针块、与数据等)刷新到磁盘。
 * sync()调用，SUSv3规定直接返回，Linux需要等待刷新磁盘完成调用才会返回。Linux pdflush内核进程自动执行刷新。
 * 文件内容有4个区域:磁盘区、内核缓冲区、stdio缓冲区、用户数据区。 tlpi.P228.<图13.1:I/O缓冲小结>
 * read()和write()系统调用在操作磁盘文件时不会直接发起磁盘访问，而是仅仅在用户空间缓存区和内核空间缓存区(页面高速缓存)之间复制数据。
 * 数据传输时间取决于:系统调用时间、缓存之间交换数据时间、页面高速缓存和磁盘之间交换数据时间。
 */
#include <unistd.h>
int fsync(int fd);
int fdatasync(int fd);
void sync(void);
```

## 目录和链接

* 文件由i-node和数据块组成。i-node存储文件的各种属性(struct stat)和指向文件数据块的指针信息。i-node中不包含文件的名称。
* 目录是特殊的文件，目录的数据是列出文件名和i-node编号之间对应关系的一个表格。不能直接调用read()/write()。
* 硬链接就是目录数据中一条文件名和i-node编号对应关系的条目。文件i-node的硬链接引用数变为0时，会自动删除文件(的i-node和数据块)。
* 软链接(符号链接)是一个文件，文件的数据是文件的名称，可能不会分配数据块。一般访问符号链接会解引用，访问指向的文件。

* 头文件

```c
#include <sys/stat.h>
#include <unistd.h>
#include <stdio.h>
#include <dirent.h>
```

### remove - 删除一个文件或目录(库函数)

```c
/*
 * 功能: 删除一个文件或目录(库函数)
 * 返回: 0，成功; -1，失败
 * 说明: 不会对符号链接解引用，文件是目录时调用rmdir()，否则调用unlink()
 */
#include <stdio.h>
int remove(const char *pathname);
```

### unlink - 删除文件的一个名字(硬链接)

```c
/*
 * 功能: 删除文件的一个名字(硬链接)
 * 返回: 0，成功; -1，失败
 * 说明:  不会对符号链接解引用，如果这个名字指向一个符号链接，则立即删除这个符号链接。
 * 可用于文件、socket、fifo或者一个设备，立即从文件系统中删除一个名字。
 * 删除一个名字后，打开这个文件的进程还可以继续对这个文件进行操作。
 * 当所有进程关闭这个文件的文件描述符并且文件的硬链接计数变为0，还会删除文件本身。
 * unlink()后如果再次open()同样名字的文件，必须使用O_CREAT标志，将会创建一个新的文件。
 * unlink()不能删除一个目录，删除目录使用rmdir()或remove()
 */
#include <unistd.h>
int unlink(const char *pathname);
```

### link - 给文件创建一个新名字(硬链接)
```c
/*
 * 功能: 给文件创建一个新名字(硬链接)
 * bash: ln oldpath newpath
 * 返回: 0，成功; -1，失败
 * IN  : oldpath    文件原有名字，调用link()后还可以通过oldpath访问文件
 * IN  : newpath    文件新的名字，newpath调用前不能存在，否则调用失败，错误号EEXIST
 * 说明:  不会对符号链接解引用
 * 不能对目录创建硬链接，不能对其它文件系统分区的文件创建硬链接。(符号链接没有这2个限制)
 */
#include <unistd.h>
int link(const char *oldpath, const char *newpath);
```

### symlink - 创建一个符号链接文件

```c
/*
 * 功能: 创建一个符号链接文件
 * bash: ln -s filepath linkpath
 * 返回: 0，成功; -1，失败
 * IN  : filepath   文件名字，filepath调用前无需存在
 * IN  : linkpath   符号链接文件的名字，linkpath调用前不能存在，否则调用失败，错误号EEXIST
 */
#include <unistd.h>
int symlink(const char *filepath, const char *linkpath);
```

### readlink - 读取符号链接的文件内容

```c
/*
 * 功能: 读取符号链接的文件内容
 * 返回: 成功返回读取字节数; 失败返回-1
 * OUT : buffer     读取的文件内容
 * IN  : bufsiz     buffer的大小，PATH_MAX。
 * 说明: 不会对符号链接解引用
 * 若符号链接内容长度大于bufsiz，会返回部分内容
 */
#include <unistd.h>
ssize_t readlink(const char *pathname, char *buffer, size_t bufsiz);
```

### rename - 移动/重命名文件

```c
/*
 * 功能: 移动/重命名文件
 * 返回: 0，成功; -1，失败
 * 说明: 不会对符号链接解引用，rename对文件名进行操作
 * newpath 和 oldpath 同名时不进行任何操作且调用成功
 * newpath 已有文件存在时，会删除newpath原先指向的文件
 * oldpath 为文件时，newpath如果原先指向目录名则调用失败，错误号 EISDIR
 * oldpath 为目录时，newpath如果原先指向已有文件则调用失败，错误号 ENOTDIR
 * oldpath 为目录时，newpath如果原先指向非空目录则调用失败,错误号 ENOTTEMPTY
 * oldpath 为目录时, newpath如果是包含oldpath作为目录前缀则调用失败,错误号 EINVAL
 * 如果 newpath 和 oldpath 不是同一文件系统则调用失败,错误号 EXDEV
 */
#include <unistd.h>
int rename(const char *oldpath, const char *newpath);
```

### mkdir - 创建一个新的目录

```c
/*
 * 功能: 创建一个新的目录
 * 返回: 0，成功; -1，失败
 * IN  : pathname   目录名字，pathname调用前不能存在，否则调用失败，错误号EEXIST
 * IN  : mode       权限模式，对set-user-id(s) set-group-id(s) sticky(t)的设置依赖实现
 */
#include <sys/stat.h>
int mkdir(const char *pathname, mode_t mode);
```

### rmdir - 删除一个空目录

```c
/*
 * 功能: 删除一个空目录
 * 返回: 0，成功; -1，失败
 * 说明: 不能删除非空目录
 * 如果pathname是符号链接，调用失败，错误号 ENOTDIR
 */
#include <unistd.h>
int rmdir(const char *pathname);
```

### opendir / fdopendir - 打开一个目录

```c
/*
 * 功能: 打开一个目录
 * 返回: 成功返回目录流句柄; 失败返回-1
 * 说明: 不会对符号链接解引用，文件是目录时调用rmdir()，否则调用unlink()
 */
#include <dirent.h>
DIR *opendir(const char *dirpath);
DIR *fdopendir(int fd);
```

### readdir - 读取目录条目(非重入)

```c
/*
 * 功能: 读取目录条目(非重入)
 * 返回: 成功返回目录的一条条目(静态分配的数据)的指针; 失败或结尾返回NULL
 * 说明: 每调用readdir()一次，就从dirp目录流中读取下一条目，条目的顺序是添加条目的顺序
 */
#include <dirent.h>
struct dirent {
    ino_t   d_ino;      /* File i-node number */
    char    d_name[];   /* Null-terminated name of file */
    ...
};
struct dirent *readdir(DIR *dirp);
```

### readdir_r - 读取目录条目(重入版)

```c
/*
 * 功能: 读取目录条目(重入版)
 * 返回: 0, 成功; > 0 ,失败
 * OUT : entry      读取到目录条目存放的buffer
 * OUT : result     如果读取到目录条目，则写入buffer的地址，如果目录流结尾则写入NULL
 * 说明: readdir_r()一次，就从dirp目录流中读取下一条目
 */
#include <dirent.h>
int readdir_r(DIR *dirp, struct dirent *entry, struct dirent **result);
```

### closedir - 关闭目录

```c
/*
 * 功能: 关闭目录
 * 返回: 成功返回0; 失败返回-1
 */
#include <dirent.h>
int closedir(DIR *dirp);
```

### telldir - 告诉目录流当前的偏移位置

```c
/*
 * 功能: 告诉目录流当前的偏移位置
 */
#include <dirent.h>
long telldir(DIR *dirp);
```

### rewinddir - 将目录流位置回移到起点

```c
/*
 * 功能: 将目录流位置回移到起点
 */
#include <dirent.h>
void rewinddir(DIR *dirp);
```

### seekdir - 将目录流位置移到到指定位置

```c
/*
 * 功能: 将目录流位置移到到指定位置
 */
#include<dirent.h>
void seekdir(DIR *dirp, long offset);
```

### dirfd - 目录流句柄转换为文件描述符

```c
/*
 * 功能: 目录流句柄转换为文件描述符
 * 返回: 成功返回文件描述符; 失败返回-1
 */
#include <dirent.h>
int dirfd(DIR *dirp);
```

### nftw - 文件树递归遍历

```c
/*
 * 功能: 文件树递归遍历(P300)
 * 返回: 完全遍历返回0; 失败返回-1; 成功返回func返回的第一个非0值
 * IN  : dirpath    目录名
 * IN  : func       对遍历到的文件执行的函数，如果返回0，会继续nftw遍历，返回非0停止nftw遍历
 * IN  : nopenfd    最大持有的文件描述符数目
 * IN  : flags      遍历顺序标志
 */
#include <ftw.h>
int nftw(const char *dirpath,
                int (*func) (const char *pathname, const struct stat *statbuf, int typeflag, struct FTW *ftwbuf),
                int nopenfd,
                int flags);
```

### getcwd - 获取当前工作目录

```c
/*
 * 功能: 获取当前工作目录
 * 返回: 成功返回cwdbuf地址并将绝对路径写入cwdbuf; 失败返回NULL
 * OUT : cwdbuf     返回的绝对路径名存储的缓冲区
 * IN  : size       buffer的大小，一般设为PATH_MAX。如果当前工作目录名的实际长度大于size，将调用失败，错误号 ERANGE
 * 说明: 若buffer为NUL且size为0，调用会malloc一块内存返回。
 */
#include <unistd.h>
char *getcwd(char *cwdbuf, size_t size);
```

### chdir / fchdir - 改变当前工作目录

```c
/*
 * 功能: 改变当前工作目录
 * 返回: 成功返回0; 失败返回-1
 */
#include <unistd.h>
int chdir(const char *pathname);
int fchdir(int fd);
```

### chroot - 改变进程的根目录(特权程序)

```c
/*
 * 功能: 改变进程的根目录(特权程序)
 * 返回: 成功返��0; 失败返回-1
 */
#include <unistd.h>
int chroot(const char *pathname);
```

### realpath - 解析路径名

```c
/*
 * 功能: 解析路径名
 * 返回: 成功返回resolved_path地址并将绝对路径写入resolved_path; 失败返回NULL
 * OUT : resolved_path  返回的绝对路径名存储的缓冲区，至少为PATH_MAX长，若为空会自动malloc一块空间，需要自己free
 */
#include <stdlib.h>
char *realpath(const char *pathname, char *resolved_path);
```

### dirname / basename - 解析路径字符串(不可重入)

```c
/*
 * 功能: 解析路径字符串(不可重入)
 * 返回: dirname()成功返回父目录地址; 失败返回NULL
 *       basename()成功返回不含路径的文件名地址; 失败返回NULL
 * 说明: 忽略pathname末尾的斜杠 '/'
 * pathname为"/home/lengjing/"，dirname()返回"/home" ， basename返回"lengjing"
 * pathname不含斜杠，  dirname()返回 "." ， basename返回 pathname
 * pathname只含斜杠，  dirname()返回 "/" ， basename返回 "/"
 * pathname为空字符串，dirname()返回 "." ， basename返回 "."
 */
#include <libgen.h>
char *dirname(const char *pathname);
char *basename(const char *pathname);
```

## stdio I/O

* 头文件

```c
#include <stdio.h>
#include <stdlib.h>
```

### fopen / freopen / fdopen - 打开文件流

```c
/*
 * 功能: 打开文件流
 * 返回: 返回文件流对象的指针，失败返回NULL
 * IN  : filename   文件名字
 * IN  : mode       打开模式
 * IN  : stream     给定文件流对象的指针
 * freopen()会尝试关闭stream文件流对象，然后返回对象关联到stream对象。
 * fdopen() 文件描述符转换为文件流
 * r 只读 r+ 读写;  w 只写 w+ 读写; a 追加写 a+ 读写; 左边的6个模式后面加 b 表示二进制文件。
 * 如果文件不存在，r 类型模式不能新建文件，w 类型和 a 类型模式会新建文件。如果文件存在，w 类型模式会清空文件。
 * a 类型模式在写文件前，将流的偏移量设置为文件结尾，总是在结尾处写，不管有没有调用fseek()。
 * + 类型，写流(输出)之后必须调用 fflush fseek fsetpos rewind 后才能读流(输入)，读流之后(若文件不在尾段)必须调用 fseek fsetpos rewind才能写流。
 * 二进制和文本模式的区别
 * 1.在windows系统中，文本模式下，文件以"\r\n"代表换行。若以文本模式打开文件，并用fputs等函数写入换行符"\n"时，函数会自动在"\n"前面加上"\r"。即实际写入文件的是"\r\n" 。
 * 2.在类Unix/Linux系统中文本模式下，文件以"\n"代表换行。所以Linux系统中在文本模式和二进制模式下并无区别。
 */
#include <stdio.h>
FILE *fopen(const char *filename, const char *mode);
FILE *freopen(const char *filename, const char *mode, FILE *stream);
FILE *fdopen(int fd, const char *mode);
```

### fileno - 文件流转换为文件描述符

```c
/*
 * 功能: 文件流转换为文件描述符
 * 返回: 成功返回文件描述符>=0，失败返回-1
 * IN  : stream     文件流。
 */
#include <unistd.h>
int fileno(FILE *stream);
```

### fread - 从给定流读取数据

```c
/*
 * 功能: 从给定流读取数据
 * 返回: 返回读取元素个数(一般是nmemb)
 * OUT : ptr        读取数据存放的缓冲区
 * IN  : size       读取的元素的大小 sizeof()
 * IN  : nmemb      读取的元素的个数
 * IN  : stream     给定文件流对象的指针
 */
#include <stdio.h>
size_t fread(void *ptr, size_t size, size_t nmemb, FILE *stream);
```

### fwrite - 向给定流写入数据

```c
/*
 * 功能: 向给定流写入数据
 * 返回: 返回写入元素个数(一般是nmemb)
 */
#include <stdio.h>
size_t fwrite(const void *ptr, size_t size, size_t nmemb, FILE *stream);
```

### fclose - 关闭给定文件流

```c
/*
 * 功能: 关闭给定文件流
 * 返回: 成功返回0，失败返回EOF
 * 说明: 流关闭之前会冲洗输出，丢弃输入。
 */
#include <stdio.h>
int fclose(FILE *stream);
```

### ftell / ftello - 返回流的当前偏移量

```c
/*
 * 功能: 返回流的当前偏移量，失败返回-1
 */
#include <stdio.h>
long ftell(FILE *stream);
off_t ftello(FILE *stream);
```

### fseek / fseeko - 改变流的偏移量

```c
/*
 * 功能: 改变流的偏移量，类似lseek()
 * 返回: 成功返回0，失败返回-1
 * IN  : whence     参考位置，SEEK_SET 0 文件开头; SEEK_CUR 1 当前位置; SEEK_END 2 文件结尾。
 */
#include <stdio.h>
int fseek(FILE *stream, long offset, int whence);
int fseeko(FILE *stream, off_t offset, int whence);
```

### rewind - 设置流的偏移量为文件开头

```c
/*
 * 功能: 设置流的偏移量为文件开头
 */
#include <stdio.h>
void rewind(FILE *stream)
```

### fgetpos - 获取流 stream 的当前文件位置，并把它写入到 pos

```c
/*
 * 功能: 获取流 stream 的当前文件位置，并把它写入到 pos
 * 返回: 成功返回0，失败返回非0
 */
#include <stdio.h>
int fgetpos(FILE *stream, fpos_t *pos)
```

### fsetpos - 设置给定流 stream 的文件位置为给定的位置pos

```c
/*
 * 功能: 设置给定流 stream 的文件位置为给定的位置pos
 * 返回: 成功返回0，失败返回非0
 */
#include <stdio.h>
int fsetpos(FILE *stream, fpos_t *pos)
```

### printf / scanf - stdio 格式化输出/输入

```c
/*
 * 功能: stdio 格式化输出/输入
 * 返回: 格式化输出成功返回输出字符数(不含'\0')，失败返回负数
 * 返回: 格式化输入成功返回输入字符数，文件尾端或失败返回EOF
 * 说明: linux 内核打印使用 `printk` 函数，普通打印使用 `printf` 函数
 */
#include <stdio.h>
int printf(const char *format, ...);                    // 格式化输出到stdout
int fprintf(FILE *stream, const char *format, ...);     // 格式化输出到流stream
int dprintf(int fd, const char *format, ...);           // 格式化输出到文件fd
int sprintf(char *str, const char *format, ...);        // 格式化输出到str字符串
// 同上, 只是最多格式化 size-1 个字符到目标串str中，然后再在后面加一个 '\0'
int snprintf(char *str, size_t size, const char *format, ...);
int scanf(const char *format, ...);                     // 从stdin读取格式化输入
int fscanf(FILE *stream, const char *format, ...);      // 从流stream读取格式化输入
int sscanf(const char *str, const char *format, ...);   // 从str字符串读取格式化输入

#include <stdarg.h>
int vprintf(const char *format, va_list arg);
int vfprintf(FILE *stream, const char *format, va_list arg);
int vdprintf(int fd, const char *format, va_list arg);
int vsprintf(char *str, const char *format, va_list arg);
int vsnprintf(char *str, size_t size, const char *format, va_list arg);
int vscanf(const char *format, va_list arg);
int vfscanf(FILE *stream, const char *format, va_list arg);
int vsscanf(const char *str, const char *format, va_list arg);
```

```c
/* ##args 的含义就是把 args... 中的多个参数串连起来 */
#define APP_ERR(format, args...)  do {  \
    printf(format, ##args);             \
} while (0)

/* v类输出函数使用方法举例 */
void APP_ERR(const char *format, ...)
{
    va_list args;
    va_start(args, format);
    vprintf(format, args);
    va_end(args);
}
```

* 格式化举例

| 格式符    | 说明 |
| -----     | ---- |
| `%d`      | 格式化整数 int / short int |
| `%u`      | 格式化无符号整数 unsigned int |
| `%ld`     | 格式化长整数 long |
| `%lld`    | 格式化长长整数 long long |
| `%llu`    | 格式化无符号长长整数 unsigned long long |
| `%x`      | 格式化整数成小写16进制数 |
| `%X`      | 格式化整数成大写16进制数 |
| `%8d`     | 格式化整数最少占用8个字符，不足时前面用空格补齐(右对齐) |
| `%08d`    | 格式化整数最少占用8个字符，不足时前面用0补齐 |
| `%-8d`    | 格式化整数最少占用8个字符，不足时后面用空格补齐(左对齐) |
| `%f`      | 格式化单精度浮点数float |
| `%lf`     | 格式化双精度浮点数double |
| `%.4f`    | 格式化浮点数有4位小数，小数位多于4时截断，小于4时补0 |
| `%8.4f`   | 格式化浮点数最少占用8个字符(其中小数字符占用4位) |
| `%c`      | 格式化字符 |
| `%s`      | 格式化字符串 |
| `%p`      | 格式化指针 |

### get / put - stdio 字符(串)读取/写入

```c
/*
 * 功能: stdio 字符(串)读取/写入
 * 返回: 字符读取成功返回读取字符，到达流尾端或出错返回EOF
 *       字符串读取成功返回buf，到达流尾端或出错返回NULL
 *       字符写入成功返回写入字符c，出错返回EOF
 *       字符写入成功返回>0，出错返回EOF
 * 说明: getc()可能是宏，fgetc()一定是函数。putc()可能是宏，fputc()一定是函数。
 */
#include <stdio.h>
int getchar(void)               // 从stdin读取一个无符号字符c
int getc(FILE *stream)          // 从流stream读取一个无符号字符c
int fgetc(FILE *stream)         // 从流stream读取一个无符号字符c
char *gets(char *s)             // 从stdin读取一行到字符串s (当读取到换行符时，或者到达文件末尾时会停止; 换行符丢弃)
char *fgets(char *s, int n, FILE *stream) // 从流stream读取一行到字符串s，(当读取到n-1个字符或换行符时，或者到达文件末尾时会停止; 换行符保留，最后写入空字符)

int putchar(int c)              // 把一个无符号字符c写入到stdout
int putc(int c, FILE *stream)   // 把一个无符号字符c写入到流stream
int fputc(int c, FILE *stream)  // 把一个无符号字符c写入到流stream
int puts(const char *s)         // 把字符串s写入到stdout(直到空字符，但不包括空字符，最后会追加换行符到stdout)
int fputs(const char *s, FILE *stream) // 把字符串s写入到流stream(直到空字符，但不包括空字符，不会追加换行符到流stream)
```

### ferrof - 判断流是否出错

```c
/*
 * 功能: 判断流是否出错
 * 返回: 真返回非0，假返回0
 * 说明: 流有两个标志: 出错标志和文件结束标志。stdio函数返回EOF时不能判断是哪种。
 */
#include <stdio.h>
int ferrof(FILE *stream);
```

### feof - 判断流是否结尾

```c
 /*
 * 功能: 判断流是否结尾
 * 返回: 真返回非0，假返回0
 */
#include <stdio.h>
int feof(FILE *stream);
```

### clearerr - 清除出错标志和文件结束标志

```c
 /*
 * 功能: 清除出错标志和文件结束标志
 */
#include <stdio.h>
void clearerr(FILE *stream);
```

### tmpnam - 返回临时文件路径名

```c
/*
 * 功能: 返回临时文件路径名
 * 返回: 成功返回唯一文件路径名，失败返回NULL
 * IN  : buf        存放文件路径名的buf，至少长L_tmpnam，NULL时文件路径名放在静态区，每次调用会重写
 */
#include <stdlib.h>
char *tmpnam(char *buf);
```

### tmpfile - 新建临时文件"wb+"

```c
/*
 * 功能: 新建临时文件"wb+"
 * 返回: 成功返回文件指针，失败返回NULL
 * 说明: 程序结束或文件关闭会自动删除文件
 */
#include <stdio.h>
FILE *tmpfile(void);
```

### mkstemp - 新建临时文件(O_CREAT | O_EXCL)

```c
/*
 * 功能: 新建临时文件(O_CREAT | O_EXCL)
 * 返回: 成功返回文件描述符，失败返回-1
 * INOUT:template   文件路径名，必须是字符数组(最后6个字符为XXXXXX)，mkstemp会修改template的最后6个字符。
 */
#include <stdlib.h>
int mkstemp(char *template);
```

### setvbuf / setbuf / setbuffer - 设置流的stdio缓冲(用户区)模式

```c
/*
 * 功能: 设置流的stdio缓冲(用户区)模式
 * 返回: 成功返回0，失败返回非0值
 * IN  : stream     文件流
 * IN  : buf        缓冲区，必需是静态的或堆分配的，为NULL时stdio库会自动分配缓冲区并忽略size
 * IN  : mode       缓冲类型: _IONBF不缓冲; _IOLBF 行缓冲; _IOFBF buf缓冲。
 * IN  : size       缓冲区大小
 * 说明: stdio函数调用read()或write()系统调用时机:不缓冲每次调用(stderr)，行缓冲遇到换行符调用(终端)，buf缓冲buf满时调用。
 *      打开流后，必需在调用任何其它stdio函数前调用setvbuf()。
 *      BUFSIZ定义在<stdio.h>中，一般是8192.
 */
#include <stdio.h>
int setvbuf(FILE *stream, char *buf, int mode, size_t size);
void setbuf(FILE *stream, char *buf); <==> setvbuf(fp, buf, (buf != NULL) ? _IOFBF: _IONBF, BUFSIZ);
void setbuffer(FILE *stream, char *buf, size_t size); <==> setvbuf(fp, buf, (buf != NULL) ? _IOFBF : _IONBF, size);
```

### fflush - 强制刷新stdio缓冲(用户区)

```c
/*
 * 功能: 强制刷新stdio缓冲(用户区)
 * 返回: 成功返回0，失败返回EOF
 * IN  : stream     文件流。NULL时刷新所有缓冲区。用于输入流会丢弃已缓冲的数据。
 * 说明: 关闭流会自动刷新其缓冲区。从stdin读取输入会隐含调用fflush(stdout)。
 */
#include <stdio.h>
int fflush(FILE *stream);
```

## 文件属性

### 文件属性(struct stat)

```c
struct stat {
    dev_t       st_dev;     /* IDs of device on which file resides */   // 设备号
    ino_t       st_ino;     /* I-node number of file */                 // 文件的i节点号
    mode_t      st_mode;    /* File type and permissions */             // (4位)文件类型和(12位)权限
    nlink_t     st_nlink;   /* Number of (hard) links to file */        // 硬链接计数
    uid_t       st_uid;     /* User ID of file owner */                 // 文件属主ID
    gid_t       st_gid;     /* Group ID of file owner */                // 文件属组ID
    dev_t       st_rdev;    /* IDs for device special files */          // 针对设备，设备主/辅ID
    off_t       st_size;    /* Total file size (bytes) */               // 文件的字节数
    blksize_t   st_blksize; /* Optimal block size for I/O (bytes) */    // 文件逻辑块大小(4096)
    blkcnt_t    st_blocks;  /* Number of (512B) blocks allocated */     // 文件的总块数(空洞不分配块)
    time_t      st_atime;   /* Time of last file access */              // 文件数据最近访问时间
    time_t      st_mtime;   /* Time of last file modification */        // 文件数据最近修改时间
    time_t      st_ctime;   /* Time of last status change */            // i-node状态最近改动时间
};
```

### 文件类型(st_mode & S_IFMT)

| Constant  | Test macro    | File type         | 说明 |
| ---       | ---           | ---               | --- |
| S_IFREG   |  S_ISREG()    | Regular file      | 常规文件 |
| S_IFDIR   |  S_ISDIR()    | Directory         | 目录 |
| S_IFLNK   |  S_ISLNK()    | Symbolic link     | 符号链接 |
| S_IFCHR   |  S_ISCHR()    | Character device  | 字符设备 |
| S_IFBLK   |  S_ISBLK()    | Block device      | 块设备 |
| S_IFIFO   |  S_ISFIFO()   | FIFO or pipe      | FIFO或管道 |
| S_IFSOCK  |  S_ISSOCK()   | Socket            | 套接字 |

### 文件权限

| S_IRUID set-user-id(s)  | S_IRGID set-group-id(s) | S_ISVTX sticky(t)      |
| ---                     | ---                     | ---                    |
| S_IRUSR 所有者可读(r)   | S_IRGRP 所有组可读(r)   | S_IROTH 其它人可读(r)   |
| S_IWUSR 所有者可写(w)   | S_IWGRP 所有组可写(w)   | S_IWOTH 其它人可写(w)   |
| S_IXUSR 所有者可执行(x) | S_IXGRP 所有组可执行(x) | S_IXOTH 其它人可执行(x) |

* 一旦将某一目录的set-group-id置位后，该目录下的所有子目录也将置位。
* 文件的属主或属组发生变化，会清除set-user-id和set-group-id。改变文件的属主或属组时，如果屏蔽了属组的可执行权限位或改变的是目录，那么将不会屏蔽set-group-id。
* 文件创建时，st_uid取自进程有效用户ID; st_gid取自进程有效组ID(SYSV默认)或父目录的组ID(BSD默认)。
* ext2文件系统，mount文件系统未指定 “-ogrpid” (即默认-onogrpid选项)，且父目录置位 set-group-id，st_gid取自父目录的组ID，否则set-group-id取自进程有效组ID。
* chmod u+s prog ; chmod g+s prog，程序prog置位了set-user-id和set-group-id，exec(prog)会将进程的有效用户ID/有效组ID设置为可执行文件的UID/GID，而不是父进程的有效用户ID/有效组ID。
* chmod g+s,g-x file 启用文件记录加锁为强制加锁。
* 为目录设置S_ISVTX位，仅当非特权进程对该目录有可写权限，该进程只能对该目录下的同所有者的文件或目录进行删除或重命名。即各个用户可以在设置S_ISVTX位的目录(对该目录有可写权限)创建、删除、重命名文件，但不能删除或重命名其它用户创建的文件。

* 权限影响
    * 对文件来说，r 可读取文件内容，w 可修改文件内容，x 可执行文件。
    * 对目录来说，r 可列出目录下的文件，w 可创建删除重命名目录下文件(不管对文件权限如何)，x 可访问目录中的文件节点信息。
    * 对符号链接来说，一般不考虑它的权限，而考虑它引用的文件的权限。

* 进程对文件的访问规则:
    * 若进程是特权进程，则授予其所有访问权限，
    * 否则 若进程有效用户ID和文件的用户ID相同，则授予其文件的属主访问权限，
    * 否则 若进程有效组ID或任一附属组ID和文件的组ID相同，则授予其文件的属组访问权限，
    * 否则 则授予其文件的其它人访问权限。
        * 后面3条规则的权限需要除去进程的掩码屏蔽的权限。对第1条，如果文件不是目录且没有任何可执行权限，特权进程也不会对其具有可执行权限。
        * 进程的umask通常继承自其父shell，大多数shell会将umask默认置为八进制022(----w--w-)，含义是对属组和其它人总是屏蔽写权限。

* 头文件

```c
#include <sys/stat.h>
#include <unistd.h>
```

### stat / lstat / fstat - 读取文件属性

```c
/*
 * 功能: 读取文件属性到statbuf
 * 返回: 成功返回0，失败返回-1
 * 说明: lstat不会对符号链接解引用，符号链接仅st_size和st_mode成员有效
 */
#include <sys/stat.h>
int stat(const char *pathname, struct stat *statbuf);
int lstat(const char *pathname, struct stat *statbuf);
int fstat(int fd, struct stat *statbuf);
```

### chown / lchown / fchown - 修改文件的uid/gid

```c
/*
 * 功能: 修改文件的uid/gid
 * 返回: 成功返回0，失败返回-1
 * 说明:lchown不会对符号链接解引用
 * 不修改的项可以置为-1
 * uid 只有特权进程可以修改
 * gid 特权进程可以修改为任意值，普通进程(需要有效用户ID等于文件uid)可以修改为附属IDs中的一个。
 */
#include <unistd.h>
int chown(const char *pathname, uid_t owner, gid_t group);
int lchown(const char *pathname, uid_t owner, gid_t group);
int fchown(int fd, uid_t owner, gid_t group);
```

### access - 进程对文件的权限测试

```c
/*
 * 功能: 进程对文件的权限测试
 * 返回: 权限允许返回0，否则返回-1
 * IN  : mode       测试模式: F_OK 存在， R_OK读权限， W_OK 写权限， X_OK 执行权限
 */
#include <unistd.h>
int access(const char *pathname, int mode);
```

### umask - 修改进程的权限掩码

```c
/*
 * 功能: 修改进程的权限掩码
 * 返回: 总是成功返回原来的mask
 */
#include <sys/stat.h>
mode_t umask(mode_t mask);
```

### chmod / fchmod - 修改文件的权限

```c
/*
 * 功能: 修改文件的权限
 * 返回: 成功返回0，失败返回-1
 * 说明:特权进程可以修改，普通进程需要有效用户ID等于文件uid才能修改。
 */
#include <sys/stat.h>
int chmod(const char *pathname, mode_t mode);
int fchmod(int fd, mode_t mode);
```

### utime / utimes / lutimes / futimes / utimensat / futimens - 修改文件的时间戳(UTC)

```c
/*
 * 功能: 修改文件的时间戳(UTC)
 * 返回: 成功返回0，失败返回-1
 * IN  : buf        要更新的时间，NULL表示更新为当前时间
 * IN  : tv         要更新的精确时间，tv[0]文件数据最近访问时间，tv[1]文件数据最近修改时间，NULL表示更新为当前时间
 * IN  : dirfd      相对的路径，见openat()
 *       times      要更新的精确时间，times[0]文件数据最近访问时间，times[1]文件数据最近修改时间，NULL表示更新为当前时间
 *                  将成员tv_nsec设置为: UTIME_NOW 表示更新为当前时间，UTIME_OMIT 表示更新为不修改此项
 *       flags      设置为 AT_SYMLINK_NOFOLLOW 表示不会对符号链接解引用。
 * 说明:lutimes不会对符号链接解引用
 * 特权进程可以修改，普通进程需要有效用户ID等于文件uid并且局域写权限才能修改。
 */
#include <utime.h>
#include <sys/time.h>
struct utimbuf {
    time_t actime;      /* Access time */
    time_t modtime;     /* Modification time */
};
struct timeval {
    time_t      tv_sec;     /* Seconds since 00:00:00, 1 Jan 1970 UTC */
    suseconds_t tv_usec;    /* Additional microseconds (long int) (us)*/
};
struct timespec {
    time_t tv_sec;      /* Seconds ('time_t' is an integer type) */
    long tv_nsec;       /* Nanoseconds (ns)*/
};
int utime(const char *pathname, const struct utimbuf *buf);
int utimes(const char *pathname, const struct timeval tv[2]);
int lutimes(const char *pathname, const struct timeval tv[2]);
int futimes(int fd, const struct timeval tv[2]);
int utimensat(int dirfd, const char *pathname, const struct timespec times[2], int flags);
int futimens(int fd, const struct timespec times[2]);
```

## 进程和线程

### 程序、进程、线程

* 程序program是包含了一系列信息的文件，这些信息描述了如何在运行时穿件一个进程。
    * 信息包括: 二进制格式标识(elf)、机器语言指令、程序入口地址、数据、符号表和重定位表、共享库和动态链接信息、其它信息。
* 进程process是一个可执行程序program的实例。进程是由内核定义抽象的实体，并为该实体分配用以执行程序的各项系统资源。从内核角度看，进程由用户内存空间(代码和变量)和一系列的内核数据结构(维护进程状态信息)组成。进程是资源分配的基本单位。
    * 所有与该进程有关的资源，都被记录在进程控制块PCB中。
* 线程thread是程序执行流的最小单元。一个标准的线程由线程控制表TCB，寄存器集合和线程堆栈组成。线程各自拥有独立的错误码全局变量 errno。
    * 另外，线程是进程中的一个实体，是被系统独立调度和分派的基本单位，线程自己不拥有系统资源，只拥有一点儿在运行中必不可少的资源，但它可与同属一个进程的其它线程共享进程所拥有的全部资源。一个进程的所有线程共享进程的虚拟内存地址空间。

### 进程内存布局

* 地址从高到低依次为:
    * kernel_map  : 内核映射到进程虚拟内存，程序无法访问
    * stack       : 栈，向下增长(栈顶，最低地址)，栈由栈帧stack frames组成，栈帧中存储函数的自动变量和CPU寄存器等信息。
        * 调用函数分配分配一个栈帧，函数返回，移除栈帧。
        * linux使用 `dump_stack()` 查找堆栈信息
    * unused      : 堆顶到栈顶之间还有一段未使用的空间，程序无法访问
    * heap        : 堆，向上增长，堆顶称为program break，malloc()等动态分配的内存位于堆。
        * 通过brk()、 sbrk()、 malloc函数族可以提升堆顶。
        * free()一般不会降低堆顶。
    * bss         : 未初始化数据段，block started by symbol，未初始化或初始化为0的全局变量和静态变量位于此区，程序启动时会初始化为0。
    * data        : 初始化数据段，显示初始化的全局变量和静态变量。
    * text        : 文本段，只读，存放代码指令。程序计数器(pc)总是指向下一条要执行的指令。
    * reserved    : 保留区域，程序无法访问

* 说明
    * 对x86来说，text的起始地址为 0x08048000，kernel_map的起始地址为 0xC0000000。
    * 线程栈(地址从高到低)依次是: argv和envp——主线程的栈——还未分配的空间——线程n的栈——......——线程2的栈——线程1的栈——共享函数库的共享内存。最低地址为 TASK_UNMAPPED_BASE (x86这个值为 0x40000000)。
    * reserved区域、unused区域、kernel_map区域不允许进程直接访问，用户进程访问这些区域的内存会触发段错误并强行终止进程。
    * 大多数Unix/Linux实现提供了三个全局符号 {extern char etext, edata, end;} 分别指向 text、data、bss结尾的下一字节的地址。
    * text和data影响程序占用的flash空间，bss不占用flash空间。

```c
#define STR  "Hello World!"     // data常量区
int a = 10;                     // data非常量区
char buf[100];                  // bss
char buf2[100] = {0};           // bss

int main(void)
{
    int b;                      // stack栈
    static int c = 0;           // bss，编译器可能会把内存占用小的初始化为0的静态变量分配到data
    static int d = 100;         // data非常量区
    char s[] = "abc";           // "abc"在data常量区，s在stack栈上

    char *p1;                   // stack栈
    p1 = (char *)malloc(20);    // 分配得来得20字节的区域就在heap堆区
    strcpy(p1, "123456");       // (123456\0)在data常量区，编译器可能会将它与p2所指向的"123456"优化成一个地方。
    free(p1);                   // heap堆区分配的内存需要手动释放
    char *p2 = "123456";        // (123456\0)在data常量区，p2在stack栈上。

    return 0;
}
```

## 进程

### 进程基础

* fork可以创建当前进程的一个副本，父进程和子进程只有PID(进程ID)不同。fork()对父进程返回子进程的pid，对子进程返回0。
* exec将一个新程序加载到当前进程的内存中并执行。
* Linux用clone方法创建线程。其工作方式类似于fork，但启用了精确的检查，以确认哪些资源与父进程共享、哪些资源为线程独立创建。
* wait 的作用有两个:子进程未终止时挂起父进程，子进程的终止状态通过wait的status参数返回。
* 进程通过 fork() 系统调用复制当前进程创建一个子进程，函数返回时父进程恢复执行，产生新的子进程开始执行。子进程接着通过 exec() 系统调用创建的新的地址空间，装入新的程序。子进程通过 exit() 系统调用退出执行，此时子进程设置为僵死状态直到父进程调用 wait() 或 waitpid() 为止(进程终结时所需的清理工作和进程描述符的删除被分开执行)。
* fork() 系统调用的开销就是复制父进程的页表以及给子进程创建唯一的进程描述符。fork(), vfork(), __clone() 根据各自需要的参数标识去调用 clone(), 然后由 clone() 调用 do_fork() <kernel/fork.c> , do_fork() 调用 copy_process() 函数。现在调用 fork() 创建进程的方法引入了写时复制(Copy-On-Write， COW)。
* vfork() 除了不复制父进程的页表项之外，与 fork() 的功能完全相同。子进程作为父进程的一个单独的线程在他的地址空间运行，父进程被阻塞，直到子进程退出或调用 exec()。不建议使用。
* Linux 通过slab分配器分配 struct task_struct 结构(动态分配) <linux/sched.h>，任务队列是一个双向循环链表。为了只要通过栈指针就能计算出结构的位置，只需要在栈的尾端{栈底(向下生长的栈)或栈顶(向上生长的栈)}创建一个新的结构 struct thread_info 结构 <asm/thread_info.h> 。注:task_struct指针是thread_info的第1个成员。
* 线程仅仅被视为一个与其他进程共享某些资源(如地址空间、文件系统信息、文件描述符和信号处理程序等)的进程。每个线程都有一个唯一隶属于自己的 task_struct 。
* 僵尸状态: 进程的资源(内存、与外设的连接，等等)已经释放(因此它们无法也决不会再次运行), 但进程表中仍然有对应的表项。
    * 僵尸是如何产生的？其原因在于 UNIX 操作系统下进程创建和销毁的方式。在两种事件发生时，程序将终止运行。第一，程序必须由另一个进程或一个用户杀死(通常是通过发送 SIGTERM 或 SIGKILL 信号来完成，这等价于正常地终止进程); 进程的父进程在子进程终止时必须调用或已经调用 wait4(读做 wait for)系统调用。 这相当于向内核证实父进程已经确认子进程的终结。该系统调用使得内核可以释放为子进程保留的资源。只有在第一个条件发生(程序终止)而第二个条件不成立的情况下(wait4)，才会出现“僵尸”状态。
* /proc/PIDn/xxx 进程内核信息的虚拟文件。

### 进程ID凭证

* 口令文件
    * /etc/passwd 用户密码文件
    ```
    lengjing:x:1000:1000:lengjing,,,:/home/lengjing:/bin/bash
    7个字段，冒号隔开，分别是:"登录名:密码:用户ID(UID):首选组ID(GID):注释:家目录:shell程序"
    ```
    * /etc/shadow 隐藏密码文件
    ```
    lengjing:$6$9hJ8nxS0$Sv83v2OM4HNM792f4VcfPBZdbE.cAWBAUTtjRALyxwpxM/cDV49ySV/ehalfvuxPYbFinyDMW8sFEoFtmJTX0.:17640:0:99999:7:::
    ```
    * /etc/group  组文件
    ```
    adm:x:4:syslog,lengjing
    lengjing:x:1000:
    4个字段，冒号隔开，分别是:"组名:密码:用户ID(UID):组ID(GID):逗号隔开的用户列表"
    ```

* ID凭证
    * UID/GID     : 用户ID/组ID，对应唯一用户/组
    * RUID/RGID   : 实际用户ID/实际组ID，real UID/GID，确定进程所属用户和组，
    * EUID/EGID   : 有效用户ID/有效组ID，effective UID/GID
    * SUID/SGID   : 保存用户ID/保存组ID，saved set UID/GID
    * FSUID/FSGID : 文件用户ID/文件组ID，file system UID/GID
    * SGIDs       : 辅助组IDs集合，supplementary group IDs
* 登录shell从/etc/passwd读取UID/GID作为实际用户ID/有实际组ID，子进程继承父进程的实际用户ID/实际组ID 。
* 通常有效用户ID/有效组ID等于实际用户ID/实际组ID。两种例外: 1. 某些系统调用可以修改ID。2. Set-User-ID/Set-Group-ID 程序。
* 有效用户ID、有效组ID和辅助组IDs一起确认进程执行系统调用权限。内核还会使用有效用户ID决定一个进程是否可以向另一个进程发送信号。有效用户ID为0的进程是特权进程，拥有超级用户的所有权限。
* 保存用户ID/保存组ID由有效用户ID/有效组ID复制而来。
* 文件用户ID、文件组ID和辅助组IDs一起确认操作文件的权限。文件用户ID、文件组ID是早期信号发送权限有缺陷引入，现在一般不会使用。
* 登录shell从/etc/passwd读取辅助组IDs作为实际辅助组IDs，子进程继承父进程的辅助组IDs。

* 头文件

```c
#include <unistd.h>
#include <stdlib.h>
#include <sys/wait.h>
```

* getuid / getgid / ... - 获取进程的ID号

```c
/*
 * 功能: 获取进程的ID号
 * 返回: getuid / getgid / geteuid /getegid 总是成功返回
 *       getresuid / getresgid，成功返回0，失败返回-1
         getgroups，成功返回辅助组ID个数，失败返回-1
 * 说明: gidsetsize 是数组大小，一般设为NGROUPS_MAX+1，如果实际辅助组ID个数大于gidsetsize，getgroups调用失败，错误号 EINVAL
 * NGROUPS_MAX值可能很大，所以需要动态分配grouplist。
 */
#include <unistd.h>
uid_t getuid(void);     // 返回实际用户ID
gid_t getgid(void);     // 返回实际组ID
uid_t geteuid(void);    // 返回有效用户ID
gid_t getegid(void);    // 返回有效用户ID
int getresuid(uid_t *ruid, uid_t *euid, uid_t *suid); // 将获取的实际用户ID、有效用户ID、保存用户ID分别写入 ruid、euid、suid
int getresgid(gid_t *rgid, gid_t *egid, gid_t *sgid); // 将实际组ID、有效组ID、保存组ID分别写入 rgid、egid、sgid
int getgroups(int gidsetsize, gid_t grouplist[]); // 将获取的辅助组ID集(有的实现可能包含有效组ID)写入grouplist
```

### setuid / setgid / ... - 修改进程的ID号

```c
/*
 * 功能: 修改进程的ID号
 * 返回: 成功返回0，错误返回-1，错误号EPERM
 * 说明: 修改多个ID的函数，若某个参数不修改，设置ID为-1。修改要么都成功，要么都失败。
 * setuid(e) / setgid(e)
 * 非特权进程: 将有效ID改为值e(实际ID、保存ID)
 * 特权进程:   将实际ID、有效ID、保存ID改为任意ID值e，特权进程取消特权: setuid(getuid())
 * seteuid(e) / setegid(e)
 * 非特权进程: 将有效ID改为值e(实际ID、保存ID)
 * 特权进程:   将有效ID改为任意ID值e
 * setreuid(r, e); / setregid(r, e);
 * 非特权进程: 将实际ID改为值r(实际ID、有效ID)，将有效ID改为值e(实际ID、有效ID、保存ID)
 * 特权进程:   将实际ID改为任意ID值r，将有效ID改为任意ID值e
 * 说明:       r不为-1或e不等于调用之前的实际ID时，会将有效ID改为新的有效ID。
 * setresuid(r, e, s) / setresgid(r, e, s)
 * 非特权进程: 将实际ID改为值r(实际ID、有效ID、保存ID)，将有效ID改为值e(实际ID、有效ID、保存ID)，将保存ID改为值s(实际ID、有效ID、保存ID)
 * 特权进程:   将实际ID改为任意ID值r，将有效ID改为任意ID值e，将保存ID改为任意ID值s
 * 说明:       总是会将文件ID改为新的有效ID。
 * setfsuid(f) / setfsgid(f);
 * 非特权进程: 将文件ID改为值f(实际ID、有效ID、保存ID、文件ID)
 * 特权进程:   将文件ID改为任意ID值f
 * 说明:       返回值与其它不同，总是返回原先的文件ID.
 * setgroups(num, array);
 * 非特权进程: 无法调用
 * 特权进程:   将辅助组IDs改为任意array集
 * initgroups(user, gid);
 * 扫描/etc/groups文件，为user创建辅助组IDs，并将gid追加到辅助组IDs。
 */
int setuid(uid_t uid);
int setgid(gid_t gid);
int seteuid(uid_t euid);
int setegid(gid_t egid);
int setreuid(uid_t ruid, uid_t euid);
int setregid(gid_t rgid, gid_t egid);
int setresuid(uid_t ruid, uid_t euid, uid_t suid);
int setresgid(gid_t rgid, gid_t egid, gid_t sgid);
int setfsuid(uid_t fsuid);
int setfsgid(gid_t fsgid);
int setgroups(size_t gidsetsize, const gid_t *grouplist);
int initgroups(const char *user, gid_t group);
```

### getpid - 获取进程的进程号

```c
/*
 * 功能: 获取进程的进程号
 * 说明: 总是执行成功，进程号总是大于0，init 的进程号为1。内核顺序递增分配下一个可用的进程号，到最大值后重置计数为300
 */
pid_t getpid(void);
```

### getppid - 获取进程的父进程号

```c
/*
 * 功能: 获取进程的父进程号
 * 说明: 进程的父进程终止会由init进程收养该进程
 */
pid_t getppid(void);
```

### fork - 创建进程

```c
/*
 * 功能: 创建进程
 * 返回: 错误返回 -1，成功两次返回，在父进程处返回子进程PID，在父进程处返回0。
 * 说明: fork()/vfork()子进程复制了父进程的文件描述符表，而不是共享。
 * fork()子进程和父进程共享代码段，子进程复制了父进程数据段、堆、栈(写时复制)。
 * fork()后进程修改数据段、堆、栈的数据不会互相影响，fork()后无法确定父进程和子进程谁先运行。
 * vfork()无需复制虚拟内存页和页表，子进程和父进程共享内存空间。
 * vfork()后子进程先运行，父进程将挂起，直到子进程执行了exec()或exit()退出。
 * vfork()后，子进程执行了exec()或exit()退出前，在此期间子进程修改数据段、堆、栈的数据会影响父进程。子进程在最外层调用return会使父进程由于段错误终止。
 */
pid_t fork(void);
pid_t vfork(void);
```

### _exit / exit - 主动终止进程

```c
/*
 * 功能: 主动终止进程
 * IN  : status     终止状态，仅低8位有效，惯例0表示正常退出，非零表示异常退出
 * 说明: exit()是封装_exit()的glibc库函数，exit()会先调用退出处理程序和刷新stdio流缓冲区，然后执行_exit()。标准C里有EXIT_SUCCESS和EXIT_FAILURE两个宏。
 * 程序因为信号而异常终止或直接调用_exit()不会调用退出处理程序和刷新stdio流缓冲区。
 */
void _exit(int status);
void exit(int status);
```

### atexit / on_exit - 注册退出处理程序
```c
/*
 * 功能: 注册退出处理程序
 * 返回: 成功返回0，错误返回非0。
 * 说明: on_exit 是对atexit扩展的glibc库函数，退出处理程序第一个参数是退出状态。
 * 进程退出时以相反顺序运行注册的退出处理程序。
 */
int atexit(void (*func)(void));
int on_exit(void (*func)(int, void *), void *arg);
```

### wait - 等待子进程终止

```c
/*
 * 功能: 等待子进程终止
 * 返回: 成功返回子进程PID，错误返回-1。
 * OUT : status     子进程退出状态，NULL表示不关心子进程退出状态
 * 说明: 子进程未终止时父进程将挂起，不存在没有未被wait的子进程时调用wait()返回-1，errno 置为 ECHILD
 */
pid_t wait(int *status);
```

### waitpid - 等待子进程终止(或因信号停止或恢复执行)

```c
/*
 * 功能: 等待子进程终止(或因信号停止或恢复执行)
 * 返回: 成功返回子进程PID或0，错误返回-1。
 * IN  : pid        根据值类型等待不同子进程
 *       > 0        等待ID为pid的子进程;
 *       == 0       等待同一进程组的子进程;
 *       == -1      等待任意子进程;
 *       < -1       等待进程组ID等于pid绝对值的所有子进程。
 * OUT : status     子进程退出状态，NULL表示不关心子进程退出状态
 *       测试宏                 获取退出状态或信号编号(int)     子进程状态
 *       WIFEXITED(status)      WEXITSTATUS(status)             正常结束子进程
 *       WIFSIGNALED(status)    WTERMSIG(status)                信号杀死子进程(WCOREDUMP(status)测试是否产生内核转储文件)
 *       WIFSTOPPED(status)     WSTOPSIG(status)                子进程因信号停止
 *       WIFCONTINUED(status)   SIGCONT                         子进程因信号恢复执行
 * IN  : options    位掩码标识符
 *       WUNTRACED  等待子进程终止或等待子进程因信号(SIGSTOP/SIGTTIN)停止
 *       WCONTINUED 等待子进程因信号(SIGCONT)由停止状态恢复执行
 *       WNOHANG    子进程状态未发生改变则立即返回0，如果找不到与pid匹配的子进程，返回-1，错误号 ECHILD
 */
pid_t waitpid(pid_t pid, int *status, int options);
```

### waitid - 等待子进程

```c
/*
 * 功能: 等待子进程
 * 返回: 成功返回0并更新infop，错误返回-1。
 * IN  : idtype      P_ALL，等待任意子进程; P_PID, 等待ID为id的子进程; P_GID，等待进程组ID为id的所有子进程。
 * IN  : id         进程ID或进程组ID
 * OUT : infop      返回的子进程状态相关信息
 * IN  : options    执行方式
 * WEXITED          等待子进程终止或等待子进程因信号(SIGSTOP/SIGTTIN)停止
 * WSTOPPED         等待子进程因信号(SIGSTOP/SIGTTIN)停止
 * WCONTINUED       等待子进程因信号(SIGCONT)由停止状态恢复执行
 * WNOHANG          子进程状态未发生改变则立即返回0，改变将子进程状态写入到infop，如果找不到与pid匹配的子进程，返回-1，错误号 ECHILD
 * WNOWAIT          获取子进程状态，成功立即返回0，将子进程状态写入到infop，子进程还是可等待的。
 */
int waitid(idtype_t idtype, id_t id, siginfo_t *infop, int options);
```

### wait3 / wait4 - 等待子进程(不建议)

```c
/*
 * 功能: 等待子进程(不建议)
 * 返回: 成功返回子进程PID并更新rusage，错误返回-1。
 * OUT : rusage     子进程资源相关信息
 */
pid_t wait3(int *status, int options, struct rusage *rusage);  // ==> waitpid(-1, &status, options);
pid_t wait4(pid_t pid, int *status, int options, struct rusage *rusage); // ==> waitpid(pid, &status, options);
```

### sigchldHandler - SIGCHLD 信号处理函数

```c
/*
 * 功能: SIGCHLD 信号处理函数
 * 作用: 防止僵尸线程
 * 无论子进程如何终止，都会向它的父进程发送 SIGCHLD 信号，父进程对该信号的默认处理是忽略。
 * 当信号处理程序时，会暂时阻塞引发调用的信号，在此期间产生同样的信号不会被捕获。
 * 应用应该在创建任何子进程之前创建SIGCHLD 信号处理函数。
 * 如果 sigaction()设置SIGCHLD处理程序时传入了 SA_NOCLDSTOP 标志，子进程停止和恢复执行时会向它的父进程发送 SIGCHLD 信号。
 */
static void sigchldHandler(int sig)
{
    while (waitpid(-1, NULL, WNOHANG) > 0)
        continue;
}
```

### exec - 执行新程序

```c
/*
 * 功能: 执行新程序(bin文件或脚本文件)
 * 返回: 成功永不返回，错误返回-1。
 * IN  : pathname   可执行(包含路径)文件名
 * IN  : filename   可执行文件名，包含'/'则是可执行(包含路径)文件名，否则在PATH环境变量指定的目录中搜索。
 * IN  : fd         文件描述符指定可执行(包含路径)文件
 * IN  : argv       命令行参数数组
 * IN  : arg        命令行参数列表，以NULL结尾。
 * IN  : envp       环境列表，echo $PATH
 * 说明: execve()是系统调用，其它是封装的库函数。
 * 执行新程序会重建进程的虚拟内存空间，原有内存空间的数据全部丢弃，但进程ID不变。
 * 对命令行参数的描述: v表示使用命令行参数数组，l表示命令行参数字列表。命令行字符串格式为"name=value"
 * 对程序文件的描述  : 有p表示在PATH环境变量指定的目录中搜索可执行文件名，否则表示(包含路径的)文件名。
 * 对环境列表的描述  : 有e表示使用指定的envp环境列表，否则表示使用进程原来的环境列表。
 */

int execv(const char *pathname,  char *const argv[]);
int execvp(const char *filename, char *const argv[]);
int execve(const char *pathname, char *const argv[], char *const envp[]); // 系统调用

int execl(const char *pathname,  const char *arg, ..., (char *) NULL);
int execlp(const char *filename, const char *arg, ..., (char *) NULL);
int execle(const char *pathname, const char *arg, ..., (char *) NULL, char *const envp[]);

int fexecve(int fd, char *const argv[], char *const envp[]);
```

### system - 执行shell命令
```c
/*
 * 功能: 执行shell命令
 * 返回: 返回值根据不同情况返回不通知。
 * 说明: system()会创建一个子进程执行shell，shell进程创建子进程执行shell命令。
 * command为NULL时，shell可用返回非0，不可用返回0。
 * 无法创建子进程或无法获取其终止状态，返回-1。
 * 子进程不能执行shell，返回状态和子shell调用_exit(127)一样。
 * 调用成功返回command的子shell终止状态。
 * command()运行期间必须阻塞SIGCHLD信号。
 */
int system(const char *command);
```

```c
// 例：进程简单使用
int main(int argc, char *argv[])
{
    pid_t pid;
    switch (pid = fork()) {                 // 创建进程
        case -1:                            // 出错
            errExit("fork");                // 父进程出错退出
        case 0:                             // 子进程在此运行
            child_handle();
            exit(EXIT_SUCCESS);             // 子进程退出
            break;
        default:                            // 父进程在此运行
            parent_handle();
            wait(NULL);                     // 父进程等待子进程退出
            exit(EXIT_SUCCESS);             // 父进程退出
            break;
    }

}
```

## 线程

### 线程基础

* 线程操作函数成功一般返回0，失败返回一个正的错误号。进程操作函数成功一般返回0，失败返回-1。
* static __thread val_type val_name;  // __thread 声明，定义线程局部变量
    * 线程局部变量是指每个线程都有一份对变量的拷贝，直到线程终止，会自动释放这一份拷贝。
* Linux上线程有2种实现:
    * LinuxThreads : 轻量级进程
        * clone()标志 CLONE_VM | CLONE_FILES | CLONE_FS | CLONE_SIGHAND
        * Linux2.6之前的实现，已废弃，除主线程外的所有线程都由进程的管理线程创建。
        * 不共享进程PID、PPID、ID凭证，fork()、exec()、exit() 表现类似进程，调用他们只对当前线程有影响。信号处理模型不同。
    * NPTL : 轻量级进程
        * clone()标志 CLONE_VM | CLONE_FILES | CLONE_FS | CLONE_SIGHAND | CLONE_THREAD | CLONE_SETTLS | CLONE_PARENT_SETTID | CLONE_CHILD_CLEARTID | CLONE_SYSVSEM
        * Linux2.6即之后的实现，增加线程组概念
        * `ps -L` 可以列出这些线程。
        * 共享进程PID、PPID、ID凭证，exit()调用exit_group()终止所有同一进程的线程， pthread_exit()调用_exit()终止当前线程。
        * 和SUSv3不一致的地方: 不共享nice值。

* 头文件

```c
#include <pthread.h>
```

### pthread_self - 获取自己的线程ID

```c
/*
 * 功能: 获取自己的线程ID
 * 说明: pthread_t一般是 unsigned long
 */
pthread_t pthread_self(void);
```

### pthread_equal - 比较线程ID

```c
/*
 * 功能: 比较线程ID
 * 返回: 0，相等; !=0，不相等
 */
int pthread_equal(pthread_t t1, pthread_t t2);
```

### pthread_create - 创建线程

```c
/*
 * 功能: 创建线程
 * 返回: 0，成功; >0，错误号。注意进程创建失败返回的负的错误号，和线程创建不同。
 * OUT : thread     保存线程唯一标志的地址
 * IN  : attr       传入的线程属性地址，NULL表示默认
 * IN  : start      线程执行函数地址，函数名
 * IN  : arg        传入线程执行函数的参数
 * 说明: 一个进程的所有线程共享代码段、全局数据段、堆、文件描述符，但各自的栈私有。
 * 除主线程之外的所有线程，栈的缺省值为2M(x86)/32M(x64)，主线程的栈要大的多。
 */
int pthread_create(pthread_t *thread, const pthread_attr_t *attr, void *(*start)(void *), void *arg);
```

### pthread_detach - 线程分离

```c
/*
 * 功能: 线程分离
 * 返回: 0，成功; >0，失败
 * 说明: 线程分离后，线程终止时会被自动清理，不能再调用pthread_join()获取其状态(未定义行为)
 */
int pthread_detach(pthread_t thread);
```

### pthread_join - 连接终止的线程

```c
/*
 * 功能: 连接终止的线程
 * 返回: 0，成功; >0，失败
 * OUT : retval     获取线程终止的返回值(线程终止的返回值是void*)，为NULL时表示不关心返回值。
 * 说明: 等待由thread标识的线程终止，如果线程已经终止，pthread_join() 会立即返回。
 *       线程未分离detached，必须调用pthread_join()链接，否则产生僵尸线程。
 *       线程可以join所属进程的任意其它未分离的线程，而进程只能由父进程wait子进程。
 */
int pthread_join(pthread_t thread, void **retval);
```

### pthread_exit - 终止线程

* 终止线程的方式:
    * 线程start函数 return
    * 线程自己调用 pthread_exit()
    * 同进程的其它线程调用 pthread_cancel() 取消线程
    * 进程终止会关闭同进程的所有线程，例如: 同进程的任意线程调用了 exit() ，或主线程执行了return，或进程被强制退出。
* 注意: 主线程自己调用 pthread_exit()，主线程会退出，其它线程会继续运行。

```c
/*
 * 功能: 终止线程
 * IN  : retval     线程返回值地址，不要放在线程栈中
 * 说明: 线程执行函数自己调用或线程执行函数调用的函数调用
 */
void pthread_exit(void *retval);
```

### pthread_cancel - 取消其它线程

```c
/*
 * 功能: 取消其它线程
 * 返回: 0，成功; >0，失败
 * 说明: 同进程其它线程调用，发送取消请求，不等待其它线程终止，被请求的线程可以选择忽略取消或控制如何取消
 *
 */
int pthread_cancel(pthread_t thread);
```

### pthread_testcancel - 设置一个取消点

```c
/*
 * 功能: 设置一个取消点
 * 说明: 设置一个取消点，线程有已挂起的取消请求时，调用该函数会终止线程。有些函数自带取消点。
 *       线程被取消的返回值是 PTHREAD_CANCELED
 */
void pthread_testcancel(void);
```

### pthread_setcancelstate / pthread_setcanceltype 修改对取消请求的响应状态

```c
/*
 * 功能: 修改对取消请求的响应状态
 * 返回: 0，成功; >0，失败
 * IN  : state      PTHREAD_CANCEL_DISABLE      禁止取消，收到取消请求时挂起请求，直到允许取消
 *                  PTHREAD_CANCEL_ENABLE       允许取消，默认状态
 * IN  : type       PTHREAD_CANCEL_ASYNCHRONOUS 异步取消，任何时点取消(可能立即取消)
 *                  PTHREAD_CANCEL_DEFERRED     延迟取消，默认状态，到达取消点时被请求的线程终止
 * OUT : oldxx      放置前一个取消状态或模式，NULL表示不关心前一个状态
 * fork()出来的子进程会继承对线程取消请求的响应状态，exec()会恢复默认。
 */
int pthread_setcancelstate(int state, int *oldstate);
int pthread_setcanceltype(int type, int *oldtype);
```

### pthread_cleanup_push / pthread_cleanup_pop - 线程清理函数注册和删除

```c
/*
 * 功能: 线程清理函数注册和删除(可能是宏实现)
 * 说明: push注册线程清理函数，放在线程执行函数开头; pop是删除，放在线程执行函数结尾
 *       线程清理函数routine会在线程中途取消或pthread_exit()终止时按线程注册相反的顺序执行，但直接从线程执行函数return不会执行
 *       执行到pop时，pop的execute为非0会执行后再删除最顶层清理函数，为0时直接删除最顶层清理函数不执行
 */
void pthread_cleanup_push(void (*routine)(void*), void *arg);
void pthread_cleanup_pop(int execute);
```

### pthread_once - 一次性初始化

```c
/*
 * 功能: 一次性初始化
 * 返回: 0，成功; >0，失败
 * 说明: *once_control 的值等于PTHREAD_ONCE_INIT，才执行init函数并修改*once_control的值。
 */
pthread_once_t once_var = PTHREAD_ONCE_INIT;
int pthread_once(pthread_once_t *once_control, void (*init)(void));
```

## IPC(进程间通信和同步)

** `code/linux_ipc` 目录演示了使用不同IPC实现同一个功能(客户端发消息给服务端)的示例。**

* 工具种类
    * 通信
        * 数据传输:
            * 字节流: PIPE、FIFO、TCP套接字
            * 消  息: SYSV消息队列、POSIX消息队列、UDP套接字
            * 伪终端
        * 共享内存:
            * SYSV共享内存、POSIX共享内存、文件内存映射、匿名内存映射
    * 同步
        * 线程同步:
            * mutex(互斥量)、rwlock(读写锁)、cond(条件变量)、spin(自旋锁)、barrier(屏障)
        * 进程同步:
            * 文件锁: 记录锁(fcntl)、文件锁(flock)
            * 信号量: SYSV信号量、POSIX命名信号量、POSIX无名信号量
            * 信号: 常称为软中断，有中断号

* 工具属性

    | 工具类型          | 名字空间  | 对象描述符           | 可访问性   | 持久性 |
    | ---               | ---       | ---                  | ---        | ---  |
    | PIPE无名管道      | 无名      | 文件描述符           | 相关进程   | 进程 |
    | FIFO命名管道      | 文件路径名| 文件描述符           | 权限掩码   | 进程 |
    | POSIX互斥锁       | 无名      | pthread_mutex_t*指针 |            | 进程 |
    | POSIX读写锁       | 无名      | pthread_rwlock_t*指针|            | 进程 |
    | POSIX条件变量     | 无名      | pthread_cond_t*指针  |            | 进程 |
    | SYSV消息队列      | IPC键key_t| IPC标识符int         | 权限掩码   | 内核 |
    | SYSV信号量        | IPC键key_t| IPC标识符int         | 权限掩码   | 内核 |
    | SYSV共享内存      | IPC键key_t| IPC标识符int         | 权限掩码   | 内核 |
    | POSIX消息队列     | IPC路径名 | mqd_t描述符          | 权限掩码   | 内核 |
    | POSIX命名信号量   | IPC路径名 | sem_t*指针           | 权限掩码   | 内核 |
    | POSIX无名信号量   | 无名      | sem_t*指针           | 内存权限   | 进程 |
    | POSIX共享内存     | IPC路径名 | 文件描述符           | 权限掩码   | 内核 |
    | 文件内存映射      | 路径名    | 文件描述符           | 权限掩码   | 文件 |
    | 匿名内存映射      | 无名      | 无                   | 相关进程   | 进程 |
    | flock()文件锁     | 文件路径名| 文件描述符           | open()操作 | 进程 |
    | fcntl()文件锁     | 文件路径名| 文件描述符           | open()操作 | 进程 |
    | TCP套接字         | IP+端口   | 文件描述符           | 任意进程   | 进程 |
    | UDP套接字         | IP+端口   | 文件描述符           | 任意进程   | 进程 |
    | Unix域套接字      | 路径名    | 文件描述符           | 权限掩码   | 进程 |

* 名词解释:
    * 相关进程: 同一进程fork()出来的进程。父进程和子进程之间，两个子进程之间。
    * POSIX的IPC路径名以 `/` 开头，且后面的路径不含 `/`

* 其它说明:
    * 进程持久性: IPC对象一直存在直到打开着该对象的最后一个进程关闭或关闭该对象为止
        * 注：FIFO特殊，所有进程关闭了FIFO，但文件系统的FIFO节点一直保持着，需要unlink()显式删除
    * 内核持久性: IPC对象一直存在直到内核重新自举或显示删除该对象为止
    * 文件系统持久性: IPC对象一直存在直到内核显示删除该对象为止，内核重新自举不会删除该对象

<br>

* 数据传输说明:
    * 一个进程将数据写入到IPC工具中(进程缓冲区复制到内核缓冲区)，另一个进程从IPC工具中读取数据(内核缓冲区复制到进程缓冲区)。
    * 一个数据传输工具可能会有多个读取者，但读取操作是破坏性的，读取操作回会消耗数据，其它进程将无法获取消耗的数据。注意socket有特殊情况。
    * 试图从当前不含有数据的通信工具中读取数据，默认情况下将会阻塞当前进程，直到一些进程向该工具写入数据。
    * 试图向当前容量满的通信工具中写入数据，默认情况下将会阻塞当前进程，直到一些进程向该工具读取数据。
    * 字节流没有分隔符，可以读取任意字节，不管写入的块大小是什么。
    * 消息有分隔符，一次只能读取一条完整消息，一次无法读取部分消息或多条消息。

* 共享内存说明:
    * 共享内存将数据放在进程间共享的一块内存(用户内存)中完成信息的交换，这块内存对所有共享这块内存的进程可见。
    * 共享内存中需要同步工具保护数据，通常使用信号量。
    * 内存映射给硬件直接访问(不经过CPU)，不能直接cache。需要使用一致性DMA缓存(Coherent DMA buffers)或流式DMA映射(DMA Streaming Mapping)。

* 信号量说明:
    * 信号量是一个由内核维护的整数，值永远不会小于0。一个进程可以增加或减小一个信号量的值。
    * 试图信号量的值减小到小于0，默认情况下将会阻塞当前进程，直到信号量的值增加到大于0。

* 文件锁说明:
    * 文件锁是协调操作同一文件多个进程的动作的一种同步方法。文件锁分为读锁和写锁。
    * flock()对整个文件加锁，fcntl()对同一文件的不同区域加上多个读锁和写锁。

## 管道PIPE和命名管道FIFO

* 管道说明
    * 管道中数据的传递方向是单向的，一端用于读取，另一端用于写入。
    * 多个进程写入同一管道，在一个时刻写入数据不超过PIPE_BUF(Linux是4096)个字节就不会出现多个进程的数据交叉。超过PIPE_BUF，内核会将数据分割成几个小的片段传输，在读者从管道读取消耗数据时再附加上后续数据。
    * 读取进程事先关闭写入描述符原因: 写入进程完成写入并关闭写入描述符后，读取进程读完管道数据之后可以看到文件结束; 否则读取进程读完管道数据之后read()会阻��以等待数据。
    * 写入进程事先未关闭读取描述符，读取进程关闭读取描述符后，写入进程继续写数据会将数据充满整个管道，最后write()会永远阻塞。

* 打开一个FIFO的语义

    | 打开目的 | open()标记            | 有一端已经打开写入 | 还没有端打开写入 |
    | ---      | ---                   | ---               | ---            |
    | 读取     | O_RDONLY              | 立即成功           | 阻塞 |
    | 读取     | O_RDONLY | O_NONBLOCK | 立即成功           | 立即成功 |

    | 打开目的 | open()标记            | 有一端已经打开读取 | 还没有端打开读取 |
    | ---      | ---                   | ---               | ---            |
    | 写入     | O_WRONLY              | 立即成功           | 阻塞 |
    | 写入     | O_WRONLY | O_NONBLOCK | 立即成功           | 失败(ENXIO) |

    * 创建FIFO后，open() 只能以 O_RDONLY 或 O_WRONLY 标识打开FIFO，不能以 O_RDWR 标识打开FIFO。
    * O_NONBLOCK会影响后续的read()、write()调用的表现，O_NONBLOCK还可以防止下面两种情况死锁:
        * 同一个进程同时打开FIFO的读取写入端
        * 两个线程分别打开两个FIFO的读取写入端。

* 向一个包含p字节的PIPE/FIFO中读取n字节的语义

    | O_NONBLOCK | p=0写入端打开 | p=0写入端关闭 | p < n     | p >= n |
    | ---        | ---           | ---           | ---       | --- |
    | NO         | 阻塞          | 返回0(EOF)    | 读取p字节 | 读取n字节 |
    | YES        | 失败(EAGAIN)  | 返回0(EOF)    | 读取p字节 | 读取n字节 |

    * 管道或FIFO读取数据是顺序的，无法lseek()。
    * 当所有引用管道或FIFO的描述符被关闭后，所有未被读取的数据将会丢弃。

* 向一个PIPE/FIFO中写入n字节的语义
    | O_NONBLOCK  | 读取端关闭     |  n<=PIPE_BUF读取端打开 | |         n>PIPE_BUF读取端打开 | |
    | --- | --- | --- | --- | --- | --- |
    |             | 任意           | 可用空间<n   | 可用空间>=n   | 可用空间==0  | 可用空间>0 |
    | NO          | SIGPIPE+EPIPE  | 阻塞         | 原子写入n字节 | 阻塞         | 部分写多次(阻塞)，最终写入n字节 |
    | YES         | SIGPIPE+EPIPE  | 失败(EAGAIN) | 原子写入n字节 | 失败(EAGAIN) | 部分写一次，最终写入这次可用空间字节 |

    * 向没有任何读取描述符打开的管道或FIFO写入数据，内核会向进程发送SIGPIPE信号，SIGPIPE信号默认会杀死进程。

### 获取状态

```c
/* 获取状态 */
ioctl(fd, FIONREAD, &cnt);          // 返回管道或FIFO中未读取的字节数。
fcntl(fd, F_SETPIPE_SIZE, size);    // 可以修改管道容量的大小。
fcntl(fd, F_GETPIPE_SIZE);          // 返回管道容量的大小。
```

### 打开O_NONBLOCK标记

```c
/* 打开O_NONBLOCK标记 */
int flags;
flags = fcntl(fd, F_GETFL); /* Fetch open files status flags */
flags |= O_NONBLOCK;        /* Enable O_NONBLOCK bit */
fcntl(fd, F_SETFL, flags);  /* Update open files status flags */
```

### 关闭O_NONBLOCK标记

```c
/* 关闭O_NONBLOCK标记 */
int flags;
flags = fcntl(fd, F_GETFL);
flags &= ~O_NONBLOCK;       /* Disable O_NONBLOCK bit */
fcntl(fd, F_SETFL, flags);
```

### pipe - 创建PIPE

```c
/*
 * 功能: 创建PIPE
 * bash: 竖线 | ，如: ls | wc
 * 返回: 0，成功; -1，失败
 * OUT : fd[0]      PIPE读取端
 *       fd[1]      PIPE写入端
 * 说明: exec()不会自动关闭管道。
 */
#include <unistd.h>
int pipe(int fd[2]);
```

```c
// 将标准输出绑定到PIPE写入端
if (pfd[1] != STDOUT_FILENO) {
    dup2(pfd[1], STDOUT_FILENO);
    close(pfd[1]);
}
// 将标准输入绑定到PIPE读取端
if (pfd[0] != STDIN_FILENO) {
    dup2(pfd[0], STDIN_FILENO);
    close(pfd[0]);
}
```

### mkfifo - 创建FIFO

```c
/*
 * 功能: 创建FIFO
 * bash: mkfifo [-m mode] pathname
 * 返回: 0，成功; -1，失败
 * IN  : pathname   路径名
 *       mode       模式，类似打开文件
 * 说明: mkfifo已隐含指定O_CREAT|O_EXCL，即它要么创建一个新的FIFO，要么返回一个EEXIST错误。
 */
#include <sys/stat.h>
int mkfifo(const char *pathname, mode_t mode);
```

## SYSV IPC

| 接口      | 消息队列            | 信号量           | 共享内存 |
| ---       | ---                 | ---             | --- |
| 头文件    | <sys/msg.h>         | <sys/sem.h>     | <sys/shm.h> |
| 描述符    | msqid_ds            | semid_ds        | shmid_ds |
| 创建/打开 | msgget()            | semget()        | shmget() + shmat() |
| 关闭对象  | 无                  | 无              | shmdt() |
| 控制操作  | msgctl()            | semctl()        | shmctl() |
| 执行IPC   | msgsnd() / msgrcv() | msgop()         |   |
|           | 发送/接收 消息      | 测试/调整 信号量 | 操作共享内存 |

* SYSV IPC描述符对系统全局可见，所有访问同一SYSV IPC对象的进程使用相同的描述符。
* SYSV消息队列和SYSV信号量对对象的删除是立即生效的(注意安全地删除对象)， SYSV共享内存只有所有进程解除了映射后才会删除。
* 可以使用IPC_PRIVATE(0)产生唯一的key，使用ftok()产生近似唯一的key

### ftok - 产生近似唯一的key

```c
/*
 * 功能: 产生近似唯一的key
 * 返回: 成功返回key，失败返回-1
 * IN  : pathname   文件路径全名，必须是可以应用stat()的既有文件，取得文件的i-node
 * IN  : proj       附加，使用最低8位，0时结果未定义
 * 说明: 不同文件可能生成相同的key，删除重建文件i-node会变化，符号链接会解引用
 * key的组成: proj最低8位，文件系统设备号(次设备号)最低8位，文件的i-node号最低16位
 */
key_t ftok(char *pathname, int proj)
```
### ipc_perm - ipc_perm结构体

```c
/*
 * 功能: ipc_perm结构体
 * 进程的特权性、有效用户ID和辅助组ID与uid、gid比较确定访问修改权限
 * mode和文件I/O的mode相同
 */
struct ipc_perm {
    key_t           __key;      /* Key, as supplied to 'get' call */
    uid_t           uid;        /* Owner's user ID */
    gid_t           gid;        /* Owner's group ID */
    uid_t           cuid;       /* Creator's user ID */
    gid_t           cgid;       /* Creator's group ID */
    unsigned short  mode;       /* Permissions */
    unsigned short  __seq;      /* Sequence number */
};
```

## SYSV 消息队列

### msqid_ds - 消息队列数据结构

```c
/*
 * 功能: 消息队列数据结构
 */
struct msqid_ds {
    struct ipc_perm msg_perm;   /* Ownership and permissions */
    time_t          msg_stime;  /* Time of last msgsnd() */
    time_t          msg_rtime;  /* Time of last msgrcv() */
    time_t          msg_ctime;  /* Time of last change */
    unsigned long __msg_cbytes; /* Number of bytes in queue */  // 所有消息mtext字段字节数总和
    msgqnum_t       msg_qnum;   /* Number of messages in queue */ // 当前消息数
    msglen_t m      sg_qbytes;  /* Maximum bytes in queue */  // mtext字段最大长度，默认MSGMNB(x86-64为0x7fffffff)
    pid_t           msg_lspid;  /* PID of last msgsnd() */
    pid_t           msg_lrpid;  /* PID of last msgrcv() */
};
```

### msgget - 新建或打开消息队列

```c
/*
 * 功能: 新建或打开消息队列
 * 返回: 成功返回消息队列描述符，失败返回-1
 * IN  : key        键值
 * IN  : msgflg     模式，IPC_CREAT IPC_EXCL
 */
int msgget(key_t key, int msgflg);
```

### msgsnd - 发送消息

```c
/*
 * 功能: 发送消息
 * 返回: 成功返回0，失败返回-1
 * IN  : msqid      消息队列描述符
 * IN  : msgp       要发送的消息的缓冲区mymsg
 * IN  : msgsz      要发送的消息的长度，不含消息类型mtype的长度
 * IN  : msgflg     发送标志: IPC_NOWAIT(非阻塞)
 * 说明: 阻塞的msgsnd()调用可能会被信号处理器中断，此时失败返回EINTR错误
 */
struct mymsg {
long                mtype;        /* Message type */
char                mtext[msgsz]; /* Message body */
}
int msgsnd(int msqid, const void *msgp, size_t msgsz, int msgflg);
```

### msgrcv - 接收消息

```c
/*
 * 功能: 接收消息
 * 返回: 成功返回读取字节数，失败返回-1
 * IN  : msqid      消息队列描述符
 * OUT : msgp       接收到消息的存放的缓冲区
 * IN  : maxmsgsz   缓冲区的长度，不含消息类型mtype的长度
 * IN  : msgtyp     要接收消息的类型，0表示不选择类型，>0 选择对应类型， < 0 选择小于等于绝对值的类型
 * IN  : msgflg     标志: IPC_NOWAIT(非阻塞)
 *                  MSG_EXPECT(msgtyp>0 非对应类型)
 *                  MSG_NOERROR(maxmsgsz可能小于mtext实际长度，指定此标志会截断mtext返回，
 *                      否则调用失败且不从消息队列删除这条信息)
 * 说明: 阻塞的msgrcv()调用会被信号处理器中断，此时失败返回EINTR错误
 * 每条消息可以用一个整数表示类型，从消息队列中读取消息可以按照先入先出，也可以按照类型。
 */
ssize_t msgrcv(int msqid, void *msgp, size_t maxmsgsz, long msgtyp, int msgflg);
```

### msgctl - 控制消息队列

```c
/*
 * 功能: 控制消息队列
 * 返回: 成功返回读取字节数，失败返回-1
 * IN  : msqid      消息队列描述符
 * IN  : cmd        指令
 * INOUT: buf       数据存储区
 * cmd指令:
 * IPC_RMID         立即删除消息队列，所有消息会被清空，msgsnd/msgrcv 返回EIDRM错误，msgsnd/msgrcv阻塞进程会唤醒。
 * IPC_STAT         取得消息队列数据结构副本
 * IPC_SET          修改消息队列数据结构，可修改msg_perm的 uid gid mode，特权进程可修改 sg_qbytes
 * IPC_INFO         取得消息队列资源消耗情况，获取entries数组最大下标
 */
int msgctl(int msqid, int cmd, ... /* struct msqid_ds *buf */);
```

## SYSV 信号量

### semid_ds - 信号量集数据结构

```c
/*
 * 功能: 信号量集数据结构
 */
struct semid_ds {
    struct ipc_perm sem_perm; /* Ownership and permissions */
    time_t          sem_otime; /* Time of last semop() */
    time_t          sem_ctime; /* Time of last change */
    unsigned long   sem_nsems; /* Number of semaphores in set */
};
```

### semget - 新建或打开信号量集

```c
/*
 * 功能: 新建或打开信号量集
 * 返回: 成功返回信号量集描述符，失败返回-1
 * IN  : key        键值
 * IN  : nsems      集合中信号量的数目，nsems必须大于0
 * IN  : semflg     模式，IPC_CREAT IPC_EXCL
 * 说明: nsems必须大于0，当打开一个既有的信号量集合时，nsems必须要小于等于集合的大小
 * Linux中信号量集中信号量的值默认初始化为0，其它实现可能不同，所以必须显示初始化。
 */
int semget(key_t key, int nsems, int semflg);
```

### semop / semtimedop - 操作信号量的值

```c
/*
 * 功能: 操作信号量的值
 * 返回: 成功返回0，失败返回-1
 * IN  : semid      信号量集描述符
 * IN  : sops       操作的数组
 * IN  : nsops      数组的大小，必须大于1
 * 说明: 阻塞的msgrcv()调用会被信号处理器中断，此时失败返回EINTR错误
 * sem_num          信号量序号，从0开始
 * sem_op           操作类型，>0 信号量值加sem_op，=0 等待信号量值变为0，< 0 信号量值减sem_op绝对值
 * sem_flg          标志: IPC_NOWAIT(非阻塞) SEM_UNDO(进程意外终止时撤销带有SEM_UNDO的sem_op操作)

 */
struct sembuf {
    unsigned short  sem_num;    /* Semaphore number */
    short           sem_op;     /* Operation to be performed */
    short           sem_flg;    /* Operation flags (IPC_NOWAIT and SEM_UNDO) */
};
int semop(int semid, struct sembuf *sops, unsigned int nsops);
int semtimedop(int semid, struct sembuf *sops, unsigned int nsops, struct timespec *timeout);
```

### semctl - 控制信号量

```c
/*
 * 功能: 控制信号量(集)
 * 返回: 成功依据cmd，失败返回-1
 * IN  : msqid      信号量集描述符
 * IN  : sem_num    信号量序号，从0开始，有些操作会忽略这个参数的值
 * IN  : cmd        操作类型
 * IN  : buf        数据存储区
 * cmd指令(用于信号量集):
 * IPC_RMID         立即删除信号量集，所有消息会被清空，semop 返回EIDRM错误，semop阻塞进程会唤醒。
 * IPC_STAT         取得信号量集数据结构副本
 * IPC_SET          修改信号量集数据结构，可修改msg_perm的 uid gid mode
 * IPC_INFO         取得信号量集资源消耗情况，获取entries数组最大下标
 * GETALL           获取全部信号量的值，存入到arg.array
 * SETALL           初始化全部信号量的值为, arg.array
 * cmd指令(用于单个信号量):
 * GETVAL           获取信号量的值，无需arg
 * SETVAL           初始化信号量的值为, arg.val
 * GETPID           返回上一次在该信号量上执行semop的进程ID
 * GETNCNT          返回等待该信号量的值增长的进程数
 * GETZCNT          返回等待该信号量的值变为0的进程数
 */
union semun { /* Used in calls to semctl() */
    int             val;
    struct semid_ds *buf;
    unsigned short  *array;
#if defined(__linux__)
    struct seminfo  *__buf;
#endif
};
int semctl(int semid, int semnum, int cmd, ... /* union semun arg */);
```

## SYSV 共享内存

### shmid_ds - 共享内存数据结构

```c
/*
 * 功能: 共享内存数据结构
 */
struct shmid_ds {
    struct ipc_perm shm_perm;   /* Ownership and permissions */
    size_t          shm_segsz;  /* Size of segment in bytes */
    time_t          shm_atime;  /* Time of last shmat() */
    time_t          shm_dtime;  /* Time of last shmdt() */
    time_t          shm_ctime;  /* Time of last change */
    pid_t           shm_cpid;   /* PID of creator */
    pid_t           shm_lpid;   /* PID of last shmat() / shmdt() */
    shmatt_t        shm_nattch; /* Number of currently attached processes */
};
```

### shmget - 新建或打开共享内存段

```c
/*
 * 功能: 新建或打开共享内存段
 * 返回: 成功返回共享内存段描述符，失败返回-1
 * IN  : key        键值
 * IN  : size       共享内存段大小，上舍到分页大小的整数倍
 * IN  : shmflg     模式，IPC_CREAT  IPC_EXCL
 *                  SHM_HUGETLB(巨页而不是分页) SHM_NORESERVE
 */
int shmget(key_t key, size_t size, int shmflg);
```

### shmat - 将共享内存段映射到进程虚拟地址空间

```c
/*
 * 功能: 将共享内存段映射到进程虚拟地址空间
 * 返回: 成功返回内存地址，失败返回-1
 * IN  : shmid      共享内存段描述符
 * IN  : shmaddr    指定调用进程内被映射区的起始地址，通常设为NULL，若未指定SHM_RND，则shmaddr必须为SHMLBA的整数倍
 * IN  : shmflg     模式，SHM_RDONLY(只读) SHM_REMAP(重映射，Linux扩展) SHM_RND(shmaddr上舍到SHMLBA的整数倍)
 *                  SHM_HUGETLB(巨页而不是分页) SHM_NORESERVE
 */
void *shmat(int shmid, const void *shmaddr, int shmflg);
```

### shmdt - 解除共享内存段到进程虚拟地址空间的映射

```c
/*
 * 功能: 解除共享内存段到进程虚拟地址空间的映射
 * 返回: 成功返回内存地址，失败返回-1
 * IN  : shmaddr    指定调用进程内被映射区的起始地址
 */
int shmdt(const void *shmaddr);
```

### shmctl - 控制共享内存段

```c
/*
 * 功能: 控制共享内存段
 * 返回: 成功0，失败返回-1
 * IN  : msqid      共享内存段描述符
 * IN  : cmd        命令
 * INOUT: buf       数据存储区
 * cmd指令:
 * IPC_RMID         删除控制共享内存段(需要所有进程解除映射)，所有消息会被清空，msgsnd/msgrcv 返回EIDRM错误，msgsnd/msgrcv阻塞进程会唤醒。
 * IPC_STAT         取得共享内存段数据结构副本
 * IPC_SET          修改共享内存段数据结构，可修改shm_perm的 uid gid mode
 * IPC_INFO         取得消息队列资源消耗情况，获取entries数组最大下标
 * SHM_LOCK         共享内存段内存锁
 * SHM_UNLOCK       共享内存段内存解锁
 */
int shmctl(int shmid, int cmd, struct shmid_ds *buf);
```

## POSIX IPC

| 接口      | 消息队列      | 信号量        | 共享内存        |
| ----      | ----          | ----          | ----            |
| 头文件    | <mqueue.h>    | <semaphore.h> | <mman.h>        |
| 描述符    | mqd_t         | sem_t*        | int(文件描述符) |
| 创建/打开 | mq_open()     | sem_open()    | shm_open()      |
| 关闭对象  | mq_close()    | sem_close()   | close()         |
| 断开连接  | mq_unlink()   | sem_unlink()  | shm_unlink()    |
| 执行IPC   | mq_send()     | sem_post()    | 使用文件I/O函数 |
|           | mq_receive()  | sem_wait()    |                 |
|           |               | sem_getvalue()|                 |
| 其它操作  |  mq_getattr() | sem_init()    |                 |
|           | mq_setattr()  | sem_destroy() |                 |
|           | mq_notify()   |               |                 |

* 除非特别说明，完全可以套用文件I/O模型理解和使用POSIX IPC。

## POSIX 消息队列

### mq_attr - 消息队列属性

```c
/*
 * 功能: 消息队列属性
 * 说明: 只能修改mq_flags的O_NONBLOCK标志，mq_maxmsg和mq_msgsize在mq_open()中指定后就无法修改，mq_curmsgs动态变化
 */
struct mq_attr {
    long mq_flags;   // 标志
    long mq_maxmsg;  // 最大消息数目
    long mq_msgsize; // 最大消息长度
    long mq_curmsgs; // 当前消息数目
};
```

### mq_getattr - 获取消息队列属性

```c
/*
 * 功能: 获取消息队列属性
 * 返回: 成功返回0，失败返回-1
 * IN  : mqdes      消息队列描述符
 * OUT : attr       获取的消息队列属性
 */
int mq_getattr(mqd_t mqdes, struct mq_attr *attr);
```

### mq_setattr - 设置消息队列属性

```c
/*
 * 功能: 设置消息队列属性
 * 返回: 成功返回0，失败返回-1
 * IN  : mqdes      消息队列描述符
 * IN  : newattr    设置的消息队列属性
 * OUT : oldattr    返回原先的消息队列属性，可以为NULL
 * 说明: 只能修改mq_flags的O_NONBLOCK标志。
 */
int mq_setattr(mqd_t mqdes, const struct mq_attr *newattr, struct mq_attr *oldattr);
```

### mq_open - 新建或打开消息队列

```c
/*
 * 功能: 新建或打开消息队列
 * 返回: 成功返回消息队列描述符mqd_t，失败返回-1
 * IN  : name       绝对文件路径名 /mq_xxx
 * IN  : oflag      可以使用 O_CREAT O_EXCL O_NONBLOCK    O_RDONLY O_WRONLY O_RDWR
 * IN  : mode       权限，和文件I/O一样
 * IN  : attr       属性，NULL时取默认
 * 说明: 新建消息队列需要mode和attr，否则可以省略
 * mq_send()需要写权限，mq_receive() 需要读权限
 * mqd_t在Linux上是int，Solaris上是void*。
 * 在fork()中子进程会得到mqd_t副本，但不会继承消息通知注册。
 */
mqd_t mq_open(const char *name, int oflag, .../* mode_t mode, struct mq_attr *attr */);
```

### mq_close - 关闭消息队列

```c
/*
 * 功能: 关闭消息队列
 * 返回: 成功返回0，失败返回-1
 * IN  : mqdes      消息队列描述符
 * 说明: mq_close()会自动删除消息通知注册。
 */
int mq_close(mqd_t mqdes);
```

### mq_unlink - 删除消息队列

```c
/*
 * 功能: 删除消息队列
 * 返回: 成功返回0，失败返回-1
 * IN  : name       路径名
 */
int mq_unlink(const char *name);
```

### mq_send / mq_timedsend - 发送消息

```c
/*
 * 功能: 发送消息
 * 返回: 成功返回0，失败返回-1
 * IN  : mqdes      消息队列描述符
 * IN  : msg_ptr    要发送的消息的缓冲区
 * IN  : msg_len    要发送的消息的长度
 * IN  : msg_prio   要发送的消息的优先级，正整数，0的优先最高，
 * IN  : abs_timeout超时时间 s+ns
 * 说明: 优先级高的消息放在前面，相同优先级的消息先发送的放在前面。
 */
int mq_send(mqd_t mqdes, const char *msg_ptr, size_t msg_len, unsigned int msg_prio);
int mq_timedsend(mqd_t mqdes, const char *msg_ptr, size_t msg_len, unsigned int msg_prio, const struct timespec *abs_timeout);
```

### mq_receive / mq_timedreceive - 接收消息

```c
/*
 * 功能: 接收消息
 * 返回: 成功返回0，失败返回-1
 * IN  : mqdes      消息队列描述符
 * OUT : msg_ptr    接受到消息的存放的缓冲区
 * IN  : msg_len    缓冲区长度，必须大于等于最大消息长度，否则EMSGSIZE错误
 * OUT : msg_prio   接受到消息的优先级复制到这里，可以为NULL
 * IN  : abs_timeout超时时间 s+ns
 * 说明: 接受到的是最前面的一条消息。
 */
ssize_t mq_receive(mqd_t mqdes, char *msg_ptr, size_t msg_len, unsigned int *msg_prio);
ssize_t mq_timedreceive(mqd_t mqdes, char *msg_ptr, size_t msg_len, unsigned int *msg_prio, const struct timespec *abs_timeout);
```

### mq_notify - 注册接收通知

```c
/*
 * 功能: 注册接收通知
 * 返回: 成功返回0，失败返回-1
 * IN  : mqdes      消息队列描述符
 * IN  : notification   对消息队列的通知方式
 * 说明: 1.只有一个进程能注册消息通知。已有一个进程注册消息通知时，后续注册消息通知时会返回EBUSY错误。
 * 2.只有一条新消息进入之前为空的队列时才会向注册进程发送通知，新消息进入之前有消息的队列不会向注册进程发送通知。
 * 3.其它进程mq_receive()阻塞时，一条新消息进入之前为空的队列时不会向注册进程发送通知，优先处理接收消息。
 * 4.向注册进程发送通知后，会删除注册进程的注册消息。
 * 5.注册进程注册消息通知后，运行mq_notify(mqdes,NULL)会删除注册消息
 */
int mq_notify(mqd_t mqdes, const struct sigevent *notification);
```

## POSIX 信号量

### sem_open - 新建或打开信号量

```c
/*
 * 功能: 新建或打开信号量
 * 返回: 成功返回信号量指针sem_t*，失败返回-1
 * IN  : name       绝对文件路径名 /xxx，/dev/shm/目录出现sem.xxx文件
 * IN  : oflag      可以使用 O_CREAT O_EXCL，没有O_NONBLOCK O_RDONLY O_WRONLY O_RDWR
 * IN  : mode       权限，和文件I/O一样，但默认需要提供访问这个信号量的读写权限即666
 * IN  : value      信号量的初始值
 * 说明: 新建信号量需要mode和value，否则可以省略。
 * 不能为sem_t变量赋值，{sem_t *sp, sem; sp = sem_open(...); sem = *sp}结果未定义。
 */
sem_t *sem_open(const char *name, int oflag, .../* mode_t mode, unsigned int value */ );
```

### sem_close - 关闭信号量

```c
/*
 * 功能: 关闭信号量
 * 返回: 成功返回0，失败返回-1
 * IN  : sem        信号量指针
 * 说明: mq_close()会自动删除消息通知注册。
 */
int sem_close(sem_t *sem);
```

### sem_unlink - 删除信号量

```c
/*
 * 功能: 删除信号量
 * 返回: 成功返回0，失败返回-1
 * IN  : name       信号量路径名
 */
int sem_unlink(const char *name);
```

### sem_wait / sem_trywait / sem_timedwait - 等待一个信号量(值-1)

```c
/*
 * 功能: 等待一个信号量(值-1)
 * 返回: 成功返回0，失败返回-1
 * 说明: 当前信号量的值大于0时，sem_wait()会使信号量的值-1并立即成功返回，否则阻塞或报错。
 * 阻塞的sem_wait()调用会被信号处理器中断，此时失败返回EINTR错误
 */
int sem_wait(sem_t *sem);
int sem_trywait(sem_t *sem);
int sem_timedwait(sem_t *sem, const struct timespec *abs_timeout);
```

### sem_post - 发布一个信号量(值+1)

```c
/*
 * 功能: 发布一个信号量(值+1)
 * 返回: 成功返回0，失败返回-1
 * 说明: 当前信号量值为0并且有阻塞的sem_wait()调用进程时，sem_post()会唤醒一条(优先级最高等待时间最长的)进程。
 */
int sem_post(sem_t *sem);
```

### sem_getvalue - 获取信号量的当前值

```c
/*
 * 功能: 获取信号量的当前值
 * 返回: 成功返回0，失败返回-1
 * IN  : sem        信号量指针
 * OUT : sval       获取的信号量的值
 * 说明: 有阻塞的sem_wait()调用时，返回的sval的值是0(Linux)或等待者数目的负数，取决于实现。
 * 获取sval的值可能你再使用的时候就已经过时了。
 */
int sem_getvalue(sem_t *sem, int *sval);
```

### sem_init - 初始化未命名信号量

```c
/*
 * 功能: 初始化未命名信号量
 * 返回: 成功返回0，失败返回-1
 * IN  : sem        信号量指针
 * IN  : pshared    共享类型: 0，线程间共享; 非0，进程间共享。有些实现不支持进程间共享。
 * IN  : value      信号量的初始值
 * 说明: 线程间共享的sem是全局变量或堆变量的地址，具有进程持久性。
 * 进程间共享的sem是共享内存区域(共享内存、内存映射)的地址，持久性和共享内存区域一致。
 */
int sem_init(sem_t *sem, int pshared, unsigned int value);
```

### sem_destroy - 销毁未命名信号量

```c
/*
 * 功能: 销毁未命名信号量
 * 返回: 成功返回0，失败返回-1
 * IN  : sem        信号量指针
 * 说明: 必须不存在进程或线程等待一个信号量时才能安全地销毁未命名信号量。
 */
int sem_destroy(sem_t *sem);
```

## POSIX 共享内存

### shm_open - 新建或打开共享内存

```c
/*
 * 功能: 新建或打开共享内存
 * 返回: 成功返回共享内存文件描述符，失败返回-1
 * IN  : name       绝对文件路径名 /xxx，/dev/shm/目录会创建xxx的文件
 * IN  : oflag      可以使用 O_CREAT O_EXCL O_TRUNC O_RDONLY O_RDWR，没有O_WRONLY
 * IN  : mode       权限，总是需要，没有O_CREAT标志时该值可以为0
 * 说明: 默认存在close_on_exec标记，新共享内存创建时其初始长度为0。
 * 可以使用ftruncate()来改变共享内存长度。新增加的长度会默认初始化为0。
 * 后续可以使用文件I/O函数对共享内存文件描述符进行操作。
 * 常用方法是shm_open打开一个共享内存，mmap将文件描述符映射到内存地址，关闭文件描述符，对映射的内存地址进行操作，删除映射的内存。
 */
int shm_open(const char *name, int oflag, mode_t mode);
```

### shm_unlink - 删除共享内存名字

```c
/*
 * 功能: 删除共享内存名字
 * 返回: 成功返回0，失败返回-1
 * IN  : name       共享内存路径名
 * 说明: 默认存在close_on_exec标记，新共享内存创建时其初始长度为0。
 */
int shm_unlink(const char *name);
```

## 内存映射

* 执行fork()时子进程会继承映射和映射类型(私有/共享)，执行exec()后映射会丢失。
* 内存映射的用途

    | 变更可见性 | 文件映射                 | 匿名映射              |
    | ---        | ---                     | ---                   |
    | 私有       | 根据文件内容初始化内存   | 分配新内存并初始化为0 |
    | 共享       | 内存映射I/O; 共享内存IPC | 共享内存IPC           |

### mmap - 新建内存映射

```c
/*
 * 功能: 新建内存映射
 * 返回: 成功返回被映射区的起始地址，失败返回MAP_FAILED
 * IN  : addr       指定调用进程内被映射区的起始地址，通常设为NULL，由系统决定映射区的起始地址
 * IN  : len        映射到调用进程地址空间中的字节数，从offset算起。
 * IN  : prot       权限: PROT_READ(可读) PROT_WRITE(可写) PROT_EXEC(可执行) PROT_NONE(无法访问)
 * IN  : flags      变动共享状态: MAP_SHARED(变动共享) MAP_PRIVATE(变动私有) MAP_FIXED(准确解释addr)
 * IN  : fd         映射的文件
 * IN  : offset     偏移量，一般写成0
 * 说明: 将一个文件或一个POSIX共享内存对象映射到调用进程的地址空间，不能映射终端和套接字的文件描述符。
 * 违反prot保护的操作会触发SIGSEGV信号。PROT_NONE通常作为起始或结束位置的保护分页。
 * MAP_SHARED，变更对其它MAP_SHARED进程可见，变更是会同步到文件; MAP_PRIVATE，变更对其它进程不可见，变更会被丢弃。
 * 可能根据addr自动上舍入到分页对齐地址返回; len不必是分页大小的倍数，但内核会以分页大小创建内存映射。
 * 分页对齐(某些实现不要求): offset是分页大小倍数; 指定了MAP_FIXED，要求addr分页对齐; 指定了MAP_FIXED，要求addr和offset除以分页大小的余数相同。
 * 创建匿名映射有两种方法: fd传入打开的/dev/zero设备的文件描述符; fd传入-1，并flags指定MAP_ANONYMOUS
 */
void *mmap(void *addr, size_t len, int prot, int flags, in fd, off_t offset);
```

### mremap - 重新内存映射(Linux专有)

```c
/*
 * 功能: 重新内存映射(Linux专有)
 * 返回: 成功返回被映射区的起始地址(可能与old_addr不同)，失败返回MAP_FAILED
 * IN  : flags      映射选项: MREMAP_MAYMOVE MREMAP_FIXED
 *        MREMAP_MAYMOVE   如果未指定此选项时，并且当前位置没有足够空间扩展，返回ENOMEM错误。
 *        MREMAP_MAYMOVE | MREMAP_FIXED  指定此选项组合时，在new_addr处重新映射。
 */
void *mremap(void *old_addr, size_t old_len, size_t new_len, int flags, .../* void *new_addr */);
```

### munmap - 解除内存映射

```c
/*
 * 功能: 解除内存映射
 * 返回: 成功返回0，失败返回-1
 * IN  : addr       被映射区的起始地址，必须分页对齐
 * IN  : len        被映射区的字节数，会上舍入到分页倍数大小
 * 说明: 解除不是映射的地址会返回0。可以解除部分映射区。访问解除了的映射的地址区间会触发SIGSEGV信号。
 * 解除映射会删除进程持有的在指定地址范围内的内存锁。解除映射前需要调用msync()。
 */
int munmap(void *addr, size_t len);
```

### msync - 强制同步内存映射到文件

```c
/*
 * 功能: 强制同步内存映射到文件
 * 返回: 成功返回0，失败返回-1
 * IN  : addr       被映射区的起始地址，必须分页对齐
 * IN  : len        被映射区的字节数
 * IN  : flags      同步模式: MS_ASYNC(异步写) MS_SYNC(同步写) MS_INVALIDATE(使高速缓存数据失效)
 * 说明: MS_ASYNC(异步写)立即返回，MS_SYNC(同步写)等写操作完成才返回。
 */
int msync(void *addr, size_t len, int flags);
```

### mprotect - 修改内存保护模式

```c
/*
 * 功能: 修改内存保护模式
 * 返回: 成功返回0，失败返回-1
 * IN  : addr       内存的起始地址，必须分页对齐
 * IN  : len        内存的字节数，上舍到分页大小的整数倍
 * IN  : flags      权限: PROT_READ(可读) PROT_WRITE(可写) PROT_EXEC(可执行) PROT_NONE(无法访问)
 */
int mprotect(void *addr, size_t len, int prot);
```

### mlock / munlock - 内存加解锁

```c
/*
 * 功能: 内存加解锁
 * 返回: 成功返回0，失败返回-1
 * IN  : addr       内存的起始地址
 * IN  : len        内存的字节数
 * 说明: 内存锁的作用是将一块虚拟进程区域锁进物理内存，从而防止他被交换出去，以提高性能。
 * 特权进程能够锁住的内存数量没有限制，非特权进程限制为RLIMIT_MEMLOCK(默认8个分页)
 * 内存锁不会在fork()中继承，多次lock不会叠加
 */
int mlock(void *addr, size_t len);
int munlock(void *addr, size_t len);
```

### mlockall / munlockall - 进程的所有内存加解锁

```c
 /*
 * 功能: 进程的所有内存加解锁
 * 返回: 成功返回0，失败返回-1
 * IN  : flags      选项标志: MCL_CURRENT(当前的映射加锁) MCL_FUTURE(后续的映射也加锁)
 */
int mlockall(int flags);
int munlockall(void);
```

### mincore - 确定内存驻留性

```c
 /*
 * 功能: 确定内存驻留性
 * 返回: 成功返回0，失败返回-1
 * IN  : addr       内存的起始地址，必须分页对齐
 * IN  : len        内存的字节数，上舍到分页大小的整数倍
 * OUT : vec        驻留状态，大小为分页页数，使用最低有效位判断是否驻留在内存中
 */
int mincore(void *addr, size_t len, unsigned char *vec);
```

### madvise - 建议后续内存的使用模式

```c
 /*
 * 功能: 建议后续内存的使用模式
 * 返回: 成功返回0，失败返回-1
 * IN  : addr       内存的起始地址，必须分页对齐
 * IN  : len        内存的字节数，上舍到分页大小的整数倍
 * OUT : advice     使用建议，默认行为是MADV_MORMAL
 */
int madvise(void *addr, size_t len, int advice);
```

## 文件加锁

* 劝告式锁指一个进程可以忽略另一进程在文件上放置的锁。强制式锁不能忽略。
* stdio库在用户空间进行缓冲可能会影响文件加锁。避免这一问题可以采用如下方法:
    * 使用read()和write()而不是stdio库
    * 文件加锁之后和释放锁之前各立即刷新一次stdio库
    * 使用setbuf禁用stdio缓冲(会影响效率)

### flock - 整个文件加锁(BSD)

```c
 /*
 * 功能: 整个文件加锁(BSD)
 * 返回: 成功返回0，失败返回-1
 * IN  : fd         文件描述符
 * IN  : operation  加锁方式: LOCK_SH(共享锁) LOCK_EX(互斥锁) LOCK_UN(解锁) LOCK_NB(非阻塞锁)
 * 说明: LOCK_SH(共享锁) LOCK_EX(互斥锁) 的使用类似读写锁
 * 同一个进程可以再次flock直接转换 LOCK_SH(共享锁)，LOCK_EX(互斥锁），转换过程先释放旧锁，再创建新锁，转换不是原子的。
 * 文件锁与文件描述符相关联，文件描述符被关闭后锁会自动释放(需要关闭此进程所有打开同一个文件的描述符)。
 * 文件描述符被复制dup()后新的文件描述符会引用同一个文件锁, 解锁时解锁一次就可以。
 * 文件描述符被fork()后子进程的文件描述符会引用同一个文件锁, 解锁子进程文件锁父进程也会解锁。锁在exec()会被保留。
 * 进程再次打开同一个文件，加锁新的文件描述符会新建一个新的文件锁。如果对前面的文件描述符加了锁，对新的文件描述符加锁会阻塞。
 * flock只能放置劝告式锁，很多NFS实现不支持flock()放置的锁。
 */
 int flock(int fd, int operation);
```

### fcntl - 记录加锁(文件部分加锁(SYSV POSIX)

```c
 /*
 * 功能: 记录加锁(文件部分加锁(SYSV POSIX)
 * 返回: 成功取决于cmd，失败返回-1
 * IN  : fd         文件描述符
 * IN  : cmd        命令模式 F_SETLK(非阻塞锁, EAGAIN或EACESS错误) F_SETLKW(阻塞锁) F_GETLK(检测是否可以获得锁)
 * IN  : arg        参数缓存
 * 说明: 可以对未加锁的文件区域解锁，也会返回成功
 * 同一个进程可以再次fcntl直接转换加锁方式(F_RDLCK, F_WRLCK)，转换过程先释放旧锁，再创建新锁，转换是原子的。
 * 无法对文件区域之外加锁。
 * 已有锁与新键的不同模式的锁严格完全包含，会产生三把锁。已有锁与新键的不同模式的锁部分重合会产生两把锁(已有锁截断重合部分)。
 * 已有锁与与新键的相同同模式的锁包含或重合会合并为一般大锁。
 * 记录锁与进程和i-node相关联。一个进程的所有线程共享一组记录锁，fork()子进程不会继承锁，锁在exec()会被保留。
 * 启用强制加锁 $ chmod g+s,g-x file，有些文件系统不支持。劝告式锁指进程可以不加锁访问其它进程加锁了的文件，强制加锁不能。
 */
struct flock {
    short           l_type;     /* Lock type: F_RDLCK, F_WRLCK, F_UNLCK */
    short           l_whence;   /* How to interpret 'l_start': SEEK_SET,SEEK_CUR, SEEK_END */
    off_t           l_start;    /* Offset where the lock begins */
    off_t           l_len;      /* Number of bytes to lock; 0 means "until EOF" */
    pid_t           l_pid;      /* Process preventing our lock (F_GETLK only) */
};
int fcntl(int fd, int cmd, ... /* struct flock *arg */);
```

## 线程同步

* 头文件

```c
#include <pthread.h>
```

## 互斥量

* 互斥量有两种状态:已锁定(locked)和未锁定(unlocked)。
* 任何时候只有一个线程可以锁定该互斥量，并且只有所有者线程才能对该互斥量解锁。
* 线程对为锁定的互斥量加锁调用会立即返回，线程对已锁定的互斥量再次加锁，将会阻线程或调用失败。
* 线程不能对自己加锁了的互斥量再次加锁，不能对其它线程拥有的互斥量或未锁定的互量解锁。
* 互斥量开销比信号量和文件锁小，因为信号量和文件锁的加解锁总是发起系统调用，而互斥量的实现采用了机器语言级的原子操作，只有发生锁的争用时才会执行系统调用futex()。

### pthread_mutex_init / pthread_mutex_destroy - 互斥量初始化和销毁

```c
/*
 * 功能: 互斥量初始化和销毁
 * 返回: 0，成功; >0，失败
 * IN  : attr       定义互斥量的属性，NULL为默认
 * 说明: PTHREAD_MUTEX_INITIALIZER  对静态分配的互斥量默认属性初始化
 *       pthread_mutex_init         动态初始化互斥量，栈或堆中的互斥量或不是默认属性的互斥量必须动态初始化
 *       pthread_mutex_destroy      销毁动态初始化的互斥量，静态分配的互斥量不需要显示destroy
 */
pthread_mutex_t mtx = PTHREAD_MUTEX_INITIALIZER;
int pthread_mutex_init(pthread_mutex_t *mutex, const pthread_mutexattr_t *attr);
int pthread_mutex_destroy(pthread_mutex_t *mutex);
```

### pthread_mutex_lock / pthread_mutex_unlock - 互斥量加解锁

```c
/*
 * 功能: 互斥量加解锁
 * 返回: 0，成功; >0，失败
 * IN  : tsptr      秒和纳秒描述时间
 * 说明: 对未锁定的互斥量加锁将直接锁定该互斥量并返回0
 *       lock       加锁互斥量，对已被加锁的互斥量加锁将导致线程阻塞直到该互斥量被解锁
 *       trylock    加锁互斥量，对已被加锁的互斥量加锁不会导致线程阻塞，直接返回EBUSY错误
 *       timedlock  加锁互斥量，超时未获取锁返回ETIMEDOUT错误
 *       unlock     解锁互斥量
 */
int pthread_mutex_lock(pthread_mutex_t *mutex);
int pthread_mutex_trylock(pthread_mutex_t *mutex);
int pthread_mutex_timedlock(pthread_mutex_t *mutex, const struct timespec *tsptr);
int pthread_mutex_unlock(pthread_mutex_t *mutex);
```

## 读写锁

* 读写锁有3种状态:读锁定(read locked，共享锁定)、写锁定(write locked，互斥锁定)和未锁定(unlocked)。
* 任何时候只有一个线程持有写锁，其它线程读加锁和写加锁都将会阻塞线程或报错失败。
* 可以有多个线程可以同时持有读锁，其它线程写加锁会阻塞线程或报错失败。
* 当有线程尝试写加锁时，后面的读加锁优先级比写加锁低，优先进行写加锁。

### pthread_rwlock_init / pthread_rwlock_destroy - 读写锁初始化和销毁

```c
/*
 * 功能: 读写锁初始化和销毁
 * 返回: 0，成功; >0，失败
 */
pthread_rwlock_t rwlock = PTHREAD_RWLOCK_INITIALIZER;
int pthread_rwlock_init(pthread_rwlock_t *rwlock, const pthread_rwlockattr_t *attr);
int pthread_rwlock_destroy(pthread_rwlock_t *rwlock);
```

### pthread_rwlock_rdlock / pthread_rwlock_wrlock / pthread_rwlock_unlock - 读写锁加解锁

```c
/*
 * 功能: 读写锁加解锁
 * 返回: 0，成功; >0，失败
 * 说明: rdlock 读加锁，wrlock 写加锁，unlock 解锁。其它修饰类似互斥锁。
 */
int pthread_rwlock_rdlock(pthread_rwlock_t *rwlock);
int pthread_rwlock_wrlock(pthread_rwlock_t *rwlock);
int pthread_rwlock_tryrdlock(pthread_rwlock_t *rwlock);
int pthread_rwlock_trywrlock(pthread_rwlock_t *rwlock);
int pthread_rwlock_timedrdlock(pthread_rwlock_t *rwlock, const struct timespec *tsptr);
int pthread_rwlock_timedwrlock(pthread_rwlock_t *rwlock, const struct timespec *tsptr);
int pthread_rwlock_unlock(pthread_rwlock_t *rwlock);
```

## 条件变量

* 条件变量允许一个线程就某个共享资源的状态变化通知其它线程，其它线程阻塞知道收到这个通知。
* 条件变量总是结合互斥量使用，条件变量就共享变量的状态改变发出通知，而互斥量则提供对该共享变量访问的互斥。
* pthread_cond_signal只保证唤醒至少一条找到阻塞的线程，pthread_cond_broadcast唤起所有。
* pthread_cond_wait阻塞当前线程，直到收到条件变量cond的通知。没有任何线程wait时忽略通知。

### pthread_cond_init / pthread_cond_destroy - 条件变量初始化和销毁

```c
/*
 * 功能: 条件变量初始化和销毁
 * 返回: 0，成功; >0，失败
 * 说明: attr为NULL时，取默认值
 */
pthread_cond_t cond = PTHREAD_COND_INITIALIZER;
int pthread_cond_init(pthread_cond_t *cond, const pthread_condattr_t *attr);
int pthread_cond_destroy(pthread_cond_t *cond);
```

### pthread_cond_signal / pthread_cond_broadcast / pthread_cond_wait - 条件变量发送和等待

```c
/*
 * 功能: 条件变量发送和等待
 * 返回: 0，成功; >0，失败
 */
int pthread_cond_signal(pthread_cond_t *cond);
int pthread_cond_broadcast(pthread_cond_t *cond);
int pthread_cond_wait(pthread_cond_t *cond, pthread_mutex_t *mutex);
int pthread_cond_timedwait(pthread_cond_t *cond, pthread_mutex_t *mutex, const struct timespec *tsptr);
```

```c
/* 发送条件变量通知方法 */
pthread_mutex_lock(&mtx);
change_shared_variable();
pthread_mutex_unlock(&mtx);
pthread_cond_signal(&cond)

/* 等待条件变量通知方法 */
pthread_mutex_lock(&mtx);
while (test_shared_variable())
    pthread_cond_wait(&cond, &mtx);
pthread_mutex_unlock(&mtx);
```

## 自旋锁

* 自旋锁与互斥量类似，但它不通过休眠使进程阻塞，而是获取锁之前一直处于忙等状态
* 自旋锁适用于锁持有时间特别短，而且线程不希望重新调度。一般不用于用户线程。
* 自旋锁等待可用时，CPU不能做其它事情，自旋锁会阻塞中断。中断不能休眠，所以它能用的同步原语只能是自旋锁。
* 不要在持有自旋锁的情况下调用可能会进入休眠的函数。
* Linux内核编程中使用的自旋锁是专有的，例如中断中会使用 spin_lock_irqsave() spin_unlock_irqrestore()

### pthread_spin_init / pthread_spin_destroy - 自旋锁初始化和销毁

```c
/*
 * 功能: 自旋锁初始化和销毁
 * 返回: 0，成功; >0，失败
 * IN  : pshared    线程进程共享同步
 *                  PTHREAD_PROCESS_SHARED  自旋锁能被可以访问锁底层内存的线程访问，即使线程属于不同的进程
 *                  PTHREAD_PROCESS_PRIVATE 自旋锁只能被初始化该锁的进程的线程访问
 */
int pthread_spin_init(pthread_spinlock_t *lock, int pshared);
int pthread_spin_destroy(pthread_spinlock_t *lock);
```

### pthread_spin_lock / pthread_spin_unlock - 自旋锁加解锁

```c
/*
 * 功能: 自旋锁加解锁
 * 返回: 0，成功; >0，失败
 * 说明: rdlock 读加锁，wrlock 写加锁，unlock 解锁。其它修饰类似互斥锁。
 */
int pthread_spin_lock(pthread_spinlock_t *lock);
int pthread_spin_trylock(pthread_spinlock_t *lock);
int pthread_spin_unlock(pthread_spinlock_t *lock);
```

## 屏障barrier

* 屏障是协调多个线程并行工作的同步机制，允许每个线程等待，直到所有合作线程都到达某一点，然后从该点继续执行。
* 类似 pthread_join()，但屏障允许任意数量的线程等待。可用于大数据计算。

### pthread_barrier_init / pthread_barrier_destroy - 屏障初始化和销毁

```c
/*
 * 功能: 屏障初始化和销毁
 * 返回: 0，成功; >0，失败
 * IN  : count      到达屏障点的最少数目。未满足计数时，到达屏障点的线程都会进入休眠; 满足计数时，唤醒所有线程。
 * 说明: restrict，C语言中的一种类型限定符，用于告诉编译器，对象已经被指针所引用，不能通过除该指针外所有其他直接或间接的方式修改该对象的内容。
 */
int pthread_barrier_init(pthread_barrier_t *restrict barrier, const pthread_barrierattr_t *restrict attr, unsigned int count);
int pthread_barrier_destroy(pthread_barrier_t *barrier);
```

### pthread_barrier_wait - 设定屏障点

```c
/*
 * 功能: 设定屏障点
 * 返回: 0或PTHREAD_BARRIER_SERIAL_THREAD，成功; >0，失败
 * 说明: 一个任意线程会得到PTHREAD_BARRIER_SERIAL_THREAD返回，它作为主线程; 剩下的所有线程得到0返回
 */
int pthread_barrier_wait(pthread_barrier_t *barrier);
```

## 信号

* 信号其实就是一个软件中断，例如：
    1. 输入命令，在Shell下启动一个前台进程。
    2. 用户按下Ctrl-C（Ctrl+C产生的信号只能发送给前台进程），键盘输入产生一个硬件中断。
    3. 如果CPU当前正在执行这个进程的代码，则该进程的用户空间代码暂停执行， CPU从用户态切换到内核态处理硬件中断。
    4. 终端驱动程序将Ctrl-C解释成一个SIGINT信号，记在该进程的PCB中（也可以说发送了一个SIGINT信号给该进程）。
    5. 当某个时刻要从内核返回到该进程的用户空间代码继续执行之前，首先处理PCB中记录的信号，发现有一个SIGINT信号待处理，而这个信号的默认处理动作是终止进程，所以直接终止进程而不再返回它的用户空间代码执行。

* 信号与中断的区别
* 相同点：
    * 采用了相同的异步通信方式
    * 当检测出有信号或中断请求时，都暂停正在执行的程序而转去执行相应的处理程序
    * 都在处理完毕后返回到原来的断点
    * 对信号或中断都可进行屏蔽
* 不同点：
    * 中断有优先级，而信号没有优先级，所有的信号都是平等的
    * 信号处理程序是在用户态下运行的，而中断处理程序是在核心态下运行
    * 中断响应是及时的，而信号响应通常都有较大的时间延迟

### 内核处理信号的3种方式

* 忽略此信号
    * SIGKILL 和 SIGSTOP 无法被忽略，因为他们向内核和超级用户提供了进程终止和停止的可靠方法
* 捕捉信号
    * 如果信号的处理动作是用户自定义函数，在信号递达时就调用这个函数，这称为捕捉信号。
* 执行系统默认操作
    * 大多数信号默认操作时中止该进程

### 信号列表

```
$ kill -l
 1) SIGHUP   2) SIGINT   3) SIGQUIT  4) SIGILL   5) SIGTRAP
 6) SIGABRT  7) SIGBUS   8) SIGFPE   9) SIGKILL 10) SIGUSR1
11) SIGSEGV 12) SIGUSR2 13) SIGPIPE 14) SIGALRM 15) SIGTERM
16) SIGSTKFLT   17) SIGCHLD 18) SIGCONT 19) SIGSTOP 20) SIGTSTP
21) SIGTTIN 22) SIGTTOU 23) SIGURG  24) SIGXCPU 25) SIGXFSZ
26) SIGVTALRM   27) SIGPROF 28) SIGWINCH    29) SIGIO   30) SIGPWR
31) SIGSYS  34) SIGRTMIN    35) SIGRTMIN+1  36) SIGRTMIN+2  37) SIGRTMIN+3
38) SIGRTMIN+4  39) SIGRTMIN+5  40) SIGRTMIN+6  41) SIGRTMIN+7  42) SIGRTMIN+8
43) SIGRTMIN+9  44) SIGRTMIN+10 45) SIGRTMIN+11 46) SIGRTMIN+12 47) SIGRTMIN+13
48) SIGRTMIN+14 49) SIGRTMIN+15 50) SIGRTMAX-14 51) SIGRTMAX-13 52) SIGRTMAX-12
53) SIGRTMAX-11 54) SIGRTMAX-10 55) SIGRTMAX-9  56) SIGRTMAX-8  57) SIGRTMAX-7
58) SIGRTMAX-6  59) SIGRTMAX-5  60) SIGRTMAX-4  61) SIGRTMAX-3  62) SIGRTMAX-2
63) SIGRTMAX-1  64) SIGRTMAX
```

### signal - 设置信号处理方式

```c
/*
 * 功能: 设置信号处理方式
 * 返回: 返回以前的信号处理函数，成功; SIG_ERR，失败
 * IN  : signum     信号编号
 * IN  : handler    信号处理函数，可选择：
 *                  函数地址 : 用户自定义信号处理函数
 *                  SIG_IGN : 忽略信号
 *                  SIG_DFT : 系统默认处理
 */
#include <signal.h>
typedef void (*sighandler_t)(int);
sighandler_t signal(int signum, sighandler_t handler);
```

### sigaction - 检查或修改指定信号的处理方式

```c
/*
 * 功能: 检查或修改指定信号的处理方式
 * 返回: 0，成功; -1，失败
 * IN  : signum     要操作的信号编号
 * IN  : act        要设置的对信号的新处理方式，可以为NULL
 * OUT : oldact     原来对信号的处理方式，可以为NULL
 *
 * struct sigaction 说明:
 * sa_handler       和signal()的参数handler相同，代表新的信号处理函数
 * sa_sigaction     新的信号处理函数，和 sa_handler 二选一
 * sa_mask          用来设置在处理该信号时暂时将 sa_mask 指定的信号集阻塞
 * sa_flags         用来设置信号处理的其他相关操作，如下：
 *  SA_RESTART      使被信号打断的系统调用自动重新发起。
 *  SA_NOCLDSTOP    使父进程在它的子进程暂停或继续运行时不会收到 SIGCHLD 信号
 *  SA_NOCLDWAIT    使父进程在它的子进程退出时不会收到 SIGCHLD 信号，这时子进程如果退出也不会成为僵尸进程
 *  SA_NODEFER      使对信号的屏蔽无效，即在信号处理函数执行期间仍能发出这个信号
 *  SA_RESETHAND    信号处理之后重新设置为默认的处理方式 SIG_DFL
 *  SA_SIGINFO      使用 sa_sigaction 成员而不是 sa_handler 作为信号处理函数
 * sa_restorer      废弃不用
 * 注：
 * 1. sa_handler主要用于不可靠信号（实时信号当然也可以，只是不能带信息）
 * 2. sa_sigaction用于实时信号可以带信息(siginfo_t)
*/

#include <signal.h>
typedef union sigval {
    int sival_int;
    void __user *sival_ptr;
} sigval_t;
typedef struct siginfo_t{
    int si_signo;   //信号编号
    int si_errno;   //如果为非零值则错误代码与之关联
    int si_code;    //说明进程如何接收信号以及从何处收到
    pid_t si_pid;   //适用于SIGCHLD，代表被终止进程的PID
    pid_t si_uid;   //适用于SIGCHLD,代表被终止进程所拥有进程的UID
    int si_status;  //适用于SIGCHLD，代表被终止进程的状态
    clock_t si_utime;//适用于SIGCHLD，代表被终止进程所消耗的用户时间
    clock_t si_stime;//适用于SIGCHLD，代表被终止进程所消耗系统的时间
    sigval_t si_value;
    int si_int;     // si_value.sival_int
    void* si_ptr;   // si_value.sival_ptr
    void* si_addr;
    int si_band;
    int si_fd;
};
struct sigaction {
    void     (*sa_handler)(int);
    void     (*sa_sigaction)(int, siginfo_t *, void *);
    sigset_t   sa_mask;
    int        sa_flags;
    void     (*sa_restorer)(void);
};

int sigaction(int signum, const struct sigaction *act,
                struct sigaction *oldact);
```
### kill / raise - 发送信号

```c
/*
 * 功能: 发送信号
 * 返回: 0，成功; -1，失败
 * IN  : pid        进程pid
                    >0, 发送信号到特定进程;
                    0, 发送信号到同一进程组的所有进程;
                    -1, 发送信号到可以发送信号的所有进程
                    <-1,发送信号到特定进程组的所有进程;
 * IN  : sig        信号编号，0时表示只检查错误不发送信号
 */
#include <sys/types.h>
#include <signal.h>
int kill(pid_t pid, int sig);
int raise(int sig); // == kill(getpid(), sig);
```

### sigqueue - 发送信号，支持信号带有参数
```c
/*
 * 功能: 发送信号，支持信号带有参数
 * 返回: 0，成功; -1，失败
 * IN  : pid        进程pid，只能向一个进程发送信号
                    >0, 发送信号到特定进程;
 * IN  : sig        信号编号，0时表示只检查错误不发送信号
 * IN  : value
 * 设置信号处理方式是需要使用sigaction的sa_sigaction
 */
#include <sys/types.h>
#include <signal.h>
int sigqueue(pid_t pid, int sig, const union sigval value);
```

### abort - 发送SIGABRT信号使进程异常终止

```c
/*
 * 功能: 发送SIGABRT信号使进程异常终止
 * 返回: 无
 */
#include <stdlib.h>
void abort(void); // = raise(SIGABRT)
```

### alarm - 超时向自己发送SIGALRM信号

```c
/*
 * 功能: 超时向自己发送SIGALRM信号
 * 返回: 0 或 前面调用alarm剩余的秒数(每个进程只有一个闹钟时间)
 * IN  : seconds    超时秒数
 */
#include <unistd.h>
unsigned int alarm(unsigned int seconds);
```

### pause - 挂起进程直到捕捉到信号

```c
/*
 * 功能: 挂起进程直到捕捉到信号
 * 返回: 仅在捕获信号并返回信号捕获函数时返回
 */
#include <unistd.h>
int pause(void);
```

### 信号集操作函数

```c
/*
 * 功能: 信号集操作函数
 * 返回: 0，成功; -1，失败(sigismember例外)
 * sigismember: 1, 是信号集成员; 0，成功; -1，失败
 * IN  : set        要操作的信号集
 * IN  : signo      要操作的信号编号
 */
#include <signal.h>
typedef struct {
    unsigned long sig[_NSIG_WORDS];
} sigset_t;

int sigemptyset(sigset_t* set);                 // 将set集合置空
int sigfillset(sigset_t* set);                  // 将所有信号加入set集合
int sigaddset(sigset_t* set, int signo);        // 将signo信号加入到set集合
int sigdelset(sigset_t* set, int signo);        // 从set集合中移除signo信号
int sigismember(const sigset_t* set, int signo);// 判断信号是否在set集合中置位
```

### sigprocmask - 读取或更改进程的阻塞信号集

```c
/*
 * 功能: 读取或更改进程的阻塞信号集
 * 返回: 0，成功; -1，失败
 * IN  : how        要执行的操作
 *      SIG_BLOCK   set包含了我们希望添加到当前信号屏蔽字的信号（往里加）
 *      SIG_UNBLOCK set包含了我们希望从当前信号屏蔽字中解除阻塞的信号（往外减）
 *      SIG_SETMASK 设置当前信号屏蔽字为set所指向的值（重新设置）
 * IN  : set        要操作的信号集，可以为NULL
 * OUT : oldset     返回原来的阻塞信号集，可以为NULL
 * 说明: 如果在信号阻塞时将其发送给进程，那么该信号的传递就被推迟直到对它解除了阻塞。
 */

#include <signal.h>
int sigprocmask(int how, const sigset_t *set, sigset_t *oldset);
```

### sigpending - 读取当前进程的未决信号集

```c
/*
 * 功能: 读取或更改进程的阻塞信号集
 * 返回: 0，成功; -1，失败
 * OUT : set        返回当前进程的未决信号集
 */

#include <signal.h>
int sigpending(sigset_t *set);
```

### sigsuspend - 设置当前进程的临时掩码并挂起

```c
/*
 * 功能: 设置阻塞信号为mask，等待其他信号（除mask之外的信号）的发生，若信号发生且对应的handler已执行，则返回-1，并设置相应的errno(已发生的信号值）
 * 返回: 总是返回-1，并将errno设置为EINTR（表示一个被中断的系统调用）
 * IN  : mask           临时的进程掩码
 * sigsuspend实际是将sigprocmask和pause结合起来原子操作：
 * （1）设置新的mask阻塞当前进程
 * （2）收到临时的进程掩码的信号，阻塞，程序继续挂起；收到其他信号，恢复原先的掩码
 * （3）调用该进程设置的信号处理函数
 * （4）待信号处理函数返回，sigsuspend返回了
 */

#include <signal.h>
int sigsuspend(const sigset_t *mask);
```

## socket编程

* 头文件

```c
#include <sys/socket.h>
#include <arpa/inet.h>
#include <netinet/in.h>
```

### 工具

* iputils 软件包

iputils软件包是linux环境下一些实用的网络工具的集合。一开始由Alexey Kuznetsov维护。

- iputils包含以下几个工具：
  - `ping` 使用 ping可以测试计算机名和计算机的ip地址，验证与远程计算机的连接。ping程序由ping.c ping6.cping_common.c ping.h 文件构成
  - `tracepath` 与traceroute功能相似，使用tracepath测试IP数据报文从源主机传到目的主机经过的路由。tracepath程序由tracepath.c tracepath6.c traceroute6.c 文件构成。
  - `arping` 使用arping向目的主机发送ARP报文，通过目的主机的IP获得该主机的硬件地址。arping程序由arping.c文件构成。
  - `tftpd`  tftpd是简单文件传送协议TFTP的服务端程序。tftpd程序由tftp.h tftpd.c tftpsubs.c文件构成。
  - rarpd。rarpd是逆地址解析协议的服务端程序。rarpd程序由rarpd.c文件构成。
  - `clockdiff` 使用clockdiff可以测算目的主机和本地主机的系统时间差。clockdiff程序由clockdiff.c文件构成。
  - `rdisc` rdisc是路由器发现守护程序。rdisc程序由rdisc.c文件构成。

* net-tools 软件包(已弃用) 和 iproute2 的 ip 命令(最新)

| net-tools | iproute2 |
| :--: | :--: |
| arp | ip neighbor |
| ifconfig | ip addr, ip link |
| netstat | ss |
| route | ip route |

* wireless_tools 软件包和 iw 命令

| Software | Package | WEXT | nl80211 | WEP | WPA/WPA2 | rchiso |
| :--: | :--: | :--: | :--: | :--: | :--: | :--: |
| wireless_tools | wireless_tools | Yes | No | Yes | No | Yes|
| iw | iw | No | Yes | Yes | No | Yes |
| WPA supplicant | wpa_supplicant | Yes | Yes | Yes | Yes | Yes |
| iwd | iwd | No | Yes | Yes | Yes | Yes |

| iw command | wireless_tools | command Description |
| :-- | :-- | :-- |
| iw dev | iwconfig | Getting interface name. |
| iw dev wlan0 link | iwconfig wlan0 | Getting link status. |
| iw dev wlan0 scan | iwlist wlan0 scan | Scanning for available access points. |
| iw dev wlan0 set type ibss | iwconfig wlan0 mode ad-hoc | Setting the operation mode to ad-hoc. |
| iw dev wlan0 connect your_essid | iwconfig wlan0 essid your_essid | Connecting to open network. |
| iw dev wlan0 connect your_essid 2432 | iwconfig wlan0 essid your_essid freq 2432M | Connecting to open network specifying channel. |
| iw dev wlan0 connect your_essid key 0:your_key | iwconfig wlan0 essid your_essid key your_key | Connecting to WEP encrypted network using hexadecimal key. |
| iw dev wlan0 connect your_essid key 0:your_key | iwconfig wlan0 essid your_essid key s:your_key | Connecting to WEP encrypted network using ASCII key. |
| iw dev wlan0 set power_save on | iwconfig wlan0 power on | Enabling power save. |

### 网络命令

* `ifconfig`        : 查看网络接口详细信息
* `host ip/domain`  : DNS查询
* `ping ip/domain`  : 查看网络连通性，向远程计算机发送报文并报告它是否作出响应
    * ping每秒发送一个请求报文，并对接收到的每个响应报文产生一行对应的输出。该输出信息告知已接收分组的长度、顺序号，以及以毫秒为单位的往返时间
    * 当用户中断程序的运行时，ping产生出汇总的统计信息，包括：发送和接收到的分组数目，丢失分组所占的百分比，以及最短、平均和最长的往返时间
* `traceroute ip/domain ` : 识别到远程主机沿途所经过的各个中间计算机(或路由器)
    * traceroute能确定到达目的主机的路径上的所有路由器，并对应每个路由器打印出一行信息，最后一行对应目的主机本身
* `wireshark+winpcap` : 抓包
    * `tshark`      : wireshark的命令行命令
* `nslookup`        : 查询域名的IP地址或查询本地IP地址的域名
* `dig`             : 解析域名的所有信息
* `telnet`          : Internet远程登陆服务的标准协议和主要方式
* `arp`             : 检查ARP缓存
* `route`           : 查看路由表
* `netstat`         :
    * `netstat -a`  : 查看套接字状态
    * `netstat -at` : 列出所有tcp端口
    * `netstat -ni` : 查看网络接口信息
    * `netstat -nr` : 查看路由表，等价`route -n`
    * `netstat -l`  : 列出所有有监听的服务状态
* `nc`
    * 实现任意TCP/UDP端口的侦听，nc可以作为server以TCP或UDP方式侦听指定端口
    * 端口的扫描，nc可以作为client发起TCP或UDP连接
    * 机器之间传输文件
    * 机器之间网络测速
* `iperf3`            : 网速测试
    * 服务端命令行 `iperf3 -s -p 1314 -i 1`
    * `-s`          : 表示服务器模式
    * `-p`          : 定义端口号
    * `-i`          : 设置每次报告之间的时间间隔，单位为秒，如果设置为非零值，就会按照此时间间隔输出测试报告，默认值为零
    * 客户端命令行 `iperf3 -c 10.0.0.2 -p 1314 -t 60  -i 1`
    * `-c`          : 表示服务器的IP地址
    * `-p`          : 表示服务器的端口号
    * `-i`          : 设置每次报告之间的时间间隔，单位为秒，如果设置为非零值，就会按照此时间间隔输出测试报告，默认值为零
    * `-u`          : 表示采用UDP协议发送报文，不带该参数表示采用TCP协议
    * `-t`          : 参数可以指定传输测试的持续时间，iperf在指定的时间内，重复的发送指定长度的数据包，默认是10秒钟
    * `-w`          : 设置套接字缓冲区为指定大小，对于TCP方式，此设置为TCP窗口大小，对于UDP方式，此设置为接受UDP数据包的缓冲区大小，限制可以接受数据包的最大值
    * `-b`          : 使用带宽大小，bits/sec (0 for unlimited, default 1 Mbit/sec for UDP, unlimited for TCP)
    * `-R`          : 反向传输，缺省iperf3使用上传模式：Client负责发送数据，Server负责接收；如果需要测试下载速度，则在Client侧使用-R参数即可
    * 其它命令行
    * `-F`          : 指定文件作为数据流进行带宽测试
    * `-A`          : CPU亲和性，可以将具体的iperf3进程绑定对应编号的逻辑CPU，避免iperf进程在不同的CPU间调度。
    * `-P`          : 多线程，默认是1个线程。需要客户端与服务器端同时使用此参数
    * `--logfile`   : 参数可以将输出的测试结果储存至文件中
    * 例子
        * `iperf3    -c 10.0.0.2 -t 60 -d`              : 测试上下行带宽（TCP双向传输）
        * `iperf3    -c 10.0.0.2 -t 60 -P 30`           : 测试多线程TCP吞吐量
        * `iperf3 -u -c 10.0.0.2 -t 60 -d -b 100M`      : 测试上下行带宽（UDP双向传输）
        * `iperf3 -u -c 10.0.0.2 -t 60 -b 100M`         : 测试UDP吞吐量
        * `iperf3 -u -c 10.0.0.2 -t 60 -b 5M -P 30`     : 测试多线程UDP吞吐量

### 网络基础

* 五层模型
    * 五层模型: 物理层、数据链路层(帧)、网络层(包)(IP)、传输层(段)(TCP UDP)、应用层
    * 数据链路层(可以使用网桥互联)
        * ARP(Address Resolution Protocol)          : 地址解析协议: 把一个IP地址映射成一个硬件地址
        * RARP(Reverse Address Resolution Protocol) : 反向地址解析协议: 把一个硬件地址映射成一个IP地址
    * 网络层(可以使用路由器互联)
        * IP(Internet Protocol) 网际协议:
        * ICMP(Internet Control Message Protocol)   : 网际控制消息协议: ping 和 traceroute 使用了ICMP，传递差错报文以及其他需要注意的信息
        * IGMP(Internet Group Management Protocol)  : 网际组管理协议: 用于UDP多播和广播
    * 传输层
        * TCP(Transmission Control Protocol)        : 传输控制协议: 面向连接的可靠的双向的无边界的字节流
        * UDP(User Datagram Protocol)               : 用户数据报协议: 不可靠的无序的有消息边界的数据报
        * SCTP(Stream Control Transmission Protocol): 流控制传输协议: 面向连接的可靠的有消息边界的数据流
* IP
    * 根据子网掩码，可以知道两个IP地址是否处于同一个子网
    * 和其它设备通信，需要ARP获取其Mac地址
    * 跨子网通信需要网关转发，先通过ARP获取网关的Mac地址，通过网关转发数据包
    * 已经知道了对方Mac地址，就不需要再发ARP了
    * 如果A收到数据时B的IP和Mac地址匹配，B认为A和它处于同一个子网
    * 如果A收到数据时B的IP和Mac地址不匹配，B认为A和它不处于同一个子网，B通过网关转发数据包给A，此时Mac地址为网关的NAT(Network Address Translation)网络地址转换可以改变IP地址

* TCP
    * TCP封装: IP头 + TCP头 + 数据
    * TCP有 RTTp(Round Trip Time) 往返时间]、序列号、确认、超时、重传、通告窗口、流量控制
    * TCP数据传输时处于的状态是 ESTABLISHED
    * TCP最大窗口基数大小为65535，可以放大2^n倍数(n最大为14)，TCP分节数据部分最大为1460
    * TCP建立连接需要3路握手: `客户端(conncet阻塞) --- (1)SYN J --> 服务器(accept阻塞) --- (2)SYN K, ACK J+1 --> 客户端(conncet返回) --- (3)ACK K+1 --> 服务器(accept返回)`
    * TCP连接终止需要4路握手: `客户端(close) --- (1)FIN M --> 服务器(read返回0) --- (2)ACK M+1 --> 客户端; 服务器(close)--- (3)FIN N --> 客户端 --- (3)ACK N+1 --> 服务器`

### 编程模型

```c
服务端                      客户端
__________________TCP____________________
socket()                    socket()
bind()
listen()
accept()                    conncet()
read()/recv()               write()/send()
write()/send()              read()/recv()
close()                     close()

__________________UDP____________________
socket()                    socket()
bind()
recvfrom()                  sendto()
sendto()                    recvfrom()
close()                     close()

__________________UDP____________________
socket()                    socket()
bind()
                            conncet()
recvfrom()                  write()/send()
sendto()                    read()/recv()
close()                     close()
_________________________________________
```

### 结构体

```c
/* POSIX.1g specifies this type name for the `sa_family' member.  */
typedef unsigned short int sa_family_t;

/* This macro is used to declare the initial common members
   of the data types used for socket addresses, `struct sockaddr',
   `struct sockaddr_in', `struct sockaddr_un', etc.  */

#define __SOCKADDR_COMMON(sa_prefix) \
    sa_family_t sa_prefix##family

/* Type to represent a port.  */
typedef uint16_t in_port_t;

/* Internet address.  */
typedef uint32_t in_addr_t;
struct in_addr
{
    in_addr_t s_addr;
};

struct in6_addr
{
    union
    {
        uint8_t __u6_addr8[16];
#if defined __USE_MISC || defined __USE_GNU
        uint16_t __u6_addr16[8];
        uint32_t __u6_addr32[4];
#endif
    } __in6_u;

#define s6_addr         __in6_u.__u6_addr8
#if defined __USE_MISC || defined __USE_GNU
# define s6_addr16      __in6_u.__u6_addr16
# define s6_addr32      __in6_u.__u6_addr32
#endif
};

/* Structure describing a generic socket address. Can be converted to sockaddr_in/sockaddr_in6 */
struct sockaddr
{
    __SOCKADDR_COMMON (sa_);        /* Common data: address family and length.  */
    char sa_data[14];               /* Address data.  */
};

/* Ditto, for IPv4.  */
struct sockaddr_in
{
    __SOCKADDR_COMMON (sin_);
    in_port_t sin_port;             /* Port number.  */
    struct in_addr sin_addr;        /* Internet address.  */

    /* Pad to size of `struct sockaddr'. */
    unsigned char sin_zero[sizeof (struct sockaddr) -
        __SOCKADDR_COMMON_SIZE -
        sizeof (in_port_t) -
        sizeof (struct in_addr)];
};

/* Ditto, for IPv6.  */
struct sockaddr_in6
{
    __SOCKADDR_COMMON (sin6_);
    in_port_t sin6_port;            /* Transport layer port # */
    uint32_t sin6_flowinfo;         /* IPv6 flow information */
    struct in6_addr sin6_addr;      /* IPv6 address */
    uint32_t sin6_scope_id;         /* IPv6 scope-id */
};
```

### socket - 创建socket

```c

/*
 * 功能: 创建socket
 * 返回: >=0，成功，套接字描述符; -1，失败
 * IN  : domain     主机类型(常用AF_INET和AF_INET6)
 *          AF_INET             IPv4协议
 *          AF_INET6            IPv6协议
 *          AF_UNIX(AF_LOCAL)   Unix域协议
 *          AF_ROUTE            路由套接字
 *          AF_KEY              密钥套接字
 *       type       类型(常用SOCK_STREAM和SOCK_DGRAM)
 *          SOCK_STREAM         字节流套接字(TCP/SCTP)
 *          SOCK_DGRAM          数据报套接字(UDP)
 *          SOCK_SEQPACKET      有序分组套接字(SCTP)
 *          SOCK_RAM            原始套接字(IP)
 *       protocol   协议(通常写0取默认值即可)
 *          IPPROTO_TCP         TCP传输协议
 *          IPPROTO_UDP         UDP传输协议
 *          IPPROTO_SCTP        SCTP传输协议
 */
int socket(int domain, int type, int protocol);
```

### bind - 将socket绑定到地址

```c
/*
 * 功能: 将socket绑定到地址
 * 返回: 0，成功; -1，失败
 * IN  : sockfd     socket返回的套接字描述符
 *       addr       地址，取决于socket的domain，AF_INET(32位ipv4地址+16位端口号) AF_INET6(128位ipv6地址+16位端口号) AF_UNIX(文件路径)
 *       addrlen    addr的大小
 * 说明: 1、bind绑定0值ip地址(INADDR_ANY/IN6ADDR_ANY)表示有内核自己选择主机的网络接口，绑定0值端口表示由内核选择一个临时端口
 * 2、若没有先调用bind，当调用listen或connect时，内核自己选择主机的网络接口和临时端口
 */
int bind(int sockfd, const struct sockaddr *addr, socklen_t addrlen);
```

### listen - 监听接入连接

```c
/*
 * 功能: 监听接入连接
 * 返回: 0，成功; -1，失败
 * IN  : sockfd     socket返回的套接字描述符
 *       backlog    最大监听的接入数目(不要设为0)，实际接入数目可能比这个值稍大
 */
int listen(int sockfd, int backlog);
```

### accept - 接受客户端的连接请求

```c
/*
 * 功能: 接受客户端的连接请求
 * 返回: >=0，成功，套接字描述符; -1，失败
 * IN  : sockfd     socket返回的监听套接字描述符
 * OUT : addr       客户端的地址，取决于socket的domain
 *       addrlen    addr的大小
 * 说明: accept()会创建一个新的socket，与执行connect()的对等socket进行连接。
 */
int accept(int sockfd, struct sockaddr *addr, socklen_t *addrlen);
```

### connect - 客户端连接到服务器

```c
/*
 * 功能: 客户端连接到服务器
 * 返回: >0，成功，套接字描述符; -1，失败
 * IN  : sockfd     socket返回的套接字描述符
 *       addr       客户端的地址，取决于socket的domain
 *       addrlen    addr的大小
 * 说明: 1、connect失败后必须关闭sockfd，重新创建sockfd再调用connect
 * 2、TCP客户端调用connect将触发TCP的三次握手过程:
 * a、ETIMEDOUT 错误表示没有收到SYN的ACK，连接不稳定或服务器没有剩余资源可用
 * b、ECONNREFUSED 错误表现为SYN的响应为RST，服务器没有在指定端口等待客户端连接
 *    注: 取消一个已有连接或接收到不存在的连接上的SYN也会出现RST
 * c、EHOSTUNREACH/ENETUNREACH 表示ICMP错误(无法收到ARP的响应)，路由不可达
 * 3、UDP也可以调用connect，表示记住对端地址，connect后可以使用send/recv，
 * 4、已连接的UDP不能再与其它对端(非记住的对端)通信，ICMP端口不可达错误
 * 5、UDP可以重复调用connect，表示修改记住新的对端或取消记住对端(sin_family设为AF_UNSPEC)
 */
int connect(int sockfd, const struct sockaddr *addr, socklen_t addrlen);
```

### send / recv - tcp发送接收，已连接UDP发送接收

```c
/*
 * 功能: tcp发送接收，已连接UDP发送接收
 * 返回: >0，发送/接收字节数; 0, EOF; -1，失败
 */
ssize_t send(int sockfd, const void *buffer, size_t length, int flags);
size_t recv(int sockfd, void *buffer, size_t length, int flags);

### sendto / recvfrom - udp发送接收

/*
 * 功能: udp发送接收
 * 返回: >0，发送/接收字节数; 0, EOF; -1，失败
 * IN  : flags      MSG_NOSIGNAL --> 忽略SIGPIPE信号(sendto)
 *                  MSG_DONTWAIT --> 此次启用非阻塞操作O_NONBLOCK (sendto/recvfrom)
 */
ssize_t sendto(int sockfd, const void *buffer, size_t length, int flags,
                    const struct sockaddr *dest_addr, socklen_t addrlen);
ssize_t recvfrom(int sockfd, void *buffer, size_t length, int flags,
                    struct sockaddr *src_addr, socklen_t *addrlen);
```

### close - 关闭socket

```c
/*
 * 功能: 关闭socket
 * 返回: 0, 成功; -1，失败
 * IN  : sockfd     socket返回的套接字描述符
 * 说明: close后，TCP默认还会继续发送已排队等待发送到对端的数据，发送完毕后是正常的tcp终止
 */
int close(int sockfd);
```

### shutdown - 半关闭socket

```c
/*
 * 功能: 半关闭socket
 * 返回: 0, 成功; -1，失败
 * IN  : sockfd     socket返回的套接字描述符
 *       how        SHUT_RD关闭读端; SHUT_WR关闭写端; SHUT_RDWR 关闭读写端
 * 说明: close把描述符计数减1，计数为0才关闭套接字；shutdown不管计数立即关闭
 * SHUT_RD 会丢弃套接字接收缓冲区的任何数据，调用后套接字接收对端的任何数据都会ACK后丢弃
 * SHUT_WR 继续发送已排队等待发送到对端的数据，发送完毕后是顶半部的tcp终止序列，半关闭
 * SHUT_RDWR 先调用SHUT_RD，然后调用SHUT_WR
 */
int shutdown(int sockfd, int how);
```

### 网络字节转换，网络传输使用大端序

```c
/*
 * 功能: 网络字节转换，网络传输使用大端序
 * 说明: s 16位， l 32位， h host主机， n network网络
 */
uint16_t htons(uint16_t host_uint16);
uint32_t htonl(uint32_t host_uint32);
uint16_t ntohs(uint16_t net_uint16);
uint32_t ntohl(uint32_t net_uint32);
```

### 点分字符串ip地址转换

```c
/*
 * 功能: inet_pton  点分字符串ip地址转换(字符串到数值)
 *       inet_ntop  点分字符串ip地址转换(数值到字符串)
 *       inet_addr  IPv4点分字符串ip地址转换(字符串到数值)(废弃)
 *       inet_aton  IPv4点分字符串ip地址转换(字符串到数值)
 *       inet_ntoa  IPv4点分字符串ip地址转换(数值到字符串)(不可重入)
 * 返回: inet_pton  1，成功; 0, EOF; -1，失败
 *       inet_ntop  dst_str地址，成功; NULL，失败
 *       inet_addr  32位网络字节序的数值，成功; INADDR_NONE(位全为1), 失败
 *       inet_aton  1，成功; 0, 失败
 *       inet_ntoa  非空指针，成功; NULL，失败
 * 说明: p present呈现形式， n network网络
 *       domain     主机类型，AF_UNIX(AF_LOCAL) AF_INET AF_INET6
 *       src_str/dst_str  点分ip地址字符串
 *       len        数组长度 INET_ADDRSTRLEN INET6_ADDRSTRLEN
 *       addrptr    转换的数值 in_addr, in6_addr
 */
int inet_pton(int domain, const char *src_str, void *addrptr);
const char *inet_ntop(int domain, const void *addrptr, char *dst_str, size_t len);

in_addr_t inet_addr(const char *src_str);
int inet_aton(const char *src_str, struct in_addr *addrptr);
char *inet_ntoa(struct in_addr addrptr);
```

### getsockname / getpeername - 返回sockfd的本机/对端ip参数

```c
/*
 * 功能: getsockname 返回sockfd的本机ip参数
 *       getpeername 返回sockfd的对端ip参数
 * 返回: 0，成功; -1，失败
 */
int getsockname(int sockfd, struct sockaddr *localaddr, socklen_t *addrlen);
int getpeername(int sockfd, struct sockaddr *peeraddr, socklen_t *addrlen);
```

### getsockopt / setsockopt - 获取/设置套接字属性

```c
/*
 * 功能: getsockopt 获取套接字属性
 *       setsockopt 设置套接字属性
 * 返回: 0，成功; -1，失败
 */
int getsockopt(int sockfd, int level, int optname, void *optval, socklen_t *optlen);
int setsockopt(int sockfd, int level, int optname, const void *optval, socklen_t *optlen);
```

### gethostbyname / gethostbyaddr : 查询主机详细信息

```c
/*
 * 功能: gethostbyname 通过主机名查询主机详细信息
 *       gethostbyaddr 通过IP地址值查询主机详细信息
 * 返回: 非空指针，成功; NULL，失败
 * 说明: 1、函数执行失败不会设置errno，而是设置h_errno为 HOST_NOT_FOUND TRY_AGAIN NO_RECOVERY NO_DATA(NO ADDRESS) 中的某个值，可以使用hstrerror获取错误说明。
 * 2、gethostbyname的hostname接受www.google.com类型的主机名，实现一般可以接受点分字符串
 * 3、gethostbyaddr的addr实际不是 char* 类型，而是 in_addr* 结构指针
 * 3、只适用于IPv4，不适用于IPv6，将被弃用
 */
struct hostent
{
    char *h_name;               /* Official name of host */
    char **h_aliases;           /* Alias list */
    int h_addrtype;             /* Host address type */
    int h_length;               /* Length of address */
    char **h_addr_list;         /* List of IPv4 addresses from name server */
#if defined __USE_MISC || defined __USE_GNU
# define h_addr h_addr_list[0]  /* Address, for backward compatibility */
#endif
};
struct hostent *gethostbyname(const char *hostname);
struct hostent *gethostbyaddr(const char *addr, socklen_t len, int family);
```

### getservbyname / getservbyport - 查询服务详细信息

```c
/*
 * 功能: getservbyname 通过服务名查询服务详细信息
 *       getservbyport 通过IP端口值查询服务详细信息
 * 返回: 非空指针，成功; NULL，失败
 * 例子: getservbyname("ftp", "tcp")  getservbyport(htons(21), "tcp")
 */
struct servent
{
  char *s_name;                 /* Official service name */
  char **s_aliases;             /* Alias list */
  int s_port;                   /* Port number */       // 网络字节序
  char *s_proto;                /* Protocol to use */
};
struct servent *getservbyname(const char *servname, const char *protoname);
struct servent *getservbyport(int port, const char *protoname); // port 网络字节序
```

### getaddrinfo - 查询主机和服务详细信息

```c
/*
 * 功能: 查询主机和服务详细信息
 * 返回: 0，成功; 非0，失败(使用gai_strerror获取描述)
 * IN  : hostname   主机名或ip地址字符串
 *       service    服务名或端口号字符串
 *       hints      获取建议选项，可以为空
 * OUT : result     获取结果
 * 说明: 1、适用于IPv4和IPv6
 * 2、需要调用freeaddrinfo释放 *result
 */
struct addrinfo
{
    int ai_flags;               /* Input flags */
    int ai_family;              /* Protocol family for socket */
    int ai_socktype;            /* Socket type */
    int ai_protocol;            /* Protocol for socket */
    socklen_t ai_addrlen;       /* Length of socket address */
    struct sockaddr *ai_addr;   /* Socket address for socket */
    char *ai_canonname;         /* Canonical name for service location */
    struct addrinfo *ai_next;   /* Pointer to next in list */
};
int getaddrinfo(const char *hostname, const char *service,
        const struct addrinfo *hints, struct addrinfo **result);
void freeaddrinfo(getaddrinfo *ai)

/*
 * 功能: 查询主机和服务信息
 * 返回: 0，成功; 非0，失败(使用gai_strerror获取描述)
 * 说明: 将addrinfo转换为可读字符串
 */
int getnameinfo(const struct sockaddr *addrinfo, socklen_t addrlen,
        char *host, socklen_t hostlen, char *serv, socklen_t servlen,
        const struct addrinfo *hints, struct addrinfo **result);
```

## IO多路复用

### select poll epoll 对比

| 接口   | 最大连接  | 操作方式 | 底层实现 | IO效率 | fd拷贝 |
| ---    | ---       | ---      | ---     | ---     | ---    |
| select | 1024(x86) | 遍历     | 数组    | 每次调用都进行线性遍历O(n) | 每次调用select，都需要把fd集合 从用户态拷贝到内核态 |
| poll   | 无上限    | 遍历     | 链表    | 每次调用都进行线性遍历O(n) | 每次调用poll，都需要把fd集合 从用户态拷贝到内核态 |
| epoll  | 无上限    | 回调     | 哈希表  | 事件通知方式，每当fd就绪，注册的回调函数就会被调用，将就绪fd放到rdllist里面O(1) | 调用epoll_ctl时拷贝进内核并保存，之后每次epoll_wait不拷贝 |

### select

```c
/*
 * 功能: 查询文件描述符集合中的fd就绪状态
 * 返回: >0，就绪描述符数目; 0, 超时; -1，出错(例如EINTR)
 * IN  : maxfdp1    描述符集合中值最大的描述符值加1
 * INOUT:readfds/writefds/exceptfds    监控需要 读取/写入/异常 的文件描述符集合，设为NULL表示不关心
 * IN  : timeout    超时时间: NULL，知道有fd就绪才返回； 值为0， 查询后立即返回； 值大于0，有fd就绪返回或超时返回timeval 为 tv_sec + tv_usec
 * 说明: 1、调用select时，我们将关心的fd加入fd_set，select返回时，结果将指示哪些描述符已经就绪
 * 2、select会修改fdset，所以每次select调用前都要清空集合再将fd加入集合
 * 3、select每次调用查询前都要把fd_set从应用复制到内核，查询完后都要把fd_set从内核复制到应用
 * 4、select支持的fd数目有限，最大 FD_SETSIZE，例如 1024(x86) 2048(x64)
 * 5、监听套接字可读表示有客户端接入，这时可以调用accept
 * 6、当某个套接字上发生错误时，fd既可读又可写
 * 7、监控异常例如TCP带外数据
 */
 #include <sys/select.h>
void FD_ZERO(fd_set *fdset);            // 清空文件描述符集合
void FD_SET(int fd, fd_set *fdset);     // fd加入文件描述符集合
void FD_CLR(int fd, fd_set *fdset);     // fd离开文件描述符集合
void FD_ISSET(int fd, fd_set *fdset);   // select()后测试fd是否就绪
int select(int maxfdp1, fd_set *readfds,　fd_set *writefds, fd_set *exceptfds,
        const struct timeval *timeout);
```

### poll

```c
/*
 * 功能: 查询文件描述符集合中的fd就绪状态
 * 返回: >0，就绪描述符数目; 0, 超时; -1，出错(例如EINTR)
 * INOUT:fds        监控fd描述符的数组
 * IN  : nfds       监控fd的数目
 * IN  : timeout    超时时间: INFTIM ，永远等待; 0 ，立即返回; >0 ， 等待毫秒数
 * 说明: 可读项和可写项可以作为events的输入，可读项、可写项和异常项可以作为revents的输出
 * 可读项: POLLIN       普通或优先级带数据可读
 *         POLLRDNORM   普通数据可读
 *         POLLRDBAND   优先级带数据可读
 *         POLLPRI      高优先级数据可读
 * 可写项: POLLOUT      普通数据可写
 *         POLLRDNORM   普通数据可写
 *         POLLRDBAND   优先级带数据可写
 * 异常项：POLLERR      发生错误
 *         POLLHUP      发生挂起
 *         POLLRDBAND   描述符不是一个打开的文件
 * 说明: 调用poll函数之后fds数组不会被清空
 */
#include <poll.h>

struct pollfd {
    int fd;             /* 需要被检测或选择的文件描述符 负值表示不关心 */
    short events;       /* 对文件描述符fd上感兴趣的事件，用户调用前设置这个域*/
    short revents;      /* 文件描述符fd上当前实际发生的事件，内核在调用返回时设置这个域 */
}
int poll(struct pollfd *fds, nfds_t nfds, int timeout);
```

### epoll

* epoll是linux专有函数

#### epoll_create - 创建epoll文件描述符

```c
/*
 * 功能: 创建epoll文件描述符
 * 返回: >=0，epoll文件描述符; -1，失败
 * IN  : size       监听文件描述符的数目，Linux 2.6.8后已废弃，但必须大于0
 * 说明: 可以使用close关闭epoll文件描述符
 */
#include <sys/epoll.h>
int epoll_create(int size);
```

#### epoll_ctl - 控制操作的文件描述符

 * epoll对文件描述符的操作有两种模式：LT(level trigger)和ET(edge trigger)。
    * LT模式：当epoll_wait检测到描述符事件发生并将此事件通知应用程序，应用程序可以不立即处理该事件。下次调用epoll_wait时，会再次响应应用程序并通知此事件。
    * ET模式：当epoll_wait检测到描述符事件发生并将此事件通知应用程序，应用程序必须立即处理该事件。如果不处理，下次调用epoll_wait时，不会再次响应应用程序并通知此事件。
        * ET模式在很大程度上减少了epoll事件被重复触发的次数，因此效率要比LT模式高。
        * epoll工作在ET模式的时候，必须使用非阻塞套接口，以避免由于一个文件句柄的阻塞读/阻塞写操作把处理多个文件描述符的任务饿死。
        * 如果一直不对这个fd作IO操作(从而导致它再次变成未就绪)，内核就不会发送更多的通知(only once)

```c
/*
 * 功能: 控制操作的文件描述符
 * 返回: 0，成功; -1，失败
 * IN  : epfd       epoll文件描述符
 * IN  : op         进行的操作
 *      EPOLL_CTL_ADD 注册新的fd到epfd中
 *      EPOLL_CTL_MOD 修改已经注册的fd的监听事件
 *      EPOLL_CTL_DEL 从epfd中删除一个fd
 * IN  : fd         要操作的文件描述符
 * IN  : event      位掩码
 *      EPOLLIN         可以读(包括对端SOCKET正常关闭)
 *      EPOLLOUT        可以写
 *      EPOLLPRI        有紧急的数据可读(这里应该表示有带外数据到来)
 *      EPOLLERR        发生错误
 *      EPOLLHUP        发生挂起
 *      EPOLLET         将epoll设为边缘触发(Edge Triggered)模式
 *      EPOLLONESHOT    只监听一次事件，监听到后就把该文件描述符从epfd
 */
#include <sys/epoll.h>
typedef union epoll_data {
    void        *ptr;
    int          fd;
    uint32_t     u32;
    uint64_t     u64;
} epoll_data_t;

struct epoll_event {
    uint32_t     events;      /* Epoll events */
    epoll_data_t data;        /* User data variable */
};
int epoll_ctl(int epfd, int op, int fd, struct epoll_event *event);
```

#### epoll_wait - 阻塞等待内核返回的可读写事件

```c
/*
 * 功能: 阻塞等待内核返回的可读写事件
 * 返回: >0，就绪描述符数目; 0, 超时; -1，出错(例如EINTR)
 * IN  : epfd       epoll文件描述符
 * INOUT:events     监控事件的数组
 * IN  : nfds       监控事件的数目，必须大于0
 * IN  : timeout    超时时间: -1 ，永远等待; 0 ，立即返回; >0 ， 等待毫秒数
 */
#include <sys/epoll.h>
int epoll_wait(int epfd, struct epoll_event *events, int maxevents, int timeout);
```

## socket举例

```c
/******************** socket 接口层 ********************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>
#include <time.h>
#include <errno.h>
#include <sys/types.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <fcntl.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <netinet/tcp.h>

#include <sys/select.h>
#include <poll.h>
#include <sys/epoll.h>

/**** printf debug ****/
#define PRINTF_LEVEL_CLOSE          0
#define PRINTF_LEVEL_ERRNO          1
#define PRINTF_LEVEL_ERROR          2
#define PRINTF_LEVEL_INFO           3
#define PRINTF_LEVEL_WARN           4
#define PRINTF_LEVEL_DEBUG          5

static int s_sock_printf_level = PRINTF_LEVEL_INFO;
const char *_printf_level_str(int level)
{
    static const char *level_buf[] = {
        "\033[31mERRNO\033[0m",
        "\033[31mERROR\033[0m",
        "\033[32mINFO\033[0m",
        "\033[33mWARN\033[0m",
        "\033[34mDEBUG\033[0m"
    };

    if (level > PRINTF_LEVEL_DEBUG)
        level = PRINTF_LEVEL_DEBUG;
    else if (level < PRINTF_LEVEL_ERRNO)
        level = PRINTF_LEVEL_ERRNO;

    return level_buf[level-1];
}

#define COMMON_SPRINTF(level, limit, fmt, args...)  do {                        \
    if (level > limit) break;                                                   \
    printf(fmt, ##args);                                                        \
} while (0)

#define COMMON_PRINTF(level, limit, fmt, args...)  do {                         \
    if (level > limit) break;                                                   \
    printf("[%s|%s:%d] ", _printf_level_str(level), __func__, __LINE__);        \
    if (level == PRINTF_LEVEL_ERRNO) printf("[%d:%s] ", errno, strerror(errno));\
    printf(fmt, ##args);                                                        \
} while (0)

#define SOCK_ERRNO(fmt, args...)    COMMON_PRINTF (PRINTF_LEVEL_ERRNO, s_sock_printf_level, fmt, ##args)
#define SOCK_ERROR(fmt, args...)    COMMON_PRINTF (PRINTF_LEVEL_ERROR, s_sock_printf_level, fmt, ##args)
#define SOCK_SINFO(fmt, args...)    COMMON_SPRINTF(PRINTF_LEVEL_INFO,  s_sock_printf_level, fmt, ##args)
#define SOCK_INFO(fmt, args...)     COMMON_PRINTF (PRINTF_LEVEL_INFO,  s_sock_printf_level, fmt, ##args)
#define SOCK_SDBG(fmt, args...)     COMMON_SPRINTF(PRINTF_LEVEL_DEBUG, s_sock_printf_level, fmt, ##args)
#define SOCK_DBG(fmt, args...)      COMMON_PRINTF (PRINTF_LEVEL_DEBUG, s_sock_printf_level, fmt, ##args)

#define SOCK4_ADDR_LEN              32

/* 设置了O_NONBLOCK(非阻塞模式)，读取不到数据时会立即返回-1，并且设置errno为EAGAIN */
int sockfd_nonblock_set(int sockfd)
{
    int flags = fcntl(sockfd, F_GETFL, 0);
    return fcntl(sockfd, F_SETFL, flags | O_NONBLOCK);
}

/* connect/send 的超时设置 */
int send_timeout_set(int sockfd, time_t sec, long usec)
{
    struct timeval timeout;

    timeout.tv_sec = sec;
    timeout.tv_usec = usec;
    if (setsockopt(sockfd, SOL_SOCKET, SO_SNDTIMEO, &timeout, sizeof(timeout)) < 0) {
        SOCK_ERRNO("fd=%d\n", sockfd);
        return -1;
    }

    return 0;
}

/* accept/recv 的超时设置 */
int recv_timeout_set(int sockfd, time_t sec, long usec)
{
    struct timeval timeout;

    timeout.tv_sec = sec;
    timeout.tv_usec = usec;
    if (setsockopt(sockfd, SOL_SOCKET, SO_RCVTIMEO, &timeout, sizeof(timeout)) < 0) {
        SOCK_ERRNO("fd=%d\n", sockfd);
        return -1;
    }

    return 0;
}

/*
 * SO_REUSEADDR 功能:
 * 1. 重启服务时，即使以前建立的相同本地端口的连接仍存在(TIME_WAIT)，bind也不出错
 * 2、允许bind相同的端口，只要ip不同即可
 * 3、允许udp多播绑定相同的端口和ip
 * TIME_WAIT状态存在的理由:
 * 1. 可靠地实现TCP全双工连接的终止
 * 2. 允许老的重复分节在网络中消逝
 */
int sock_reuse_addr_set(int sockfd)
{
    int optval = 1;

    if (setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR, &optval, sizeof(optval)) < 0) {
        SOCK_ERRNO("fd=%d\n", sockfd);
        return -1;
    }

    return 0;
}

/* TCP主动关闭的一方资源会延时释放，设置so_linger，主动关闭会立即释放资源
 * socket或accept后调用，正常关闭时主动关闭的这端有2MSL状态
 * // l_linger, "posix: The unit is 1 sec"; "bsd: The unit is 1 tick(10ms)"
 * l_onoff  l_linger  closesocket行为         发送队列          超时行为
 *   0         /      立即返回                保持直到发送完成  系统接管套接字并保证将数据发送到对端
 *   1         0      立即返回                直接丢弃          直接发送RST包，自身立即复位，跳过TIMEWAIT, 不用经过2MSL状态，对端收到RST错误
 *                                                              (Linux上只有可能只有在丢弃数据时才发送RST)
 *   1         >0     阻塞直到发送完成或超时  超时内超时发送    超时内发送成功正常关闭(FIN-ACK-FIN-ACK四次握手关闭)
 *                    (sockfd需要设置为阻塞)  超时后直接丢弃    超时后同RST, 错误号 EWOULDBLOCK
 */
int tcp_no_linger_set(int sockfd)
{
    struct linger so_linger;

    so_linger.l_onoff = 1;
    so_linger.l_linger = 0;
    if (setsockopt(sockfd, SOL_SOCKET, SO_LINGER, &so_linger, sizeof(so_linger)) < 0) {
        SOCK_ERRNO("fd=%d\n", sockfd);
        return -1;
    }

    return 0;
}

/* 启动TCP_NODELAY，就意味着禁用了Nagle算法，允许小包立即发送 */
int tcp_no_delay_set(int sockfd)
{
    int optval = 1;

    if (setsockopt(sockfd, IPPROTO_TCP, TCP_NODELAY, &optval, sizeof(optval)) < 0) {
        SOCK_ERRNO("fd=%d\n", sockfd);
        return -1;
    }

    return 0;
}

/*
 * 判断TCP连接对端是否断开的方法有以下几种:
 * 1、select()测试到sockfd可读，但read/recv读取返回的长度为0，并且(errno != EINTR)，对端TCP连接已经断开
 * 2、向对方write/send发送数据，返回-1，并且(errno != EAGAIN || errno != EINTR)
 * 3、判断TCP的状态，如函数tcp_connected_check
 * 4、启用TCP心跳检测
 * 5、使用自定义超时检测，一段时间没有数据交互就关闭，tcp_heart_beat_set
 */
int tcp_connected_check(int sockfd)
{
    int flag = -1;
    struct tcp_info info;
    socklen_t len = sizeof(info);

    memset(&info, 0, sizeof(info));
    getsockopt(sockfd, IPPROTO_TCP, TCP_INFO, &info, (socklen_t *)&len);
    flag = (info.tcpi_state == TCP_ESTABLISHED) ? 0 : -1;

    return flag;
}

/*
 * 启用TCP心跳检测，设置后，若断开，则在使用该socket读写时立即失败，并返回ETIMEDOUT错误
 * keep_idle: 如该连接在keep_idle秒内没有任何数据往来,则进行探测
 * keep_interval: 探测时发包的时间间隔为keep_interval秒
 * keep_count: 探测尝试的次数keep_count(如果第1次探测包就收到响应了,则后2次的不再发)
 */

int tcp_heart_beat_set(int sockfd, int keep_idle, int keep_interval, int keep_count)
{
    int keep_alive = 1; // 开启keepalive属性
    setsockopt(sockfd, SOL_SOCKET, SO_KEEPALIVE, (void *)&keep_alive, sizeof(int));
    setsockopt(sockfd, SOL_TCP, TCP_KEEPIDLE, (void *)&keep_idle, sizeof(int));
    setsockopt(sockfd, SOL_TCP, TCP_KEEPINTVL, (void *)&keep_interval, sizeof(int));
    setsockopt(sockfd, SOL_TCP, TCP_KEEPCNT, (void *)&keep_count, sizeof(int));
    return 0;
}

/* UDP加入某个广播组，之后就可以向这个广播组发 // 加入广播组送数据或者从广播组接收数据 */
int sock4_add_udp_multicast(int sockfd, const char *addr)
{
    int optval = 1;
    struct ip_mreq mreq;

    if (setsockopt(sockfd, SOL_SOCKET, SO_BROADCAST, &optval, sizeof(optval)) < 0) { // 允许发送广播
        SOCK_ERRNO("fd=%d, addr=%s\n", sockfd, addr);
        return -1;
    }

    mreq.imr_interface.s_addr = htonl(INADDR_ANY);  // INADDR_ANY=0, 本机任意网卡IP地址
    if (inet_pton(AF_INET, addr, &mreq.imr_multiaddr.s_addr) <= 0) { // 广播组IP地址
        SOCK_ERRNO("fd=%d, addr=%s\n", sockfd, addr);
        return -1;
    }
    if (setsockopt(sockfd, IPPROTO_IP, IP_ADD_MEMBERSHIP, &mreq, sizeof(mreq)) < 0) { // 加入广播组
        SOCK_ERRNO("fd=%d, addr=%s\n", sockfd, addr);
        return -1;
    }

    return 0;
}

/* 从 addr + port 填写sockaddr_in结构*/
int sock4_addr_fill(struct sockaddr_in *serv, const char *addr, unsigned short port)
{
    memset(serv, 0, sizeof(struct sockaddr_in));
    serv->sin_family = AF_INET;
    serv->sin_port = htons(port);
    if (!addr || strlen(addr) == 0|| (strlen(addr) == 1 && *addr == '0')) {
        serv->sin_addr.s_addr = htonl(INADDR_ANY);
    } else {
        if (inet_pton(AF_INET, addr, &serv->sin_addr) <= 0) {
            SOCK_ERRNO("addr=%s, port=%d\n", addr, port);
            return -1;
        }
    }

    return 0;
}

int sock4_addr_get(int sockfd, char *addr, unsigned short *port)
{
    struct sockaddr_in serv;
    socklen_t len = sizeof(struct sockaddr_in);

    if (getsockname(sockfd, (struct sockaddr *)&serv, &len)) {
        SOCK_ERRNO("\n");
        return -1;
    }
    if (addr) {
        inet_ntop(AF_INET, &serv.sin_addr, addr, SOCK4_ADDR_LEN);
    }
    if (port) {
        *port = ntohs(serv.sin_port);
    }

    return 0;
}

int sock4_addr_parse(struct sockaddr_in *serv, char *addr, unsigned short *port)
{
    if (addr) {
        // strcpy(addr, inet_ntoa(serv->sin_addr));
        inet_ntop(AF_INET, &serv->sin_addr, addr, SOCK4_ADDR_LEN);
    }
    if (port)
        *port = ntohs(serv->sin_port);

    return 0;
}

int sock4_tcp_listen_create(const char *addr, unsigned short port, int listen_num)
{
    int sockfd;
    struct sockaddr_in serv;

    if (sock4_addr_fill(&serv, addr, port) < 0) {
        SOCK_ERROR("\n");
        return -1;
    }
    if (!addr) addr = "0"; // 防止打印的时候addr为空
    if ((sockfd = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
        SOCK_ERRNO("addr=%s, port=%d\n", addr, port);
        return -1;
    }

    if (sock_reuse_addr_set(sockfd) < 0) {
        SOCK_ERROR("\n");
        goto err;
    }
    send_timeout_set(sockfd, 5, 0);
    recv_timeout_set(sockfd, 5, 0);

    if (bind(sockfd, (struct sockaddr *)&serv, sizeof(serv)) < 0) {
        SOCK_ERRNO("addr=%s, port=%d\n", addr, port);
        goto err;
    }
    if (listen(sockfd, listen_num) < 0) {
        SOCK_ERRNO("addr=%s, port=%d, listen_num=%d\n", addr, port, listen_num);
        goto err;
    }

    SOCK_INFO("TCP %d listen on %s:%d\n", sockfd, inet_ntoa(serv.sin_addr), ntohs(serv.sin_port));
    return sockfd;
err:
    close(sockfd);
    return -1;
}

int sock4_tcp_accept(int listen_fd, char *daddr, unsigned short *dport)
{
    int sockfd;
    struct sockaddr_in serv;
    socklen_t len = sizeof(struct sockaddr_in);

    if ((sockfd = accept(listen_fd, (struct sockaddr *)&serv, (socklen_t *)&len)) < 0) {
        SOCK_ERRNO("listen_fd=%d\n", listen_fd);
        return -1;
    }
    send_timeout_set(sockfd, 1, 100000);
    recv_timeout_set(sockfd, 1, 100000);
    sock4_addr_parse(&serv, daddr, dport);

    SOCK_INFO("TCP %d accept %s:%d on %d\n", sockfd, inet_ntoa(serv.sin_addr), ntohs(serv.sin_port), listen_fd);
    return sockfd;
}

int sock4_udp_bind_create(const char *addr, unsigned short port)
{
    int sockfd;
    struct sockaddr_in serv;

    if (sock4_addr_fill(&serv, addr, port) < 0) {
        SOCK_ERROR("\n");
        return -1;
    }
    if (!addr) addr = "0"; // 防止打印的时候addr为空
    if ((sockfd = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)) < 0) {
        SOCK_ERRNO("addr=%s, port=%d\n", addr, port);
        return -1;
    }

    // ipv4 D类地址(224.0.0.0-239.255.255.255)为多播地址
    if (addr && atoi(addr) >= 224) {
        if (sock4_add_udp_multicast(sockfd, addr) < 0) {
            SOCK_ERROR("\n");
            goto err;
        }
        // 嵌入式 bsd_tcpip 库不能直接绑定多播地址, 需要把ip地址变为0
        // linux 不必做这一步，并且不做更好
        serv.sin_addr.s_addr = htonl(INADDR_ANY);
    }

    if (sock_reuse_addr_set(sockfd) < 0) {
        SOCK_ERROR("\n");
        goto err;
    }
    send_timeout_set(sockfd, 1, 100000);
    send_timeout_set(sockfd, 1, 100000);

    if (bind(sockfd, (struct sockaddr *)&serv, sizeof(serv)) < 0) {
        SOCK_ERRNO("addr=%s, port=%d\n", addr, port);
        goto err;
    }

    SOCK_INFO("UDP %d bind on %s:%d\n", sockfd, inet_ntoa(serv.sin_addr), ntohs(serv.sin_port));
    return sockfd;
err:
    close(sockfd);
    return -1;
}

static int sock4_tcp_connect_create_base(const char *src, unsigned short sport,
    const char *dst, unsigned short dport, struct sockaddr_in *dserv)
{
    int sockfd;
    struct sockaddr_in temp;

    if (!dserv) dserv = &temp;
    if ((sock4_addr_fill(dserv, dst, dport)) < 0) {
        SOCK_ERROR("\n");
        return -1;
    }

    if ((sockfd = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
        SOCK_ERRNO("\n");
        return -1;
    }

    if ((src && src[0]) || sport) {
        struct sockaddr_in serv;

        if (sock4_addr_fill(&serv, src, sport) < 0) {
            SOCK_ERROR("\n");
            goto err;
        }
        if (!src) src = "0"; // 防止打印的时候addr为空
        if (sock_reuse_addr_set(sockfd) < 0) {
            SOCK_ERROR("\n");
            goto err;
        }
        if (bind(sockfd, (struct sockaddr *)&serv, sizeof(serv)) < 0) {
            SOCK_ERRNO("addr=%s, port=%d\n", src, sport);
            goto err;
        }
    }

    send_timeout_set(sockfd, 5, 0);
    if (connect(sockfd, (struct sockaddr *)dserv, sizeof(struct sockaddr_in)) < 0) {
        SOCK_ERRNO("\n");
        goto err;
    }
    send_timeout_set(sockfd, 1, 100000);
    recv_timeout_set(sockfd, 1, 100000);

    SOCK_INFO("TCP %d connect to %s:%d\n", sockfd, inet_ntoa(dserv->sin_addr), ntohs(dserv->sin_port));
    return sockfd;
err:
    close(sockfd);
    return -1;
}

int sock4_tcp_bind_connect_create(const char *src, unsigned short sport,
    const char *dst, unsigned short dport, struct sockaddr_in *dserv)
{
    return sock4_tcp_connect_create_base(src, sport, dst, dport, dserv);
}

int sock4_tcp_connect_create(const char *dst, unsigned short dport, struct sockaddr_in *dserv)
{
    return sock4_tcp_connect_create_base(NULL, 0, dst, dport, dserv);
}

static int sock4_udp_connect_create_base(const char *src, unsigned short sport,
    const char *dst, unsigned short dport, struct sockaddr_in *dserv)
{
    int sockfd;
    struct sockaddr_in temp;

    if (!dserv) dserv = &temp;
    if ((sock4_addr_fill(dserv, dst, dport)) < 0) {
        SOCK_ERROR("\n");
        return -1;
    }

    if ((src && src[0]) || sport) {
        if ((sockfd = sock4_udp_bind_create(src, sport)) < 0) {
            SOCK_ERROR("\n");
            return -1;
        }
    } else {
        if ((sockfd = socket(AF_INET, SOCK_DGRAM, 0)) < 0) {
            SOCK_ERRNO("\n");
            return -1;
        }
    }

    send_timeout_set(sockfd, 5, 0);
    if (connect(sockfd, (struct sockaddr *)dserv, sizeof(*dserv)) < 0) {
        SOCK_ERRNO("\n");
        goto err;
    }
    send_timeout_set(sockfd, 1, 100000);
    send_timeout_set(sockfd, 1, 100000);

    SOCK_INFO("UDP %d connect to %s:%d\n", sockfd, inet_ntoa(dserv->sin_addr), ntohs(dserv->sin_port));
    return sockfd;
err:
    close(sockfd);
    return -1;
}

int sock4_udp_bind_connect_create(const char *src, unsigned short sport,
    const char *dst, unsigned short dport, struct sockaddr_in *dserv)
{
    return sock4_udp_connect_create_base(src, sport, dst, dport, dserv);
}

int sock4_udp_connect_create(const char *dst, unsigned short dport, struct sockaddr_in *dserv)
{
    return sock4_udp_connect_create_base(NULL, 0, dst, dport, dserv);
}

ssize_t sock_send(int sockfd, const void *buf, ssize_t blen)
{
    ssize_t size = 0;

    size = send(sockfd, buf, blen, 0);
    //size = send(sockfd, buf, blen, MSG_NOSIGNAL); // MSG_NOSIGNAL: 对端已经关闭再写，不产生SIGPIPE信号
    if (size != blen) {
        if (size < 0 && (errno == EAGAIN || errno == EINTR || errno == ETIMEDOUT))
            return 0;
        SOCK_ERRNO("%lu!=%lu, send(%d) failed!\n", blen, size, sockfd);
    }

    return size;
}

ssize_t sock_recv(int sockfd, void *buf, size_t blen)
{
    ssize_t size = 0;

    size = recv(sockfd, buf, blen, 0);
    if (size < 0) {
        SOCK_ERRNO("recv(%d) failed!\n", sockfd);
    }

    return size;
}

ssize_t sock4_sendto(int sockfd, const void *buf, ssize_t blen, const struct sockaddr_in *serv)
{
    ssize_t size = 0;
    socklen_t slen = sizeof(struct sockaddr_in);

    size = sendto(sockfd, buf, blen, 0, (const struct sockaddr *)serv, slen);
    // size = sendto(sockfd, buf, blen, MSG_NOSIGNAL, (const struct sockaddr *)serv, slen);
    if (size != blen) {
        SOCK_ERRNO("%lu!=%lu, sendto(%d) failed!\n", blen, size, sockfd);
    }

    return size;
}

ssize_t sock4_recvfrom(int sockfd, void *buf, size_t blen, struct sockaddr_in *serv)
{
    ssize_t size = 0;
    socklen_t slen = sizeof(struct sockaddr_in);

    size = recvfrom(sockfd, buf, blen, 0, (struct sockaddr *)serv, &slen);
    if (size < 0) {
        SOCK_ERRNO("recvfrom(%d) failed!\n", sockfd);
    }

    return size;
}

/******************** http文件服务器 ********************/

#define MAX_CLIENTS     10
#define MAX_DATA_LEN    1316
#define ADDR_LEN        32
#define FD_CLOSE(fd) do { if (fd >= 0) close(fd); fd = -1; } while (0)
#define FP_CLOSE(fp) do { if (fp) fclose(fp); fp = 0; } while (0)
#define MEM_FREE(ptr) do { if (ptr > 0) free(ptr); ptr = 0; } while (0)

typedef struct {
    int sockfd;
    FILE *filefp;
    int flag; // 0xffff cricle play
    int len;
    int sel;
} ClientParam;

typedef struct {
    char req[32];
    char url[512];
    char type[32];
} ReqLine;

static void client_param_release(ClientParam *arg)
{
    FD_CLOSE(arg->sockfd);
    FP_CLOSE(arg->filefp);
    arg->flag = 0;
    arg->len = 0;
    arg->sel = 0;
}

static int request_analysis(char *buf, ReqLine *line)
{
    int len = 0, len1 = 0, len2 = 0;
    char *temp = NULL;

    memset(line, 0, sizeof(ReqLine));
    if ((temp = strstr(buf, " ")) == NULL) {
        SOCK_ERROR("\n");
        return -1;
    }
    len1 = sizeof(line->req)-1;
    len2 = temp-buf;
    len = (len1 < len2) ? len1 : len2;
    memcpy(line->req, buf, len);

    buf = temp + 1;
    if ((temp = strstr(buf, " ")) == NULL) {
        SOCK_ERROR("\n");
        return -1;
    }
    len1 = sizeof(line->url)-1;
    len2 = temp-buf;
    len = (len1 < len2) ? len1 : len2;
    memcpy(line->url, buf, len);

    buf = temp + 1;
    if ((temp = strstr(buf, "\r\n")) == NULL) {
        SOCK_ERROR("\n");
        return -1;
    }
    len1 = sizeof(line->type)-1;
    len2 = temp-buf;
    len = (len1 < len2) ? len1 : len2;
    memcpy(line->type, buf, len);

    SOCK_DBG("req = %s, url = %s, type = %s\n", line->req, line->url, line->type);
    return 0;
}

const char *gmt_date_str_get(void)
{
    static char date_str[32];
    time_t s = 0;
    struct tm *t;

    s = time(NULL);
    t = gmtime(&s);
    if (!t)
        return "Wed,  1 May 2019 00:00:00 GMT";
    if (!strftime(date_str, sizeof(date_str), "%a, %e %b %Y %H:%M:%S GMT", t))
        return "Wed,  1 May 2019 00:00:00 GMT";

    return date_str;
}

static int strrncasecmp(const char *s1, const char *s2, size_t size)
{
    int len1 = strlen(s1) - size;
    int len2 = strlen(s2) - size;

    if (len1 < 0 || len2 < 0)
        return -1;
    else
        return strncasecmp(s1+len1, s2+len2, size);
}

static int stream_read(ClientParam *arg)
{
    const char *error_reply  = "HTTP/1.1 404 Not Found\r\nDate: %s\r\nConnection: close\r\n\r\n";
    const char *head_reply   = "HTTP/1.1 200 OK\r\nDate: %s\r\nContent-Type: %s\r\nConnection: close\r\n\r\n";
    const char *getok_reply  = "HTTP/1.1 200 OK\r\nDate: %s\r\nContent-Type: %s\r\nContent-Length: %d\r\nConnection: close\r\n\r\n";
    const char *circle_reply = "HTTP/1.1 200 OK\r\nDate: %s\r\nCache-Control: no-cache\r\nContent-Type: %s\r\nExpires: -1\r\nPragma: no-cache\r\n\r\n";

    const char *audio_suffixs[] = {".mp3", ".wma", ".aac", ".m4a", ".wav", ".flac", ".ape", ".agg", NULL };
    const char *video_suffixs[] = {".mp4", ".wmv", ".mkv", ".avi", ".ts", ".mpg", ".flv", ".dat", ".vob", ".mov", ".m2ts", NULL};

    int i = 0;
    int rlen;
    int wlen;
    char rbuf[2000] = {0};
    char wbuf[2000] = {0};
    ReqLine line;
    const char *path = NULL;
    const char *ctype = NULL;
    int clen;

    if ((rlen = sock_recv(arg->sockfd, rbuf, sizeof(rbuf)-1)) <= 0) {
        if (errno != EINTR) {
            SOCK_ERROR("sock_recv failed!\n");
            client_param_release(arg);
            return -1;
        } else {
            return 0;
        }
    }
    SOCK_DBG("[recv] size=%d\n%s\n", rlen, rbuf);
    if (request_analysis(rbuf, &line) < 0) {
        return 0;
    }
    SOCK_INFO("[recv] %s %s\n", line.req, line.url);

    if (strncmp(line.url, "/c/", 3) == 0) {
        arg->flag = 0xffff;
        path = line.url + 7;
    } else if (strncmp(line.url, "/t/", 3) == 0) {
        arg->flag = 0xfffe;
        path = line.url + 6;
        clen = atoi(path);
        ctype = "text/plain";
        arg->len = clen;
        arg->sel = 0;
    }
    else { arg->flag = 0;
        path = line.url;
    }

    if (!ctype) {
        i = 0;
        while (audio_suffixs[i]) {
            if (strrncasecmp(path, audio_suffixs[i], strlen(audio_suffixs[i])) == 0) {
                ctype = "audio/mp3";
                break;
            }
            i++;
        }
    }
    if (!ctype) {
        i = 0;
        while (video_suffixs[i]) {
            if (strrncasecmp(path, video_suffixs[i], strlen(video_suffixs[i])) == 0) {
                ctype = "video/mpeg";
                break;
            }
            i++;
        }
    }
    if (!ctype) {
        ctype = "text/plain";
    }

    if (strncmp(line.req, "HEAD", 4) == 0) {
        snprintf(wbuf, sizeof(wbuf), head_reply, gmt_date_str_get(), ctype);
        wlen = strlen(wbuf);
        sock_send(arg->sockfd, wbuf, wlen);
        return 0;
    }
    if (strncmp(line.req, "GET", 3) == 0) {
        FP_CLOSE(arg->filefp);
        if (arg->flag == 0xfffe) {
            snprintf(wbuf, sizeof(wbuf), getok_reply, gmt_date_str_get(), ctype, clen);
        } else {
            if ((arg->filefp = fopen(path, "r")) == NULL) {
                SOCK_ERROR("fopen(%s) failed!\n", path);
                goto err;
            }

            if (arg->flag == 0xffff) {
                snprintf(wbuf, sizeof(wbuf), circle_reply, gmt_date_str_get(), ctype);
            } else {
                fseek(arg->filefp, 0, SEEK_END);
                clen = ftell(arg->filefp);
                fseek(arg->filefp, 0, SEEK_SET);
                snprintf(wbuf, sizeof(wbuf), getok_reply, gmt_date_str_get(), ctype, clen);
            }
        }
        SOCK_INFO("[send] GET response\n%s\n", wbuf);
        wlen = strlen(wbuf);
        sock_send(arg->sockfd, wbuf, wlen);
        return 0;
    } else {
        SOCK_ERROR("method (%s) not supported!\n", line.req);
        goto err;
    }

err:
    snprintf(wbuf, sizeof(wbuf), error_reply, gmt_date_str_get());
    wlen = strlen(wbuf);
    sock_send(arg->sockfd, wbuf, wlen);
    client_param_release(arg);
    return -1;
}

static int stream_write(ClientParam *arg)
{
    int len, size;
    char buf[MAX_DATA_LEN] = {0};

    if (arg->flag == 0xfffe) {
        len = arg->len - arg->sel;
        if (len > MAX_DATA_LEN)
            len = MAX_DATA_LEN;
        memset(buf, 'a', MAX_DATA_LEN);
    } else {
        len = fread(buf, 1, MAX_DATA_LEN, arg->filefp);
    }

    if (len < 0) {
        SOCK_ERROR("fread() failed!\n");
        goto err;
    } else if (len == 0) {
        SOCK_INFO("fread() end!\n");
        if (arg->flag == 0xffff) {
            fseek(arg->filefp, 0, SEEK_SET);
        } else {
            client_param_release(arg);
        }
        return 0;
    } else {
        size = sock_send(arg->sockfd, buf, len);

        if (arg->flag == 0xfffe) {
            if (size < 0) {
                SOCK_ERROR("send() failed!\n");
                goto err;
            }
            arg->sel += size;
        } else {
            if (size < 0) {
                SOCK_ERROR("send() failed!\n");
                goto err;
            }
            else if (size < len) {
                fseek(arg->filefp, size-len, SEEK_CUR);
            }
        }
        return 0;
    }

err:
    client_param_release(arg);
    return -1;
}

static int stream_accept(int listen_fd, ClientParam *arg)
{
    int sockfd;
    uint16_t port;
    char addr[ADDR_LEN] = {0};

    if ((sockfd = sock4_tcp_accept(listen_fd, addr, &port)) < 0) {
        SOCK_ERROR("\n");
        return -1;
    }

    arg->sockfd = sockfd;
    if (stream_read(arg) < 0 || (arg->filefp == 0 && arg->len == 0)) {
        client_param_release(arg);
        return -1;
    }

    return 0;
}

void do_select(int listen_fd)
{
    int i;
    int maxfd = 0;
    ClientParam param[MAX_CLIENTS];

    int result;
    fd_set rd_fds, wr_fds;
    struct timeval timeout;

    for (i = 0; i < MAX_CLIENTS; i++) {
        param[i].sockfd = -1;
        param[i].filefp = 0;
        param[i].flag = 0;
        param[i].len = 0;
        param[i].sel = 0;
    }

    while (1) {
        maxfd = listen_fd;
        FD_ZERO(&rd_fds);
        FD_SET(listen_fd, &rd_fds);
        FD_ZERO(&wr_fds);
        for (i = 0; i < MAX_CLIENTS; i++) {
            if (param[i].sockfd >= 0) {
                maxfd = (maxfd > param[i].sockfd) ? maxfd : param[i].sockfd;
                FD_SET(param[i].sockfd, &rd_fds);
                FD_SET(param[i].sockfd, &wr_fds);
            }
        }
        timeout.tv_sec = 2;
        timeout.tv_usec = 100000;
        result = select(maxfd + 1, &rd_fds, &wr_fds, 0, &timeout);
        if (result <= 0)
            continue;

        for (i = 0; i < MAX_CLIENTS; i++) {
            if (param[i].sockfd >= 0 && FD_ISSET(param[i].sockfd, &rd_fds)) {
                stream_read(&param[i]);
            }
        }
        for (i = 0; i < MAX_CLIENTS; i++) {
            if (param[i].sockfd >= 0 && FD_ISSET(param[i].sockfd, &wr_fds)) {
                stream_write(&param[i]);
            }
        }

        if (FD_ISSET(listen_fd, &rd_fds)) {
            int sel = -1;
            for (i = 0; i < MAX_CLIENTS; i++) {
                if (param[i].sockfd < 0) {
                    sel = i;
                    break;
                }
            }
            if (sel >= 0) {
                stream_accept(listen_fd, &param[i]);
            } else {
                SOCK_ERROR("NO free client\n");
            }
        }
    }
}

void do_poll(int listen_fd)
{
    int i;
    int nfds = 0;
    ClientParam param[MAX_CLIENTS];
    struct pollfd fds[MAX_CLIENTS + 1];
    int result;

    fds[0].fd = listen_fd;
    fds[0].events = POLLIN;
    nfds = 0;

    for (i = 0; i < MAX_CLIENTS; i++) {
        fds[i+1].fd = -1;
        param[i].sockfd = -1;
        param[i].filefp = 0;
        param[i].flag = 0;
        param[i].len = 0;
        param[i].sel = 0;
    }

    while (1) {
        result = poll(fds, nfds + 1, 2100);
        if (result <= 0)
            continue;

        for (i = 0; i < nfds; i++) {
            if (param[i].sockfd >= 0 && (fds[i+1].revents & POLLIN)) {
                stream_read(&param[i]);
                fds[i+1].fd = param[i].sockfd;
            }
            if (param[i].sockfd >= 0 && (fds[i+1].revents & POLLOUT)) {
                stream_write(&param[i]);
                fds[i+1].fd = param[i].sockfd;
            }
        }

        if (fds[0].revents & POLLIN) {
            int sel = -1;
            for (i = 0; i < MAX_CLIENTS; i++) {
                if (param[i].sockfd < 0) {
                    sel = i;
                    break;
                }
            }
            if (sel >= 0) {
                stream_accept(listen_fd, &param[i]);
                if (param[i].sockfd >= 0) {
                    fds[i+1].fd = param[i].sockfd;
                    fds[i+1].events = POLLIN | POLLOUT;
                    if (nfds < i + 1)
                        nfds = i + 1;
                }
            } else {
                SOCK_ERROR("NO free client\n");
            }
        }
    }
}

void do_epoll(int listen_fd)
{
    int i, j;
    int epfd = -1;
    int accept_flag = 0;
    ClientParam param[MAX_CLIENTS];
    struct epoll_event event;
    struct epoll_event events[MAX_CLIENTS + 1];
    int result;

    epfd = epoll_create(MAX_CLIENTS + 1);
    event.data.fd = listen_fd;
    event.events = EPOLLIN;
    epoll_ctl(epfd, EPOLL_CTL_ADD, listen_fd, &event);

    for (i = 0; i < MAX_CLIENTS; i++) {
        param[i].sockfd = -1;
        param[i].filefp = 0;
        param[i].flag = 0;
        param[i].len = 0;
        param[i].sel = 0;
    }

    while (1) {
        accept_flag = 0;
        result = epoll_wait(epfd, events, MAX_CLIENTS + 1, 2100);
        if (result <= 0)
            continue;

        for (i = 0; i < result; i++) {
            if (events[i].data.fd == listen_fd) {
                if (events[i].events & EPOLLIN) {
                    accept_flag = 1;
                }
            } else {
                for (j = 0; j < MAX_CLIENTS; j++) {
                    if (events[i].data.fd == param[j].sockfd)
                        break;
                }
                if (j != MAX_CLIENTS) {
                    if (param[j].sockfd >= 0 && (events[i].events & EPOLLIN)) {
                        stream_read(&param[j]);
                    }
                    if (param[j].sockfd >= 0 && (events[i].events & EPOLLOUT)) {
                        stream_write(&param[i]);
                    }
                }
                if (j == MAX_CLIENTS || param[j].sockfd < 0) {
                    event.data.fd = events[i].data.fd;
                    event.events = EPOLLIN | EPOLLOUT;
                    epoll_ctl(epfd, EPOLL_CTL_DEL, events[i].data.fd, &event);
                }
            }
        }

        if (accept_flag) {
            int sel = -1;
            for (i = 0; i < MAX_CLIENTS; i++) {
                if (param[i].sockfd < 0) {
                    sel = i;
                    break;
                }
            }
            if (sel >= 0) {
                stream_accept(listen_fd, &param[i]);
                if (param[i].sockfd >= 0) {
                    event.data.fd = param[i].sockfd;
                    event.events = EPOLLIN | EPOLLOUT;
                    epoll_ctl(epfd, EPOLL_CTL_ADD, param[i].sockfd, &event);
                }
            } else {
                SOCK_ERROR("NO free client\n");
            }
        }
    }
    FD_CLOSE(epfd);
}

int main(int argc, char *argv[])
{
    int listen_fd;
    int port = 0;

    if (argc != 4) {
        printf("Usage: %s ip_addr ip_port io_choice\n", argv[0]);
        printf("           io_choice: 0 select; 1 poll; 2 epoll\n");
        return -1;
    }
    if ((port = atoi(argv[2])) == 0) {
        printf("Usage: %s ip_addr ip_port\n", argv[0]);
        return -1;
    }

    if ((listen_fd = sock4_tcp_listen_create(argv[1], port, MAX_CLIENTS)) < 0) {
        SOCK_ERROR("\n");
        return -1;
    }

    switch (atoi(argv[3])) {
        case 0: do_select(listen_fd); break;
        case 1: do_poll(listen_fd);   break;
        case 2: do_epoll(listen_fd);  break;
        default: printf("Invalid io choice!\n"); break;
    }

    FD_CLOSE(listen_fd);
    return 0;
}

```

## 一个写，多个读的线程fifo

```c
#define MULTI_FIFO_ERR(fmt, args...)  do {                          \
    printf("[MultiFifo][%s:%d] ", __func__, __LINE__);              \
    printf(fmt, ##args);                                            \
} while (0)

#define MULTI_FIFO_MEM_FREE(ptr) do { if (ptr) free(ptr); ptr = NULL; } while (0)

typedef struct {
    int size;
    int total;
    int wchoice;    // FIFO空间不够完全写时: 0, 部分写; 1, 不写直接返回; 3, 清理读取慢的客户端再全部写
    int minread;    // 如果minread不为0且读取的时候fifo中的剩余数据小于这个值，不读直接返回
} MultiFifoSet;

typedef struct {
    pthread_mutex_t mtx;
    int size;
    int total;
    int wchoice;
    int minread;
    char *ptr;
    char *head;
    char **cur;
    char *full;
    int *len;
} MultiFifo;

int multi_fifo_destroy(MultiFifo *fifo)
{
    pthread_mutex_destroy(&fifo->mtx);
    MULTI_FIFO_MEM_FREE(fifo->len);
    MULTI_FIFO_MEM_FREE(fifo->full);
    MULTI_FIFO_MEM_FREE(fifo->cur);
    MULTI_FIFO_MEM_FREE(fifo->ptr);
    MULTI_FIFO_MEM_FREE(fifo);

    return 0;
}

MultiFifo* multi_fifo_init(MultiFifoSet *para)
{
    MultiFifo *fifo = NULL;

    if ((fifo = calloc(1, sizeof(MultiFifo))) == NULL)
    {
        MULTI_FIFO_ERR("malloc(%d) failed!\n", sizeof(MultiFifo));
        return NULL;
    }
    if ((fifo->ptr = calloc(1, para->size)) == NULL)
    {
        MULTI_FIFO_ERR("malloc(%d) failed!\n", size);
        goto err;
    }
    if ((fifo->cur = calloc(para->total, sizeof(char*))) == NULL)
    {
        MULTI_FIFO_ERR("malloc(%d) failed!\n", para->total*sizeof(char*));
        goto err;
    }
    if ((fifo->full = calloc(para->total, sizeof(char))) == NULL)
    {
        MULTI_FIFO_ERR("malloc(%d) failed!\n", para->total*sizeof(char));
        goto err;
    }
    if ((fifo->len = calloc(para->total, sizeof(int))) == NULL)
    {
        MULTI_FIFO_ERR("malloc(%d) failed!\n", para->total*sizeof(int));
        goto err;
    }
    if (pthread_mutex_init(&fifo->mtx, NULL) != 0)
    {
        MULTI_FIFO_ERR("mutex init failed!\n");
        goto err;
    }

    fifo->size = para->size;
    fifo->total = para->total;
    fifo->wchoice = para->wchoice;
    fifo->minread = para->minread;
    fifo->head = fifo->ptr;

    return fifo;

err:
    MULTI_FIFO_MEM_FREE(fifo->len);
    MULTI_FIFO_MEM_FREE(fifo->full);
    MULTI_FIFO_MEM_FREE(fifo->cur);
    MULTI_FIFO_MEM_FREE(fifo->ptr);
    MULTI_FIFO_MEM_FREE(fifo);
    return NULL;
}

int multi_fifo_pause(MultiFifo *fifo)
{
    pthread_mutex_lock(&fifo->mtx);
    MULTI_FIFO_MEM_FREE(fifo->ptr);
    pthread_mutex_unlock(&fifo->mtx);

    return 0;
}

int multi_fifo_resume(MultiFifo *fifo)
{
    int i = 0;
    int ret = -1;

    pthread_mutex_lock(&fifo->mtx);
    if (fifo->ptr == NULL && (fifo->ptr = calloc(1, fifo->size)) == NULL)
    {
        MULTI_FIFO_ERR("malloc(%d) failed!\n", fifo->size);
        goto end;
    }
    fifo->head = fifo->ptr;
    for (i = 0; i < fifo->total; i++)
    {
        if (fifo->cur[i] != NULL)
        {
            fifo->cur[i] = fifo->head;
            fifo->full[i] = 0;
        }
    }

    ret = 0;
end:
    pthread_mutex_unlock(&fifo->mtx);
    return ret;
}

int multi_fifo_reset(MultiFifo *fifo)
{
    int i = 0;

    pthread_mutex_lock(&fifo->mtx);
    if (!fifo->ptr)
    {
        goto end;
    }
    fifo->head = fifo->ptr;
    for (i = 0; i < fifo->total; i++)
    {
        if (fifo->cur[i] != NULL)
        {
            fifo->cur[i] = fifo->head;
            fifo->full[i] = 0;
        }
    }

end:
    pthread_mutex_unlock(&fifo->mtx);
    return 0;
}

int multi_fifo_write(MultiFifo *fifo, char *buf, int size)
{
    int i = 0;
    int ret = 0;
    int tmp = 0;
    int client_ok = 0;
    int max = size;

    if (!fifo || !buf || size <= 0)
        return 0;

    pthread_mutex_lock(&fifo->mtx);
    if (!fifo->ptr)
    {
        goto end;
    }
    if (fifo->size < size)
    {
        MULTI_FIFO_ERR("Fifo size is small than size to write, %d < %d!\n", fifo->size, size);
        goto end;
    }

    for (i = 0; i < fifo->total; i++)
    {
        if (fifo->cur[i] != NULL)
        {
            if (fifo->head > fifo->cur[i])
                fifo->len[i] = fifo->size - (fifo->head - fifo->cur[i]);
            else if (fifo->head < fifo->cur[i])
                fifo->len[i] = fifo->cur[i] - fifo->head;
            else if (fifo->full[i] == 0)
                fifo->len[i] = fifo->size;
            else
                fifo->len[i] = 0;

            max = max < fifo->len[i] ? max : fifo->len[i];
            if (fifo->len[i] < size)
            {
                if (fifo->wchoice == 2)
                {
                    fifo->cur[i] = fifo->head;
                    fifo->full[i] = 0;
                    MULTI_FIFO_ERR("Client %d read too slow!\n", i);
                }
            }
        }
    }

    if (max < size)
    {
        if (fifo->wchoice == 1)
        {
            goto end;
        }
        else (fifo->wchoice == 0)
        {
            if (max == 0)
                goto end;
            size = max;
        }
    }

    if (fifo->head + size <= fifo->ptr + fifo->size)
    {
        memcpy(fifo->head, buf, size);
        fifo->head += size;
    }
    else
    {
        tmp = fifo->size - (fifo->head - fifo->ptr);
        memcpy(fifo->head, buf, tmp);
        memcpy(fifo->ptr, buf + tmp, size - tmp);
        fifo->head = fifo->ptr + size - tmp;
    }

    for (i = 0; i < fifo->total; i++)
    {
        if (fifo->cur[i] != NULL)
        {
            if (fifo->cur[i] == fifo->head)
                fifo->full[i] = 1;
        }
    }

    ret = size;
end:
    pthread_mutex_unlock(&fifo->mtx);
    return ret;
}

int multi_fifo_read(MultiFifo *fifo, char *buf, int size, int sel)
{
    int i = 0;
    int ret = 0;
    int max = 0;
    int tmp = 0;

    if (!fifo || !buf || size <= 0 || sel < 0)
        return 0;

    pthread_mutex_lock(&fifo->mtx);
    if (!fifo->ptr)
    {
        goto end;
    }
    if (fifo->total <= sel)
    {
        MULTI_FIFO_ERR("sel is too large, %d <= %d!\n", fifo->total, sel);
        goto end;
    }

    if (fifo->head > fifo->cur[sel])
        max = fifo->head - fifo->cur[sel];
    else if (fifo->head < fifo->cur[sel])
        max = fifo->size - (fifo->cur[sel] - fifo->head);
    else if (fifo->full[sel] == 0)
        max = 0;
    else
        max = fifo->size;

    size = (max <= size) ? max : size;
    if (size == 0 || (fifo->minread && size < fifo->minread))
    {
        //MULTI_FIFO_ERR("No data!\n");
        goto end;
    }

    if (fifo->cur[sel] + size <= fifo->ptr + fifo->size)
    {
        memcpy(buf, fifo->cur[sel], size);
        fifo->cur[sel] += size;
    }
    else
    {
        tmp = fifo->size - (fifo->cur[sel] - fifo->ptr);
        memcpy(buf, fifo->cur[sel], tmp);
        memcpy(buf + tmp, fifo->ptr, size - tmp);
        fifo->cur[sel] = fifo->ptr + size - tmp;
    }
    fifo->full[sel] = 0;

    ret = size;
end:
    pthread_mutex_unlock(&fifo->mtx);
    return ret;
}

int multi_fifo_free_sel_get(MultiFifo *fifo)
{
    int i = 0;
    int sel = -1;

    if (!fifo)
        return -1;

    pthread_mutex_lock(&fifo->mtx);
    for (i = 0; i < fifo->total; i++)
    {
        if (fifo->cur[i] == NULL)
        {
            fifo->cur[i] = fifo->head;
            fifo->full[i] = 0;
            sel = i;
            break
        }
    }
    pthread_mutex_unlock(&fifo->mtx);

    return sel;
}

int multi_fifo_sel_set(MultiFifo *fifo, int sel)
{
    // multi_fifo_free_sel_get不要和multi_fifo_sel_set混用
    if (!fifo || sel < 0)
        return -1;

    pthread_mutex_lock(&fifo->mtx);
    if (fifo->total <= sel)
    {
        MULTI_FIFO_ERR("sel is too large, %d <= %d!\n", fifo->total, sel);
        pthread_mutex_unlock(&fifo->mtx);
        return -1;
    }
    fifo->cur[sel] = fifo->head;
    fifo->full[sel] = 0;
    pthread_mutex_unlock(&fifo->mtx);

    return 0;
}

int multi_fifo_sel_unset(MultiFifo *fifo, int sel)
{
    if (!fifo || sel < 0)
        return -1;

    pthread_mutex_lock(&fifo->mtx);
    if (sel >= fifo->total)
    {
        MULTI_FIFO_ERR("sel is too large, %d <= %d!\n", fifo->total, sel);
        pthread_mutex_unlock(&fifo->mtx);
        return -1;
    }
    fifo->cur[sel] = NULL;
    fifo->full[sel] = 0;
    pthread_mutex_unlock(&fifo->mtx);

    return 0;
}
```

## 某种内存分配管理

```c
typedef struct {
    struct list_head list;      // 链表节点
    int id;                     // 所属类别ID
    int size;                   // 内存大小
    uint8_t *ptr;               // 首部地址
    uint8_t *cur;               // 当前地址
} BlockMemNode;

/*
 * 函数说明:
 * block_mem_add_none           预分配一块内存
 * block_mem_add_data           分配内存并将数据复制过去
 * block_mem_add_str            分配内存并将字符串复制过去
 * block_mem_free               释放某类ID的全部内存node
 * block_mem_free_all           释放所有ID的全部内存node
 * block_mem_init               初始化head
 *
 * 参数说明:
 * head                         管理内存node的头
 * size                         内存node的内存大小(4字节对齐)
 * id                           内存node的所属id
 * len                          需要分配的内存大小
 * ptr                          需要复制的数据指针
 * str                          需要复制的字符串指针
 *
 * block_mem_add_xxx 主要用于分配小内存:
 * 1、如果找到相同id的node并且空余空间足够: 返回node的cur，cur再自增len(4字节对齐)。
 * 2、如果没有找到相同id的node，或相同id的nodes剩余空间不够: 此时会分配一块大小为 max(size, len) 的新的node，再进行第1步。
 */

void *block_mem_add_none(int len, int id, int size, struct list_head *head);
void *block_mem_add_data(void *ptr, int len, int id, int size, struct list_head *head);
void *block_mem_add_str(const char *str, int id, int size, struct list_head *head);
void block_mem_free(int id, struct list_head *head);
void block_mem_free_all(struct list_head *head);
void block_mem_init(struct list_head *head);

static void *block_mem_new(int id, int size, struct list_head *head)
{
    BlockMemNode *node = NULL;
    void *ret = NULL;
    int tmp1 = 0, tmp2 = 0;

    tmp1 = size % 4;
    tmp2 = (tmp1 != 0) ? (size + 4 - tmp1) : (size);

    if ((node = calloc(1, sizeof(BlockMemNode))) == NULL)
    {
        printf("[%s:%d]malloc failed!\n", __func__, __LINE__);
        return NULL;
    }
    node->id = id;
    node->size = tmp2;
    if ((node->ptr = calloc(1, node->size)) == NULL)
    {
        free(node);
        printf("[%s:%d]malloc failed!\n", __func__, __LINE__);
        return NULL;
    }
    node->cur = node->ptr;
    ret = node->cur;
    list_add(&node->list, head);

    return ret;
}

void *block_mem_add_none(int len, int id, int size, struct list_head *head)
{
    BlockMemNode *pos = NULL, *n = NULL;
    bool not_find = true;
    void *ret = NULL;
    int tmp1 = 0, tmp2 = 0, tmp3 = 0;

    tmp1 = len % 4;
    tmp2 = (tmp1 != 0) ? (len + 4 - tmp1) : (len);
    tmp3 = (tmp2 > size) ? tmp2 : size;

    do {
        list_for_each_entry_safe(pos, n, head, list)
        {
            if (pos->id == id)
            {
                if (pos->cur + tmp2 <= pos->ptr + pos->size)
                {
                    not_find = false;
                    ret = pos->cur;
                    pos->cur += tmp2;
                    break;
                }
            }
        }
    } while (not_find && block_mem_new(id, tmp3, head));

    return ret;
}

void *block_mem_add_data(void *ptr, int len, int id, int size, struct list_head *head)
{
    void *ret = NULL;

    if (!ptr)
    {
        printf("[%s:%d]null ptr!\n", __func__, __LINE__);
        return NULL;
    }
    if ((ret = block_mem_add_none(len, id, size, head)) != NULL)
    {
        memcpy(ret, ptr, len);
    }

    return ret;
}

void *block_mem_add_str(const char *str, int id, int size, struct list_head *head)
{
    if (!str)
    {
        printf("[%s:%d]null ptr!\n", __func__, __LINE__);
        return NULL;
    }
    return block_mem_add_data((void*)str, strlen(str)+1, id, size, head);
}

void block_mem_free(int id, struct list_head *head)
{
    BlockMemNode *pos = NULL, *n = NULL;
    list_for_each_entry_safe(pos, n, head, list)
    {
        if (pos->id == id)
        {
            list_del(&pos->list);
            free(pos->ptr);
            free(pos);
        }
    }
}

void block_mem_free_all(struct list_head *head)
{
    BlockMemNode *pos = NULL, *n = NULL;
    list_for_each_entry_safe(pos, n, head, list)
    {
        list_del(&pos->list);
        free(pos->ptr);
        free(pos);
    }
}

void block_mem_init(struct list_head *head)
{
    INIT_LIST_HEAD(head);
}

/**** 排序方法 ****/

int binary_search(int value, int *array, int num)
{
    int low, centre, high, temp;

    for (low = 0, high = num - 1; low <= high; ) {
        centre = (low + high) / 2;
        temp = array[centre];
        if (value == temp) {
            return centre;
        } else if (value < temp) {
            high = centre - 1;
        } else {
            low = centre + 1;
        }
    }
    return -1;
}

int binary_sort(int *array, int num)
{
    int *sort = NULL;
    int cnt = 0;
    int i;
    int low, centre, high;

    if (num <= 0 || array == NULL)
        return -1;
    if ((sort = calloc(num, sizeof(int))) == NULL) {
        printf("[%s:%d]malloc err!", __func__, __LINE__);
        return 0;
    }

    sort[cnt++] = array[0];
    while (cnt < num) {
        centre = 0;
        for (low = 0, high = cnt - 1; low <= high; ) {
            centre = (low + high) / 2;
            } else if (sort[centre] >= array[cnt]) {
                if (centre-1 < 0 || sort[centre-1] <= array[cnt]) {
                    break;
                }
                high = centre - 1;
            } else {
                if (centre+1 == cnt || sort[centre+1] >= array[cnt]) {
                    centre++;
                    break;
                }
                low = centre + 1;
            }
        }

        for (j = cnt; j > centre; j--) {
            sort[j] = sort[j-1];
        }
        sort[centre] = array[cnt];
    }
    free(sort);

    return 0;
}
```

## 文件操作

```c
#define _fmalloc   GxCore_Malloc
#define _ffree     GxCore_Free
#define _fclose_fp(fp) do {if (fp) fclose(fp); fp = NULL; } while (0)
#define _free_ptr(ptr) do {if (ptr) _ffree(ptr); ptr = NULL; } while (0)

int copy_file_to_file(const char *src, const char *dst, int unit_size)
{
    int ret = -1;
    FILE *rfp = NULL, *wfp = NULL;
    uint8_t *data = NULL;
    int size = 0;

    if (!src || !dst)
        return -1;
    if ((rfp = fopen(src, "r")) == NULL)
        return -1;
    if ((wfp = fopen(dst, "w+")) == NULL)
        goto end;
    if (unit_size < 512)
        unit_size = 8192;
    if ((data = _fmalloc(unit_size)) == NULL)
        goto end;
    while ((size = fread(data, 1, unit_size, rfp)) > 0) {
        if (size != fwrite(data, 1, size, wfp))
            goto end;
    }

    ret = 0;
end:
    _fclose_fp(rfp);
    _fclose_fp(wfp);
    _free_ptr(data);
    if (ret < 0 && access(dst, F_OK) == 0)
        unlink(dst);
    return ret;
}

int copy_data_to_file(uint8_t *data, int size, const char *dst)
{
    int ret = -1;
    FILE *wfp = NULL;

    if (!data || !dst)
        return -1;
    if ((wfp = fopen(dst, "w+")) == NULL)
        return -1;
    if (size == fwrite(data, 1, size, wfp))
        ret = 0;
    _fclose_fp(wfp);
    if (ret < 0 && access(dst, F_OK) == 0)
        unlink(dst);

    return ret;
}

int read_file_to_data(const char *src, uint8_t **data, int *size)
{
    FILE *rfp = NULL;
    int total = 0;

    if (!src || !data)
        return -1;

    if (!size)
        size = &total;
    *data = NULL, *size = 0;

    if ((rfp = fopen(src, "r")) == NULL)
        return -1;
    fseek(rfp, 0, SEEK_END);
    *size = ftell(rfp);
    fseek(rfp, 0, SEEK_SET);
    if (*size == 0)
        goto err;

    if ((*data = _fmalloc(*size + 1)) == NULL)
        goto err;
    if (*size != fread(*data, 1, *size, rfp))
        goto err;

    (*data)[*size] = 0;
    _fclose_fp(rfp);
    return 0;
err:
    _fclose_fp(rfp);
    _free_ptr(*data);
    *size = 0;
    return -1;
}

int read_file_data_free(uint8_t **data, int *size)
{
    if (data)
        _free_ptr(*data);
    if (size)
        *size = 0;
    return 0;
}
```
