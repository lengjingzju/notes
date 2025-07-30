# Python编程笔记

* 官方文档： https://docs.python.org/zh-cn/3/
* 包查找： https://pypi.org/

## 目录

[TOC]

## 基础概念

### 交互式编程

* 交互式编程
    * 终端输入 `python3` 进入Python3交互式命令行
    * 主提示符 `>>>` 是解释器告诉你它在等待你输入下一个语句
    * 次提示符 `...` 告诉你解释器正在等待你输入当前语句的其它部分
    * 语句使用关键字来组成命令，类似告诉解释器一个命令
    * 表达式没有关键字，它们可以是使用数学运算符构成的算术表达式，也可以是使用括号调用的函数
    * 交互式命令行退出命令为 `quit()` ，相应的快捷键 `Ctrl+d`(Linux) 或 `Ctrl+z`(Win)

```py
jleng@jleng:~$ python3
Python 3.6.9 (default, Jan 26 2021, 15:33:00)
[GCC 8.4.0] on linux
Type "help", "copyright", "credits" or "license" for more information.
>>> print("Hello World!")
Hello World!
>>> quit()
```

### 脚本式编程

* 脚本式编程
    * 运行python脚本使用 `./script.py` 或 `python3 script.py`
    * `python3 -m module-name` 在 sys.path 中搜索指定模块，并以 __main__ 模块执行其内容
    * 脚本首行 `#!/usr/bin/python3` 指定了python解释器的路径，这句话仅仅在linux或unix系统下有作用
    * 首行也可以使用 `#!/usr/bin/env python3` ，表示会到 env 设置里查找 python3 的安装路径
    * Python 能在运行时检测该模块是被导入还是被直接执行，如果模块是被导入，` __name__` 的值为模块名字，如果模块被直接执行， `__name__` 的值为 `__main__`

```py
#!/usr/bin/python3

if __name__ == "__main__":
    print("Hello World!")
```

### 安装模块

* `sudo python3 setup.py install`       : 手动下载模块包解压后安装
* `sudo pip3 install module_name`       : 自动下载模块安装，安装路径为 `/usr/local/lib/python3.x/dist-packages`
    安装pip3 `sudo apt install python3-pip`
    升级pip3 `sudo pip3 install --upgrade pip`
* `pip3 install module_name --user`     : 自动下载模块安装，当前用户
* `sudo pip3 install module_name=version -i URL --trusted-host HOST`: 自动下载模块安装，指定仓库和版本
    `-i https://pypi.tuna.tsinghua.edu.cn/simple --trusted-host pypi.tuna.tsinghua.edu.cn`
* pip3其他命令选项
    -h ：帮助信息
    install：安装库
    uninstall：卸载库
    list：列出已安装库的信息
    show：列出已安装库的详细信息
    search：通过PyPI搜索库
    help：帮助命令
* 永久修改pip源
    ```sh
    # 清华源
    pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
    # 阿里源
    pip config set global.index-url https://mirrors.aliyun.com/pypi/simple/
    # 腾讯源
    pip config set global.index-url http://mirrors.cloud.tencent.com/pypi/simple
    # 豆瓣源
    pip config set global.index-url http://pypi.douban.com/simple/
    # 还原源
    pip config unset global.index-url
    ```

### 对象内存管理

* 变量无须事先声明，无须指定类型，在第一次被赋值时自动声明，只有被创建和赋值后才能被使用
* 对象的类型和内存占用都是运行时确定的，使用了引用计数追踪内存中的对象
* Python的垃圾收集器实际上是一个引用计数器和一个循环垃圾收集器。当一个对象的引用计数变为0，解释器会暂停，释放掉这个对象和仅有这个对象可访问的其他对象
* 在有指针的情况下，**浅拷贝** 只是增加了一个指针指向已经存在的内存，而 **深拷贝** 就是增加一个指针并且申请一个新的内存，使这个增加的指针指向这个新的内存

* 对象的引用计数增加
    * `x = 3.14`                        : 对象被创建
    * `y = x `                          : 其它的别名被创建
    * `foobar(x)`                       : 被作为参数传递给函数(新的本地引用)
    * `myList = [123, x, 'xyz']`        : 成为容器对象的一个元素\
    * 任何追踪或调试程序会给一个对象增加一个额外的引用，这会推迟该对象被回收的时间

* 对象的引用计数减小
    * `del y or del x`                  : 对象的别名被显式销毁
    * `x = 123`                         : 对象的一个别名被赋值给其他对象
    * `foobar(x)`                       : 对象离开作用域被隐式销毁，比如离开函数
    * `myList.remove(x)`                : 对象从一个容器对象中移除
    * `del myList`                      : 容器对象本身被销毁

### 身份

* `id(obj)`                             : 查看 Python 对象的标识，每一个对象都有一个唯一的身份标识自己，这个值可以被认为是该对象的内存地址
    * Python 会缓存简单整数，Python 缓存的整数范围是 (-1, 100)，这个范围可能会变化
* `obj1 is obj2` / `obj1 is not obj2`   : 运算符来测试两个对象名是否指向同一个对象
* `type(obj)`                           : 查看 Python 对象的类型, type() 不会认为派生类对象的类型是基类类型。
* `isinstance(obj, class_type)`         : 判断 Python 对象是否属于类型，isinstance 会认为派生类对象属于基类类型。
    * obj是实例对象，class_type 可以是直接或间接(基类)类名、基本类型或由它们组成的元组

### 编码

* 默认情况下，Python 3 源码文件以 UTF-8 编码，所有字符串都是 unicode 字符串
* 当然你也可以为源码文件指定不同的编码 [参考pep-0263](http://www.python.org/dev/peps/pep-0263/)

```py
#!/usr/bin/python3
# -*- coding: utf-8 -*-
```

### 标识符

* 标识符的第一个字符必须是字母表中字母或下划线 `_` ，其他的部分可由字母、数字和下划线组成
* 下划线开始的标识符有特殊含义。
    * `__xxx__`                         : 系统定义名字，特殊方法，特殊方法的存在是为了被 Python 解释器调用
        * 通过实现特殊方法 `__func__()`, 自定义数据类型可以表现得跟内置类型一样，这样调用方法 `func(obj)`，而不用 `obj.__func__()`
    * `__xxx`                           : 类中的私有对象
    * `_xxx`                            : 模块私有对象，不要用 `from module import *` 导入
* 标识符对大小写敏感
* 在 Python3 中，非 ASCII 标识符也是允许的了
* Python 不支持方法或函数重载，一个标识符只能绑定一个身份
* Python 是动态类型语言， 也就是说不需要预先声明变量的类型。 变量的类型和值在赋值那一刻被初始化

### 关键字

* 保留字即关键字，我们不能把它们用作任何标识符名称
* Python 的标准库提供了一个 keyword 模块，可以输出当前版本的所有关键字

```py
>>> import keyword
>>> keyword.kwlist
['False', 'None', 'True', 'and', 'as', 'assert', 'break', 'class', 'continue', 'def', 'del', 'elif', 'else', 'except', 'finally', 'for', 'from', 'global', 'if', 'import', 'in', 'is', 'lambda', 'nonlocal', 'not', 'or', 'pass', 'raise', 'return', 'try', 'while', 'with', 'yield']
>>>
```

### 注释

* 单行注释以 `#` 开头，一直到行末尾
* 多行注释以 三双引号(`"""`)开始，三双引号(`"""`)结束；或 三单引号(`'''`)开始，三单引号(`'''`)结束
* 文档字符串注释: 在模块、类声明或函数声明中第一个没有赋值的字符串(放在起始处)
    * `help(func_name)` 可查看说明
    * `print(func_name.__doc__)` 可打印说明文档
    * `dir()` 可显示对象属性，

```py
>>> def example(anything):
...     '''    参数为一个任意类型的对象，
...     函数会将形参原样返回。'''
...     return anything # 原样返回
...
>>> print(example.__doc__)
    参数为一个任意类型的对象，
    函数会将形参原样返回。
>>>
```

### 行与缩进

* Python 使用缩进来表示代码块，不需要使用大括号 `{ }` ，**同一个代码块的语句必须包含相同的缩进空格数**
* Python 语句行末尾不需要添加分号 `;` ，同一行多个语句可以用分号隔开
* Python 通常是一行写完一条语句，如果语句很长，我们可以用反斜杠 `\` 来实现一条语句写成多行
* 两种例外情况一个语句不使用反斜线也可以跨行:
    1. 在使用闭合操作符时，单一语句可以跨多行，例如: 在含有小括号、中括号、花括号时可以多行书写
    2. 三引号包括下的字符串也可以跨行书写

```py
>>> a = 1; b = 2                        # 同一行多个语句用分号隔开
>>> print(a, b)
1 2
>>> a + \
... b                                   # 反斜杠 \ 实现一条语句写成多行
3
>>> a = [1, ]
>>> a = [1,
... 2]                                  # [ ] 中一条语句写成多行
>>>
```

### 语句块

* 缩进相同的一组语句构成一个代码块，我们称之为代码组
* 像 if, elif, else, while, for, def, class, try, except, finally 这样的复合语句，首行以`关键字`开始，以冒号 `:` 结束，该行之后的一行或多行代码构成代码组
* 我们将首行及后面的代码组称为一个子句(clause)

## 调试脚本

* `print()` 打印调试，例如 `print('n = %d' % n)`
* 断言调试 `assert condition, "error string"` , 例如 `assert n != 0, "error: n is zero!"`
* 在脚本中导入logging( `import logging` )后调试信息输出到文件，例如 `logging.info('n = %d' % n)`
* 在脚本中导入pdb( `import pdb` )后运行时会在 `pdb.set_trace()` 语句处停止
* pdb调试，使用和gdb类似，例如 `python3 -m pdb hello_world.py`
    * 允许你设置(条件)断点，代码逐行执行，检查堆栈，它还支持事后调试
* `profile` `hotshot` `cProfile` 用于性能测试

### 输出 print

* 基本输出` print(value, ..., sep=' ', end='\n', file=sys.stdout, flush=False)`
    * `value`   : 多个value使用逗号给开，对每个参数自动调用 str(value) 转换为字符串
    * `file`    : 默认流输出到stdout
    * `sep`     : 常用，多个value输出后默认使用空格隔开
    * `end`     : 常用，末尾默认添加换行符
    * `flush`   : 默认不强制刷新流
    * 无论什么类型，数字、列表、元组、字典、集合、... 都可以直接输出

```py
>>> a = 100
>>> aList = [1, 2, 3]
>>> aTuple = ('a', 'b', 'c')
>>> aString = 'LengJing'
>>> aDict = {"Name":"lengjing", "Age":29}
>>> print(a)
100
>>> print(aList)
[1, 2, 3]
>>> print(aTuple)
('a', 'b', 'c')
>>> print(aString)
LengJing
>>> print(aDict)
{'Age': 29, 'Name': 'lengjing'}
>>> print(a, aList, aTuple, aString, aDict) # 多个参数间的默认分隔符为空格 ' '
100 [1, 2, 3] ('a', 'b', 'c') LengJing {'Age': 29, 'Name': 'lengjing'}
>>> print(a, aList, aTuple, aString, aDict, sep = ', ') # 多个参数间的分割符改为 ', '
100, [1, 2, 3], ('a', 'b', 'c'), LengJing, {'Age': 29, 'Name': 'lengjing'}
>>> print(a, end = ', '); print(aList, end = ', '); print(aTuple, end = ', '); print(aString, end = ', '); print(aDict) # print语句改为加 ', '
100, [1, 2, 3], ('a', 'b', 'c'), LengJing, {'Age': 29, 'Name': 'lengjing'}
>>>
```

* 格式化输出
    * `%` 字符：标记转换说明符的开始
    * 转换标志：`-` 表示左对齐；`+` 表示在转换值之前加上正负号；`空白` 表示若转换值位数不够前面用空格填充；`0` 表示若转换值位数不够前面用0填充；`#` 在八进制数前面显示'0o'，在十六进制前面显示'0x'或者'0X'(取决于用的是'x'还是'X')
    * 最小字段宽度：转换后的字符串至少应该具有该值指定的宽度；如果是`*`，则宽度会从值元组中读出
    * 点(`.`)后跟精度值：如果转换的是实数，精度值就表示出现在小数点后的位数；如果是`*`，那么精度将从元组中读出
    * 字符串格式化转换类型
        * 整数：   `d` 十进制； `u` 无符号十进制； `o` 八进制； `x,X `十六进制(小写,大写)。
        * 浮点数： f,F 十进制浮点数； e,E 科学计数法(小写,大写)
        * 字符串： c 单字符(接受整数或者单字符字符串)； r 字符串(使用 repr 转换任意 Python对象)； s 字符串(使用 str 转换任意 Python 对象)。
        * 注：大写D、大写U、大写O、大写C、大写R、大写S 会报错；d、u会截断浮点数；o、x、X浮点数会报错

```py
>>> from math import pi
>>> pi
3.141592653589793
>>> print('----%10.3f----' % pi)        # 10表示打印字符数最小为10，3表示保留3位小数
----     3.142----
>>> print('----%3.10f----' % pi)        # 如果实际打印字符数大于3，输出实际字符数
----3.1415926536----
>>> print('----%10.3f----' % pi)        # 转换值位数不够默认用空格填充
----     3.142----
>>> print('----%010.3f----' % pi)       # 0 表示若转换值位数不够用0填充
----000003.142----
>>> print('----%-10.3f----' % pi)       # - 表示左对齐
----3.142     ----
>>> print('----%-010.3f----' % pi)
----3.142     ----
>>> print('----%+10.3f----' % pi)       # + 表示在转换值之前要加上正负号
----    +3.142----
>>> print('----%*.3f----' % (10, pi))   # * 表示字符宽度会从值元组中读出
----     3.142----
>>> print('----%10.*f----' % (3, pi))   # * 表示小数精度会从值元组中读出
----     3.142----
>>> print('----%10.3e----' % (pi/1000)) # e 表示科学计数法
---- 3.142e-03----
>>>

>>> a = 200
>>> print('%d, %u, %o, %x, %X' % (a,a,a,a,a))
200, 200, 310, c8, C8
>>> print('%#o %#x %#X' % (a,a,a))
0o310 0xc8 0XC8
>>> a = -200
>>> print('%d, %u, %o, %x, %X' % (a,a,a,a,a))
-200, -200, -310, -c8, -C8
>>> print('%#o %#x %#X' % (a,a,a))
-0o310 -0xc8 -0XC8
>>>

>>> a = 97
>>> print('%c, %r, %s' % (a, a, a))
a, 97, 97
>>> print('%c, %r, %s' % ('a', 'a', 'a'))
a, 'a', a
>>> print('%r, %s' % ('abc', 'abc'))
'abc', abc
>>> print('%c' % 'abc')
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
TypeError: %c requires int or char
>>>
```

### 输入 input

* input 函数在 Python 中是一个内建函数，其从标准输入中读入一个字符串，并自动忽略换行符
* 也就是说所有形式的输入按字符串处理，如果想要得到其他类型的数据进行强制类型转化
* 默认情况下没有提示字符串(prompt string)，在给定提示字符串下，会在读入标准输入前标准输出提示字符串
* `var1, var2 = eval(input())` 接受多个逗号隔开的数字输入，分别赋值给var1, var2 (var1, var2 是数字类型)

```py
>>> x = input("Enter a number: ")
Enter a number: 123
>>> x
'123'
>>> y = int(input("Enter a number: "))
Enter a number: 123
>>> y
123
>>>
```

### logging

* 日志池模块

```py
import os, sys, time
import logging, logging.config

class LoggerPool(object):
    def __init__(self):
        self.loggers = {}

    def get_logger(self, name="", filename="", options={}):
        key = name if name else "main"
        if key in self.loggers.keys():
            return self.loggers[key]["logger"]

        return self.__create_logger(name, filename, options)

    def __create_logger(self, name="", filename="", options={}):
        name = name if name else "main"
        alogger = {"name":name}

        if options:
            if "logfile" in options.keys():
                alogger["logfile"] = options["logfile"]
            if "console" in options.keys():
                alogger["console"] = options["console"]
            if "detail" in options.keys():
                alogger["detail"] = options["detail"]
            if "level" in options.keys():
                alogger["level"] = options["level"]

        if "logfile" not in alogger.keys():
            alogger["logfile"] = True
        if "console" not in alogger.keys():
            alogger["console"] = True
        if "detail" not in alogger.keys():
            alogger["detail"] = True
        if "level" not in alogger.keys():
            alogger["level"] = logging.INFO
        if not (alogger["logfile"] or alogger["console"]):
            alogger["logfile"] = True
            alogger["console"] = True

        logger = logging.getLogger(name)
        fmt = '%(asctime)s: %(levelname)s: %(filename)s+%(lineno)d: %(message)s' if alogger["detail"] else None
        formatter = logging.Formatter(fmt)
        logger.setLevel(alogger["level"])

        if alogger["logfile"]:
            if not filename:
                cur_time = time.strftime("-%Y%m%d_%H%M%S", time.localtime(time.time()))
                filename = os.path.join("logs", alogger["name"] + cur_time + ".log")
            alogger["filename"] = filename

            filepath = os.path.dirname(filename)
            if filepath and not os.path.exists(filepath):
                os.makedirs(filepath)

            file_handler = logging.FileHandler(filename, mode='w')
            file_handler.setFormatter(formatter)
            file_handler.setLevel(alogger["level"])
            logger.addHandler(file_handler)

        if alogger["console"]:
            stream_handler = logging.StreamHandler(sys.stdout)
            stream_handler.setFormatter(formatter)
            stream_handler.setLevel(alogger["level"])
            logger.addHandler(stream_handler)

        alogger["logger"] = logger
        self.loggers[alogger["name"]] = alogger

        return logger

g_logger_pool = LoggerPool()

def logger_pool_test():
    main_logger = g_logger_pool.get_logger()
    main_logger.debug("main_logger debug")
    main_logger.info("main_logger info")
    main_logger.warning("main_logger warning")
    main_logger.error("main_logger error")
    main_logger.critical("main_logger critical")

    options = {"level":logging.DEBUG}
    sub_logger = g_logger_pool.get_logger("sub", "", options)
    sub_logger.debug("sub_logger debug")
    sub_logger.info("sub_logger info")
    sub_logger.warning("sub_logger warning")
    sub_logger.error("sub_logger error")
    sub_logger.critical("sub_logger critical")

if __name__ == "__main__":
    logger_pool_test()
```

### 运行时绘制Python代码的函数调用关系

* 安装软件
```
sudo apt install graphviz
sudo pip3 install pycallgraph
```

* 修改主函数
```py
# 导入pycallgraph
from pycallgraph import PyCallGraph
from pycallgraph.output import GraphvizOutput
from pycallgraph import Config
from pycallgraph import GlobbingFilter

def main():
	# 主函数代码

if __name__ == "__main__":
    # config如果不配置就是跟踪全部函数，include要跟踪的函数，exclude要排除的函数，可用通配符
    config = Config()
    config.trace_filter = GlobbingFilter(include=[
        'main',
        'train',
    ])
    config.trace_filter = GlobbingFilter(exclude=[
        'pycallgraph.*',
    ])

    # 核心代码
    graphviz = GraphvizOutput()
    graphviz.output_file = 'basic.png'

    with PyCallGraph(output=graphviz, config=config):
        main()
```

## 数字类型

* Python 中数字有四种类型：整型、布尔型、浮点型和复数
    * 整型(int): 通常被称为是整型或整数，是正或负整数，不带小数点
        * Python 整型仅受限于用户计算机的虚拟内存总数，远比C语言中的 long long 表示的值大
    * 布尔型(bool): 只有两个值，`True` 和 `False`
        * 零数字( `0`, `0.0`, `0+0j` )和空容器( 空列表 `[]`, 空元组 `()`, 空字典 `{}`, 空集合 `set()` ) 和空对象 `None` 可以转换为 False
    * 浮点型(float): 浮点型由整数部分与小数部分组成(也可以使用科学计数法表示)
        * 浮点型是双精度的，只是一个近似值，完全遵守 IEEE754 号规范(52M/11E/1S)
    * 复数(complex): 复数由实数部分和虚数部分构成，可以用`a + bj`  或 `complex(a,b`) 表示
        * 复数的实部a和虚部b都是浮点型，不支持复数转换为整数或浮点数
        * 虚数部分必须有后缀 j 或 J
* 数字都是不可变的，改变数字变量的值，就是把旧对象引用数减1，然后把新对象赋值给变量，新对象引用数加1

```py
>>> type(1)
<class 'int'>
>>> type(True)
<class 'bool'>
>>> type(False)
<class 'bool'>
>>> type(1.0)
<class 'float'>
>>> type(1e1)
<class 'float'>
>>> type(1e-2)
<class 'float'>
>>> type(1+0j)
<class 'complex'>
>>> type(1+1j)
<class 'complex'>
>>> type(1+j)                           # j 前面必须加数字，即使数字是1或0
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
NameError: name 'j' is not defined
>>> type(1+1i)                          # 不能用 i 表示虚部，必须用小j或大J
  File "<stdin>", line 1
    type(1+1i)
            ^
SyntaxError: invalid syntax
>>> 0.1+0.1+0.1-0.3                     # 浮点数只是一个近似值
5.551115123125783e-17
>>>
```

## 序列类型

* 序列分类1
    * `list` `tuple` `collections.deque` : **容器序列** 能存放不同类型的数据，存放的是它们所包含的任意类型的对象的引用
    * `str` `bytes` `bytearray`  `memoryview` `array.array` : **扁平序列** 只能容纳一种类型，扁平序列里存放的是值，是一段连续的内存空间
* 序列分类2
    * `list` `bytearray` `array.array` `collections.deque` `memoryview` : 可变序列，可以修改元素，自运算(复合赋值)不会改变它的id，普通赋值会改变它的id
    * `tuple` `str` `bytes` : 不可变序列，不可以修改元素，自运算(复合赋值)和普通赋值都会改变它的id

### 字符串(str)

* 字符串用单引号 `' '` 或双引号 `" "` 包起来，单引号和双引号的意义完全相同
* 使用三引号 `''' '''` 或 `""" """` 可以指定一个多行字符串
* Python 没有单独的字符类型，一个字符就是长度为 1 的字符串
* 使用转义符(反斜杠 `\` ) 转义特殊字符
* 字符串前缀
    * `r`   : 原始字符串表示法，去掉反斜杠的转义含义，常用于正则表达式，例如 `r'this is a line with \n'` 则会显示 `\n`，并不是换行
    * `u`   : 后面字符串以 Unicode 格式进行编码，一般用在中文字符串前面
    * `b`   : 后面字符串是 bytes 类型，网络编程中，服务器和浏览器只认 bytes 类型数据
        * str转换为bytes类型 `str.encode('utf-8')` ， 相反转换 `bytes.decode('utf-8')`
        * Unicode 字符串 (str) ，也可以是8位字节串 (bytes)
    * `f`   : 支持大括号内的变量展开，也可以格式化输出方式
        * 例如 `name = 'lengjing'` , `f'My name is {name}.'` 和 `'My name is %s.' % name` 输出 `My name is lengjing.`
* 可以按字面意义级联字符串，注意不会自动添加空格，例如 `"Hello " "world" "!"` 表示 `"Hello world!"`
* Python 中的字符串不能改变，修改字符串实际上是新建一个新的字符串赋值给变量，id值(内存地址)变化了

* `repr(obj)`  : 返回对象适合可读性好的字符串表示
    * `repr()` 返回的字符串对python解释器友好
    * 交互式解释器则调用 `repr()` 函数来显示对象
    * 通常情况下 `obj==eval(repr(obj))` 这个等式是成立的，并不是所有 `repr()` 返回的字符串都能够用 `eval()` 内建函数得到原来的对象
    * 建议使用 `ast.literal_eval(str)` 来获取对象，因为 `eval()` 会进行计算和运行命令

* `str(obj)` : 返回一个对象的字符串表示
    * `str()` 返回的字符串对用户友好
    * `print()` 函数调用 `str()` 函数显示对象
    * 如果一个对象没有 `__str__` 函数，而 Python 又需要调用它的时候，解释器会用 `__repr__` 作为替代。

### 列表(list)

* 列表用中括号 `[ ]` 包起来，列表的元素类型可以不同，用逗号给开，元素的个数及元素的值可以改变
* 列表和元组的元素可以是不同类型的，例如 `[123, abc, ('a', 1)]`

### 元组(tuple)

* 元组用小括号 `( )` 包起来，元组的元素类型可以不同，用逗号给开，不可以改变元组中的元素
* 元组中的元素不可改变，指的是元素id不可改变，如果元组的元素是列表等，则元素列表的元素可以改变
* 当处理一组对象时，这个组默认是元组类型
<p/>

*  元组拆包
    * 元组拆包可以应用到任何可迭代对象上，唯一的硬性要求是被可迭代对象中的元素数量必须要跟接受这些元素的元组的空档数一致。

* `a, b, c = val1, val2, val3`          : 平行赋值，a被赋值成了val1, b被赋值成了val2，c被赋值成了val3

* `_, b, c = val1, val2, val3`          : 下划线作为占位符，表示元组拆包时对这个数据val1不感兴趣
* `a, *b = val1, val2, val3`            : 星号代表剩下的元素，即 b = (val2, val3)，星号也可以出现在赋值表达式的任意位置
* `func(*iterable)`                     : 星号用在函数调用中把一个可迭代对象拆开作为函数的参数
    * 星号用在函数定义中表示可变长度的匿名参数(见函数章节)
* `return val1, val2`                   : 返回多个值的函数实际上是返回了一个元组 (val1, val2)

### 例子

```py
>>> type("a")
<class 'str'>
>>> type('abc')
<class 'str'>
>>> print(r'abc\n')
abc\n
>>> print('abc\n')
abc

>>>
>>> type('')                            # 空字符串
<class 'str'>
>>> type([])                            # 空列表
<class 'list'>
>>> type(())                            # 空元组
<class 'tuple'>
>>> type((1))
<class 'int'>
>>> type((1,))                          # 单个元素的元组必须元素后加逗号
<class 'tuple'>
>>> aList = ["abc", "123", 100]         # 列表
>>> id(aList)
139853985172808
>>> id(aList[0])
139854022587984
>>> aList[0] = 'xyz'                    # 改变列表中的元素
>>> id(aList)                           # 改变列表中的元素列表的id不变
139853985172808
>>> id(aList[0])
139853986111360
>>> aTuple = ("abc", "123", 100)        # 元组
>>> aTuple[0] = 'xyz'                   # 不可以改变元组中的元素
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
TypeError: 'tuple' object does not support item assignment
>>>
>>> nTuple = (aList, 'tuple', 999)      # 序列的元素可以是序列
>>> nTuple
(['xyz', '123', 100], 'tuple', 999)
>>> id(nTuple)
139853985140528
>>> id(nTuple[0])
139853985172808
>>> nTuple[0][2] = '520'                # 改变了元组的列表元素中的元素
>>> nTuple
(['xyz', '123', '520'], 'tuple', 999)
>>> id(nTuple)
139853985140528
>>> id(nTuple[0])
139853985172808
>>>
>>> a = 1; b = 2
>>> a, b
(1, 2)
>>> a, b = b, a                         # 实际上当成的元组对待
>>> a, b
(2, 1)
>>>
>>> divmod(20, 8)
(2, 4)
>>> t = (20, 8); divmod(*t)             # 星号把可迭代对象t拆开作为divmod函数的参数
(2, 4)
>>>
```
### 具名元组(namedtuple)

* 使用前必须导入具名元组 `from collections import namedtuple`
* `collections.namedtuple` 是一个工厂函数，它可以用来构建一个带字段名的元组和一个有名字的类
* 创建一个具名元组需要两个参数: 类名和类的各个字段的名字
* 后者可以是由数个字符串组成的可迭代对象，或者是由空格分隔开的字段名组成的字符串
* 实例化具名元组，存放在对应字段里的数据要以一串参数的形式传入到构造函数中

```py
>>> from collections import namedtuple  # 导入具名元组
>>> City = namedtuple('City', 'name country population coordinates')    # 定义特定的具名元组
>>> tokyo = City('Tokyo', 'JP', 36.933, (35.689722, 139.691667))        # 实例化具名元组，也可以使用City._make(iter_obj)生成
>>> tokyo
City(name='Tokyo', country='JP', population=36.933, coordinates=(35.689722, 139.691667))
>>> tokyo.name, tokyo[0]        # 访问具名元组，两种方法
('Tokyo', 'Tokyo')
>>> City._fields    # _fields属性是一个包含这个类所有字段名称的元组。
('name', 'country', 'population', 'coordinates')
>>> tokyo._asdict()
OrderedDict([('name', 'Tokyo'), ('country', 'JP'), ('population', 36.933), ('coordinates', (35.689722, 139.691667))])
>>>
```

### 序列索引切片

* `seq[ind]`                            : 获得下标为 ind 的元素，两种索引方式，从左往右以0开始，从右往左以-1开始。
* `seq[start:end:step]`                 : 以step为步进获得下标从 ind1 到 ind2 间的元素集合
    * start表示开始元素(包含)，end表示结束元素(不包含)，step表示步进
    * step 取正值，表示每个每多少个元素取一个元素；取负值，表示反向抽取元素
    * `[:end:step]`                     : start可以省略，默认从0开始(step为负值时相反)
    * `[start::step]`                   : end可以省略，默认到序列的最后1个元素(包含)结束
    * `[start:end]`                     : step可以省略，默认步进为1

```
        1       2       3       N-1
sep     □       □       □  ...  □
        -N      -(N-1)  -(N-2)  -1
N = len(seq)
```

```py
>>> aString = "abcdefg"
>>> N = len(aString)                    # 序列长度
>>> N
7
>>> aString[0]                          # 序列首元素
'a'
>>> aString[-N]                         # 序列首元素
'a'
>>> aString[N-1]                        # 序列尾元素
'g'
>>> aString[-1]                         # 序列尾元素
'g'
>>> aString[0:3]                        # 切片包含aString[start]，不包含aString[end]
'abc'
>>> aString[:3]                         # 省略start时，默认start = 0
'abc'
>>> aString[3:]                         # 省略end时，默认end = N
'defg'
>>> aString
'abcdefg'
>>> aString[:]
'abcdefg'
>>> aString[::2]                        # 步进step设为了2，取0, 2, 4, 6元素
'aceg'
>>> aString[::-2]                       # 步进step设为了负值，反向切片
'geca'
>>> aString[::-1]                       # 步进step设为了-1，得到原序列的逆序列
'gfedcba'
>>> aString[N]                          # 索引超序列范围报错
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
IndexError: string index out of range
>>> aString[0:2*N]                      # 切片超序列范围忽略
'abcdefg'
>>>
```

### 序列操作符号

* `seq1 + seq2`                         : 连接序列 seq1 和 seq2
* `seq * num`                           : 序列重复 num 次
* `obj in seq`                          : 判断 obj 元素是否包含在 seq 中
* `obj not in seq`                      : 判断 obj 元素是否不包含在 seq 中
* `del seq[ind]`                        : 按索引删除列表元素，字符串和元组报错

```py
>>> aList = [1, 3, "a", {99}]
>>> aList + [{"a":1}]                   # 序列连接
[1, 3, 'a', {99}, {'a': 1}]
>>> aList - [1]                         # 序列没有减法
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
TypeError: unsupported operand type(s) for -: 'list' and 'list'
>>> aList * 3                           # 序列重复
[1, 3, 'a', {99}, 1, 3, 'a', {99}, 1, 3, 'a', {99}]
>>> {99} in aList                       # 是否是序列成员
True
>>> 99 in aList
False
>>> [1, 3] in aList                     # 不能判断是否是子列表
False
>>> bList = [1, 3, "a", {99}]
>>> del bList[0];bList                  # 按列表索引删除元素
[3, 'a', {99}]
>>> del bList[1:3];bList
[3]
>>> del bList[:];bList                  # 删除列表全部元素
[]
>>>
>>> aTuple = tuple(aList)
>>> aTuple
(1, 3, 'a', {99})
>>> (1, 3) in aTuple                    # 不能判断是否是子元组
False
>>>
>>> aString = 'abcdefg'
>>> 'abc' in aString                    # 可以判断是否是子字符串
True
>>> 'a' in aString
True
>>> 'acd' in aString
False
>>>
```

### 序列内建函数

* `len(seq)`                            :返回 序列 seq 的长度
* `max(iter, key=None)`                 :返回 iter 里面的最大值，如果指定了 key，比较方式由 key 回调函数确定
* `max(arg0, arg1..., key=None)`        :返回 (arg0, arg1, ...) 中的最大值
* `min(iter, key=None)`                 :返回 iter 里面的最小值
* `min(arg0, arg1..., key=None)`        :返回 (arg0, arg2, ...) 里面的最小值
* `reversed(seq)`                       :返回一个以逆序访问的迭代器
* `sorted(iter, key=None, reverse=False)`:返回一个有序的列表
* `sum(seq, init=0)`                    :返回 seq 和可选参数 init 的总和，其效果等同于 `reduce(operator.* add, seq, init)`
* `zip([it0, it1,... itN])`             :返回一个列表，其第一个元素是 it0, it1, ...这些元素的第一个元素组成的* 一个元组，第二个...类推
* `enumerate(iter)`                     :返回一个 enumerate 对象(迭代器)，enumerate 对象的每个元素是 iter 每个元素的 index 值和 item 值组成的元组

> 注意： iter 表示一个可迭代对象，list 表示一个序列， key 表示一个可以用于比较的回调函数。

### 字符串内建函数

* `s.isalnum()`                         : 如果 s 只包含字母或数字，则返回 True，否则返回 False
* `s.isalpha()`                         : 如果 s 只包含字母，则返回 True，否则返回 False
* `s.isdigit()`                         : 如果 s 只包含数字，则返回 True，否则返回 False
* `s.isdecimal()`                       : 如果 s 只包含十进制数字，则返回 True，否则返回 False
* `s.isnumeric()`                       : 如果 s 只包含数字字符，则返回 True，否则返回 False
* `s.islower()`                         : 如果 s 至少包含一个小写字符并且不包含大写字符，则返回 True，否则返回 False
* `s.isupper()`                         : 如果 s 至少包含一个大写字符并且不包含小写字符，则返回 True，否则返回 False
* `s.isspace()`                         : 如果 s 中只包含空格字符，则返回 True，否则返回 False
* `s.istitle()`                         : 如果 s 是标题化的(所有单词都是以大写开始，其余字母均为小写))，则返回 True，否则返回 False
<P/>

* `s.startswith(obj, beg=0,end=len(s))` : 检查字符串以 obj 开头，则返回 True，否则返回 False
* `s.endswith(obj, beg=0, end=len(s))`  : 检查字符串以 obj 结束，则返回 True，否则返回 False
<p/>

* `s.count(str, beg=0, end=len(s)) `    : 返回 str 在 s 里面出现的次数，beg 和 end 指定范围
* `s.find(str, beg=0, end=len(s))`      : 检测 str 是否包含在 s 中，如果是返回在 s 中开始的索引值，否则返回 -1
* `s.rfind(str, beg=0, end=len(s))`     : 类似 find() 方法，不过是从右边开始
* `s.index(str, beg=0, end=len(s))`     : 类似 find() 方法，只不过如果 str 不在 s 中会报一个异常
* `s.rindex(str, beg=0, end=len(s))`    : 类似 index() 方法，不过是从右边开始
<p/>

* `s.capitalize() `                     : 转换 s 中的第一个字符为大写
* `s.upper() `                          : 转换 s 中的所有小写字符为大写
* `s.lower()`                           : 转换 s 中的所有大写字符为小写
* `s.swapcase() `                       : 翻转 s 中的大小写
* `s.expandtabs(tabsize = N)`           : 转换 s 中的的 tab 为空格，格数为 N
* `s.title()`                           : 转换为"标题化"的 s，就是说所有单词都是以大写开始，其余字母均为小写
<p/>

* `s.ljust(width)`                      : 返回一个原字符串左对齐，并使用空格填充至长度 width 的新字符串
* `s.rjust(width)`                      : 返回一个原字符串右对齐，并使用空格填充至长度 width 的新字符串
* `s.center(width)`                     : 返回一个原字符串居中对齐，并使用空格填充至长度 width 的新字符串
* `s.zfill(width)`                      : 返回一个原字符串右对齐，并使用 0 填充至长度 width 的新字符串
*
* `s.lstrip(str)`                       : 默认截掉 s 首部的空格，如果传入 str，截掉从首部开始是 str 中的字符，遇到非 str 中的字符停止
* `s.rstrip(str)`                       : 默认截掉 s 尾部的空格，如果传入 str，截掉从尾部开始是 str 中的字符，遇到非 str 中的字符停止
* `s.strip(str)`                        : 默认截掉 s 首部和尾部的空格，同 lstrip 和 rstrip 共同作用
<p/>

* `s.partition(str)`                    : 从 str 出现的第一个位置起，把字符串 s 分成一个3元素的元组 (s_pre_str, str, s_post_str)，如果 s 中不包含 str 则返回 (s, '', '')
* `s.rpartition(str)`                   : 类似 partition() 方法，不过是从右边开始查找，如果 s 中不包含 str 则返回 ('', '', s)
* `s.split(str="", num=s.count(str))`   : 以 str 为分隔符切片 s，如果 num 有指定值，则仅分隔 num+1 个子字符串
* `s.splitlines(num=s.count('\n'))`     : 按照行分隔，返回一个包含各行作为元素的列表，如果 num 指定则仅切片 num+1 个行
* `s.join(str_iter)`                    : 以 s 作为分隔符，将 str_iter (字符串的序列或迭代器) 中所有的元素合并为一个新的字符串
* `s.replace(str1, str2, num=s.count(str1))` : 把 s 中的 str1 替换成 str2，如果 num 指定，则替换不超过 num 次
* `s.translate(str, del="")`            : 根据str给出的表(包含256个字符)转换 s 的字符，要过滤掉的字符放到 del 参数中
<p/>

* `s.decode(encoding='UTF-8', errors='strict')` : 以 encoding 指定的编码格式解码 s，如果出错默认报一个 ValueError 的异常，除非 errors 指定的是'ignore'或者 'replace'
* `s.encode(encoding='UTF-8', errors='strict')` : 以 encoding 指定的编码格式编码 s，如果出错默认报一个 ValueError 的异常，除非 errors 指定的是'ignore'或者 'replace'

```py
>>> '12345678123567'.find('56')
4
>>> '12345678123567'.rfind('56')
11
>>> '12345678123567'.partition('56')
('1234', '56', '78123567')
>>> '12345678123567'.rpartition('56')
('12345678123', '56', '7')
>>> '12345678123567'.partition('999')
('12345678123567', '', '')
>>> '12345678123567'.rpartition('999')
('', '', '12345678123567')
>>>
```

### 列表内建函数

* `list.append(obj)`                    : 向列表中添加一个对象 obj
* `list.count(obj)`                     : 返回一个对象 obj 在列表中出现的次数
* `list.extend(seq)`                    : 把序列 seq 的内容添加到列表中
* `list.index(obj, i=0, j=len(list))`   : 返回 `list[k] == obj` 的 k 值，并且 k 的范围在 `i<=k<j`；否则引发ValueError异常
* `list.insert(index, obj)`             : 在索引量为 index 的位置插入对象obj
* `list.pop(index=-1)`                  : 删除并返回指定位置的对象，默认是最后一个对象
* `list.remove(obj)`                    : 从列表中删除对象 obj
* `list.reverse()`                      : 原地翻转列表
* `list.sort(key=None, reverse=False)`  : 以指定的方式排序列表中的成员,如果 key 参数指定，则按照指定的方式比较各个元素，如果 reverse 标志被置为True，则列表以反序排列。
* `list.clear()`                        : 清空列表元素

```py
>>> aList = [(2, 2, 3), (3, 4, 2), (4, 1, 3), (1, 3, 9)]
>>> aList.sort()
>>> aList
[(1, 3, 9), (2, 2, 3), (3, 4, 2), (4, 1, 3)]
>>> aList.sort(reverse=True)
>>> aList
[(4, 1, 3), (3, 4, 2), (2, 2, 3), (1, 3, 9)]
>>> takeSecond = lambda L:  L[1]
>>> aList.sort(key=takeSecond)
>>> aList
[(4, 1, 3), (2, 2, 3), (1, 3, 9), (3, 4, 2)]
>>>
```

### 列表推导、简单生成器、字典推导

* `[expression_var for iter_var in iterable]`
* `[expression_var for iter_var in iterable if condition_var]`
    * 列表推导，通过中括号括起来的此类型的表达式是一个列表 list
    * python3中列表推导不会改变上下文中的同名变量，python2会改变

* `(expression_var for iter_var in iterable)`
* `(expression_var for iter_var in iterable if condition_var)`
    * 简单生成器，通过小括号括起来的此类型的表达式是一个生成器 generator

* `{expression_var1:expression_var2 for var1,var2 in iterable}`
    * 字典推导，iterable的元素为含有两个值的元组

```py
>>> cityList = ['Beijing', "Shanghai"]
>>> numList = [x for x in cityList[0]] # 类型推导
>>> numList
['B', 'e', 'i', 'j', 'i', 'n', 'g']
>>> numList2 = [x for y in cityList for x in y ]
>>> numList2
['B', 'e', 'i', 'j', 'i', 'n', 'g', 'S', 'h', 'a', 'n', 'g', 'h', 'a', 'i']
>>>
>>> a = [i**2 for i in range(4)]
>>> a
[0, 1, 4, 9]
>>> b = [i**2 for i in range(4) if i % 2 == 0]
>>> b
[0, 4]
>>> c = [(i,j) for i in range(2) for j in range(3)]
>>> c
[(0, 0), (0, 1), (0, 2), (1, 0), (1, 1), (1, 2)]
>>> type(c)
<class 'list'>
>>> d = ((i,j) for i in range(2) for j in range(3))
>>> d
<generator object <genexpr> at 0x7f3072d36fc0>
>>> type(d)
<class 'generator'>
>>>
>>> e = {a:b for a,b in [('a', 1), ('b', 2), ('c', 3)]}
>>> e
{'a': 1, 'c': 3, 'b': 2}
>>>
>>> type(e)
<type 'dict'>
>>>
```

## 映射和集合类型

### 字典(dict)

* 映射类型通常被称做哈希表
    * 哈希表的算法是获取键，对键执行一个叫做哈希函数的操作，并根据计算的结果，选择在数据结构的某个地址中来存储你的值
    * 任何一个值存储的地址皆取决于它的键，正因为这种随意性，哈希表中的值是没有顺序的
* 字典是 Python 语言中唯一的映射类型。
* 字典用大括号 `{ }` 包起来，字典的元素是键值对(`key:value`)，键和值用冒号 `:` 隔开；元素用 `逗号` 隔开；可以通过键改变值。
* 键必须是唯一的，但值则不必，创建字典时如果同一个键被赋值两次，后一个值会被记住
* 字典的键必须不可变，所以可以用数字、字符串、元组(不含可变元素)充当，而用列表、元组(含可变元素)、字典、集合就不行。
* 字典的值可以是任何的 Python 对象，既可以是标准的对象，也可以是用户定义的
* 字典是无序的，但可以通过 key 来进行索引，修改元素(key已经存在)或增加元素(key原先不存在)，通过 del 删除元素

```py
>>> type({})                            # 空字典
<class 'dict'>
>>> aDict = {'x':1, 'y':2}              # 创建一个字典
>>> aDict
{'y': 2, 'x': 1}
>>> aDict['x'] = 0                      # 如果键存在，更新这个键指向的值
>>> aDict
{'y': 2, 'x': 0}
>>> aDict['z'] = 3                      # 如果键不存在，添加新的键值对
>>> aDict
{'y': 2, 'x': 0, 'z': 3}
>>> del aDict['x']                      # 删除一个键值对
>>> aDict
{'y': 2, 'z': 3}
>>> del aDict                           # 删除整个字典
>>> aDict
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
NameError: name 'aDict' is not defined
>>>
>>> aDict = {}
>>> aDict[[1,2]] = 3                    # 列表不能作为键
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
TypeError: unhashable type: 'list'
>>> aDict[{'x':1}] = 3                  # 字典不能作为键
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
TypeError: unhashable type: 'dict'
>>> aDict[{1,2}] = 3                    # 集合不能作为键
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
TypeError: unhashable type: 'set'
>>> aDict[([1,2],3)] = 3                # 包含可变元素的元组不能作为键
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
TypeError: unhashable type: 'list'
>>> aDict[(1,2,3)] = 3                  # 不包含可变元素的元组可以作为键
>>> aDict
{(1, 2, 3): 3}
>>> dict(x=1, y=2)
{'y': 2, 'x': 1}
>>>
```

### 字典方法

* `dict([container])`                   : 创建字典的工厂函数。如果提供了容器类(container)，就用其中的条目填充字典，否则就创建一个空字典。
* `len(mapping)`                        : 返回映射的长度(键-值对的个数)
* `hash(obj)`                           : 返回obj的哈希值
<p/>

* `dict.items()`                        : 返回一个包含字典中(键, 值)对元组的列表
* `dict.keys()`                         : 返回一个包含字典中键的列表
* `dict.values()`                       : 返回一个包含字典中所有值的列表
* `dict.iteritems()`                    : 返回一个包含字典中(键, 值)对元组的迭代子
* `dict.iterkeys()`                     : 返回一个包含字典中键的迭代子
* `dict.itervalues()`                   : 返回一个包含字典中所有值的迭代子
<p/>

* `dict.clear()`                        : 删除字典中所有元素
* `dict.copy()`                         : 返回字典(浅复制)的一个副本
* `dict.fromkeys(seq, val=None)`        : 创建并返回一个新字典，以 seq 中的元素做该字典的键，val 做该字典中所有键对应的初始值。
* `dict.get(key, default=None)`         : 对字典 dict 中的键 key，返回它对应的值 value，如果字典中不存在此键，则返回 default 的值。
* `dict.has_key(key)`                   : 如果键 key 在字典中存在，返回 True，否则返回 False。现在使用 in 和 not in 操作符。
* `dict.pop(key[, default])`            : 和方法 get() 相似，如果字典中 key 键存在，删除并返回 dict[key]，如果 key 键不存在，且没有给出 default 的值，引发 KeyError 异常。
* `dict.setdefault(key, default=None)`  : 和方法 set() 相似，如果字典中不存在 key 键，由 dict[key] = default 为它赋值。
* `dict.update(dict2)`                  : 将字典 dict2 的键-值对添加到字典 dict

### 集合(set)和不可变集合(frozenset)

* 集合是一个无序不重复元素的序列。集合用大括号 `{ }` 包起来，元素不是键值对，元素用逗号隔开
* 可变结合可以通过 `set()` 创建， 不可变集合通过 `frozenset()` 创建。
* 可以通过序列(字符串、列表、元组)、字典、集合 等新建或更新集合
* 创建一个空集合必须用 `set()` 而不是` { }`，因为 `{ }` 是用来创建一个空字典
* 集合是无序的，所以不支持索引

```py
>>> type({})                            # 空的大括号是空字典
<class 'dict'>
>>> type(set())                         # 空集合
<class 'set'>
>>> type(frozenset())                   # 空不可变集合
<class 'frozenset'>
>>> frozenset("abc")
frozenset({'a', 'c', 'b'})
>>>
>>> A = {1, 2, 3}                       # 直接新建一个集合
>>> B = set("abc")                      # 通过字符串新建一个集合
>>> C = set([4, 5, 6])                  # 通过列表新建一个集合
>>> D = set((7, 8, 9))                  # 通过元组新建一个集合
>>> E = set({'a':10, 'b':11, 'c':12})   # 通过字典新建一个集合
>>> F = set({13, 14, 15})               # 通过集合新建一个集合
>>> print(A, B, C, D, E, F, sep='\n')
{1, 2, 3}
{'a', 'c', 'b'}
{4, 5, 6}
{8, 9, 7}
{'a', 'c', 'b'}
{13, 14, 15}
>>> H = set(1, 2, 3)
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
TypeError: set expected at most 1 arguments, got 3
>>>
>>> H = set(("abc"))                    # 通过字符串新建一个集合
>>> I = set(("abc",))                   # 通过元组新建一个集合
>>> J = set(["abc"])                    # 通过列表新建一个集合
>>> K = set({"abc"})                    # 通过集合新建一个集合
>>> print(H, I, J, K, sep='\n')
{'a', 'c', 'b'}
{'abc'}
{'abc'}
{'abc'}
>>>
```

### 集合方法

* 当用操作符时，操作符两边的操作数必须是集合；在使用内建方法时，对象也可以是迭代类型的

* 运算符

* `a   in   A`                          : `a ∈ A` ，元素a是否是集合A的成员
* `a not in A`                          : `a ∉ A` ，元素a是否不是集合A的成员
* `A   ==   B`                          : `A = B` ，集合A是否等于集合B
* `A   !=   B`                          : `A ≠ B` ，集合A是否不等于集合B
* `A   <    B`                          : `A ⊂ B` ，集合A是否是集合B的严格子集
* `A   <=   B`                          : `A ⊆ B` ，集合A是否是集合B的子集
* `A   >    B`                          : `A ⊃ B` ，集合A是否是集合B的严格超集
* `A   >=   B`                          : `A ⊇ B` ，集合A是否是集合B的超集
<p/>

* `A   |    B`                          : `A ∪ B` ，集合A和集合B并集
* `A   &    B`                          : `A ∩ B` ，集合A和集合B交集
* `A   -    B`                          : `A - B` ，集合B对集合A的相对补集
* `A   ^    B`                          : `A ∆ B` ，集合A和集合B对称差分集

* 通用集合方法

* `s.issubset(t)`                       : `s <= t` ，如果 s 是 t 的子集,则返回 True,否则返回 False
* `s.issuperset(t)`                     : `s >= t` ，如果 t 是 s 的超集,则返回 True,否则返回 False
* `s.union(t)`                          : `s |  t` ，返回一个新集合,该集合是 s 和 t 的并集
* `s.intersection(t)`                   : `s &  t` ，返回一个新集合,该集合是 s 和 t 的交集
* `s.difference(t)`                     : `s -  t` ，返回一个新集合,该集合是 s 的成员,但不是 t 的成员
* `s.symmetric_difference(t)`           : `s ^  t` ，返回一个新集合,该集合是 s 或 t 的成员,但不是 s 和 t 共有的成员
<p/>

* `s.set(t)`                            : 通过迭代类型 t 创建一个可变集合
* `s.frozenset(t)`                      : 通过迭代类型 t 创建一个不可变集合
* `s.copy()`                            : 返回一个新集合，它是集合 s 的浅复制
* `len(s)`                              : 集合 s 中元素的个数

* 可变集合方法

* `s.update(t)`                         : `s |= set(t)` ，将 t 中不同的元素添加到 s
* `s.intersection_update(t)`            : `s &= set(t)` ，s 中的成员是共同属于 s 和 t 的元素。
* `s.difference_update(t)`              : `s -= set(t)` ，s 中的成员是属于 s 但不包含在 t 中的元素
* `s.symmetric_difference_update(t)`    : `s ^= set(t)` ，s 中的成员是包含在 s 或 t 中，但不是 s 和 t 共有的元素
<p/>

* `s.add(obj)`                          : 在集合s中添加对象obj
* `s.remove(obj)`                       : 从集合s中删除对象obj；如果obj不是集合s中的元素(obj not in s)，将引发KeyError错误
* `s.discard(obj)`                      : 如果obj是集合s中的元素，从集合s中删除对象obj；
* `s.pop()`                             : 删除集合s中的任意一个对象，并返回它
* `s.clear()`                           : 删除集合s中的所有元素

## 类型总结

| 数据类型   | 存储模型 | 更新模型 | 访问模型 | 类型工厂函数 |
| ---        | ---      | ---      | ---     | --- |
| 数字       | 标量     | 不可变   | 直接访问 | int(), bool(), float(), complex() |
| 字符串     | 标量     | 不可变   | 顺序访问 | str() |
| 列表       | 标量     | 可变     | 顺序访问 | list() |
| 元组       | 容器     | 不可变   | 顺序访问 | tuple() |
| 字典       | 容器     | 可变     | 映射访问 | dict() |
| 可变集合   | 容器     | 可变     | 映射访问 | set() |
| 不可变集合 | 容器     | 不可变   | 映射访问 | frozenset() |

## 运算符

### 运算优先级

* 可以 `help('运算符')` 查看运算符优先级，例如 `help('+')`
* 优先级由高到低，前面`@`表示优先级降低，前面空白表示和上面的`@`的优先级一样
* 与C语言相比，逻辑非(not)的优先级有变化，其它优先级基本相同
* 算术和位逻辑运算符的内建函数 `__xxx__` 加上r改为反向形式 `__rxxx__`

|pro| 运算符   | 对应的内建函数  | 功能 |
| -- | ---     | ---             | --- |
| @ | `.`      |                 | 取成员或属性 |
|   | `[]`     |                 | 序列操作 |
| @ | `**`     | `__pow__`       | 乘方 pow() |
| @ | `~`      | `__invert__`    | 按位取反 |
|   | `+`      | `__neg__`       | 正号 |
|   | `-`      | `__pos__`       | 符号 |
| @ | `*`      | `__mul__`       | 乘，序列重复 |
|   | `/`      | `__truediv__`   | 真正除 |
|   | `//`     | `__floordiv__`  | 地板除 |
|   | `%`      | `__mod__`       | 取余 |
| @ | `+`      | `__add__`       | 加，序列连接 |
|   | `-`      | `__sub__ `      | 减 |
| @ | `<<`     | `__lshift__`    | 左移 |
|   | `>>`     | `__rshift__`    | 右移 |
| @ | `&`      | `__and__`       | 按位与 |
| @ | `^`      | `__xor__`       | 按位异或 |
| @ | `|`      | `__or__`        | 按位或 |
| @ | `<`      | `__lt__`        | 小于，支持 3 < 4 < 5格式 |
|   | `<=`     | `__le__`        | 小于等于 |
|   | `>`      | `__gt__`        | 大于 |
|   | `>=`     | `__ge__`        | 大于等于 |
|   | `==`     | `__eq__`        | 相等 |
|   | `!=`     | `__ne__`        | 不等 |
|   | `is`     |                 | 是指向同一个对象， 即 `id(obj1) = id(obj2)` |
|   | `is not` |                 | 不是指向同一个对象 |
|   | `in`     |` __contains__`  | 是成员 |
|   | `not in` |                 | 不是成员 |
| @ | `not`    |                 | 逻辑非 |
| @ | `and`    |                 | 逻辑与 |
| @ | `or`     |                 | 逻辑或 |
| @ | `= `     |                 | 普通赋值 |
|   | `**=`    | `__ipow__`      | 乘方赋值 |
|   | `*=`     | `__imul__`      | 乘赋值 |
|   | `/=`     | `__itruediv__`  | 真正除赋值 |
|   | `//=`    | `__ifloordiv__` | 地板除赋值 |
|   | `%=`     | `__imod__`      | 取余赋值 |
|   | `+=`     | `__iadd__`      | 加赋值 |
|   | `-=`     | `__isub__`      | 减赋值 |
|   | `<<=`    | `__ilshift__`   | 左移赋值 |
|   | `>>=`    | `__irshift__`   | 右移赋值 |
|   | `&=`     | `__iand__`      | 按位与赋值 |
|   | `^=`     | `__ixor__`      | 按位异或赋值 |
|   | `|=`     | `__ior__`       | 按位或赋值 |

* 其它算术内建函数
    * `abs()`       : `__abs__`         : 取绝对值或复数的模
    * `divmod()`    : `__divmod__`      : 返回一个包含商和余数的元组 (a // b, a % b)
    * `round()`     : `__round__`       : 返回四舍五入值，
        * `round(值, 小数点位数)`，如果返回的小数部分末尾是0，会去掉多余的0
        * `round(1.000056, 3)` 返回1.0; `round(1.120056, 3)` 返回1.12; `round(1.123056, 3)` 返回1.123

* 身份
    `obj1 is obj2`                      : obj1 和 obj2 是同一个对象，id(obj1) == id(obj2)
    `obj1 is not obj2`                  : obj1 和 obj2 不是同一个对象，id(obj1) != id(obj2)

* 算数
    `+`    `-`    `*`    `/`    `//`    `%`    `**`

```py
>>> (10/2, 10.0/2, 10/2.0, 10.0/2.0, -10/2, 10/-2, -10/-2)          # 真正除总是返回浮点数
(5.0, 5.0, 5.0, 5.0, -5.0, -5.0, 5.0)
>>> (10//3, 10.0//3, 10//3.0, 10.0//3.0, -10//3, 10//-3, -10//-3)   # 地板除，被除数绝对值a, 除数绝对值b, 值绝对值c，同符号 a > b*c，异符号 a < b*c
(3, 3.0, 3.0, 3.0, -4, -4, 3)
>>> (10%3, 10.0%3, 10%3.0, 10.0%3.0, -10%3, 10%-3, -10%-3)          # 取余，返回值符号与除数相同
(1, 1.0, 1.0, 1.0, 2, -2, -1)
>>> (10**2, 10.0**2, 10**2.0, 10.0**2.0,-10**2, 10**-2, -10**-2)    # 幂运算
(100, 100.0, 100.0, 100.0, -100, 0.01, -0.01)
>>>
```

* 移位
    `<<`    `>>`

* 比较
    `<`    `<=`    `>`    `>=`    `==`    `!=`

* 位逻辑
    `~`    `&`    `^`    `|`

* 逻辑
    `not`    `and`    `or`

* 赋值
    `=`    `+=`    `-=`    `*=`    `/=`    `//=`    `%=`    `**=`    `<<=`    `>>=`    `&=`    `^=`    `|=`

    * Python 的赋值语句不会返回值，可以链式赋值和多重赋值
        * `a=b=1` 链式赋值无问题
        * `a=(b=1)` 赋值语句不会返回值，这条语句报错
        * `x, y = y, x` 多重赋值可以实现无需中间变量交换两个变量的值
    * 不支持C语言中的自增 `++` 和自减 `--` 运算符
    * 普通赋值和增量赋值是有区别的，增量赋值不会改变可变容器对象(列表、字典、集合)的id

```py
>>> m = (n = 1)                         # Python 的赋值语句不会返回值
  File "<stdin>", line 1
    m = (n = 1)
           ^
SyntaxError: invalid syntax
>>> x = y = 1                           # Python 可以链式赋值。
>>> x, y
(1, 1)
>>> x, y, z = 1, "abc", ["list", 4]     # Python 可以多重赋值，实际上当做了元组
>>> x, y, z
(1, 'abc', ['list', 4])
>>>
>>> aList = [1, 2, 3]
>>> id(aList)
140591146347912
>>> aList += [4, 5, 6]                  # 增量赋值没有改变list的id
>>> id(aList)
140591146347912
>>> aList = aList + [4, 5, 6]           # 运算后赋值改变了list的id
>>> id(aList)
140591145753928
>>> bList = aList                       # 直接赋值id相等
>>> id(bList)
140591145753928
>>>
>>> aTuple = (1, 2, 3)
>>> id(aTuple)
140591183302088
>>> aTuple += (4, 5, 6)                 # 增量赋值改变了tuple的id
>>> id(aTuple)
140591103283368
>>> aTuple = aTuple + (7, 8, 9)         # 运算后赋值改变了tuple的id
>>> id(aTuple)
140591120822088
>>> bTuple = aTuple                     # 直接赋值id相等
>>> id(bTuple)
140591120822088
>>>
```

## 语句

### 条件语句

* if 语句

```py
if expression:
    expr_true_suite
```
*  if-else 语句

```py
if expression:
    expr_true_suite
else:
    expr_false_suite
```

* if-elif-else 语句

```py
if expression1:
    expr1_true_suite
elif expression2:
    expr2_true_suite
...
elif expressionN:
    exprN_true_suite
else:
    none_of_the_above_suite
```

* 条件表达式

```py
expr_true_suite if expression else expr_false_suite
```

* Python 没有 switch-case 条件语句

* 解析一串字符串为list
    * 空格作为分隔符，但引号内的字符串为一个整体(即使有空格)

```py
def parse_str_to_list(vstr, parse_slash=True):
    vstr=vstr.strip()
    vlist, var, quote, slash= [], '', '', False
    for v in vstr:
        if var != '' and var[-1] == '\\' and slash == False:
            if parse_slash:
                if   v == ' '  : var = var[:-1] + ' '
                elif v == 'r'  : var = var[:-1] + '\r'
                elif v == 'n'  : var = var[:-1] + '\n'
                elif v == 't'  : var = var[:-1] + '\t'
                elif v == 'v'  : var = var[:-1] + '\v'
                elif v == '\'' : var = var[:-1] + '\''
                elif v == '"'  : var = var[:-1] + '"'
                elif v == '\\' : var = var[:-1] + '\\'; slash = True; continue
                else           : var += v
            else:
                if   v == '\\' : var += v; slash = True; continue
                else           : var += v
        else:
            if quote:
                if v == quote:
                    vlist.append(var)
                    var = ''
                    quote = ''
                else:
                    var += v
            else:
                if var:
                    if v == ' ' or v == '\t':
                        vlist.append(var)
                        var = ''
                    else:
                        var += v
                else:
                    if v == ' ' or v == '\t':
                        pass
                    elif v == '\'' or v == '"':
                        quote = v
                    else:
                        var += v
        slash = False
    if var:
        vlist.append(var)
    return vlist
```

### 循环语句

* while 中的代码块会一直循环执行，直到循环条件不再为真
* for-in 可以遍历序列成员，可以用在列表解析和生成器表达式中，它会自动地调用迭代器的 next() 方法，捕获 StopIteration 异常并结束循环
* `else` 语句块只有在 while 循环条件为假, 或 for 循坏遍历完成才会运行
* `break` 退出循环不会运行 else 语句块
<p/>

* while 循环

```py
while expression:
    suite_to_repeat
```

* while-else 循环

```py
while expression:
    suite_to_repeat
else:
    expr_false_suite
```

* for-in 循环

```py
for iter_var in iterable:
    suite_to_repeat
```

* 遍历字典

```py
for key, value in student.items():
    suite_to_repeat
for key in student.keys():
    suite_to_repeat
for value in student.values():
    suite_to_repeat
```

* for-in-else 循环

```py
for iter_var in iterable:
    suite_to_repeat
else:
    expr_false_suite
```

### 控制语句

* `break` 语句
    * Python 中的 break 语句可以结束当前循环然后跳转到循环外的下条语句，类似C中的传统 break
    * break 语句可以用在 while 和 for 循环中

* `continue` 语句
    * 当遇到 continue 语句时，程序会终止当前循环，并忽略剩余的语句，然后回到循环的顶端
    * 在开始下一次迭代前，如果是条件循环，我们将验证条件表达式；如果是迭代循环，我们将验证是否还有元素可以迭代
    * 只有在验证成功的情况下，我们才会开始下一次迭代。continue 语句可以用在 while 和 for 循环中

* `pass` 语句
    * 由于 Python 没有符号表示空语句，所以 Python 提供了 pass 语句，它不做任何事情———即 NOP(No OPeration，无操作)

### 迭代器

* `iter(obj)`                           : 生成一个迭代器
    * 生成一个迭代器，obj 一般是字符串、列表、元组
    * obj 也可以是一个实现了 `__iter__` 和 `__next__` 方法的类的实例
    * 字典的迭代器会遍历它的键
    * 文件的迭代器会遍历它的行

* `next(iter_name)`                     : 获取移动到下一个元素的迭代器
    * 返回取出当前元素，并且迭代器的位置指向下一个元素
    * 条目全部取出后(迭代完成)，再次调用next()会引发一个 StopIteration 异常
    * 迭代器只能向后移动，不能向前移动，不能复制一个迭代器

* `range([[start=0,]stop[,step=1])`     : 返回一个整数列表
    * 起始值为 start, 结束值为 stop-1; start 默认值为 0， step 默认值为 1
    * 三种形式: `range(stop)` `range(start, stop)`  `range(start, stop, step)`

* 一个迭代器的类

```py
class Count:
    def __init__(self, max):
        self.cnt = 1
        self.max = max
    def __iter__(self):
        return self
    def __next__(self):
        if self.cnt <= self.max:
            x = self.cnt
            self.cnt += 1
            return x
        else:
            raise StopIteration
```

```py
>>> cityList = ['Beijing', "Shanghai", 'Guangzhou', 'Shenzheng']
>>> for city in cityList:
...     print(city)
...
Beijing
Shanghai
Guangzhou
Shenzheng
>>> for index in range(len(cityList)):
...     print(cityList[index])
...
Beijing
Shanghai
Guangzhou
Shenzheng
>>> for index, city in enumerate(cityList):
...     print(index, city)
...
0 Beijing
1 Shanghai
2 Guangzhou
3 Shenzheng
>>>
>>> cityIter = iter(cityList)           # 生成一个迭代器
>>> while True:
...     try:
...         print(next(cityIter))
...     except StopIteration:
...         print("Iter is end!")
...         break                       # 必须退出，否则一直运行 next() 触发异常
...
Beijing
Shanghai
Guangzhou
Shenzheng
Iter is end!
>>> next(cityIter)                      # 迭代器next()会改变cityIter
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
StopIteration
>>>
```

### 生成器generator

* 在Python中，使用了 `yield` 的函数被称为生成器
* 生成器是一个返回迭代器对象的函数，只能用于迭代操作，调用一个生成器函数，返回的是一个迭代器对象
* 在调用生成器运行的过程中，每次遇到 yield 时函数会暂停并保存当前所有的运行信息，返回 yield 的值，并在下一次执行 next() 方法时从当前位置继续运行
* 在一个生成器中，如果没有 return，则默认执行至函数完毕，如果在执行过程中 return，则直接抛出 StopIteration 终止迭代
* 生成器表达式背后遵守了迭代器协议，可以逐个地产出元素，而不是先建立一个完整的列表，能够节省内存。

```py
>>> def cityYield():
...     cityList = ['Beijing', "Shanghai", 'Guangzhou', 'Shenzheng']
...     for city in cityList:
...         yield city                  # 使用了 yield 的函数被称为生成器
...
>>> cityIter = cityYield()              # 生成器是一个返回迭代器的函数
>>> type(cityIter)
<class 'generator'>
>>> while True:
...     try:
...         print(next(cityIter))
...     except StopIteration:
...         print("Iter is end!")
...         break                       # 必须退出，否则一直运行 next() 触发异常
...
Beijing
Shanghai
Guangzhou
Shenzheng
Iter is end!
>>>
>>> def IterCount(max):
...     cnt = 1
...     while cnt < max:
...         x = cnt
...         cnt += 1
...         print('iter', x)
...         yield x
...
>>> aIter = IterCount(4)
>>> aIter
<generator object IterCount at 0x7f3072d5d1a8>
>>> for i in aIter:
...     print(i)
...
iter 1
1
iter 2
2
iter 3
3
>>>
```

### 例子

* 例1：将一组数字从小到大排序

```py
def insert_list(new, list2):
    length = len(list2)
    min = 0
    max = length-1
    if length == 0:
        list2.append(new)
    elif new >= list2[max]:
        list2.append(new)
    elif new <= list2[max]:
        list2.insert(0, new)
    else:
        while min != max:
            if(new < list2[(min+max)//2]):
                max = (min+max)//2
            else:
                min = (min+max)//2 + 1
        else:
            list2.insert(min, new)

def order_list(list1):
    list2 = []
    for i in list1:
        insert_list(i,list2)
    print(list2)
```

* 例2：狗狗年龄换算人的年龄 gougou.py

```py
#!/usr/bin/python3

def gougou():                           # 定义函数
    '''
    狗狗年龄对比系统
    输入大于0的数字，返回人的年龄'''
    control = ""
    retry_times = 0
    print("欢迎进入狗狗年龄对比系统")
    while control != 'Q' and control != 'q':
        control = input("请输入Q退出，或输入您家狗狗的年龄: ")
        if control == 'Q' or control == 'q':
            continue                    # continue 是跳过后面语句直接开始下次循环
        try:
            age = float(control)
            retry_times = 0
            if age < 0:
                print("您在逗我？")
            elif age == 1:
                print("相当于人类14岁")
            elif age == 2:
                print("相当于人类22岁")
            else:
                human = 22 + (age-2) * 5
                print("相当于人类%d岁" % human)
        except ValueError:              # 错误处理
            retry_times += 1
            if retry_times <= 3:
                print("输入不合法，请输入有效年龄")
            else:
                print("连续输入不合法大于3次，强制退出")
                break                   # break 终止循环，不会运行 else 语句块
    else:                               # while 条件为假正常终止循环会运行 else 语句块
        print("退出狗狗年龄对比系统")

if __name__ == '__main__':              # 直接运行此文件则作为main函数
    gougou()
```

* 例3：九九乘法表

```py
def print99mula():
    for i in range(1, 10):
        for j in range(1, i+1):
            print("%dx%d=%02d" % (j, i, j*i), end="\t")
        print()

def print99mulb():
    for i in range(9, 0, -1):
        for j in range(1, i):
            print("\t",end="")
        for k in range(i, 10):
            print("%dx%d=%02d" % (i, k, k*i), end="\t")
        print()
```

## 函数

### 定义函数

```py
def func_name(arguments):
    "function_documentation_string"
    function_body_suite

# 非关键字参数
def func_name(arg1, arg2, arg3):
    func_suite

# 关键字参数
def func_name(arg1, arg2, arg3 = value3):
    func_suite

# 参数组
def func_name(*tuple_grp_nonkw_args, **dict_grp_kw_args):
    func_suite
```

* 函数的子句由声明的标题行以及随后的定义体组成的，放在同一个文件
* Python 不允许在函数未声明之前对其进行调用，但允许在函数定义中使用未声明的函数
* 参数的顺序为 非关键字参数，关键字参数，非关键字参数组，关键字参数组

### 参数传递

* 不可变类型：类似 C++ 的值传递，如 整数、字符串、元组，内部修改参数的值，只是修改另一个复制的对象，不会影响本身
* 可变类型：类似 C++ 的引用传递，如 列表、字典，内部修改参数的值，会影响本身
* 原理：
    * 对可更改类型的属性进行操作，这只是对引用的内存块里面的值进行操作，引用并没变，自然所有引用它的对象的值都变了
    * 而对不可更改的对象进行操作，因为它引用的内存块只是对应一个固定的值，不能进行修改，要重新复制实际上就是更新引用

```py
>>> aList = [1, 2, 3]
>>> aTuple = (1, 2, 3)
>>> def aFunc(abc):
...     abc *= 2
...
>>> print(aList);aFunc(aList);print(aList)
[1, 2, 3]
[1, 2, 3, 1, 2, 3]
>>> print(aTuple);aFunc(aTuple);print(aTuple)
(1, 2, 3)
(1, 2, 3)
>>>
```

### 参数类型

* 使用关键字参数允许函数调用时参数的顺序与声明时不一致
* 定义函数时，默认参数不在最后，会报错；调用函数时，如果没有传递参数，则会使用默认参数
* 加了星号 `*` 的参数会以元组(tuple)的形式传入。星号 `*` 后的参数必须用关键字传入
* 加了两个星号 `**` 的参数会以字典的形式传入

```py
>>> def printa(a, *b):
...     print(a)
...     for i in b: print(i)
...
>>> def printb(a, **b):
...     print(a)
...     for i in b.values(): print(i)
...
>>> printa(1, 2, 3)
1
2
3
>>> printb(1, b1=2, b2=3)
1
3
2
>>>
>>> def printc(a, *b, c):
...     print(a)
...     for i in b: print(i)
...     print(c)
...
>>> printc(1, 2)
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
TypeError: printc() missing 1 required keyword-only argument: 'c'
>>> printc(1, 2, 3)
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
TypeError: printc() missing 1 required keyword-only argument: 'c'
>>> printc(1, 2, c=3)                   # 星号 * 后的参数必须用关键字传入
1
2
3
>>>

>>> record = ('Dave', 'dave@example.com', '773-555-1212', '847-555-1212')
>>> name, email, *phone_numbers = record # 注意 星号 * 的不同意义，多项赋值中当做了列表
>>> phone_numbers
['773-555-1212', '847-555-1212']
>>>
>>> def abc(arg_1, *arg_t, **arg_d):
...     print(arg_1, arg_t, arg_d)
...
>>> abc(1, 2, 3, 'a'=1, 'b'=2, 'c'=3)
  File "<stdin>", line 1
SyntaxError: keyword can't be an expression
>>> abc(1, 2, 3, a=1, b=2, c=3)
1 (2, 3) {'a': 1, 'b': 2, 'c': 3}
>>>
>>> abc(1, 2, 3, 4)
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
TypeError: abc() missing 1 required keyword-only argument: 'arg_2'
>>> abc(1, 2, 3, arg_2=4)
1 (2, 3) 4
>>>
```

### 返回值

* 函数返回值数目为 0 时返回值类型是 NoneType
* 函数返回值数目为 1 时返回值类型是 obiect 的类型
* 函数返回值数目为 >1 时返回值类型是 tuple

```py
>>> def aFunc(): pass
...
>>> def bFunc(): return 0
...
>>> def cFunc(): return 0, 1, 2
...
>>> aFunc(), bFunc(), cFunc()
(None, 0, (0, 1, 2))
>>> type(aFunc()), type(bFunc()), type(cFunc())
(<class 'NoneType'>, <class 'int'>, <class 'tuple'>)
>>>
```

### 匿名函数 lambda

* 定义 `func_name = lambda arg1, arg2, ..., argn: expression`
    * 使用lambda定义一个匿名函数，lambda后面接着逗号分隔的参数(可以为空)，然后数冒号，最后是表达式
    * lambda 函数拥有自己的命名空间，且不能访问自己参数列表之外或全局命名空间里的参数

```py
>>> mypow = lambda a: a**2
>>> mypow(10)
100
>>>
```

### 闭包函数

```py
def funcA(arguments):
    funcA_suite
    def funcB(arguments):
        funcB_suite
```

* 闭包从表现形式上定义(解释)为：如果在一个内部函数里，对在外部作用域(但不是在全局作用域)的变量进行引用，那么内部函数就被认为是闭包(closure)
* 闭包函数可以访问上层函数的变量，上层函数可以调用闭包函数，但上层函数外部不可以调用闭包函数
* Python闭包函数所引用的外部自由变量是延迟绑定的，解决方法是生成闭包函数的时候立即绑定(使用函数形参的默认值):
* 禁止在闭包函数内对引用的自由变量进行重新绑定，解决方法是打算修改闭包函数引用的自由变量时, 可以将其放入一个list

```c
>>> flist = []
>>> for i in range(3):
...     def foo(x): print (x + i)       # i是闭包函数引用的外部作用域的自由变量, 只有在内部函数被调用的时候才会搜索变量i的值, 由于循环已结束, i指向最终值2
...     flist.append(foo)
...
>>> for f in flist:
...     f(2)
...
4
4
4
>>> flist = []
>>> for i in range(3):
...     def foo(x, y=i): print (x + y)  # 生成闭包函数的时候立即绑定(使用函数形参的默认值)
...     flist.append(foo)
...
>>> for f in flist:
...     f(2)
...
2
3
4
>>>

```

* 例：斐波那契数列

```py
#!/usr/bin/python3

def fib(n):
    dic = {0:0, 1:1}                    # 定义函数时的环境
    def fib_child(n):                   # 函数块
        if n in dic:
            return dic[n]
        else:
            temp = fib_child(n-1)+fib_child(n-2)
            dic[n] = temp
            return temp
    return fib_child(n)
```

### 变量作用域

* Python的作用域一共有4种，分别是：
    * L (Local)                         : 局部作用域
    * E (Enclosing)                     : 嵌套作用域，闭包函数外的函数中
    * G (Global)                        : 全局作用域
    * B (Built-in)                      : 内建作用域
* 以 `L –> E –> G –>B` 的规则查找
    * 即：在局部找不到，便会去局部外的局部找（例如闭包），再找不到就会去全局找，再者去内建中找
* 只有模块 module，类 class 以及函数 def、lambda 才会引入新的作用域
* 它的代码块(如 if/elif/else/、try/except、for/while 等)不会引入新的作用域的，也就是说这些语句内定义的变量，外部也可以访问
* 可变对象：可以访问并修改外层作用域对象，无需事先声明
* 不可变对象：可以访问外层作用于不可变对象，但不能更新(修改)其值
    * 如果要修改全局作用域的不可变对象，必须使用 `global` 声明
    * 如果要修改嵌套作用域中的不可变对象，必须使用 `nonlocal` 声明

```py
>>> a = 10
>>> def test():
...     a = a + 1
...     print(a)
...
>>> test()
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
  File "<stdin>", line 2, in test
UnboundLocalError: local variable 'a' referenced before assignment
>>>
```

### 装饰器

* 装饰器本质上是一个 Python 函数或类，它可以让其他函数或类在不需要做任何代码修改的前提下增加额外功能
* 装饰器的返回值也是一个函数/类对象。它经常用于有切面需求的场景，比如：插入日志、性能测试、事务处理、缓存、权限校验等场景，装饰器是解决这类问题的绝佳设计
* `@` 符号就是装饰器的语法糖，它放在函数开始定义的地方，这样就可以省略最后一步再次赋值的操作
* 一个函数还可以同时定义多个装饰器，它的执行顺序是从里到外，最先调用最里层的装饰器，最后调用最外层的装饰器，它等效于 `f = a(b(c(f)))`

```py
@a
@b
@c
def f():
```

* 例 ：装饰器

```py
import logging

def use_logging(func):
    def wrapper():
        logging.warn("%s is running" % func.__name__)
        return func()
    return wrapper

@use_logging
def foo():
    print("i am foo")

foo()                                   # use_logging(foo)()
```

输出

```
WARNING:root:foo is running
i am foo
```

## 异常

### 抛出捕获异常

```py
# try-except-finally
try:
    try_suite
except SomeError:
    except_suite
except SomeError2 as e:
    except_suite2
except (SomeError3, SomeError4):
    except_suite3_4
except (SomeError5, SomeError6) ad e:
    except_suite5_6
except:
    except_suite
finally:
    finally_suite

# try-except-else
try:
    try_suite
except SomeError1:
    except_suite1
else:
    else_suite
```

* 步骤
    * 首先，执行try子句
    * 如果在执行try子句的过程没有异常发生，忽略except子句，try子句执行完成后结束
    * 如果在执行try子句的过程中发生了异常，那么try子句余下的语句将被忽略，跳转到except子句
    * 如果异常的类型和except之后的类型相符，那么对应的except子句将被执行
    * 如果一个异常没有与任何的except匹配，那么这个异常将会传递给上层的try中
    * 如果一个异常最终没有与任何的except匹配，默认终止程序

* 其他说明
    * try子句抛出的是异常类的实例，而不是异常类的类型
    * 可以用as获取错误类型的实例，except SomeError2 as e: e是SomeError2类型的一个实例，子句可以访问e对象的成员
    * 一个try语句可能包含多个except子句，分别来处理不同的特定的异常，最多只有一个分支会被执行
    * 一个except子句可以同时处理多个异常，这些异常将被放在一个括号里成为一个元组
    * 最后一个except子句可以忽略异常的名称(可选)，它将被当作通配符使用
    * 放在所有的except子句之后的finally子句(可选)，无论try子句是否抛出异常，**finally** 子句都会执行
    * 放在所有的except子句之后的 **else** 子句(可选)，将在try子句没有发生任何异常的时候执行
    * finally子句和else子句不能同时存在

```py
with command as var:
    with_suite
```

* 将command的值赋值给var
* 如果command没有异常，执行with_suite子句
* 如果command抛出异常，自动执行command的清理操作(finally子句)

```py
class SomeError(Exception):
```

* 自定义异常类必须继承自 Exception 类，可以直接继承，或者间接继承。

```py
raise
```
* 一般用在expect子句中，将当前异常实例再次抛出

```py
raise SomeError(value)
```

* SomeError是一个异常类，value是实例化异常类的参数，根据SomeError的 `__init__` 函数的参数确定。

```py
raise SomeErrorVar
```

* 将一个异常实例抛出，可以直接raise标准错误类型，此时用空字符串实例了类型。

### 举例

* try-except-finally例子

```py
def show_age():
    while True:
        try:
            age = int(input("Please enter your age: "))
            if age < 0:
                print("Are you kidding me?");
            elif age < 7:
                print("You are a child.");
            elif age < 18:
                print("You are a teenager.");
            elif age < 41:
                print("You are a young man.");
            elif age < 65:
                print("You are a middle-aged man.");
            else:
                print("You are an old man.");
        except ValueError as e:
            print(e)
        finally:                        # finally子句无论try子句有没有抛出异常都会执行
            yes = input("If you need to try again, please enter Y/y: ")
            if 'Y' != yes and 'y' != yes:
                print("exit...")
                break
```

* try-except-else例子

```py
def show_age():
    while True:
        try:
            age = int(input("Please enter your age: "))
            if age < 0:
                print("Are you kidding me?");
            elif age < 7:
                print("You are a child.");
            elif age < 18:
                print("You are a teenager.");
            elif age < 41:
                print("You are a young man.");
            elif age < 65:
                print("You are a middle-aged man.");
            else:
                print("You are an old man.");
        except ValueError:
            print("It's invalid number, please try again...")
        else:                           # else子句只有try子句没有抛出异常时执行
            yes = input("If you need to try again, please enter Y/y: ")
            if 'Y' != yes and 'y' != yes:
                print("exit...")
                break
```

* with打开文件举例

```py
with open("myfile.txt") as f:
    for line in f:
        print(line, end="")
```

* 自定义异常类举例

```py
>>> class MyError(Exception):           # 自定义异常类
...     def __init__(self, value):
...         self.value = value
...     def __str__(self):
...         return repr(self.value)
...
>>>
>>> try:
...     raise MyError('other err!')     # 抛出异常类的实例
... except MyError as e:
...     print(e)
...     print(e.value+"...")
...
'other err!'
other err!...
>>>
>>> try:
...     raise MyError                   # 不能只抛出自定义异常类的类型
... except MyError:
...     print("err...")
...
Traceback (most recent call last):
  File "<stdin>", line 2, in <module>
TypeError: __init__() missing 1 required positional argument: 'value'
>>>
```

### 常见异常

| 异常 | 功能 |
| ---  | ---  |
| Exception         | 所有异常的基类 |
| AttributeError    | 特性应用或赋值失败时引发 |
| IOError           | 试图打开不存在的文件时引发 |
| IndexError        | 在使用序列中不存在的索引时引发 |
| KeyError          | 在使用映射不存在的键时引发 |
| NameError         | 在找不到名字(变量)时引发 |
| SyntaxError       | 在代码为错误形式时引发 |
| TypeError         | 在内建操作或者函数应用于错误类型的对象是引发 |
| ValueError        | 在内建操作或者函数应用于正确类型的对象，但是该对象使用不合适的值时引发 |
| ZeroDivisionError | 在除法或者摸除操作的第二个参数为0时引发 |
| AssertionError    | 断言错误，运行 assert condition, condition为假时引发 |

## 类

### 类定义

```py
# 类定义
class ClassName:
    'class documentation string'
    class_suite

# 单继承类，ClassName继承自基类BaseName
class ClassName(BaseName):
    class_suit

# 多继承类
class ClassName(Base1, Base2, Base3):
    class_suit
```

* 类(Class): 用来描述具有相同的属性和方法的对象的集合。它定义了该集合中每个对象所共有的属性和方法。对象是类的实例。
    * 定义类以class关键字开头，后面接着自定义类名(类名通常由大写字母打头)和冒号
* 方法：类中定义的函数。
* 类变量：类变量在整个实例化的对象中是公用的。类变量定义在类中且在函数体之外。类变量通常不作为实例变量使用。
* 数据成员：类变量或者实例变量用于处理类及其实例对象的相关的数据。
* 方法重写：如果从父类继承的方法不能满足子类的需求，可以对其进行改写，这个过程叫方法的覆盖（override），也称为方法的重写。
    * 方法在继承类中被重写时，首先使用继承类的方法，方法在继承类中未找到时，Python从左到右查找基类中是否包含方法
* 局部变量：定义在方法中的变量，只作用于当前实例的类。
* 实例变量：在类的声明中，属性是用变量来表示的，这种变量就称为实例变量，实例变量就是一个用 self 修饰的变量。
* 继承：即一个派生类（derived class）继承基类（base class）的字段和方法。继承也允许把一个派生类的对象作为一个基类对象对待。
    * `object` 是 “所有类之母”，如果你的类没有继承任何其他基类，object 将作为默认的基类
    * 子类（派生类 DerivedClassName）会继承父类（基类 BaseClassName）的属性和方法
    * 例如，有这样一个设计：一个Dog类型的对象派生自Animal类，这是模拟"是一个（is-a）"关系
* 实例化：创建一个类的实例，类的具体对象。
    * 类是对象的定义，而实例是“真正的实物”，它存放了类中所定义的对象的具体信息
* 对象：通过类定义的数据结构实例。对象包括两个数据成员（类变量和实例变量）和方法。

### 类方法的定义

```py
# 普通方法
def func(self, var1, var2): # self : 表示实例化类后的地址id
    func_suit

# 静态方法
@staticmethod
def func(var1, var2):
    func_suit

# 类方法
@classmethod
def func(cls, var1, var2): # cls : 表示没用被实例化的类本身
    func_suit
```

* 使用 def 关键字来定义一个方法
* 类方法第一个参数必须是 self，self 代表的是类的实例，而非类(self是惯例写法，也可以换成this)
* 调用时省略self，self是自动传入的，例如 ClassExample.func(var1, var2)

* 普通方法:     默认有个self参数，且只能被类对象调用
* 系统内建方法: `__name__` 两个下划线开头结尾的方法是系统内建方法，
* 私有方法:     `__name`   两个下划线开头但不结尾的变量或方法是私有变量或方法，外部不能调用
* 静态方法:     用 `@staticmethod` 装饰的不带 self 参数的方法叫做静态方法，可以被类名或类对象调用
* 类方法:       用 `@classmethod` 装饰的带 cls 参数的方法叫做类方法，可以被类名或类对象调用

### 类装饰器

* 调用该方法的方式：`类实例名.方法名`
    * 通过 @property 装饰器，可以直接通过方法名来访问方法，不需要在方法名后添加一小括号
    ```py
    @property
    def 方法名(self)
        代码块
    ```

### 构造函数和析构函数

```py
def __init__(self, var1, var2):
    //super(ClassName, self).__init__(var1, var2)
    # Base1.__init__(self, var1, var2)
    # Base2.__init__(self, var1, var2)
    func_suit

def __del__(self, var1, var2):
    func_suit
```

* 构造函数，在生成对象时自动调用，析构函数，在释放对象时自动调用
* 如果继承类不重写 `__init__` ，实例化继承类时，会自动调用基类定义的 `__init__`
* 如果继承类重写了 `__init__` ，实例化继承类时，不会自动调用基类已经定义的 `__init__`
* 如果继承类重写了 `__init__` ，继承类要继承基类的构造方法，
    * 可以直接通过基类类名调用基类的函数
    * 推荐使用 `super()` 方法
        * 多继承时使用 `super()` 可以很好地避免构造函数被调用两次
        * Python 3 可以使用直接使用 `super().xxx` 代替 `super(Class, self).xxx`
        * 它会查找所有的基类，以及基类的基类，直到找到所需的特性为止(最深的一个基类)
* 下面例子的输出是 `Fin,Cin,Bin,Bout,Cout,Fout`

```py
class A:
    def __init__(self): print('Ain', end=','); print('Aout', end=',')

class B:
    def __init__(self): print('Bin', end=','); print('Bout', end=',')

class C(B):
    def __init__(self): print('Cin', end=','); super().__init__(); print('Cout', end=',')

class D(A):
    def __init__(self): print('Din', end=','); super().__init__(); print('Dout', end=',')

class F(C, D):
    def __init__(self): print('Fin', end=','); super().__init__(); print('Fout')

f = F()
```

### 类的访问

```py
ClassExample.var
ClassExample.func()
func(ClassExample)
```

* 通过点号访问类的公有变量 var 和公有方法 func
* `属性名=property(fget=None, fset=None, fdel=None, doc=None)`
    * 让开发者使用“类对象.属性”的方式操作类中的属性
* 通过系统内建函数func访问的类的系统内建方法 `__func__` , 即 `ClassExample.__func__()`

### 特殊类属性

| 属性 | 功能 |
| ---  | ---  |
| `C.__name__`   | 类C的名字(字符串) |
| `C.__doc__`    | 类C的文档字符串 |
| `C.__bases__`  | 类C的所有父类构成的元组 |
| `C.__dict__`   | 类C的属性 |
| `C.__module__` | 类C定义所在的模块 |

### 举例

```py
#!/usr/bin/python3

## 类定义 ##
class people:
    # 定义基本属性
    name = ''
    age = 0

    # 定义私有属性，私有属性在类外部无法直接进行访问
    __weight = 0

    # 定义构造方法
    def __init__(self, n, a, w):
        self.name = n
        self.age = a
        self.__weight = w

    # 定义普通方法
    def speak(self):
        print("%s 说: 我 %d 岁。" % (self.name, self.age))

## 单继承 ##
class student(people):
    grade = ''
    def __init__(self, n, a, w, g):
        # 调用父类的构造方法
        people.__init__(self, n, a, w)
        self.grade = g

    # 覆写父类的方法
    def speak(self):
        print("%s 说: 我 %d 岁了，我在读 %d 年级" % (self.name, self.age, self.grade))

## 另一个类定义 ##
class speaker:
    name = ''
    topic = ''

    def __init__(self, n, t):
        self.name = n
        self.topic = t

    def speak(self):
        print("我叫 %s，我是一个演说家，我演讲的主题是 %s" % (self.name, self.topic))

## 多重继承 ##
class sample1(speaker, student):
    def __init__(self, n, a, w, g, t):
        student.__init__(self, n, a, w, g)
        speaker.__init__(self, n, t)

class sample2(student, speaker):
    def __init__(self, n, a, w, g, t):
        student.__init__(self, n, a, w, g)
        speaker.__init__(self, n, t)

## 调用 ##
test1 = sample1("Tim", 25, 80, 4, "Python")
test2 = sample2("Tim", 25, 80, 4, "Python")
# 方法名同，默认调用的是在括号中排前地父类的方法
test1.speak()
test2.speak()
```

## 模块

* 一个文件被看作是一个独立模块，一个模块也可以被看作是一个文件。模块的文件名就是模块的名字加上扩展名py
* 每个模块都定义了它自己的唯一的名称空间
* 推荐模块结构和布局：(1) 起始行(Unix)(2) 模块文档(3) 模块导入(4) 变量定义(5) 类定义(6) 函数定义(7) 主程序

### 模块导入

在 Python 用 import 或者 from...import 来导入相应的模块

* `import module_name`                  : 将整个模块导入
* `import module_name1, module_name2`   : 将多个整个模块导入
* `import module_name.obj1 as obj2`     : 从某个模块中导入单个对象并重命名为obj2
* `from module_name import obj_name`    : 从某个模块中导入单个对象
* `from module_name import obj1, obj2`  : 从某个模块中导入多个对象
* `from module_name import *`           : 从某个模块中导入全部对象
<p/>

* 解释器执行到 import 这条语句，如果在搜索路径中找到了指定的模块，就会加载它。该过程遵循作用域原则:
    * 如果在一个模块的顶层导入，那么它的作用域就是全局的
    * 如果在函数中导入，那么它的作用域是局部的
    * 如果模块是被第一次导入，它将被加载并执行
        * 加载模块会导致这个模块被“执行”，也就是被导入模块的顶层代码将直接被执行，这通常包括设定全局变量以及类和函数的声明
* 模块中的 `__all__` 变量可以限制或者指定能被导入到别的模块的函数，类，全局变量等
    * 如果指定了那么只能是指定的那些可以被导入，没有指定默认就是全部可以导入，当然私有属性应该除外

### `__init__.py`

* 在Python工程里，当python检测到一个目录下存在 `__init__.py` 文件时，python就会把它当成一个模块(module)
* `__init__.py` 的原始使命是声明一个模块，所以它可以是一个空文件
* 只在`__init__.py`中导入有必要的内容，不要做没必要的运算。利用`__init__.py`对外提供类型、变量和接口，对用户隐藏各个子模块的实现。

### 加入模块到搜索路径

```py
import sys
sys.path.append('程序所在路径')
```

### 编译成模块

1. Pypi Server Side
    1. install pypi-server
        `$ pip3 install pypi-server`
    2. create folder to store pip package
        `$ mkdir pypi_src (/home/XXX/pypi_src)`
    3. run pypi-server
        `$ pypi-server -p 11111 /home/XXX/pypi_src`

2. Pack and Release Private Library:
    1. create package path and keep layout like:
        ```
        xxx_lib
        |-- README.md
        |-- xxx_lib
        | |-- __init__.py
        | |-- .....
        |-- setup.cfg
        `-- setup.py
        ```
    2. copy target library files to folder(xxx_lib) and write setup.py, setup.cfg
        ```
        $ cat setup.cfg
        [metadata]
        description-file = README.md
        $ cat setup.py
        from setuptools import setup
        setup(
        name='xxx',
        packages=['xxx'],
        description='xxx',
        version='0.1',
        url='XXXX',
        author='PengWang',
        author_email='xxx@xxx.com',
        keywords=['pip', 'xxx']
        )
        ```
    3. compile package:
        `$ python3 setup.py sdist`
    4. new package will be created under path 'dist'.
        `$ mv dist/xxx_lib-0.1.tar.gz ~/pypi_src`

3. Install Package on Client Side
    `pip install --index-url http://xxx.xxx.xxx.xxxx:xxx/simple/ PACKAGE [PACKAGE2...]`

    e.g.: `pip install --trusted-host xxx.xxx.xxx.xxx --extra-index-url http://xxx.xxx.xxx.xxxx:xxx/simple/ xxx`

## 单例模式

### 全局变量

* 建立一个名字为gol.py 的文件

```py
# -*- coding: utf-8 -*-

def init_value():  # 初始化
    global _global_dict
    _global_dict = {}

def set_value(key, value): # 设置值
    _global_dict[key] = value

def get_value(key): # 获取值
    try:
        return _global_dict[key]
    except:
        print('read' + key + 'failed!')
```

* 在每个使用跨文件全局变量的py文件里，都导入上面的gol模块 `import gol`
* 在自己主程序模块里，先初始化gol模块一次 `gol.init_value()`
    * 注意：只需初始化一次，再次初始化会将已配置的全局变量清空
* 之后就简单了，不同的py文件中：
    * 新建或者重置跨文件全局变量：`gol.set_value(变量名, 变量值)`
    * 获得某个跨文件全局变量的值：`gol.get_value(变量名)`

### 单例模式

* 保证一个类仅有一个实例，并提供一个访问它的全局访问点
* 单例的使用主要是在需要保证全局只有一个实例可以被访问的情况，比如系统日志的输出、操作系统的任务管理器等。

#### 使用模块

* 模块天然就是单例的，因为模块只会被加载一次，加载之后，其他脚本里如果使用import 二次加载这个模块时，会从sys.modules里找到已经加载好的模块
* 在任何引用此模块的脚本里，此模块的全局对象都是同一个对象，这就确保了系统中只有一个实例

* 编写脚本my_singleton.py

```py
class Singleton():
    def __init__(self, name):
        self.name = name

singleton = Singleton('模块单例')
```

* 在其他脚本里 `from my_singleton import singleton`，都是同一个实例

#### 使用装饰器

```py
def Singleton(cls):
    instance = {}
    def _singleton_wrapper(*args, **kargs):
        if cls not in instance:
            instance[cls] = cls(*args, **kargs)
        return instance[cls]
    return _singleton_wrapper

@Singleton
class SingletonTest(object):
    def __init__(self, name):
        self.name = name

slt_1 = SingletonTest('第1次创建')
slt_2 = SingletonTest('第2次创建')
print(slt_1.name, slt_2.name)
print(slt_1 is slt_2)
```

* 输出

```
第1次创建 第1次创建
True
```

* 创建slt_2 对象时，instance 字典中已经存在SingletonTest 这个key，因此直接返回了第一次创建的对象，slt_1 和 slt_2 是同一个对象。
* 需要保证多线程安全

```py
from threading import RLock
single_lock = RLock()

def Singleton(cls):
    instance = {}
    def _singleton_wrapper(*args, **kargs):
        with single_lock:
            if cls not in instance:
                instance[cls] = cls(*args, **kargs)
        return instance[cls]
    return _singleton_wrapper
```

#### 使用类方法

```py
from threading import RLock

class Singleton(object):
    single_lock = RLock()
    def __init__(self, name):
        self.name = name
    @classmethod
    def instance(cls, *args, **kwargs):
        with Singleton.single_lock:
            if not hasattr(Singleton, "_instance"):
                Singleton._instance = Singleton(*args, **kwargs)
        return Singleton._instance

single_1 = Singleton.instance('第1次创建')
single_2 = Singleton.instance('第2次创建')
```

* instance方法会先检查是否存在类属性_instance， 如果不存在，则创建对象，并返回。
* 需要保证多线程安全

#### 基于`__new__`方法实现

```py
from threading import RLock

class Singleton(object):
    single_lock = RLock()

    def __init__(self, name):
        self.name = name

    def __new__(cls, *args, **kwargs):
        with Singleton.single_lock:
            if not hasattr(Singleton, "_instance"):
                Singleton._instance = object.__new__(cls)
        return Singleton._instance

single_1 = Singleton('第1次创建')
single_2 = Singleton('第2次创建')
```

* `__new__`方法是构造函数，是真正的用来创建对象的
* `__new__`方法创建对象后，会调用一次`__init__`来初始化对象，name被重置了
* 修正方法

```py
def __init__(self, name):
        if hasattr(self, 'name'):
            return
        self.name = name
```

#### 使用元类

```py
from threading import RLock

class SingletonType(type):
    single_lock = RLock()
    def __call__(cls, *args, **kwargs):   # 创建cls的对象时候调用
        with SingletonType.single_lock:
            if not hasattr(cls, "_instance"):
                cls._instance = super(SingletonType, cls).__call__(*args, **kwargs)     # 创建cls的对象
        return cls._instance

class Singleton(metaclass=SingletonType):
    def __init__(self, name):
        self.name = name

single_1 = Singleton('第1次创建')
single_2 = Singleton('第2次创建')
```

* class Singleton(metaclass=SingletonType) 这行代码定义了一个类，这个类是元类SingletonType的实例，是元类SingletonType的`__new__`构造出来的
* Singleton是实例，那么Singleton('第1次创建')就是在调用元类SingletonType 的`__call__`方法，`__call__`方法可以让类的实例像函数一样去调用。
* 在`__call__`方法里，cls就是类Singleton，为了创建对象，使用super来调用`__call__`方法，而不能直接写成`cls(*args, **kwargs)`, 这样等于又把SingletonType的`__call__`方法调用了一次，形成了死循环。
