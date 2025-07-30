# SIMD学习笔记

## 目录

[TOC]

## ARM-NEON函数

官方文档： https://developer.arm.com/architectures/instruction-sets/intrinsics

头文件 `arm_neon.h` ，ARM NEON函数名命名规则，函数名一般分为5部分：首字、前缀、操作、后缀、类型、宽度。首字固定为 `v(vector)` ，表示为向量。

* 例如 `vqaddq_s16` ：
    * `v`    : 首字，表示向量指令
    * `q`    : 前缀，表示饱和运算
    * `add`  : 操作，表示加法
    * `q`    : 后缀，表示四字(quad)，表示操作数的总宽度为 128bits
    * `s`    : 类型，表示有符号整型(signed)
    * `16`   : 宽度，表示操作数组成元素的宽度是 16bits

### NEON前缀

* 运算结果修饰
    * `q`    : 饱和运算，结果数据溢出时限制在当前类型能表示的最大值或最小值
    * `p`    : 成对运算(pairwise)，即对向量操作数的相邻元素进行运算，而不是第1个操作数的元素和第2个操作数的对应元素进行运算
    * `h`    : 取半运算(half)，即正常运算后，还要运算的结果元素再除以2
    * `d`    : 加倍运算(double)，即正常运算后，还要运算的结果元素再乘以2
    * `r`    : 四舍五入运算(round)，一般和窄指令合用，保留高位数据时根据低位数据四舍五入
    * `r`    : 倒数运算(reciprocal)，用于平方根中
    * `c`    : 复数运算(complex)，运算后角度有旋转，一般和 `rot90` `rot270` 合用
    * `m`    : 矩阵运算(matrix)，运算的操作数的元素被视为矩阵
<br>
* 操作数不一致修饰
    * `s`    : 存在有符号数不一致(signed)，例如加法中：结果元素和第1个操作数是无符号数，第2个操作数是有符号数
    * `u`    : 存在有无符号数不一致(unsigned)，例如加法中：结果元素和第1个操作数是有符号数，第2个操作数是无符号数

### NEON操作

* 数据转换
    * `create` : 从uint64_t变量创建向量
    * `dup`  : 单元素复制到向量的每个元素
    * `ld1`  : 加载数组成向量
        * `vld1_类型_xn` : 从内存连续加载(加载完第1个向量才加载第2个向量)
        * `vldn_类型` : 从内存交错加载(加载完所有向量的第1个元素才加载第2个元素)
        * `vldn_dup_类型` : 从内存单个加载(加载第n个单元素并广播到第n个向量的所有元素)
    * `st1`  : 向量存储为数组
        * `vst1_??_xn` : 连续存储到内存(存储完第1个向量才存储第2个向量)
        * `vstn_??` : 交错存储到内存(存储完所有向量的第1个元素才存储第2个元素)
    * `get`  : 获取向量的单个元素或半向量
    * `set`  : 设置向量的单个元素
    * `combine`：联合两个短向量到全向量
    * `mov`  : 移动全向量低半部或高半部到短向量
    * `ext`  : 提取交织(Extract Interleave)，提取第2个操作数的低n位(第3个操作数指定)(放在结果的高位)，结合第1个操作数的高L-n位
    * `copy` : 替换指定元素，返回结果是第1个操作数，它的某元素被第3个操作数的某元素替换
    * `cvt`  : 类型转换
    * `rnd`  : 浮点变换到整数，但还是浮点数表示
    * `rev`  : 顺序反转(Reverse)，操作数组成元素的顺序反转，后面数字是周期N，即交换 `v[i]` 和  `v[N-i]`
    * `trn1` : 选择偶数转置操作(Transpose)， `V = {a[0], b[0], a[2], b[2], ...}`
    * `trn2` : 选择奇数转置操作(Transpose)， `V = {a[1], b[1], a[3], b[3], ...}`
    * `trn`  : 转置操作(Transpose)，`V[0]` 选择偶数转置，`V[1]` 选择奇数转置
    * `tbl`  : 查找表(Table lookup)，从多向量中分别选取元素组成新向量，索引无效时该位置元素置为0
    * `tbx`  : 查找表扩展(Table lookup extension)，从多向量中分别选取元素组成新向量，索引无效时该位置元素置为第1个操作数相应位置的元素

* 算术运算
    * `add`  : 加法， `ret[i] = a[i] + b[i]`
    * `sub`  : 减法， `ret[i] = a[i] - b[i]`
    * `mul`  : 乘法， `ret[i] = a[i] * b[i]`
    * `div`  : 除法， `ret[i] = a[i] / b[i]`
    * `neg`  : 相反值， `ret[i] = -a[i]`
    * `abs`  : 绝对值， `ret[i] = abs(a[i])`
    * `abd`  : 差绝对值 `ret[i] = abs(a[i] - b[i])`
    * `aba`  : 加差绝对值， `ret[i] = r[i] + abs(a[i] - b[i])`
    * `mla`  : 加乘， `ret[i] = r[i] + a[i] * b[i]`
    * `mls`  : 减乘，`ret[i] = r[i] - a[i] * b[i]`
    * `fma`  : 加浮点乘， `ret[i] = r[i] + a[i] * b[i]`
    * `fms`  : 减浮点乘， `ret[i] = r[i] - a[i] * b[i]`
    * `dot`  : 点积累加， `ret[i] = r[i] + (a[4i] * b[4i] + ... + a[4i+3] * b[4i+3]`
    * `pada` : 一对二加法， `ret[i] = a[i] + b[2i] + b[2i+1]`
    * `sqrt` : 平方根， `ret[i] = sqrt(a[i])`
    * `recp` : 倒数， `ret[i] = 1 / a[i]`
<br>

* 逻辑运算
    * `min`  : 取小值
    * `max`  : 取大值
    * `ceq`  : 相等时相应结果元素的所有位置1，否则置0
    * `ceqz` : 等于0时相应结果元素的所有位置1，否则置0
    * `cgt`  : 大于时相应结果元素的所有位置1，否则置0
    * `cgtz` : 大于0时相应结果元素的所有位置1，否则置0
    * `cge`  : 大于等于时相应结果元素的所有位置1，否则置0
    * `cgez` : 大于等于0时相应结果元素的所有位置1，否则置0
    * `clt`  : 小于时相应结果元素的所有位置1，否则置0
    * `cltz` : 小于0时相应结果元素的所有位置1，否则置0
    * `cle`  : 小于等于时相应结果元素的所有位置1，否则置0
    * `clez` : 小于等于0时相应结果元素的所有位置1，否则置0
    * `cagt` : 绝对值大于时相应结果元素的所有位置1，否则置0
    * `cage` : 绝对值大于等于时相应结果元素的所有位置1，否则置0
    * `calt` : 绝对值小于时相应结果元素的所有位置1，否则置0
    * `cale` : 绝对值小于等于时相应结果元素的所有位置1，否则置0
<br>

* 位运算
    * `cls`  : 计算指从整数的最高位(符号位)之后开始（不含），直到遇到第一个与符号位不同的位之前的所有bit数
    * `clz`  : 计算指前导0的bit数
    * `cnt`  : 计算位是1的bit数
    * `tst`  : 按位与判断(and)，按位与的值不为0时相应结果元素的所有位置1，否则置0
    * `and`  : 按位与(and)
    * `orr`  : 按位或(or)
    * `eor`  : 按位异或(xor)
    * `bic`  : 按位清零(and clean)
    * `orn`  : 按位或非(or not)
    * `mvn`  : 按位取反(bitwise not)
    * `rbit` : 按位翻转(Reverse Bit order)，即原先高位到低位，原先低位到高位
    * `bsl`  : 按位选择，当第1个操作数某位为1时，返回值的位选择第2个操作数的相应位，否则选择第3个操作数的相应位
    * `shl`  : 左移
    * `shr`  : 右移
    * `sli`  : 左移插入，提取第2个操作数的低L-n位(第3个操作数指定)(放在结果的高位)，结合第1个操作数的低n位
    * `sri`  : 右移插入
    * `sra`  : 右移累加
    * `bcax` : 位清除并异或(Bit Clear and Exclusive OR)，`ret[i] = (a[i] and b[i]的补码) xor c[i]` (注：负数的补码 = 反码 + 1)

注：在下面的运算说明中，`L` 代表结果向量单个元素的宽度，`N` 代表结果向量元素的数量

### NEON后缀

* 指令类型
    * 无     : 短指令，操作数的宽度一般为 64bits，结果元素的宽度通常与操作数的元素的宽度相同 (一般不会被使用)
    * `q`    : 全指令(quad)，操作数的宽度一般为 128bits，结果元素的宽度通常与操作数的元素的宽度相同
    * `l`    : 长指令(long)，操作数的宽度一般为 128bits，结果元素的宽度通常是操作数的元素的宽度的两倍
    * `w`    : 宽指令(wide)，操作数的宽度一般为 128bits，结果元素的宽度通常与第1个操作数的元素的宽度相同，是第2个操作数的元素的宽度的两倍
    * `n`    : 窄指令(narrow)，操作数的宽度一般为 128bits，结果元素的宽度通常是操作数的元素的宽度的一半
        * `hn` / `h` : 窄指令取高半部(high narrow)
<br>

* 单指令：一般是对两个单数据或x2型的向量数据进行操作，生成结果是单数据
    * `b`    : 字节(byte)，结果元素是单数据，宽度是 8bits
    * `h`    : 半字(half word)，结果元素是单数据，宽度是 16bits
    * `s`    : 单字(single word)，结果元素是单数据，宽度是 32bits
    * `d`    : 双字(double words)，结果元素是单数据，宽度是 64bits
<br>

* `v`        : 归一指令，一般是对向量数据进行操作，生成结果是单数据，例如对数组求和或取最值等
<br>

* `h`        : 运算后结果取进位数据，一般用于乘法
* `_n`       : 向量数字运算，标明第2个操作数可能是单元素，例如用于乘法系数
* `_lane`    : 挑选运算，改变操作方式，只对操作向量的指定通进行运算，例如操作数等效为大小为8的数组，只对序号lane的元素进行运算
    * `_laneq` : 表示被挑选的第2个操作数的宽度是128bits
* `_high`    : 半部运算，改变操作方式，只对操作向量的后半部分进行运算，例如操作数等效为大小为8的数组，只对序号4~7的元素进行运算
* `x`        : 扩展运算，操作数的有效位数被扩展，以在运算中得到更高的精度

### NEON类型

* 操作数的类型
    * `s`    : 有符号整型(signed)
    * `u`    : 无符号整型(unsigned)
    * `f`    : 浮点型(float)
    * `bf`   : AI浮点型(Brain Floating Point)是一种16bit的浮点数格式，动态表达范围和float32是一样的，但是精度低，常用于人工智能
    * `p`    : 多项式型(poly)，通常用于特定的数学运算，如多项式乘法、除法以及有限域上的运算等，例如密码学

### 内存说明

寄存器处理数据时，NEON通常需要先将要处理的数据加载到NEON寄存器，然后执行SIMD操作；而SSE的SSE寄存器(XMM寄存器)可以直接与内存交互(内存交互比较耗时)。

NEON寄存器在进行数据加载和存储时，要求数据的内存地址与数据类型的位宽对齐。例如，对于16位(半字)数据，地址应该是2的倍数；对于32位(字)数据，地址应该是4的倍数；对于64位(双字)或128位(四字)数据，地址应该是8的倍数或16的倍数。

对齐数据可以提高CPU访问内存的效率，因为现代处理器通常具有对齐访问的优化。未对齐的数据访问可能导致多次内存访问或额外的内存操作，从而降低性能。

## X86_64-mmintrin函数

官方文档： https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html

MMX、SSE和AVX是Intel处理器中支持的单指令多数据流（SIMD）指令集，它们在不同时期被引入，操作数的宽度分别是 64bits、128bits、256/512bits，考虑兼容一般使用SSE指令，考虑性能一般使用AVX指令。

* MMX(MultiMedia eXtensions): 64bits MM0~MM7
    * MMX: `mmintrin.h` ，1997年推出(P1 Klamath)
* SSE(Streaming SIMD Extensions): 128bits XMM0~XMM7，SSE指令集向下兼容MMX指令集，并增强了处理器在浮点运算方面的性能
    * SSE: `xmmintrin.h` 编译选项 `-msse` ，1999年推出(P3 Katmai)，整型运算仍使用MMX寄存器，支持128位浮点运算，只支持单精度浮点运算
    * SSE2: `emmintrin.h` 编译选项 `-msse2` ，2000年推出(P4 Willamette)，支持128位整型运算，支持双精度浮点数运算，CPU快取的控制指令
    * SSE3: `pmmintrin.h` 编译选项 `-msse3` ，2004年推出(P4 Prescott)，扩展的指令包含寄存器的局部位之间的运算
    * SSSE3: `tmmintrin.h` ，2006年推出(Core Merom)
    * SSE4.1: `smmintrin.h` 编译选项 `-msse4.1` ，2007年推出(Core Penryn)，增加性能
    * SSE4.2: `nmmintrin.h` 编译选项 `-msse4.2` ，2008年推出(1代酷睿 Nehalem)
* AVX256(Advanced Vector Extensions): 256bits YMM0~YMM15
    * AVX: `immintrin.h` 编译选项 `-mavx` ，2011年推出(2代酷睿 SandyBridge)，整型运算可能仍使用128bits寄存器，支持256位浮点运算
    * AVX2: `immintrin.h` 编译选项 `-mavx2` ，2013年推出(4代酷睿 Haswell，AMD Zen2)，支持256位整型运算
* AVX512(Advanced Vector Extensions): 512bits ZMM0~ZMM31
    * AVX512: `immintrin.h` 编译选项 `-mavx512f` `-mavx512bw` 等，2015年推出(6代酷睿 SkyLake，AMD Zen4)，支持512位整型运算，支持16位浮点型运算

统一头文件 `immintrin.h`  ，ARM NEON函数名命名规则，函数名一般分为3部分： `_<前缀>_<向量操作>_<后缀>` 。

### mmintrin变量类型

* x86的操作数不像ARM一样分成“<类型><宽度>x<数量>_t”的多个形式，而是统一归类：
    * `__m64` 、 `__m128i` 、 `__m256i` 、 `__m512i` : 存储N个固定8/16/32/64bits的整数
    *            `__m128h` 、 `__m256h` 、 `__m512h` : 存储N个固定16bits的半精度浮点数(AVX加入)
    *            `__m128`  、 `__m256`  、 `__m512`  : 存储N个固定32bits的单精度浮点数
    *            `__m128d` 、 `__m256d` 、 `__m512d` : 存储N个固定64bits的双精度浮点数
    * `__mmask8` 、 `__mmask16` 、 `__mmask32` 、 `__mmask64` : 存储位掩码的类型，实际是 `uint??_t`

### mmintrin前缀

* 前缀一般是指令集类型
    * `m`     : 一般是MMX指令集，操作数宽度一般为64bits，一般有一个对应的 `mm` 指令别名
    * `mm`    : 一般是SSE/MMX指令集，操作数宽度一般为128/64bits
        * 通过后缀再区分是操作数宽度
    * `mm256` : 一般是AVX256指令集，操作数宽度一般为256bits
    * `mm512` : 一般是AVX512指令集，操作数宽度一般为512bits

注：前缀不一致表示就是对应的指令集类型，有些 `m` 指令在SSE中加入，有些 `mm` 指令在AVX中加入。

### mmintrin操作

* 数据转换
    * `load`                : 加载数组成向量
        * `load`            : 读取，需对齐
        * `loadu`           : 读取，无需对齐
        * `loadr`           : 反向读取
        * `loadh`           : 读取到高位数字
        * `loadl`           : 读取到低位数字
        * `load1`           : 读取并复制到所有位置
    * `store`               : 向量存储为数组
    * `stream`              : 向量存储为数组，不影响当前缓存数据
    * `extract`             : 获取向量的单个元素
    * `set`                 : 设置向量的元素
        * `set`             : 设置向量的元素
        * `setr`            : 反向设置向量的元素
        * `set1`            : 读取并设置到所有位置
        * `setzero`         : 清零
    * `insert`              : 设置向量的单个元素
    * `blend`               : 根据掩码选择第1个操作数的元素还是第2个操作数的元素
    * `shuffle`             : 根据掩码提取元素成新向量
    * `pack`                : 根据一定规则生成新向量
        * `packs / packus`  : 连接两个向量，结果向量的元素的宽度减半
        * `unpackhi`        : 结果向量交错选取操作向量的高半部元素
        * `unpacklo`        : 结果向量交错选取操作向量的低半部元素
    * `cvt`                 : 类型转换
    * `round`               : 浮点变换到整数，但还是浮点数表示
<br>

* 算术运算
    * `add`                 : 加法
        * `adds`            : 饱和加法
        * `hadd`            : 临近加法
        * `avg`             : 计算平均值
    * `sub`                 : 减法
        * `subs`            : 饱和减法
        * `hsub`            : 临近减法
    * `mul`                 : 乘法
        * `mulhi`           : 乘法并取高半部
        * `mullo`           : 乘法并取低半部
    * `div`                 : 除法
    * `abs`                 : 绝对值
    * `sad`                 : 差绝对值的和
    * `sign`                : 根据条件改符号
    * `sqrt`                : 平方根
        * `rsqrt`           : 平方根倒数
    * `rcp`                 : 倒数
<br>

* 逻辑运算
    * `min`                 : 取小值
    * `max`                 : 取大值
    * `cmpeq` / `cmpneq`    : 相等/不相等时，相应结果元素的所有位置1，否则置0
    * `cmpgt` / `cmpngt`    : 大于/不大于时，相应结果元素的所有位置1，否则置0
    * `cmpge` / `cmpnge`    : 大于等于/不大于等于时，相应结果元素的所有位置1，否则置0
    * `cmplt` / `cmpnlt`    : 小于/不小于时，相应结果元素的所有位置1，否则置0
    * `cmple` / `cmpnle`    : 小于等于/不小于等于时，相应结果元素的所有位置1，否则置0
    * `cmpord` / `cmpunord` : 都不等于NaN/有等于NaN时，相应结果元素的所有位置1，否则置0
    * `cmpieq / ucmpieq`    : 相等时且都不等于Nan时，返回1，否则返回0
    * `cmpineq / ucmpineq`  : 不等时或有等于NaN时，返回1，否则返回0
    * `cmpigt / ucmpigt`    : 大于时且都不等于Nan时，返回1，否则返回0
    * `cmpige / ucmpige`    : 大于等于时且都不等于Nan时，返回1，否则返回0
    * `cmpilt / ucmpilt`    : 小于时且都不等于Nan时，返回1，否则返回0
    * `cmpile / ucmpile`    : 小于等于时且都不等于Nan时，返回1，否则返回0
<br>

* 位运算
    * `test`                : 位测试
    * `and`                 : 按位与
    * `or`                  : 按位或
    * `xor`                 : 按位异或
    * `andnot`              : 与非，先非A，然后再与B
    * `sll / slli`          : 左移
    * `srl / srli`          : 右移
    * `sra / srai`          : 右移，高位补符号位
<br>

* AVX512掩码运算
    * 前缀 `mask` : 一般表示根据掩码计算，掩码位为0时不运算直接取 `src` 的值，为1时才进行相应运算
    * 前缀 `maskz` : 一般表示根据掩码计算，掩码位为0时不运算直接设为0，为1时才进行相应运算
    * 后缀 `mask` : 一般表示返回掩码值，位于函数名尾部，一般用于逻辑运算，为真时相应位值为1，否则置为0

### mmintrin后缀

* 后缀的前1个或前2个字母代表对操作数的操作范围：
    * `p` / `ep`        : packed / extended packed，操作操作数的所有元素
        * 对于整数： `p` 一般是64bits的操作数，`ep` 一般是128/256/512bits的操作数
        * 对于浮点数： 只有 `p`，一般是128/256/512bits的操作数
    * `s`               : scaler，操作操作数的第1个元素，ARM无此类指令
        * 一般对于整数的位操作指令 `si64` 表示是MMX指令集
<br>

* 后面的字母表示操作数的元素类型：
    * 浮点数
        * `h`           : 16bits半精度浮点数，AVX512指令引入
        * `s`           : 32bits单精度浮点数
        * `d`           : 64bits双精度浮点数
    * 有符号整数
        * `i8`          : 有符号8bits整数
        * `i16`         : 有符号16bits整数
        * `i32`         : 有符号32bits整数
        * `i64`         : 有符号64bits整数
            * 注：在 `set` 命令中， `i64x` 表示 `__int64` ， `i64` 表示 `__m64`
    * 无符号整数
        * `u8`          : 无符号8bits整数
        * `u16`         : 无符号16bits整数
        * `u32`         : 无符号32bits整数
        * `u64`         : 无符号64bits整数
    * 向量整数
        * `i64`         : 64bits向量整数
        * `i128`        : 128bits向量整数
        * `i256`        : 256bits向量整数
        * `i512`        : 512bits向量整数

## create创建指令

### 短指令创建

#### vcreate

```c
int8x8_t vcreate_s8 (uint64_t a);
int16x4_t vcreate_s16 (uint64_t a);
int32x2_t vcreate_s32 (uint64_t a);
int64x1_t vcreate_s64 (uint64_t a);
```

```c
uint8x8_t vcreate_u8 (uint64_t a);
uint16x4_t vcreate_u16 (uint64_t a);
uint32x2_t vcreate_u32 (uint64_t a);
uint64x1_t vcreate_u64 (uint64_t a);
```

```c
float16x4_t vcreate_f16 (uint64_t a);
float32x2_t vcreate_f32 (uint64_t a);
float64x1_t vcreate_f64 (uint64_t a);

bfloat16x4_t vcreate_bf16 (uint64_t a);
```

```c
poly8x8_t vcreate_p8 (uint64_t a);
poly16x4_t vcreate_p16 (uint64_t a);
poly64x1_t vcreate_p64 (uint64_t a);
```

## dup复制指令

### 短指令复制

#### vdup_n

* 运算： `ret[i] = a`

```c
int8x8_t vdup_n_s8 (int8_t a);    // _mm_set1_pi8
int16x4_t vdup_n_s16 (int16_t a); // _mm_set1_pi16
int32x2_t vdup_n_s32 (int32_t a); // _mm_set1_pi32
int64x1_t vdup_n_s64 (int64_t a);
```

```c
uint8x8_t vdup_n_u8 (uint8_t a);
uint16x4_t vdup_n_u16 (uint16_t a);
uint32x2_t vdup_n_u32 (uint32_t a);
uint64x1_t vdup_n_u64 (uint64_t a);
```

```c
float16x4_t vdup_n_f16 (float16_t a);
float32x2_t vdup_n_f32 (float32_t a);
float64x1_t vdup_n_f64 (float64_t a);

bfloat16x4_t vdup_n_bf16 (bfloat16_t a);
```

```c
poly8x8_t vdup_n_p8 (poly8_t a);
poly16x4_t vdup_n_p16 (poly16_t a);
poly64x1_t vdup_n_p64 (poly64_t a);
```

#### vdup_lane

* 运算： `ret[i] = v[lane]`

```c
int8x8_t vdup_lane_s8 (int8x8_t v, const int lane);
int16x4_t vdup_lane_s16 (int16x4_t v, const int lane);
int32x2_t vdup_lane_s32 (int32x2_t v, const int lane);
int64x1_t vdup_lane_s64 (int64x1_t v, const int lane);
```

```c
uint8x8_t vdup_lane_u8 (uint8x8_t v, const int lane);
uint16x4_t vdup_lane_u16 (uint16x4_t v, const int lane);
uint32x2_t vdup_lane_u32 (uint32x2_t v, const int lane);
uint64x1_t vdup_lane_u64 (uint64x1_t v, const int lane);
```

```c
float16x4_t vdup_lane_f16 (float16x4_t v, const int lane);
float32x2_t vdup_lane_f32 (float32x2_t v, const int lane);
float64x1_t vdup_lane_f64 (float64x1_t v, const int lane);

bfloat16x4_t vdup_lane_bf16 (bfloat16x4_t v, const int lane);
```

```c
poly8x8_t vdup_lane_p8 (poly8x8_t v, const int lane);
poly16x4_t vdup_lane_p16 (poly16x4_t v, const int lane);
poly64x1_t vdup_lane_p64 (poly64x1_t v, const int lane);
```

```c
int8x8_t vdup_laneq_s8 (int8x16_t v, const int lane);
int16x4_t vdup_laneq_s16 (int16x8_t v, const int lane);
int32x2_t vdup_laneq_s32 (int32x4_t v, const int lane);
int64x1_t vdup_laneq_s64 (int64x2_t v, const int lane);
```

```c
uint8x8_t vdup_laneq_u8 (uint8x16_t v, const int lane);
uint16x4_t vdup_laneq_u16 (uint16x8_t v, const int lane);
uint32x2_t vdup_laneq_u32 (uint32x4_t v, const int lane);
uint64x1_t vdup_laneq_u64 (uint64x2_t v, const int lane);
```

```c
float16x4_t vdup_laneq_f16 (float16x8_t v, const int lane);
float32x2_t vdup_laneq_f32 (float32x4_t v, const int lane);
float64x1_t vdup_laneq_f64 (float64x2_t v, const int lane);

bfloat16x4_t vdup_laneq_bf16 (bfloat16x8_t v, const int lane);
```

```c
poly8x8_t vdup_laneq_p8 (poly8x16_t v, const int lane);
poly16x4_t vdup_laneq_p16 (poly16x8_t v, const int lane);
poly64x1_t vdup_laneq_p64 (poly64x2_t v, const int lane);
```

### 全指令复制

#### vdupq_n

* 运算： `ret[i] = a`

```c
int8x16_t vdupq_n_s8 (int8_t a);   // _mm_set1_epi8   | _mm256_set1_epi8   | _mm512_set1_epi8
int16x8_t vdupq_n_s16 (int16_t a); // _mm_set1_epi16  | _mm256_set1_epi16  | _mm512_set1_epi16
int32x4_t vdupq_n_s32 (int32_t a); // _mm_set1_epi32  | _mm256_set1_epi32  | _mm512_set1_epi32
int64x2_t vdupq_n_s64 (int64_t a); // _mm_set1_epi64x | _mm256_set1_epi64x | _mm512_set1_epi64
                                   // _mm_set1_epi64(__m64)
```

```c
uint8x16_t vdupq_n_u8 (uint8_t a);
uint16x8_t vdupq_n_u16 (uint16_t a);
uint32x4_t vdupq_n_u32 (uint32_t a);
uint64x2_t vdupq_n_u64 (uint64_t a);
```

```c
float16x8_t vdupq_n_f16 (float16_t a); // _mm_set1_ph               | _mm256_set1_ph | _mm512_set1_ph
float32x4_t vdupq_n_f32 (float32_t a); // _mm_set1_ps / _mm_set_ps1 | _mm256_set1_ps | _mm512_set1_ps
float64x2_t vdupq_n_f64 (float64_t a); // _mm_set1_pd / _mm_set_pd1 | _mm256_set1_pd | _mm512_set1_pd

bfloat16x8_t vdupq_n_bf16 (bfloat16_t a);
```

```c
poly8x16_t vdupq_n_p8 (poly8_t a);
poly16x8_t vdupq_n_p16 (poly16_t a);
poly64x2_t vdupq_n_p64 (poly64_t a);
```

#### vdupq_lane

* 运算： `ret[i] = v[lane]`

```c
int8x16_t vdupq_lane_s8 (int8x8_t v, const int lane);
int16x8_t vdupq_lane_s16 (int16x4_t v, const int lane);
int32x4_t vdupq_lane_s32 (int32x2_t v, const int lane);
int64x2_t vdupq_lane_s64 (int64x1_t v, const int lane);
```

```c
uint8x16_t vdupq_lane_u8 (uint8x8_t v, const int lane);
uint16x8_t vdupq_lane_u16 (uint16x4_t v, const int lane);
uint32x4_t vdupq_lane_u32 (uint32x2_t v, const int lane);
uint64x2_t vdupq_lane_u64 (uint64x1_t v, const int lane);
```

```c
float16x8_t vdupq_lane_f16 (float16x4_t v, const int lane);
float32x4_t vdupq_lane_f32 (float32x2_t v, const int lane);
float64x2_t vdupq_lane_f64 (float64x1_t v, const int lane);

bfloat16x8_t vdupq_lane_bf16 (bfloat16x4_t v, const int lane);
```

```c
poly8x16_t vdupq_lane_p8 (poly8x8_t v, const int lane);
poly16x8_t vdupq_lane_p16 (poly16x4_t v, const int lane);
poly64x2_t vdupq_lane_p64 (poly64x1_t v, const int lane);
```

```c
int8x16_t vdupq_laneq_s8 (int8x16_t v, const int lane);
int16x8_t vdupq_laneq_s16 (int16x8_t v, const int lane);
int32x4_t vdupq_laneq_s32 (int32x4_t v, const int lane);
int64x2_t vdupq_laneq_s64 (int64x2_t v, const int lane);
```

```c
uint8x16_t vdupq_laneq_u8 (uint8x16_t v, const int lane);
uint16x8_t vdupq_laneq_u16 (uint16x8_t v, const int lane);
uint32x4_t vdupq_laneq_u32 (uint32x4_t v, const int lane);
uint64x2_t vdupq_laneq_u64 (uint64x2_t v, const int lane);
```

```c
float16x8_t vdupq_laneq_f16 (float16x8_t v, const int lane);
float32x4_t vdupq_laneq_f32 (float32x4_t v, const int lane);
float64x2_t vdupq_laneq_f64 (float64x2_t v, const int lane);

bfloat16x8_t vdupq_laneq_bf16 (bfloat16x8_t v, const int lane);
```

```c
poly8x16_t vdupq_laneq_p8 (poly8x16_t v, const int lane);
poly16x8_t vdupq_laneq_p16 (poly16x8_t v, const int lane);
poly64x2_t vdupq_laneq_p64 (poly64x2_t v, const int lane);
```

### 单指令复制

#### vdup?_lane

* 运算： `ret = v[lane]`

```c
int8_t vdupb_lane_s8 (int8x8_t v, const int lane);
int16_t vduph_lane_s16 (int16x4_t v, const int lane);
int32_t vdups_lane_s32 (int32x2_t v, const int lane);
int64_t vdupd_lane_s64 (int64x1_t v, const int lane);
```

```c
uint8_t vdupb_lane_u8 (uint8x8_t v, const int lane);
uint16_t vduph_lane_u16 (uint16x4_t v, const int lane);
uint32_t vdups_lane_u32 (uint32x2_t v, const int lane);
uint64_t vdupd_lane_u64 (uint64x1_t v, const int lane);
```

```c
float16_t vduph_lane_f16 (float16x4_t v, const int lane);
float32_t vdups_lane_f32 (float32x2_t v, const int lane);
float64_t vdupd_lane_f64 (float64x1_t v, const int lane);

bfloat16_t vduph_lane_bf16 (bfloat16x4_t v, const int lane);
```

```c
poly8_t vdupb_lane_p8 (poly8x8_t v, const int lane);
poly16_t vduph_lane_p16 (poly16x4_t v, const int lane);
```

```c
int8_t vdupb_laneq_s8 (int8x16_t v, const int lane);
int16_t vduph_laneq_s16 (int16x8_t v, const int lane);
int32_t vdups_laneq_s32 (int32x4_t v, const int lane);
int64_t vdupd_laneq_s64 (int64x2_t v, const int lane);
```

```c
uint8_t vdupb_laneq_u8 (uint8x16_t v, const int lane);
uint16_t vduph_laneq_u16 (uint16x8_t v, const int lane);
uint32_t vdups_laneq_u32 (uint32x4_t v, const int lane);
uint64_t vdupd_laneq_u64 (uint64x2_t v, const int lane);
```

```c
float16_t vduph_laneq_f16 (float16x8_t v, const int lane);
float32_t vdups_laneq_f32 (float32x4_t v, const int lane);
float64_t vdupd_laneq_f64 (float64x2_t v, const int lane);

bfloat16_t vduph_laneq_bf16 (bfloat16x8_t v, const int lane);
```

```c
poly8_t vdupb_laneq_p8 (poly8x16_t v, const int lane);
poly16_t vduph_laneq_p16 (poly16x8_t v, const int lane);
```

## ld加载指令

### 短指令加载

#### vld1

* 运算： `ret[i] = ptr[i]`

```c
int8x8_t vld1_s8 (const int8_t *ptr);
int16x4_t vld1_s16 (const int16_t *ptr);
int32x2_t vld1_s32 (const int32_t *ptr);
int64x1_t vld1_s64 (const int64_t *ptr);
```

```c
uint8x8_t vld1_u8 (const uint8_t *ptr);
uint16x4_t vld1_u16 (const uint16_t *ptr);
uint32x2_t vld1_u32 (const uint32_t *ptr);
uint64x1_t vld1_u64 (const uint64_t *ptr);
```

```c
float16x4_t vld1_f16 (const float16_t *ptr);
float32x2_t vld1_f32 (const float32_t *ptr);
float64x1_t vld1_f64 (const float64_t *ptr);

bfloat16x4_t vld1_bf16 (const bfloat16_t *ptr);
```

```c
poly8x8_t vld1_p8 (const poly8_t *ptr);
poly16x4_t vld1_p16 (const poly16_t *ptr);
poly64x1_t vld1_p64 (const poly64_t *ptr);
```

#### vld1_dup

* 运算： `ret[i] = ptr[0]`

```c
int8x8_t vld1_dup_s8 (const int8_t *ptr);
int16x4_t vld1_dup_s16 (const int16_t *ptr);
int32x2_t vld1_dup_s32 (const int32_t *ptr);
int64x1_t vld1_dup_s64 (const int64_t *ptr);
```

```c
uint8x8_t vld1_dup_u8 (const uint8_t *ptr);
uint16x4_t vld1_dup_u16 (const uint16_t *ptr);
uint32x2_t vld1_dup_u32 (const uint32_t *ptr);
uint64x1_t vld1_dup_u64 (const uint64_t *ptr);
```

```c
float16x4_t vld1_dup_f16 (const float16_t *ptr);
float32x2_t vld1_dup_f32 (const float32_t *ptr); // _mm_load_ps1
float64x1_t vld1_dup_f64 (const float64_t *ptr); // _mm_load_pd1

bfloat16x4_t vld1_dup_bf16 (const bfloat16_t *ptr);
```

```c
poly8x8_t vld1_dup_p8 (const poly8_t *ptr);
poly16x4_t vld1_dup_p16 (const poly16_t *ptr);
poly64x1_t vld1_dup_p64 (const poly64_t *ptr);
```

#### vld1_lane

* 运算： `ret[i] = src[i]; then ret[lane] = ptr[0]`

```c
int8x8_t vld1_lane_s8 (const int8_t *ptr, int8x8_t src, const int lane);
int16x4_t vld1_lane_s16 (const int16_t *ptr, int16x4_t src, const int lane);
int32x2_t vld1_lane_s32 (const int32_t *ptr, int32x2_t src, const int lane);
int64x1_t vld1_lane_s64 (const int64_t *ptr, int64x1_t src, const int lane);
```

```c
uint8x8_t vld1_lane_u8 (const uint8_t *ptr, uint8x8_t src, const int lane);
uint16x4_t vld1_lane_u16 (const uint16_t *ptr, uint16x4_t src, const int lane);
uint32x2_t vld1_lane_u32 (const uint32_t *ptr, uint32x2_t src, const int lane);
uint64x1_t vld1_lane_u64 (const uint64_t *ptr, uint64x1_t src, const int lane);
```

```c
float16x4_t vld1_lane_f16 (const float16_t *ptr, float16x4_t src, const int lane);
float32x2_t vld1_lane_f32 (const float32_t *ptr, float32x2_t src, const int lane);
float64x1_t vld1_lane_f64 (const float64_t *ptr, float64x1_t src, const int lane);

bfloat16x4_t vld1_lane_bf16 (const bfloat16_t *ptr, bfloat16x4_t src, const int lane);
```

```c
poly8x8_t vld1_lane_p8 (const poly8_t *ptr, poly8x8_t src, const int lane);
poly16x4_t vld1_lane_p16 (const poly16_t *ptr, poly16x4_t src, const int lane);
poly64x1_t vld1_lane_p64 (const poly64_t *ptr, poly64x1_t src, const int lane);
```

### 全指令加载

#### vld1q

* 运算： `ret[i] = ptr[i]`
    * X86_64-mmintrin函数 `loadu` 无需对齐，`lddqu` 无需对齐且效率更高， `load` 需操作数宽度对齐
    * `_mm_loadu_epi??` 和 `_mm_load_epi??`为AVX512指令

```c
// _mm_loadu_si128 | _mm256_loadu_si256 | _mm512_loadu_si512
// _mm_lddqu_si128 | _mm256_lddqu_si256 | ?
// _mm_load_si128  | _mm256_load_si256  | _mm512_load_si512
int8x16_t vld1q_s8 (const int8_t *ptr);   // _mm_loadu_epi8  | _mm256_loadu_epi8  | _mm512_loadu_epi8
int16x8_t vld1q_s16 (const int16_t *ptr); // _mm_loadu_epi16 | _mm256_loadu_epi16 | _mm512_loadu_epi16
int32x4_t vld1q_s32 (const int32_t *ptr); // _mm_loadu_epi32 | _mm256_loadu_epi32 | _mm512_loadu_epi32
                                          // _mm_load_epi32  | _mm256_load_epi32  | _mm512_load_epi32
int64x2_t vld1q_s64 (const int64_t *ptr); // _mm_loadu_epi64 | _mm256_loadu_epi64 | _mm512_loadu_epi64
                                          // _mm_load_epi64  | _mm256_load_epi64  | _mm512_load_epi64
```

```c
uint8x16_t vld1q_u8 (const uint8_t *ptr);
uint16x8_t vld1q_u16 (const uint16_t *ptr);
uint32x4_t vld1q_u32 (const uint32_t *ptr);
uint64x2_t vld1q_u64 (const uint64_t *ptr);
```

```c
float16x8_t vld1q_f16 (const float16_t *ptr); // _mm_loadu_ph | _mm256_loadu_ph | _mm512_loadu_ph
                                              // _mm_load_ph  | _mm256_load_ph  | _mm512_load_ph
float32x4_t vld1q_f32 (const float32_t *ptr); // _mm_loadu_ps | _mm256_loadu_ps | _mm512_loadu_ps
                                              // _mm_load_ps  | _mm256_load_ps  | _mm512_load_ps
float64x2_t vld1q_f64 (const float64_t *ptr); // _mm_loadu_pd | _mm256_loadu_pd | _mm512_loadu_pd
                                              // _mm_load_pd  | _mm256_load_pd  | _mm512_load_pd

bfloat16x8_t vld1q_bf16 (const bfloat16_t *ptr);
```

```c
poly8x16_t vld1q_p8 (const poly8_t *ptr);
poly16x8_t vld1q_p16 (const poly16_t *ptr);
poly64x2_t vld1q_p64 (const poly64_t *ptr);
```

#### vld1q_dup

* 运算： `ret[i] = ptr[0]`

```c
int8x16_t vld1q_dup_s8 (const int8_t *ptr);
int16x8_t vld1q_dup_s16 (const int16_t *ptr);
int32x4_t vld1q_dup_s32 (const int32_t *ptr);
int64x2_t vld1q_dup_s64 (const int64_t *ptr);
```

```c
uint8x16_t vld1q_dup_u8 (const uint8_t *ptr);
uint16x8_t vld1q_dup_u16 (const uint16_t *ptr);
uint32x4_t vld1q_dup_u32 (const uint32_t *ptr);
uint64x2_t vld1q_dup_u64 (const uint64_t *ptr);
```

```c
float16x8_t vld1q_dup_f16 (const float16_t *ptr);
float32x4_t vld1q_dup_f32 (const float32_t *ptr); // _mm_load1_ps
float64x2_t vld1q_dup_f64 (const float64_t *ptr); // _mm_load1_pd / _mm_loaddup_pd

bfloat16x8_t vld1q_dup_bf16 (const bfloat16_t *ptr);
```

```c
poly8x16_t vld1q_dup_p8 (const poly8_t *ptr);
poly16x8_t vld1q_dup_p16 (const poly16_t *ptr);
poly64x2_t vld1q_dup_p64 (const poly64_t *ptr);
```

#### vld1q_lane

* 运算： `ret[i] = src[i]; then ret[lane] = ptr[0]`

```c
int8x16_t vld1q_lane_s8 (const int8_t *ptr, int8x16_t src, const int lane);
int16x8_t vld1q_lane_s16 (const int16_t *ptr, int16x8_t src, const int lane);
int32x4_t vld1q_lane_s32 (const int32_t *ptr, int32x4_t src, const int lane);
int64x2_t vld1q_lane_s64 (const int64_t *ptr, int64x2_t src, const int lane);
```

```c
uint8x16_t vld1q_lane_u8 (const uint8_t *ptr, uint8x16_t src, const int lane);
uint16x8_t vld1q_lane_u16 (const uint16_t *ptr, uint16x8_t src, const int lane);
uint32x4_t vld1q_lane_u32 (const uint32_t *ptr, uint32x4_t src, const int lane);
uint64x2_t vld1q_lane_u64 (const uint64_t *ptr, uint64x2_t src, const int lane);
```

```c
float16x8_t vld1q_lane_f16 (const float16_t *ptr, float16x8_t src, const int lane);
float32x4_t vld1q_lane_f32 (const float32_t *ptr, float32x4_t src, const int lane);
float64x2_t vld1q_lane_f64 (const float64_t *ptr, float64x2_t src, const int lane);

bfloat16x8_t vld1q_lane_bf16 (const bfloat16_t *ptr, bfloat16x8_t src, const int lane);
```

```c
poly8x16_t vld1q_lane_p8 (const poly8_t *ptr, poly8x16_t src, const int lane);
poly16x8_t vld1q_lane_p16 (const poly16_t *ptr, poly16x8_t src, const int lane);
poly64x2_t vld1q_lane_p64 (const poly64_t *ptr, poly64x2_t src, const int lane);
```

## st存储指令

### 短指令存储

#### vst1

* 运算： `ptr[i] = val[i]`

```c
void vst1_s8 (int8_t *ptr, int8x8_t val);
void vst1_s16 (int16_t *ptr, int16x4_t val);
void vst1_s32 (int32_t *ptr, int32x2_t val);
void vst1_s64 (int64_t *ptr, int64x1_t val);
```

```c
void vst1_u8 (uint8_t *ptr, uint8x8_t val);
void vst1_u16 (uint16_t *ptr, uint16x4_t val);
void vst1_u32 (uint32_t *ptr, uint32x2_t val);
void vst1_u64 (uint64_t *ptr, uint64x1_t val);
```

```c
void vst1_f16 (float16_t *ptr, float16x4_t val);
void vst1_f32 (float32_t *ptr, float32x2_t val);
void vst1_f64 (float64_t *ptr, float64x1_t val);

void vst1_bf16 (bfloat16_t *ptr, bfloat16x4_t val);
```

```c
void vst1_p8 (poly8_t *ptr, poly8x8_t val);
void vst1_p16 (poly16_t *ptr, poly16x4_t val);
void vst1_p64 (poly64_t *ptr, poly64x1_t val);
```

#### vst1_lane

* 运算： `ptr[lane] = val[lane]`

```c
void vst1_lane_s8 (int8_t *ptr, int8x8_t val, const int lane);
void vst1_lane_s16 (int16_t *ptr, int16x4_t val, const int lane);
void vst1_lane_s32 (int32_t *ptr, int32x2_t val, const int lane);
void vst1_lane_s64 (int64_t *ptr, int64x1_t val, const int lane);
```

```c
void vst1_lane_u8 (uint8_t *ptr, uint8x8_t val, const int lane);
void vst1_lane_u16 (uint16_t *ptr, uint16x4_t val, const int lane);
void vst1_lane_u32 (uint32_t *ptr, uint32x2_t val, const int lane);
void vst1_lane_u64 (uint64_t *ptr, uint64x1_t val, const int lane);
```

```c
void vst1_lane_f16 (float16_t *ptr, float16x4_t val, const int lane);
void vst1_lane_f32 (float32_t *ptr, float32x2_t val, const int lane);
void vst1_lane_f64 (float64_t *ptr, float64x1_t val, const int lane);

void vst1_lane_bf16 (bfloat16_t *ptr, bfloat16x4_t val, const int lane);
```

```c
void vst1_lane_p8 (poly8_t *ptr, poly8x8_t val, const int lane);
void vst1_lane_p16 (poly16_t *ptr, poly16x4_t val, const int lane);
void vst1_lane_p64 (poly64_t *ptr, poly64x1_t val, const int lane);
```

### 全指令存储

#### vst1q

* 运算： `ptr[i] = val[i]`
    * X86_64-mmintrin函数 `storeu` 无需对齐， `store` 需操作数宽度对齐
    * `_mm_storeu_epi??` 和 `_mm_store_epi??`为AVX512指令

```c
// _mm_storeu_si128 | _mm256_storeu_si256 | _mm512_storeu_si512
// _mm_store_si128  | _mm256_store_si256  | _mm512_store_si512
void vst1q_s8 (int8_t *ptr, int8x16_t val);   // _mm_storeu_epi8  | _mm256_storeu_epi8  | _mm512_storeu_epi8
void vst1q_s16 (int16_t *ptr, int16x8_t val); // _mm_storeu_epi16 | _mm256_storeu_epi16 | _mm512_storeu_epi16
void vst1q_s32 (int32_t *ptr, int32x4_t val); // _mm_storeu_epi32 | _mm256_storeu_epi32 | _mm512_storeu_epi32
                                              // _mm_store_epi32  | _mm256_store_epi32  | _mm512_store_epi32
void vst1q_s64 (int64_t *ptr, int64x2_t val); // _mm_storeu_epi64 | _mm256_storeu_epi64 | _mm512_storeu_epi64
                                              // _mm_store_epi64  | _mm256_store_epi64  | _mm512_store_epi64
```

```c
void vst1q_u8 (uint8_t *ptr, uint8x16_t val);
void vst1q_u16 (uint16_t *ptr, uint16x8_t val);
void vst1q_u32 (uint32_t *ptr, uint32x4_t val);
void vst1q_u64 (uint64_t *ptr, uint64x2_t val);
```

```c
void vst1q_f16 (float16_t *ptr, float16x8_t val); // _mm_storeu_ph | _mm256_storeu_ph | _mm512_storeu_ph
                                                  // _mm_store_ph  | _mm256_store_ph  | _mm512_store_ph
void vst1q_f32 (float32_t *ptr, float32x4_t val); // _mm_storeu_ps | _mm256_storeu_ps | _mm512_storeu_ps
                                                  // _mm_store_ps  | _mm256_store_ps  | _mm512_store_ps
void vst1q_f64 (float64_t *ptr, float64x2_t val); // _mm_storeu_pd | _mm256_storeu_pd | _mm512_storeu_pd
                                                  // _mm_store_pd  | _mm256_store_pd  | _mm512_store_pd

void vst1q_bf16 (bfloat16_t *ptr, bfloat16x8_t val);
```

```c
void vst1q_p8 (poly8_t *ptr, poly8x16_t val);
void vst1q_p16 (poly16_t *ptr, poly16x8_t val);
void vst1q_p64 (poly64_t *ptr, poly64x2_t val);
```

#### vst1q_lane

* 运算： `ptr[lane] = val[lane]`

```c
void vst1q_lane_s8 (int8_t *ptr, int8x16_t val, const int lane);
void vst1q_lane_s16 (int16_t *ptr, int16x8_t val, const int lane);
void vst1q_lane_s32 (int32_t *ptr, int32x4_t val, const int lane);
void vst1q_lane_s64 (int64_t *ptr, int64x2_t val, const int lane);
```

```c
void vst1q_lane_u8 (uint8_t *ptr, uint8x16_t val, const int lane);
void vst1q_lane_u16 (uint16_t *ptr, uint16x8_t val, const int lane);
void vst1q_lane_u32 (uint32_t *ptr, uint32x4_t val, const int lane);
void vst1q_lane_u64 (uint64_t *ptr, uint64x2_t val, const int lane);
```

```c
void vst1q_lane_f16 (float16_t *ptr, float16x8_t val, const int lane);
void vst1q_lane_f32 (float32_t *ptr, float32x4_t val, const int lane);
void vst1q_lane_f64 (float64_t *ptr, float64x2_t val, const int lane);

void vst1q_lane_bf16 (bfloat16_t *ptr, bfloat16x8_t val, const int lane);
```

```c
void vst1q_lane_p8 (poly8_t *ptr, poly8x16_t val, const int lane);
void vst1q_lane_p16 (poly16_t *ptr, poly16x8_t val, const int lane);
void vst1q_lane_p64 (poly64_t *ptr, poly64x2_t val, const int lane);
```

## vldN多向量交错加载指令

### 短指令多向量交错加载

#### vld2

* 运算： `V[n][i] = ptr[2i + n]`

```c
int8x8x2_t vld2_s8 (const int8_t *ptr);
int16x4x2_t vld2_s16 (const int16_t *ptr);
int32x2x2_t vld2_s32 (const int32_t *ptr);
int64x1x2_t vld2_s64 (const int64_t *ptr);
```

```c
uint8x8x2_t vld2_u8 (const uint8_t *ptr);
uint16x4x2_t vld2_u16 (const uint16_t *ptr);
uint32x2x2_t vld2_u32 (const uint32_t *ptr);
uint64x1x2_t vld2_u64 (const uint64_t *ptr);
```

```c
float16x4x2_t vld2_f16 (const float16_t *ptr);
float32x2x2_t vld2_f32 (const float32_t *ptr);
float64x1x2_t vld2_f64 (const float64_t *ptr);

bfloat16x4x2_t vld2_bf16 (const bfloat16_t *ptr);
```

```c
poly8x8x2_t vld2_p8 (const poly8_t *ptr);
poly16x4x2_t vld2_p16 (const poly16_t *ptr);
poly64x1x2_t vld2_p64 (const poly64_t *ptr);
```

#### vld3

* 运算： `V[n][i] = ptr[3i + n]`

```c
int8x8x3_t vld3_s8 (const int8_t *ptr);
int16x4x3_t vld3_s16 (const int16_t *ptr);
int32x2x3_t vld3_s32 (const int32_t *ptr);
int64x1x3_t vld3_s64 (const int64_t *ptr);
```

```c
uint8x8x3_t vld3_u8 (const uint8_t *ptr);
uint16x4x3_t vld3_u16 (const uint16_t *ptr);
uint32x2x3_t vld3_u32 (const uint32_t *ptr);
uint64x1x3_t vld3_u64 (const uint64_t *ptr);
```

```c
float16x4x3_t vld3_f16 (const float16_t *ptr);
float32x2x3_t vld3_f32 (const float32_t *ptr);
float64x1x3_t vld3_f64 (const float64_t *ptr);
bfloat16x4x3_t vld3_bf16 (const bfloat16_t *ptr);
```

```c
poly8x8x3_t vld3_p8 (const poly8_t *ptr);
poly16x4x3_t vld3_p16 (const poly16_t *ptr);
poly64x1x3_t vld3_p64 (const poly64_t *ptr);
```

#### vld4

* 运算： `V[n][i] = ptr[4i + n]`

```c
int8x8x4_t vld4_s8 (const int8_t *ptr);
int16x4x4_t vld4_s16 (const int16_t *ptr);
int32x2x4_t vld4_s32 (const int32_t *ptr);
int64x1x4_t vld4_s64 (const int64_t *ptr);
```

```c
uint8x8x4_t vld4_u8 (const uint8_t *ptr);
uint16x4x4_t vld4_u16 (const uint16_t *ptr);
uint32x2x4_t vld4_u32 (const uint32_t *ptr);
uint64x1x4_t vld4_u64 (const uint64_t *ptr);
```

```c
float16x4x4_t vld4_f16 (const float16_t *ptr);
float32x2x4_t vld4_f32 (const float32_t *ptr);
float64x1x4_t vld4_f64 (const float64_t *ptr);
bfloat16x4x4_t vld4_bf16 (const bfloat16_t *ptr);
```

```c
poly8x8x4_t vld4_p8 (const poly8_t *ptr);
poly16x4x4_t vld4_p16 (const poly16_t *ptr);
poly64x1x4_t vld4_p64 (const poly64_t *ptr);
```

#### vld2_dup

* 运算： `V[n][i] = ptr[n]`

```c
int8x8x2_t vld2_dup_s8 (const int8_t *ptr);
int16x4x2_t vld2_dup_s16 (const int16_t *ptr);
int32x2x2_t vld2_dup_s32 (const int32_t *ptr);
int64x1x2_t vld2_dup_s64 (const int64_t *ptr);
```

```c
uint8x8x2_t vld2_dup_u8 (const uint8_t *ptr);
uint16x4x2_t vld2_dup_u16 (const uint16_t *ptr);
uint32x2x2_t vld2_dup_u32 (const uint32_t *ptr);
uint64x1x2_t vld2_dup_u64 (const uint64_t *ptr);
```

```c
float16x4x2_t vld2_dup_f16 (const float16_t *ptr);
float32x2x2_t vld2_dup_f32 (const float32_t *ptr);
float64x1x2_t vld2_dup_f64 (const float64_t *ptr);

bfloat16x4x2_t vld2_dup_bf16 (const bfloat16_t *ptr);
```

```c
poly8x8x2_t vld2_dup_p8 (const poly8_t *ptr);
poly16x4x2_t vld2_dup_p16 (const poly16_t *ptr);
poly64x1x2_t vld2_dup_p64 (const poly64_t *ptr);
```

#### vld3_dup

* 运算： `V[n][i] = ptr[n]`

```c
int8x8x3_t vld3_dup_s8 (const int8_t *ptr);
int16x4x3_t vld3_dup_s16 (const int16_t *ptr);
int32x2x3_t vld3_dup_s32 (const int32_t *ptr);
int64x1x3_t vld3_dup_s64 (const int64_t *ptr);
```

```c
uint8x8x3_t vld3_dup_u8 (const uint8_t *ptr);
uint16x4x3_t vld3_dup_u16 (const uint16_t *ptr);
uint32x2x3_t vld3_dup_u32 (const uint32_t *ptr);
uint64x1x3_t vld3_dup_u64 (const uint64_t *ptr);
```

```c
float16x4x3_t vld3_dup_f16 (const float16_t *ptr);
float32x2x3_t vld3_dup_f32 (const float32_t *ptr);
float64x1x3_t vld3_dup_f64 (const float64_t *ptr);

bfloat16x4x3_t vld3_dup_bf16 (const bfloat16_t *ptr);
```

```c
poly8x8x3_t vld3_dup_p8 (const poly8_t *ptr);
poly16x4x3_t vld3_dup_p16 (const poly16_t *ptr);
poly64x1x3_t vld3_dup_p64 (const poly64_t *ptr);
```

#### vld4_dup

* 运算： `V[n][i] = ptr[n]`

```c
int8x8x4_t vld4_dup_s8 (const int8_t *ptr);
int16x4x4_t vld4_dup_s16 (const int16_t *ptr);
int32x2x4_t vld4_dup_s32 (const int32_t *ptr);
int64x1x4_t vld4_dup_s64 (const int64_t *ptr);
```

```c
uint8x8x4_t vld4_dup_u8 (const uint8_t *ptr);
uint16x4x4_t vld4_dup_u16 (const uint16_t *ptr);
uint32x2x4_t vld4_dup_u32 (const uint32_t *ptr);
uint64x1x4_t vld4_dup_u64 (const uint64_t *ptr);
```

```c
float16x4x4_t vld4_dup_f16 (const float16_t *ptr);
float32x2x4_t vld4_dup_f32 (const float32_t *ptr);
float64x1x4_t vld4_dup_f64 (const float64_t *ptr);

bfloat16x4x4_t vld4_dup_bf16 (const bfloat16_t *ptr);
```

```c
poly8x8x4_t vld4_dup_p8 (const poly8_t *ptr);
poly16x4x4_t vld4_dup_p16 (const poly16_t *ptr);
poly64x1x4_t vld4_dup_p64 (const poly64_t *ptr);
```
#### vld2_lane

* 运算： `V[n][i] = src[n][i]; then V[n][lane] = ptr[n]`

```c
int8x8x2_t vld2_lane_s8 (const int8_t *ptr, int8x8x2_t src, const int lane);
int16x4x2_t vld2_lane_s16 (const int16_t *ptr, int16x4x2_t src, const int lane);
int32x2x2_t vld2_lane_s32 (const int32_t *ptr, int32x2x2_t src, const int lane);
int64x1x2_t vld2_lane_s64 (const int64_t *ptr, int64x1x2_t src, const int lane);
```

```c
uint8x8x2_t vld2_lane_u8 (const uint8_t *ptr, uint8x8x2_t src, const int lane);
uint16x4x2_t vld2_lane_u16 (const uint16_t *ptr, uint16x4x2_t src, const int lane);
uint32x2x2_t vld2_lane_u32 (const uint32_t *ptr, uint32x2x2_t src, const int lane);
uint64x1x2_t vld2_lane_u64 (const uint64_t *ptr, uint64x1x2_t src, const int lane);
```

```c
float16x4x2_t vld2_lane_f16 (const float16_t *ptr, float16x4x2_t src, const int lane);
float32x2x2_t vld2_lane_f32 (const float32_t *ptr, float32x2x2_t src, const int lane);
float64x1x2_t vld2_lane_f64 (const float64_t *ptr, float64x1x2_t src, const int lane);

bfloat16x4x2_t vld2_lane_bf16 (const bfloat16_t *ptr, bfloat16x4x2_t src, const int lane);
```

```c
poly8x8x2_t vld2_lane_p8 (const poly8_t *ptr, poly8x8x2_t src, const int lane);
poly16x4x2_t vld2_lane_p16 (const poly16_t *ptr, poly16x4x2_t src, const int lane);
poly64x1x2_t vld2_lane_p64 (const poly64_t *ptr, poly64x1x2_t src, const int lane);
```

#### vld3_lane

* 运算： `V[n][i] = src[n][i]; then V[n][lane] = ptr[n]`

```c
int8x8x3_t vld3_lane_s8 (const int8_t *ptr, int8x8x3_t src, const int lane);
int16x4x3_t vld3_lane_s16 (const int16_t *ptr, int16x4x3_t src, const int lane);
int32x2x3_t vld3_lane_s32 (const int32_t *ptr, int32x2x3_t src, const int lane);
int64x1x3_t vld3_lane_s64 (const int64_t *ptr, int64x1x3_t src, const int lane);
```

```c
uint8x8x3_t vld3_lane_u8 (const uint8_t *ptr, uint8x8x3_t src, const int lane);
uint16x4x3_t vld3_lane_u16 (const uint16_t *ptr, uint16x4x3_t src, const int lane);
uint32x2x3_t vld3_lane_u32 (const uint32_t *ptr, uint32x2x3_t src, const int lane);
uint64x1x3_t vld3_lane_u64 (const uint64_t *ptr, uint64x1x3_t src, const int lane);
```

```c
float16x4x3_t vld3_lane_f16 (const float16_t *ptr, float16x4x3_t src, const int lane);
float32x2x3_t vld3_lane_f32 (const float32_t *ptr, float32x2x3_t src, const int lane);
float64x1x3_t vld3_lane_f64 (const float64_t *ptr, float64x1x3_t src, const int lane);
bfloat16x4x3_t vld3_lane_bf16 (const bfloat16_t *ptr, bfloat16x4x3_t src, const int lane);
```

```c
poly8x8x3_t vld3_lane_p8 (const poly8_t *ptr, poly8x8x3_t src, const int lane);
poly16x4x3_t vld3_lane_p16 (const poly16_t *ptr, poly16x4x3_t src, const int lane);
poly64x1x3_t vld3_lane_p64 (const poly64_t *ptr, poly64x1x3_t src, const int lane);
```

#### vld4_lane

* 运算： `V[n][i] = src[n][i]; then V[n][lane] = ptr[n]`

```c
int8x8x4_t vld4_lane_s8 (const int8_t *ptr, int8x8x4_t src, const int lane);
int16x4x4_t vld4_lane_s16 (const int16_t *ptr, int16x4x4_t src, const int lane);
int32x2x4_t vld4_lane_s32 (const int32_t *ptr, int32x2x4_t src, const int lane);
int64x1x4_t vld4_lane_s64 (const int64_t *ptr, int64x1x4_t src, const int lane);
```

```c
uint8x8x4_t vld4_lane_u8 (const uint8_t *ptr, uint8x8x4_t src, const int lane);
uint16x4x4_t vld4_lane_u16 (const uint16_t *ptr, uint16x4x4_t src, const int lane);
uint32x2x4_t vld4_lane_u32 (const uint32_t *ptr, uint32x2x4_t src, const int lane);
uint64x1x4_t vld4_lane_u64 (const uint64_t *ptr, uint64x1x4_t src, const int lane);
```

```c
float16x4x4_t vld4_lane_f16 (const float16_t *ptr, float16x4x4_t src, const int lane);
float32x2x4_t vld4_lane_f32 (const float32_t *ptr, float32x2x4_t src, const int lane);
float64x1x4_t vld4_lane_f64 (const float64_t *ptr, float64x1x4_t src, const int lane);

bfloat16x4x4_t vld4_lane_bf16 (const bfloat16_t *ptr, bfloat16x4x4_t src, const int lane);
```

```c
poly8x8x4_t vld4_lane_p8 (const poly8_t *ptr, poly8x8x4_t src, const int lane);
poly16x4x4_t vld4_lane_p16 (const poly16_t *ptr, poly16x4x4_t src, const int lane);
poly64x1x4_t vld4_lane_p64 (const poly64_t *ptr, poly64x1x4_t src, const int lane);
```

### 全指令指令多向量交错加载

#### vld2q

* 运算： `V[n][i] = ptr[2i + n]`

```c
int8x16x2_t vld2q_s8 (const int8_t *ptr);
int16x8x2_t vld2q_s16 (const int16_t *ptr);
int32x4x2_t vld2q_s32 (const int32_t *ptr);
int64x2x2_t vld2q_s64 (const int64_t *ptr);
```

```c
uint8x16x2_t vld2q_u8 (const uint8_t *ptr);
uint16x8x2_t vld2q_u16 (const uint16_t *ptr);
uint32x4x2_t vld2q_u32 (const uint32_t *ptr);
uint64x2x2_t vld2q_u64 (const uint64_t *ptr);
```

```c
float16x8x2_t vld2q_f16 (const float16_t *ptr);
float32x4x2_t vld2q_f32 (const float32_t *ptr);
float64x2x2_t vld2q_f64 (const float64_t *ptr);
bfloat16x8x2_t vld2q_bf16 (const bfloat16_t *ptr);
```

```c
poly8x16x2_t vld2q_p8 (const poly8_t *ptr);
poly16x8x2_t vld2q_p16 (const poly16_t *ptr);
poly64x2x2_t vld2q_p64 (const poly64_t *ptr);
```

#### vld3q

* 运算： `V[n][i] = ptr[3i + n]`

```c
int8x16x3_t vld3q_s8 (const int8_t *ptr);
int16x8x3_t vld3q_s16 (const int16_t *ptr);
int32x4x3_t vld3q_s32 (const int32_t *ptr);
int64x2x3_t vld3q_s64 (const int64_t *ptr);
```

```c
uint8x16x3_t vld3q_u8 (const uint8_t *ptr);
uint16x8x3_t vld3q_u16 (const uint16_t *ptr);
uint32x4x3_t vld3q_u32 (const uint32_t *ptr);
uint64x2x3_t vld3q_u64 (const uint64_t *ptr);
```

```c
float16x8x3_t vld3q_f16 (const float16_t *ptr);
float32x4x3_t vld3q_f32 (const float32_t *ptr);
float64x2x3_t vld3q_f64 (const float64_t *ptr);

bfloat16x8x3_t vld3q_bf16 (const bfloat16_t *ptr);
```

```c
poly8x16x3_t vld3q_p8 (const poly8_t *ptr);
poly16x8x3_t vld3q_p16 (const poly16_t *ptr);
poly64x2x3_t vld3q_p64 (const poly64_t *ptr);
```

#### vld4q

* 运算： `V[n][i] = ptr[4i + n]`

```c
int8x16x4_t vld4q_s8 (const int8_t *ptr);
int16x8x4_t vld4q_s16 (const int16_t *ptr);
int32x4x4_t vld4q_s32 (const int32_t *ptr);
int64x2x4_t vld4q_s64 (const int64_t *ptr);
```

```c
uint8x16x4_t vld4q_u8 (const uint8_t *ptr);
uint16x8x4_t vld4q_u16 (const uint16_t *ptr);
uint32x4x4_t vld4q_u32 (const uint32_t *ptr);
uint64x2x4_t vld4q_u64 (const uint64_t *ptr);
```

```c
float16x8x4_t vld4q_f16 (const float16_t *ptr);
float32x4x4_t vld4q_f32 (const float32_t *ptr);
float64x2x4_t vld4q_f64 (const float64_t *ptr);
bfloat16x8x4_t vld4q_bf16 (const bfloat16_t *ptr);
```

```c
poly8x16x4_t vld4q_p8 (const poly8_t *ptr);
poly16x8x4_t vld4q_p16 (const poly16_t *ptr);
poly64x2x4_t vld4q_p64 (const poly64_t *ptr);
```

#### vld2q_dup

* 运算： `V[n][i] = ptr[n]`

```c
int8x16x2_t vld2q_dup_s8 (const int8_t *ptr);
int16x8x2_t vld2q_dup_s16 (const int16_t *ptr);
int32x4x2_t vld2q_dup_s32 (const int32_t *ptr);
int64x2x2_t vld2q_dup_s64 (const int64_t *ptr);
```

```c
uint8x16x2_t vld2q_dup_u8 (const uint8_t *ptr);
uint16x8x2_t vld2q_dup_u16 (const uint16_t *ptr);
uint32x4x2_t vld2q_dup_u32 (const uint32_t *ptr);
uint64x2x2_t vld2q_dup_u64 (const uint64_t *ptr);
```

```c
float16x8x2_t vld2q_dup_f16 (const float16_t *ptr);
float32x4x2_t vld2q_dup_f32 (const float32_t *ptr);
float64x2x2_t vld2q_dup_f64 (const float64_t *ptr);
bfloat16x8x2_t vld2q_dup_bf16 (const bfloat16_t *ptr);
```

```c
poly8x16x2_t vld2q_dup_p8 (const poly8_t *ptr);
poly16x8x2_t vld2q_dup_p16 (const poly16_t *ptr);
poly64x2x2_t vld2q_dup_p64 (const poly64_t *ptr);
```

#### vld3q_dup

* 运算： `V[n][i] = ptr[n]`

```c
int8x16x3_t vld3q_dup_s8 (const int8_t *ptr);
int16x8x3_t vld3q_dup_s16 (const int16_t *ptr);
int32x4x3_t vld3q_dup_s32 (const int32_t *ptr);
int64x2x3_t vld3q_dup_s64 (const int64_t *ptr);
```

```c
uint8x16x3_t vld3q_dup_u8 (const uint8_t *ptr);
uint16x8x3_t vld3q_dup_u16 (const uint16_t *ptr);
uint32x4x3_t vld3q_dup_u32 (const uint32_t *ptr);
uint64x2x3_t vld3q_dup_u64 (const uint64_t *ptr);
```

```c
float16x8x3_t vld3q_dup_f16 (const float16_t *ptr);
float32x4x3_t vld3q_dup_f32 (const float32_t *ptr);
float64x2x3_t vld3q_dup_f64 (const float64_t *ptr);
bfloat16x8x3_t vld3q_dup_bf16 (const bfloat16_t *ptr);
```

```c
poly8x16x3_t vld3q_dup_p8 (const poly8_t *ptr);
poly16x8x3_t vld3q_dup_p16 (const poly16_t *ptr);
poly64x2x3_t vld3q_dup_p64 (const poly64_t *ptr);
```

#### vld4q_dup

* 运算： `V[n][i] = ptr[n]`

```c
int8x16x4_t vld4q_dup_s8 (const int8_t *ptr);
int16x8x4_t vld4q_dup_s16 (const int16_t *ptr);
int32x4x4_t vld4q_dup_s32 (const int32_t *ptr);
int64x2x4_t vld4q_dup_s64 (const int64_t *ptr);
```

```c
uint8x16x4_t vld4q_dup_u8 (const uint8_t *ptr);
uint16x8x4_t vld4q_dup_u16 (const uint16_t *ptr);
uint32x4x4_t vld4q_dup_u32 (const uint32_t *ptr);
uint64x2x4_t vld4q_dup_u64 (const uint64_t *ptr);
```

```c
float16x8x4_t vld4q_dup_f16 (const float16_t *ptr);
float32x4x4_t vld4q_dup_f32 (const float32_t *ptr);
float64x2x4_t vld4q_dup_f64 (const float64_t *ptr);
bfloat16x8x4_t vld4q_dup_bf16 (const bfloat16_t *ptr);
```

```c
poly8x16x4_t vld4q_dup_p8 (const poly8_t *ptr);
poly16x8x4_t vld4q_dup_p16 (const poly16_t *ptr);
poly64x2x4_t vld4q_dup_p64 (const poly64_t *ptr);
```

#### vld2q_lane

* 运算： `V[n][i] = src[n][i]; then V[n][lane] = ptr[n]`

```c
int8x16x2_t vld2q_lane_s8 (const int8_t *ptr, int8x16x2_t src, const int lane);
int16x8x2_t vld2q_lane_s16 (const int16_t *ptr, int16x8x2_t src, const int lane);
int32x4x2_t vld2q_lane_s32 (const int32_t *ptr, int32x4x2_t src, const int lane);
int64x2x2_t vld2q_lane_s64 (const int64_t *ptr, int64x2x2_t src, const int lane);
```

```c
uint8x16x2_t vld2q_lane_u8 (const uint8_t *ptr, uint8x16x2_t src, const int lane);
uint16x8x2_t vld2q_lane_u16 (const uint16_t *ptr, uint16x8x2_t src, const int lane);
uint32x4x2_t vld2q_lane_u32 (const uint32_t *ptr, uint32x4x2_t src, const int lane);
uint64x2x2_t vld2q_lane_u64 (const uint64_t *ptr, uint64x2x2_t src, const int lane);
```

```c
float16x8x2_t vld2q_lane_f16 (const float16_t *ptr, float16x8x2_t src, const int lane);
float32x4x2_t vld2q_lane_f32 (const float32_t *ptr, float32x4x2_t src, const int lane);
float64x2x2_t vld2q_lane_f64 (const float64_t *ptr, float64x2x2_t src, const int lane);

bfloat16x8x2_t vld2q_lane_bf16 (const bfloat16_t *ptr, bfloat16x8x2_t src, const int lane);
```

```c
poly8x16x2_t vld2q_lane_p8 (const poly8_t *ptr, poly8x16x2_t src, const int lane);
poly16x8x2_t vld2q_lane_p16 (const poly16_t *ptr, poly16x8x2_t src, const int lane);
poly64x2x2_t vld2q_lane_p64 (const poly64_t *ptr, poly64x2x2_t src, const int lane);
```

#### vld3q_lane

* 运算： `V[n][i] = src[n][i]; then V[n][lane] = ptr[n]`

```c
int8x16x3_t vld3q_lane_s8 (const int8_t *ptr, int8x16x3_t src, const int lane);
int16x8x3_t vld3q_lane_s16 (const int16_t *ptr, int16x8x3_t src, const int lane);
int32x4x3_t vld3q_lane_s32 (const int32_t *ptr, int32x4x3_t src, const int lane);
int64x2x3_t vld3q_lane_s64 (const int64_t *ptr, int64x2x3_t src, const int lane);
```

```c
uint8x16x3_t vld3q_lane_u8 (const uint8_t *ptr, uint8x16x3_t src, const int lane);
uint16x8x3_t vld3q_lane_u16 (const uint16_t *ptr, uint16x8x3_t src, const int lane);
uint32x4x3_t vld3q_lane_u32 (const uint32_t *ptr, uint32x4x3_t src, const int lane);
uint64x2x3_t vld3q_lane_u64 (const uint64_t *ptr, uint64x2x3_t src, const int lane);
```

```c
float16x8x3_t vld3q_lane_f16 (const float16_t *ptr, float16x8x3_t src, const int lane);
float32x4x3_t vld3q_lane_f32 (const float32_t *ptr, float32x4x3_t src, const int lane);
float64x2x3_t vld3q_lane_f64 (const float64_t *ptr, float64x2x3_t src, const int lane);

bfloat16x8x3_t vld3q_lane_bf16 (const bfloat16_t *ptr, bfloat16x8x3_t src, const int lane);
```

```c
poly8x16x3_t vld3q_lane_p8 (const poly8_t *ptr, poly8x16x3_t src, const int lane);
poly16x8x3_t vld3q_lane_p16 (const poly16_t *ptr, poly16x8x3_t src, const int lane);
poly64x2x3_t vld3q_lane_p64 (const poly64_t *ptr, poly64x2x3_t src, const int lane);
```

#### vld4q_lane

* 运算： `V[n][i] = src[n][i]; then V[n][lane] = ptr[n]`

```c
int8x16x4_t vld4q_lane_s8 (const int8_t *ptr, int8x16x4_t src, const int lane);
int16x8x4_t vld4q_lane_s16 (const int16_t *ptr, int16x8x4_t src, const int lane);
int32x4x4_t vld4q_lane_s32 (const int32_t *ptr, int32x4x4_t src, const int lane);
int64x2x4_t vld4q_lane_s64 (const int64_t *ptr, int64x2x4_t src, const int lane);
```

```c
uint8x16x4_t vld4q_lane_u8 (const uint8_t *ptr, uint8x16x4_t src, const int lane);
uint16x8x4_t vld4q_lane_u16 (const uint16_t *ptr, uint16x8x4_t src, const int lane);
uint32x4x4_t vld4q_lane_u32 (const uint32_t *ptr, uint32x4x4_t src, const int lane);
uint64x2x4_t vld4q_lane_u64 (const uint64_t *ptr, uint64x2x4_t src, const int lane);
```

```c
float16x8x4_t vld4q_lane_f16 (const float16_t *ptr, float16x8x4_t src, const int lane);
float32x4x4_t vld4q_lane_f32 (const float32_t *ptr, float32x4x4_t src, const int lane);
float64x2x4_t vld4q_lane_f64 (const float64_t *ptr, float64x2x4_t src, const int lane);

bfloat16x8x4_t vld4q_lane_bf16 (const bfloat16_t *ptr, bfloat16x8x4_t src, const int lane);
```

```c
poly8x16x4_t vld4q_lane_p8 (const poly8_t *ptr, poly8x16x4_t src, const int lane);
poly16x8x4_t vld4q_lane_p16 (const poly16_t *ptr, poly16x8x4_t src, const int lane);
poly64x2x4_t vld4q_lane_p64 (const poly64_t *ptr, poly64x2x4_t src, const int lane);
```

## vstN多向量交错存储指令

### 短指令多向量交错存储

#### vst2

* 运算： `ptr[2i + n] = val[n][i]`

```c
void vst2_s8 (int8_t *ptr, int8x8x2_t val);
void vst2_s16 (int16_t *ptr, int16x4x2_t val);
void vst2_s32 (int32_t *ptr, int32x2x2_t val);
void vst2_s64 (int64_t *ptr, int64x1x2_t val);
```

```c
void vst2_u8 (uint8_t *ptr, uint8x8x2_t val);
void vst2_u16 (uint16_t *ptr, uint16x4x2_t val);
void vst2_u32 (uint32_t *ptr, uint32x2x2_t val);
void vst2_u64 (uint64_t *ptr, uint64x1x2_t val);
```

```c
void vst2_f16 (float16_t *ptr, float16x4x2_t val);
void vst2_f32 (float32_t *ptr, float32x2x2_t val);
void vst2_f64 (float64_t *ptr, float64x1x2_t val);

void vst2_bf16 (bfloat16_t *ptr, bfloat16x4x2_t val);
```

```c
void vst2_p8 (poly8_t *ptr, poly8x8x2_t val);
void vst2_p16 (poly16_t *ptr, poly16x4x2_t val);
void vst2_p64 (poly64_t *ptr, poly64x1x2_t val);
```

#### vst3

* 运算： `ptr[2i + n] = val[n][i]`

```c
void vst3_s8 (int8_t *ptr, int8x8x3_t val);
void vst3_s16 (int16_t *ptr, int16x4x3_t val);
void vst3_s32 (int32_t *ptr, int32x2x3_t val);
void vst3_s64 (int64_t *ptr, int64x1x3_t val);
```

```c
void vst3_u8 (uint8_t *ptr, uint8x8x3_t val);
void vst3_u16 (uint16_t *ptr, uint16x4x3_t val);
void vst3_u32 (uint32_t *ptr, uint32x2x3_t val);
void vst3_u64 (uint64_t *ptr, uint64x1x3_t val);
```

```c
void vst3_f16 (float16_t *ptr, float16x4x3_t val);
void vst3_f32 (float32_t *ptr, float32x2x3_t val);
void vst3_f64 (float64_t *ptr, float64x1x3_t val);

void vst3_bf16 (bfloat16_t *ptr, bfloat16x4x3_t val);
```

```c
void vst3_p8 (poly8_t *ptr, poly8x8x3_t val);
void vst3_p16 (poly16_t *ptr, poly16x4x3_t val);
void vst3_p64 (poly64_t *ptr, poly64x1x3_t val);
```

#### vst4

* 运算： `ptr[2i + n] = val[n][i]`

```c
void vst4_s8 (int8_t *ptr, int8x8x4_t val);
void vst4_s16 (int16_t *ptr, int16x4x4_t val);
void vst4_s32 (int32_t *ptr, int32x2x4_t val);
void vst4_s64 (int64_t *ptr, int64x1x4_t val);
```

```c
void vst4_u8 (uint8_t *ptr, uint8x8x4_t val);
void vst4_u16 (uint16_t *ptr, uint16x4x4_t val);
void vst4_u32 (uint32_t *ptr, uint32x2x4_t val);
void vst4_u64 (uint64_t *ptr, uint64x1x4_t val);
```

```c
void vst4_f16 (float16_t *ptr, float16x4x4_t val);
void vst4_f32 (float32_t *ptr, float32x2x4_t val);
void vst4_f64 (float64_t *ptr, float64x1x4_t val);

void vst4_bf16 (bfloat16_t *ptr, bfloat16x4x4_t val);
```

```c
void vst4_p8 (poly8_t *ptr, poly8x8x4_t val);
void vst4_p16 (poly16_t *ptr, poly16x4x4_t val);
void vst4_p64 (poly64_t *ptr, poly64x1x4_t val);
```
#### vst2_lane

* 运算： `ptr[n] = val[n][lane]`

```c
void vst2_lane_s8 (int8_t *ptr, int8x8x2_t val, const int lane);
void vst2_lane_s16 (int16_t *ptr, int16x4x2_t val, const int lane);
void vst2_lane_s32 (int32_t *ptr, int32x2x2_t val, const int lane);
void vst2_lane_s64 (int64_t *ptr, int64x1x2_t val, const int lane);
```

```c
void vst2_lane_u8 (uint8_t *ptr, uint8x8x2_t val, const int lane);
void vst2_lane_u16 (uint16_t *ptr, uint16x4x2_t val, const int lane);
void vst2_lane_u32 (uint32_t *ptr, uint32x2x2_t val, const int lane);
void vst2_lane_u64 (uint64_t *ptr, uint64x1x2_t val, const int lane);
```

```c
void vst2_lane_f16 (float16_t *ptr, float16x4x2_t val, const int lane);
void vst2_lane_f32 (float32_t *ptr, float32x2x2_t val, const int lane);
void vst2_lane_f64 (float64_t *ptr, float64x1x2_t val, const int lane);
void vst2_lane_bf16 (bfloat16_t *ptr, bfloat16x4x2_t val, const int lane);
```

```c
void vst2_lane_p8 (poly8_t *ptr, poly8x8x2_t val, const int lane);
void vst2_lane_p16 (poly16_t *ptr, poly16x4x2_t val, const int lane);
void vst2_lane_p64 (poly64_t *ptr, poly64x1x2_t val, const int lane);
```

#### vst3_lane

* 运算： `ptr[n] = val[n][lane]`

```c
void vst3_lane_s8 (int8_t *ptr, int8x8x3_t val, const int lane);
void vst3_lane_s16 (int16_t *ptr, int16x4x3_t val, const int lane);
void vst3_lane_s32 (int32_t *ptr, int32x2x3_t val, const int lane);
void vst3_lane_s64 (int64_t *ptr, int64x1x3_t val, const int lane);
```

```c
void vst3_lane_u8 (uint8_t *ptr, uint8x8x3_t val, const int lane);
void vst3_lane_u16 (uint16_t *ptr, uint16x4x3_t val, const int lane);
void vst3_lane_u32 (uint32_t *ptr, uint32x2x3_t val, const int lane);
void vst3_lane_u64 (uint64_t *ptr, uint64x1x3_t val, const int lane);
```

```c
void vst3_lane_f16 (float16_t *ptr, float16x4x3_t val, const int lane);
void vst3_lane_f32 (float32_t *ptr, float32x2x3_t val, const int lane);
void vst3_lane_f64 (float64_t *ptr, float64x1x3_t val, const int lane);

void vst3_lane_bf16 (bfloat16_t *ptr, bfloat16x4x3_t val, const int lane);
```

```c
void vst3_lane_p8 (poly8_t *ptr, poly8x8x3_t val, const int lane);
void vst3_lane_p16 (poly16_t *ptr, poly16x4x3_t val, const int lane);
void vst3_lane_p64 (poly64_t *ptr, poly64x1x3_t val, const int lane);
```

#### vst4_lane

* 运算： `ptr[n] = val[n][lane]`

```c
void vst4_lane_s8 (int8_t *ptr, int8x8x4_t val, const int lane);
void vst4_lane_s16 (int16_t *ptr, int16x4x4_t val, const int lane);
void vst4_lane_s32 (int32_t *ptr, int32x2x4_t val, const int lane);
void vst4_lane_s64 (int64_t *ptr, int64x1x4_t val, const int lane);
```

```c
void vst4_lane_u8 (uint8_t *ptr, uint8x8x4_t val, const int lane);
void vst4_lane_u16 (uint16_t *ptr, uint16x4x4_t val, const int lane);
void vst4_lane_u32 (uint32_t *ptr, uint32x2x4_t val, const int lane);
void vst4_lane_u64 (uint64_t *ptr, uint64x1x4_t val, const int lane);
```

```c
void vst4_lane_f16 (float16_t *ptr, float16x4x4_t val, const int lane);
void vst4_lane_f32 (float32_t *ptr, float32x2x4_t val, const int lane);
void vst4_lane_f64 (float64_t *ptr, float64x1x4_t val, const int lane);

void vst4_lane_bf16 (bfloat16_t *ptr, bfloat16x4x4_t val, const int lane);
```

```c
void vst4_lane_p8 (poly8_t *ptr, poly8x8x4_t val, const int lane);
void vst4_lane_p16 (poly16_t *ptr, poly16x4x4_t val, const int lane);
void vst4_lane_p64 (poly64_t *ptr, poly64x1x4_t val, const int lane);
```

### 全指令多向量交错存储

#### vst2q

* 运算： `ptr[2i + n] = val[n][i]`

```c
void vst2q_s8 (int8_t *ptr, int8x16x2_t val);
void vst2q_s16 (int16_t *ptr, int16x8x2_t val);
void vst2q_s32 (int32_t *ptr, int32x4x2_t val);
void vst2q_s64 (int64_t *ptr, int64x2x2_t val);
```

```c
void vst2q_u8 (uint8_t *ptr, uint8x16x2_t val);
void vst2q_u16 (uint16_t *ptr, uint16x8x2_t val);
void vst2q_u32 (uint32_t *ptr, uint32x4x2_t val);
void vst2q_u64 (uint64_t *ptr, uint64x2x2_t val);
```

```c
void vst2q_f16 (float16_t *ptr, float16x8x2_t val);
void vst2q_f32 (float32_t *ptr, float32x4x2_t val);
void vst2q_f64 (float64_t *ptr, float64x2x2_t val);

void vst2q_bf16 (bfloat16_t *ptr, bfloat16x8x2_t val);
```

```c
void vst2q_p8 (poly8_t *ptr, poly8x16x2_t val);
void vst2q_p16 (poly16_t *ptr, poly16x8x2_t val);
void vst2q_p64 (poly64_t *ptr, poly64x2x2_t val);
```

#### vst3q

* 运算： `ptr[2i + n] = val[n][i]`

```c
void vst3q_s8 (int8_t *ptr, int8x16x3_t val);
void vst3q_s16 (int16_t *ptr, int16x8x3_t val);
void vst3q_s32 (int32_t *ptr, int32x4x3_t val);
void vst3q_s64 (int64_t *ptr, int64x2x3_t val);
```

```c
void vst3q_u8 (uint8_t *ptr, uint8x16x3_t val);
void vst3q_u16 (uint16_t *ptr, uint16x8x3_t val);
void vst3q_u32 (uint32_t *ptr, uint32x4x3_t val);
void vst3q_u64 (uint64_t *ptr, uint64x2x3_t val);
```

```c
void vst3q_f16 (float16_t *ptr, float16x8x3_t val);
void vst3q_f32 (float32_t *ptr, float32x4x3_t val);
void vst3q_f64 (float64_t *ptr, float64x2x3_t val);

void vst3q_bf16 (bfloat16_t *ptr, bfloat16x8x3_t val);
```

```c
void vst3q_p8 (poly8_t *ptr, poly8x16x3_t val);
void vst3q_p16 (poly16_t *ptr, poly16x8x3_t val);
void vst3q_p64 (poly64_t *ptr, poly64x2x3_t val);
```

#### vst4q

* 运算： `ptr[2i + n] = val[n][i]`

```c
void vst4q_s8 (int8_t *ptr, int8x16x4_t val);
void vst4q_s16 (int16_t *ptr, int16x8x4_t val);
void vst4q_s32 (int32_t *ptr, int32x4x4_t val);
void vst4q_s64 (int64_t *ptr, int64x2x4_t val);
```

```c
void vst4q_u8 (uint8_t *ptr, uint8x16x4_t val);
void vst4q_u16 (uint16_t *ptr, uint16x8x4_t val);
void vst4q_u32 (uint32_t *ptr, uint32x4x4_t val);
void vst4q_u64 (uint64_t *ptr, uint64x2x4_t val);
```

```c
void vst4q_f16 (float16_t *ptr, float16x8x4_t val);
void vst4q_f32 (float32_t *ptr, float32x4x4_t val);
void vst4q_f64 (float64_t *ptr, float64x2x4_t val);

void vst4q_bf16 (bfloat16_t *ptr, bfloat16x8x4_t val);
```

```c
void vst4q_p8 (poly8_t *ptr, poly8x16x4_t val);
void vst4q_p16 (poly16_t *ptr, poly16x8x4_t val);
void vst4q_p64 (poly64_t *ptr, poly64x2x4_t val);
```

#### vst2q_lane

* 运算： `ptr[n] = val[n][lane]`

```c
void vst2q_lane_s8 (int8_t *ptr, int8x16x2_t val, const int lane);
void vst2q_lane_s16 (int16_t *ptr, int16x8x2_t val, const int lane);
void vst2q_lane_s32 (int32_t *ptr, int32x4x2_t val, const int lane);
void vst2q_lane_s64 (int64_t *ptr, int64x2x2_t val, const int lane);
```

```c
void vst2q_lane_u8 (uint8_t *ptr, uint8x16x2_t val, const int lane);
void vst2q_lane_u16 (uint16_t *ptr, uint16x8x2_t val, const int lane);
void vst2q_lane_u32 (uint32_t *ptr, uint32x4x2_t val, const int lane);
void vst2q_lane_u64 (uint64_t *ptr, uint64x2x2_t val, const int lane);
```

```c
void vst2q_lane_f16 (float16_t *ptr, float16x8x2_t val, const int lane);
void vst2q_lane_f32 (float32_t *ptr, float32x4x2_t val, const int lane);
void vst2q_lane_f64 (float64_t *ptr, float64x2x2_t val, const int lane);
void vst2q_lane_bf16 (bfloat16_t *ptr, bfloat16x8x2_t val, const int lane);
```

```c
void vst2q_lane_p8 (poly8_t *ptr, poly8x16x2_t val, const int lane);
void vst2q_lane_p16 (poly16_t *ptr, poly16x8x2_t val, const int lane);
void vst2q_lane_p64 (poly64_t *ptr, poly64x2x2_t val, const int lane);
```

#### vst3q_lane

* 运算： `ptr[n] = val[n][lane]`

```c
void vst3q_lane_s8 (int8_t *ptr, int8x16x3_t val, const int lane);
void vst3q_lane_s16 (int16_t *ptr, int16x8x3_t val, const int lane);
void vst3q_lane_s32 (int32_t *ptr, int32x4x3_t val, const int lane);
void vst3q_lane_s64 (int64_t *ptr, int64x2x3_t val, const int lane);
```

```c
void vst3q_lane_u8 (uint8_t *ptr, uint8x16x3_t val, const int lane);
void vst3q_lane_u16 (uint16_t *ptr, uint16x8x3_t val, const int lane);
void vst3q_lane_u32 (uint32_t *ptr, uint32x4x3_t val, const int lane);
void vst3q_lane_u64 (uint64_t *ptr, uint64x2x3_t val, const int lane);
```

```c
void vst3q_lane_f16 (float16_t *ptr, float16x8x3_t val, const int lane);
void vst3q_lane_f32 (float32_t *ptr, float32x4x3_t val, const int lane);
void vst3q_lane_f64 (float64_t *ptr, float64x2x3_t val, const int lane);
void vst3q_lane_bf16 (bfloat16_t *ptr, bfloat16x8x3_t val, const int lane);
```

```c
void vst3q_lane_p8 (poly8_t *ptr, poly8x16x3_t val, const int lane);
void vst3q_lane_p16 (poly16_t *ptr, poly16x8x3_t val, const int lane);
void vst3q_lane_p64 (poly64_t *ptr, poly64x2x3_t val, const int lane);
```

#### vst4q_lane

* 运算： `ptr[n] = val[n][lane]`

```c
void vst4q_lane_s8 (int8_t *ptr, int8x16x4_t val, const int lane);
void vst4q_lane_s16 (int16_t *ptr, int16x8x4_t val, const int lane);
void vst4q_lane_s32 (int32_t *ptr, int32x4x4_t val, const int lane);
void vst4q_lane_s64 (int64_t *ptr, int64x2x4_t val, const int lane);
```

```c
void vst4q_lane_u8 (uint8_t *ptr, uint8x16x4_t val, const int lane);
void vst4q_lane_u16 (uint16_t *ptr, uint16x8x4_t val, const int lane);
void vst4q_lane_u32 (uint32_t *ptr, uint32x4x4_t val, const int lane);
void vst4q_lane_u64 (uint64_t *ptr, uint64x2x4_t val, const int lane);
```

```c
void vst4q_lane_f16 (float16_t *ptr, float16x8x4_t val, const int lane);
void vst4q_lane_f32 (float32_t *ptr, float32x4x4_t val, const int lane);
void vst4q_lane_f64 (float64_t *ptr, float64x2x4_t val, const int lane);

void vst4q_lane_bf16 (bfloat16_t *ptr, bfloat16x8x4_t val, const int lane);
```

```c
void vst4q_lane_p8 (poly8_t *ptr, poly8x16x4_t val, const int lane);
void vst4q_lane_p16 (poly16_t *ptr, poly16x8x4_t val, const int lane);
void vst4q_lane_p64 (poly64_t *ptr, poly64x2x4_t val, const int lane);
```

## vld1xN多向量连续加载指令

### 短指令多向量连续加载

#### vld1x2

* 运算： `V[n][i] = ptr[L*n + i]`

```c
int8x8x2_t vld1_s8_x2 (const int8_t *ptr);
int16x4x2_t vld1_s16_x2 (const int16_t *ptr);
int32x2x2_t vld1_s32_x2 (const int32_t *ptr);
int64x1x2_t vld1_s64_x2 (const int64_t *ptr);
```

```c
uint8x8x2_t vld1_u8_x2 (const uint8_t *ptr);
uint16x4x2_t vld1_u16_x2 (const uint16_t *ptr);
uint32x2x2_t vld1_u32_x2 (const uint32_t *ptr);
uint64x1x2_t vld1_u64_x2 (const uint64_t *ptr);
```

```c
float16x4x2_t vld1_f16_x2 (const float16_t *ptr);
float32x2x2_t vld1_f32_x2 (const float32_t *ptr);
float64x1x2_t vld1_f64_x2 (const float64_t *ptr);

bfloat16x4x2_t vld1_bf16_x2 (const bfloat16_t *ptr);
```

```c
poly8x8x2_t vld1_p8_x2 (const poly8_t *ptr);
poly16x4x2_t vld1_p16_x2 (const poly16_t *ptr);
poly64x1x2_t vld1_p64_x2 (const poly64_t *ptr);
```

#### vld1x3

* 运算： `V[n][i] = ptr[L*n + i]`

```c
int8x8x3_t vld1_s8_x3 (const int8_t *ptr);
int16x4x3_t vld1_s16_x3 (const int16_t *ptr);
int32x2x3_t vld1_s32_x3 (const int32_t *ptr);
int64x1x3_t vld1_s64_x3 (const int64_t *ptr);
```

```c
uint8x8x3_t vld1_u8_x3 (const uint8_t *ptr);
uint16x4x3_t vld1_u16_x3 (const uint16_t *ptr);
uint32x2x3_t vld1_u32_x3 (const uint32_t *ptr);
uint64x1x3_t vld1_u64_x3 (const uint64_t *ptr);
```

```c
float16x4x3_t vld1_f16_x3 (const float16_t *ptr);
float32x2x3_t vld1_f32_x3 (const float32_t *ptr);
float64x1x3_t vld1_f64_x3 (const float64_t *ptr);

bfloat16x4x3_t vld1_bf16_x3 (const bfloat16_t *ptr);
```

```c
poly8x8x3_t vld1_p8_x3 (const poly8_t *ptr);
poly16x4x3_t vld1_p16_x3 (const poly16_t *ptr);
poly64x1x3_t vld1_p64_x3 (const poly64_t *ptr);
```

#### vld1x4

* 运算： `V[n][i] = ptr[L*n + i]`

```c
int8x8x4_t vld1_s8_x4 (const int8_t *ptr);
int16x4x4_t vld1_s16_x4 (const int16_t *ptr);
int32x2x4_t vld1_s32_x4 (const int32_t *ptr);
int64x1x4_t vld1_s64_x4 (const int64_t *ptr);
```

```c
uint8x8x4_t vld1_u8_x4 (const uint8_t *ptr);
uint16x4x4_t vld1_u16_x4 (const uint16_t *ptr);
uint32x2x4_t vld1_u32_x4 (const uint32_t *ptr);
uint64x1x4_t vld1_u64_x4 (const uint64_t *ptr);
```

```c
float16x4x4_t vld1_f16_x4 (const float16_t *ptr);
float32x2x4_t vld1_f32_x4 (const float32_t *ptr);
float64x1x4_t vld1_f64_x4 (const float64_t *ptr);

bfloat16x4x4_t vld1_bf16_x4 (const bfloat16_t *ptr);
```

```c
poly8x8x4_t vld1_p8_x4 (const poly8_t *ptr);
poly16x4x4_t vld1_p16_x4 (const poly16_t *ptr);
poly64x1x4_t vld1_p64_x4 (const poly64_t *ptr);
```

### 全指令多向量连续加载

#### vld1qx2

* 运算： `V[n][i] = ptr[L*n + i]`

```c
int8x16x2_t vld1q_s8_x2 (const int8_t *ptr);
int16x8x2_t vld1q_s16_x2 (const int16_t *ptr);
int32x4x2_t vld1q_s32_x2 (const int32_t *ptr);
int64x2x2_t vld1q_s64_x2 (const int64_t *ptr);
```

```c
uint8x16x2_t vld1q_u8_x2 (const uint8_t *ptr);
uint16x8x2_t vld1q_u16_x2 (const uint16_t *ptr);
uint32x4x2_t vld1q_u32_x2 (const uint32_t *ptr);
uint64x2x2_t vld1q_u64_x2 (const uint64_t *ptr);
```

```c
float16x8x2_t vld1q_f16_x2 (const float16_t *ptr);
float32x4x2_t vld1q_f32_x2 (const float32_t *ptr);
float64x2x2_t vld1q_f64_x2 (const float64_t *ptr);

bfloat16x8x2_t vld1q_bf16_x2 (const bfloat16_t *ptr);
```

```c
poly8x16x2_t vld1q_p8_x2 (const poly8_t *ptr);
poly16x8x2_t vld1q_p16_x2 (const poly16_t *ptr);
poly64x2x2_t vld1q_p64_x2 (const poly64_t *ptr);
```

#### vld1qx3

* 运算： `V[n][i] = ptr[L*n + i]`

```c
int8x16x3_t vld1q_s8_x3 (const int8_t *ptr);
int16x8x3_t vld1q_s16_x3 (const int16_t *ptr);
int32x4x3_t vld1q_s32_x3 (const int32_t *ptr);
int64x2x3_t vld1q_s64_x3 (const int64_t *ptr);
```

```c
uint8x16x3_t vld1q_u8_x3 (const uint8_t *ptr);
uint16x8x3_t vld1q_u16_x3 (const uint16_t *ptr);
uint32x4x3_t vld1q_u32_x3 (const uint32_t *ptr);
uint64x2x3_t vld1q_u64_x3 (const uint64_t *ptr);
```

```c
float16x8x3_t vld1q_f16_x3 (const float16_t *ptr);
float32x4x3_t vld1q_f32_x3 (const float32_t *ptr);
float64x2x3_t vld1q_f64_x3 (const float64_t *ptr);

bfloat16x8x3_t vld1q_bf16_x3 (const bfloat16_t *ptr);
```

```c
poly8x16x3_t vld1q_p8_x3 (const poly8_t *ptr);
poly16x8x3_t vld1q_p16_x3 (const poly16_t *ptr);
poly64x2x3_t vld1q_p64_x3 (const poly64_t *ptr);
```

#### vld1qx4

* 运算： `V[n][i] = ptr[L*n + i]`

```c
int8x16x4_t vld1q_s8_x4 (const int8_t *ptr);
int16x8x4_t vld1q_s16_x4 (const int16_t *ptr);
int32x4x4_t vld1q_s32_x4 (const int32_t *ptr);
int64x2x4_t vld1q_s64_x4 (const int64_t *ptr);
```

```c
uint8x16x4_t vld1q_u8_x4 (const uint8_t *ptr);
uint16x8x4_t vld1q_u16_x4 (const uint16_t *ptr);
uint32x4x4_t vld1q_u32_x4 (const uint32_t *ptr);
uint64x2x4_t vld1q_u64_x4 (const uint64_t *ptr);
```

```c
float16x8x4_t vld1q_f16_x4 (const float16_t *ptr);
float32x4x4_t vld1q_f32_x4 (const float32_t *ptr);
float64x2x4_t vld1q_f64_x4 (const float64_t *ptr);

bfloat16x8x4_t vld1q_bf16_x4 (const bfloat16_t *ptr);
```

```c
poly8x16x4_t vld1q_p8_x4 (const poly8_t *ptr);
poly16x8x4_t vld1q_p16_x4 (const poly16_t *ptr);
poly64x2x4_t vld1q_p64_x4 (const poly64_t *ptr);
```

## vst1xN多向量连续存储指令

### 短指令多向量连续存储

#### vst1x2

* 运算： `ptr[L*n + i] = val[n][i]`

```c
void vst1_s8_x2 (int8_t *ptr, int8x8x2_t val);
void vst1_s16_x2 (int16_t *ptr, int16x4x2_t val);
void vst1_s32_x2 (int32_t *ptr, int32x2x2_t val);
void vst1_s64_x2 (int64_t *ptr, int64x1x2_t val);
```

```c
void vst1_u8_x2 (uint8_t *ptr, uint8x8x2_t val);
void vst1_u16_x2 (uint16_t *ptr, uint16x4x2_t val);
void vst1_u32_x2 (uint32_t *ptr, uint32x2x2_t val);
void vst1_u64_x2 (uint64_t *ptr, uint64x1x2_t val);
```

```c
void vst1_f16_x2 (float16_t *ptr, float16x4x2_t val);
void vst1_f32_x2 (float32_t *ptr, float32x2x2_t val);
void vst1_f64_x2 (float64_t *ptr, float64x1x2_t val);

void vst1_bf16_x2 (bfloat16_t *ptr, bfloat16x4x2_t val);
```

```c
void vst1_p8_x2 (poly8_t *ptr, poly8x8x2_t val);
void vst1_p16_x2 (poly16_t *ptr, poly16x4x2_t val);
void vst1_p64_x2 (poly64_t *ptr, poly64x1x2_t val);
```

#### vst1x3

* 运算： `ptr[L*n + i] = val[n][i]`

```c
void vst1_s8_x3 (int8_t *ptr, int8x8x3_t val);
void vst1_s16_x3 (int16_t *ptr, int16x4x3_t val);
void vst1_s32_x3 (int32_t *ptr, int32x2x3_t val);
void vst1_s64_x3 (int64_t *ptr, int64x1x3_t val);
```

```c
void vst1_u8_x3 (uint8_t *ptr, uint8x8x3_t val);
void vst1_u16_x3 (uint16_t *ptr, uint16x4x3_t val);
void vst1_u32_x3 (uint32_t *ptr, uint32x2x3_t val);
void vst1_u64_x3 (uint64_t *ptr, uint64x1x3_t val);
```

```c
void vst1_f16_x3 (float16_t *ptr, float16x4x3_t val);
void vst1_f32_x3 (float32_t *ptr, float32x2x3_t val);
void vst1_f64_x3 (float64_t *ptr, float64x1x3_t val);

void vst1_bf16_x3 (bfloat16_t *ptr, bfloat16x4x3_t val);
```

```c
void vst1_p8_x3 (poly8_t *ptr, poly8x8x3_t val);
void vst1_p16_x3 (poly16_t *ptr, poly16x4x3_t val);
void vst1_p64_x3 (poly64_t *ptr, poly64x1x3_t val);
```

#### vst1x4

* 运算： `ptr[L*n + i] = val[n][i]`

```c
void vst1_s8_x4 (int8_t *ptr, int8x8x4_t val);
void vst1_s16_x4 (int16_t *ptr, int16x4x4_t val);
void vst1_s32_x4 (int32_t *ptr, int32x2x4_t val);
void vst1_s64_x4 (int64_t *ptr, int64x1x4_t val);
```

```c
void vst1_u8_x4 (uint8_t *ptr, uint8x8x4_t val);
void vst1_u16_x4 (uint16_t *ptr, uint16x4x4_t val);
void vst1_u32_x4 (uint32_t *ptr, uint32x2x4_t val);
void vst1_u64_x4 (uint64_t *ptr, uint64x1x4_t val);
```

```c
void vst1_f16_x4 (float16_t *ptr, float16x4x4_t val);
void vst1_f32_x4 (float32_t *ptr, float32x2x4_t val);
void vst1_f64_x4 (float64_t *ptr, float64x1x4_t val);
void vst1_bf16_x4 (bfloat16_t *ptr, bfloat16x4x4_t val);
```

```c
void vst1_p8_x4 (poly8_t *ptr, poly8x8x4_t val);
void vst1_p16_x4 (poly16_t *ptr, poly16x4x4_t val);
void vst1_p64_x4 (poly64_t *ptr, poly64x1x4_t val);
```

### 全指令多向量连续存储

#### vst1qx2

* 运算： `ptr[L*n + i] = val[n][i]`

```c
void vst1q_s8_x2 (int8_t *ptr, int8x16x2_t val);
void vst1q_s16_x2 (int16_t *ptr, int16x8x2_t val);
void vst1q_s32_x2 (int32_t *ptr, int32x4x2_t val);
void vst1q_s64_x2 (int64_t *ptr, int64x2x2_t val);
```

```c
void vst1q_u8_x2 (uint8_t *ptr, uint8x16x2_t val);
void vst1q_u16_x2 (uint16_t *ptr, uint16x8x2_t val);
void vst1q_u32_x2 (uint32_t *ptr, uint32x4x2_t val);
void vst1q_u64_x2 (uint64_t *ptr, uint64x2x2_t val);
```

```c
void vst1q_f16_x2 (float16_t *ptr, float16x8x2_t val);
void vst1q_f32_x2 (float32_t *ptr, float32x4x2_t val);
void vst1q_f64_x2 (float64_t *ptr, float64x2x2_t val);

void vst1q_bf16_x2 (bfloat16_t *ptr, bfloat16x8x2_t val);
```

```c
void vst1q_p8_x2 (poly8_t *ptr, poly8x16x2_t val);
void vst1q_p16_x2 (poly16_t *ptr, poly16x8x2_t val);
void vst1q_p64_x2 (poly64_t *ptr, poly64x2x2_t val);
```

#### vst1qx3

* 运算： `ptr[L*n + i] = val[n][i]`

```c
void vst1q_s8_x3 (int8_t *ptr, int8x16x3_t val);
void vst1q_s16_x3 (int16_t *ptr, int16x8x3_t val);
void vst1q_s32_x3 (int32_t *ptr, int32x4x3_t val);
void vst1q_s64_x3 (int64_t *ptr, int64x2x3_t val);
```

```c
void vst1q_u8_x3 (uint8_t *ptr, uint8x16x3_t val);
void vst1q_u16_x3 (uint16_t *ptr, uint16x8x3_t val);
void vst1q_u32_x3 (uint32_t *ptr, uint32x4x3_t val);
void vst1q_u64_x3 (uint64_t *ptr, uint64x2x3_t val);
```

```c
void vst1q_f16_x3 (float16_t *ptr, float16x8x3_t val);
void vst1q_f32_x3 (float32_t *ptr, float32x4x3_t val);
void vst1q_f64_x3 (float64_t *ptr, float64x2x3_t val);

void vst1q_bf16_x3 (bfloat16_t *ptr, bfloat16x8x3_t val);
```

```c
void vst1q_p8_x3 (poly8_t *ptr, poly8x16x3_t val);
void vst1q_p16_x3 (poly16_t *ptr, poly16x8x3_t val);
void vst1q_p64_x3 (poly64_t *ptr, poly64x2x3_t val);
```

#### vst1qx4

* 运算： `ptr[L*n + i] = val[n][i]`

```c
void vst1q_s8_x4 (int8_t *ptr, int8x16x4_t val);
void vst1q_s16_x4 (int16_t *ptr, int16x8x4_t val);
void vst1q_s32_x4 (int32_t *ptr, int32x4x4_t val);
void vst1q_s64_x4 (int64_t *ptr, int64x2x4_t val);
```

```c
void vst1q_u8_x4 (uint8_t *ptr, uint8x16x4_t val);
void vst1q_u16_x4 (uint16_t *ptr, uint16x8x4_t val);
void vst1q_u32_x4 (uint32_t *ptr, uint32x4x4_t val);
void vst1q_u64_x4 (uint64_t *ptr, uint64x2x4_t val);
```

```c
void vst1q_f16_x4 (float16_t *ptr, float16x8x4_t val);
void vst1q_f32_x4 (float32_t *ptr, float32x4x4_t val);
void vst1q_f64_x4 (float64_t *ptr, float64x2x4_t val);

void vst1q_bf16_x4 (bfloat16_t *ptr, bfloat16x8x4_t val);
```

```c
void vst1q_p8_x4 (poly8_t *ptr, poly8x16x4_t val);
void vst1q_p16_x4 (poly16_t *ptr, poly16x8x4_t val);
void vst1q_p64_x4 (poly64_t *ptr, poly64x2x4_t val);
```

## get获取指令

### 短指令获取

#### vget_lane

* 运算： `ret[i] = v[i]`

```c
int8_t vget_lane_s8 (int8x8_t v, const int lane);
int16_t vget_lane_s16 (int16x4_t v, const int lane); // _mm_extract_pi16 / _m_pextrw
int32_t vget_lane_s32 (int32x2_t v, const int lane);
int64_t vget_lane_s64 (int64x1_t v, const int lane);
```

```c
uint8_t vget_lane_u8 (uint8x8_t v, const int lane);
uint16_t vget_lane_u16 (uint16x4_t v, const int lane);
uint32_t vget_lane_u32 (uint32x2_t v, const int lane);
uint64_t vget_lane_u64 (uint64x1_t v, const int lane);
```

```c
float16_t vget_lane_f16 (float16x4_t v, const int lane);
float32_t vget_lane_f32 (float32x2_t v, const int lane);
float64_t vget_lane_f64 (float64x1_t v, const int lane);

bfloat16_t vget_lane_bf16 (bfloat16x4_t v, const int lane);
```

```c
poly8_t vget_lane_p8 (poly8x8_t v, const int lane);
poly16_t vget_lane_p16 (poly16x4_t v, const int lane);
poly64_t vget_lane_p64 (poly64x1_t v, const int lane);
```

### 全指令获取

#### vgetq_lane

* 运算： `ret[i] = v[i]`

```c
int8_t vgetq_lane_s8 (int8x16_t v, const int lane);   // _mm_extract_epi8  | _mm256_extract_epi8
int16_t vgetq_lane_s16 (int16x8_t v, const int lane); // _mm_extract_epi16 | _mm256_extract_epi16
int32_t vgetq_lane_s32 (int32x4_t v, const int lane); // _mm_extract_epi32 | _mm256_extract_epi32
int64_t vgetq_lane_s64 (int64x2_t v, const int lane); // _mm_extract_epi64 | _mm256_extract_epi64
```

```c
uint8_t vgetq_lane_u8 (uint8x16_t v, const int lane);
uint16_t vgetq_lane_u16 (uint16x8_t v, const int lane);
uint32_t vgetq_lane_u32 (uint32x4_t v, const int lane);
uint64_t vgetq_lane_u64 (uint64x2_t v, const int lane);
```

```c
float16_t vgetq_lane_f16 (float16x8_t v, const int lane);
float32_t vgetq_lane_f32 (float32x4_t v, const int lane); // _mm_extract_ps
float64_t vgetq_lane_f64 (float64x2_t v, const int lane);

bfloat16_t vgetq_lane_bf16 (bfloat16x8_t v, const int lane);
```

```c
poly8_t vgetq_lane_p8 (poly8x16_t v, const int lane);
poly16_t vgetq_lane_p16 (poly16x8_t v, const int lane);
poly64_t vgetq_lane_p64 (poly64x2_t v, const int lane);
```

#### vget_low

* 运算： `V = {a[0], a[1], ..., a[N-1]}`

```c
// _mm_movepi64_pi64
int8x8_t vget_low_s8 (int8x16_t a);
int16x4_t vget_low_s16 (int16x8_t a);
int32x2_t vget_low_s32 (int32x4_t a);
int64x1_t vget_low_s64 (int64x2_t a);
```

```c
uint8x8_t vget_low_u8 (uint8x16_t a);
uint16x4_t vget_low_u16 (uint16x8_t a);
uint32x2_t vget_low_u32 (uint32x4_t a);
uint64x1_t vget_low_u64 (uint64x2_t a);
```

```c
float16x4_t vget_low_f16 (float16x8_t a);
float32x2_t vget_low_f32 (float32x4_t a);
float64x1_t vget_low_f64 (float64x2_t a);

bfloat16x4_t vget_low_bf16 (bfloat16x8_t a);
```

```c
poly8x8_t vget_low_p8 (poly8x16_t a);
poly16x4_t vget_low_p16 (poly16x8_t a);
poly64x1_t vget_low_p64 (poly64x2_t a);
```

#### vget_high

* 运算： `V = {a[N], a[N+1], ..., a[2N-1]}`

```c
int8x8_t vget_high_s8 (int8x16_t a);
int16x4_t vget_high_s16 (int16x8_t a);
int32x2_t vget_high_s32 (int32x4_t a);
int64x1_t vget_high_s64 (int64x2_t a);
```

```c
uint8x8_t vget_high_u8 (uint8x16_t a);
uint16x4_t vget_high_u16 (uint16x8_t a);
uint32x2_t vget_high_u32 (uint32x4_t a);
uint64x1_t vget_high_u64 (uint64x2_t a);
```

```c
float16x4_t vget_high_f16 (float16x8_t a);
float32x2_t vget_high_f32 (float32x4_t a);
float64x1_t vget_high_f64 (float64x2_t a);

bfloat16x4_t vget_high_bf16 (bfloat16x8_t a);
```

```c
poly8x8_t vget_high_p8 (poly8x16_t a);
poly16x4_t vget_high_p16 (poly16x8_t a);
poly64x1_t vget_high_p64 (poly64x2_t a);
```

## set设置指令

### 短指令设置

#### vset_lane

* 运算： `ret[i] = src[i]; then ret[lane] = a`

```c
int8x8_t vset_lane_s8 (int8_t a, int8x8_t src, const int lane);
int16x4_t vset_lane_s16 (int16_t a, int16x4_t src, const int lane); // _mm_insert_pi16 (src, a, lane) / _m_pinsrw
int32x2_t vset_lane_s32 (int32_t a, int32x2_t src, const int lane);
int64x1_t vset_lane_s64 (int64_t a, int64x1_t src, const int lane);
```

```c
uint8x8_t vset_lane_u8 (uint8_t a, uint8x8_t src, const int lane);
uint16x4_t vset_lane_u16 (uint16_t a, uint16x4_t src, const int lane);
uint32x2_t vset_lane_u32 (uint32_t a, uint32x2_t src, const int lane);
uint64x1_t vset_lane_u64 (uint64_t a, uint64x1_t src, const int lane);
```

```c
float16x4_t vset_lane_f16 (float16_t a, float16x4_t src, const int lane);
float32x2_t vset_lane_f32 (float32_t a, float32x2_t src, const int lane);
float64x1_t vset_lane_f64 (float64_t a, float64x1_t src, const int lane);

bfloat16x4_t vset_lane_bf16 (bfloat16_t a, bfloat16x4_t src, const int lane);
```

```c
poly8x8_t vset_lane_p8 (poly8_t a, poly8x8_t src, const int lane);
poly16x4_t vset_lane_p16 (poly16_t a, poly16x4_t src, const int lane);
poly64x1_t vset_lane_p64 (poly64_t a, poly64x1_t src, const int lane);
```

### 全指令设置

#### vsetq_lane

* 运算： `ret[i] = src[i]; then ret[lane] = a`

```c
int8x16_t vsetq_lane_s8 (int8_t a, int8x16_t src, const int lane);   //   _mm_insert_epi8(src, a, lane)
                                                                     // | _mm256_insert_epi8
int16x8_t vsetq_lane_s16 (int16_t a, int16x8_t src, const int lane); //   _mm_insert_epi16(src, a, lane)
                                                                     // | _mm256_insert_epi16
int32x4_t vsetq_lane_s32 (int32_t a, int32x4_t src, const int lane); //   _mm_insert_epi32(src, a, lane)
                                                                     // | _mm256_insert_epi32
int64x2_t vsetq_lane_s64 (int64_t a, int64x2_t src, const int lane); //   _mm_insert_epi64(src, a, lane)
                                                                     // | _mm256_insert_epi64
```

```c
uint8x16_t vsetq_lane_u8 (uint8_t a, uint8x16_t src, const int lane);
uint16x8_t vsetq_lane_u16 (uint16_t a, uint16x8_t src, const int lane);
uint32x4_t vsetq_lane_u32 (uint32_t a, uint32x4_t src, const int lane);
uint64x2_t vsetq_lane_u64 (uint64_t a, uint64x2_t src, const int lane);
```

```c
float16x8_t vsetq_lane_f16 (float16_t a, float16x8_t src, const int lane);
float32x4_t vsetq_lane_f32 (float32_t a, float32x4_t src, const int lane); // _mm_insert_ps(src, a, lane)
float64x2_t vsetq_lane_f64 (float64_t a, float64x2_t src, const int lane);

bfloat16x8_t vsetq_lane_bf16 (bfloat16_t a, bfloat16x8_t src, const int lane);
```

```c
poly8x16_t vsetq_lane_p8 (poly8_t a, poly8x16_t src, const int lane);
poly16x8_t vsetq_lane_p16 (poly16_t a, poly16x8_t src, const int lane);
poly64x2_t vsetq_lane_p64 (poly64_t a, poly64x2_t src, const int lane);
```

## combine变换指令

### 全指令变换

#### vcombine

* 运算： `V = low:high`

```c
int8x16_t vcombine_s8 (int8x8_t low, int8x8_t high);
int16x8_t vcombine_s16 (int16x4_t low, int16x4_t high);
int32x4_t vcombine_s32 (int32x2_t low, int32x2_t high);
int64x2_t vcombine_s64 (int64x1_t low, int64x1_t high);
```

```c
uint8x16_t vcombine_u8 (uint8x8_t low, uint8x8_t high);
uint16x8_t vcombine_u16 (uint16x4_t low, uint16x4_t high);
uint32x4_t vcombine_u32 (uint32x2_t low, uint32x2_t high);
uint64x2_t vcombine_u64 (uint64x1_t low, uint64x1_t high);
```

```c
float16x8_t vcombine_f16 (float16x4_t low, float16x4_t high);
float32x4_t vcombine_f32 (float32x2_t low, float32x2_t high);
float64x2_t vcombine_f64 (float64x1_t low, float64x1_t high);

bfloat16x8_t vcombine_bf16 (bfloat16x4_t low, bfloat16x4_t high);
```

```c
poly8x16_t vcombine_p8 (poly8x8_t low, poly8x8_t high);
poly16x8_t vcombine_p16 (poly16x4_t low, poly16x4_t high);
poly64x2_t vcombine_p64 (poly64x1_t low, poly64x1_t high);
```

## mov变换指令

### 短指令变换

#### vmov_n

* 运算： `ret[i] = a`

```c
int8x8_t vmov_n_s8 (int8_t a);
int16x4_t vmov_n_s16 (int16_t a);
int32x2_t vmov_n_s32 (int32_t a);
int64x1_t vmov_n_s64 (int64_t a);
```

```c
uint8x8_t vmov_n_u8 (uint8_t a);
uint16x4_t vmov_n_u16 (uint16_t a);
uint32x2_t vmov_n_u32 (uint32_t a);
uint64x1_t vmov_n_u64 (uint64_t a);
```

```c
float16x4_t vmov_n_f16 (float16_t a);
float32x2_t vmov_n_f32 (float32_t a);
float64x1_t vmov_n_f64 (float64_t a);
```

```c
poly8x8_t vmov_n_p8 (poly8_t a);
poly16x4_t vmov_n_p16 (poly16_t a);
poly64x1_t vmov_n_p64 (poly64_t a);
```

### 全指令变换

#### vmovq_n

* 运算： `ret[i] = a`

```c
int8x16_t vmovq_n_s8 (int8_t a);
int16x8_t vmovq_n_s16 (int16_t a);
int32x4_t vmovq_n_s32 (int32_t a);
int64x2_t vmovq_n_s64 (int64_t a);
```

```c
uint8x16_t vmovq_n_u8 (uint8_t a);
uint16x8_t vmovq_n_u16 (uint16_t a);
uint32x4_t vmovq_n_u32 (uint32_t a);
uint64x2_t vmovq_n_u64 (uint64_t a);
```

```c
float16x8_t vmovq_n_f16 (float16_t a);
float32x4_t vmovq_n_f32 (float32_t a);
float64x2_t vmovq_n_f64 (float64_t a);
```

```c
poly8x16_t vmovq_n_p8 (poly8_t a);
poly16x8_t vmovq_n_p16 (poly16_t a);
poly64x2_t vmovq_n_p64 (poly64_t a);
```

### 长指令变换

* 运算： `ret[i] = a[i]`

#### vmovl

```c
int16x8_t vmovl_s8 (int8x8_t a);
int32x4_t vmovl_s16 (int16x4_t a);
int64x2_t vmovl_s32 (int32x2_t a);
```

```c
uint16x8_t vmovl_u8 (uint8x8_t a);
uint32x4_t vmovl_u16 (uint16x4_t a);
uint64x2_t vmovl_u32 (uint32x2_t a);
```

#### vmovl_high

* 运算： `ret[i] = a[i] << L/2`

```c
uint16x8_t vmovl_high_u8 (uint8x16_t a);
uint32x4_t vmovl_high_u16 (uint16x8_t a);
uint64x2_t vmovl_high_u32 (uint32x4_t a);
```

```c
int16x8_t vmovl_high_s8 (int8x16_t a);
int32x4_t vmovl_high_s16 (int16x8_t a);
int64x2_t vmovl_high_s32 (int32x4_t a);
```

### 窄指令变换

#### vmovn

* 运算： `ret[i] = a[i]`

```c
int8x8_t vmovn_s16 (int16x8_t a);
int16x4_t vmovn_s32 (int32x4_t a);
int32x2_t vmovn_s64 (int64x2_t a);
```

```c
uint8x8_t vmovn_u16 (uint16x8_t a);
uint16x4_t vmovn_u32 (uint32x4_t a);
uint32x2_t vmovn_u64 (uint64x2_t a);
```

#### vqmovn

* 运算： `ret[i] = sat(a[i])`

```c
int8x8_t vqmovn_s16 (int16x8_t a);
int16x4_t vqmovn_s32 (int32x4_t a);
int32x2_t vqmovn_s64 (int64x2_t a);
```

```c
uint8x8_t vqmovn_u16 (uint16x8_t a);
uint16x4_t vqmovn_u32 (uint32x4_t a);
uint32x2_t vqmovn_u64 (uint64x2_t a);
```

#### vqmovun

* 运算： `ret[i] = sat(a[i])`

```c
uint8x8_t vqmovun_s16 (int16x8_t a);
uint16x4_t vqmovun_s32 (int32x4_t a);
uint32x2_t vqmovun_s64 (int64x2_t a);
```

#### vmovn_high

* 运算： 0~N/2-1 : `ret[i] = r[i]` ; N/2~N-1 : `ret[N/2+i] = a[i]`

```c
int8x16_t vmovn_high_s16 (int8x8_t r, int16x8_t a);
int16x8_t vmovn_high_s32 (int16x4_t r, int32x4_t a);
int32x4_t vmovn_high_s64 (int32x2_t r, int64x2_t a);
```

```c
uint8x16_t vmovn_high_u16 (uint8x8_t r, uint16x8_t a);
uint16x8_t vmovn_high_u32 (uint16x4_t r, uint32x4_t a);
uint32x4_t vmovn_high_u64 (uint32x2_t r, uint64x2_t a);
```

#### vqmovn_high

* 运算： 0~N/2-1 : `ret[i] = r[i]` ; N/2~N-1 : `ret[N/2+i] = sat(a[i])`

```c
int8x16_t vqmovn_high_s16 (int8x8_t r, int16x8_t a);
int16x8_t vqmovn_high_s32 (int16x4_t r, int32x4_t a);
int32x4_t vqmovn_high_s64 (int32x2_t r, int64x2_t a);
```

```c
uint8x16_t vqmovn_high_u16 (uint8x8_t r, uint16x8_t a);
uint16x8_t vqmovn_high_u32 (uint16x4_t r, uint32x4_t a);
uint32x4_t vqmovn_high_u64 (uint32x2_t r, uint64x2_t a);
```

#### vqmovun_high

* 运算： 0~N/2-1 : `ret[i] = r[i]` ; N/2~N-1 : `ret[N/2+i] = sat(a[i])`

```c
uint8x16_t vqmovun_high_s16 (uint8x8_t r, int16x8_t a);
uint16x8_t vqmovun_high_s32 (uint16x4_t r, int32x4_t a);
uint32x4_t vqmovun_high_s64 (uint32x2_t r, int64x2_t a);
```

### 单指令变换

#### vqmovn?

* 运算： `ret[i] = sat(a[i])`

```c
int8_t vqmovnh_s16 (int16_t a);
int16_t vqmovns_s32 (int32_t a);
int32_t vqmovnd_s64 (int64_t a);
```

```c
uint8_t vqmovnh_u16 (uint16_t a);
uint16_t vqmovns_u32 (uint32_t a);
uint32_t vqmovnd_u64 (uint64_t a);
```

#### vqmovun?

* 运算： `ret[i] = sat(a[i])`

```c
uint8_t vqmovunh_s16 (int16_t a);
uint16_t vqmovuns_s32 (int32_t a);
uint32_t vqmovund_s64 (int64_t a);
```

## ext提取交织指令

### 短指令提取交织

#### vext

* 运算： `ret[i] = concat(a[i][bit[n]:bit[L-1]], b[i][bit[0]:bit[n-1]])` b的数据在结果元素的高位

```c
int8x8_t vext_s8 (int8x8_t a, int8x8_t b, const int n);
int16x4_t vext_s16 (int16x4_t a, int16x4_t b, const int n);
int32x2_t vext_s32 (int32x2_t a, int32x2_t b, const int n);
int64x1_t vext_s64 (int64x1_t a, int64x1_t b, const int n);
```

```c
uint8x8_t vext_u8 (uint8x8_t a, uint8x8_t b, const int n);
uint16x4_t vext_u16 (uint16x4_t a, uint16x4_t b, const int n);
uint32x2_t vext_u32 (uint32x2_t a, uint32x2_t b, const int n);
uint64x1_t vext_u64 (uint64x1_t a, uint64x1_t b, const int n);
```

```c
float16x4_t vext_f16 (float16x4_t a, float16x4_t b, const int n);
float32x2_t vext_f32 (float32x2_t a, float32x2_t b, const int n);
float64x1_t vext_f64 (float64x1_t a, float64x1_t b, const int n);
```

```c
poly8x8_t vext_p8 (poly8x8_t a, poly8x8_t b, const int n);
poly16x4_t vext_p16 (poly16x4_t a, poly16x4_t b, const int n);
poly64x1_t vext_p64 (poly64x1_t a, poly64x1_t b, const int n);
```

### 全指令提取交织

#### vextq

* 运算： `ret[i] = concat(a[i][bit[n]:bit[L-1]], b[i][bit[0]:bit[n-1]])` b的数据在结果元素的高位

```c
int8x16_t vextq_s8 (int8x16_t a, int8x16_t b, const int n);
int16x8_t vextq_s16 (int16x8_t a, int16x8_t b, const int n);
int32x4_t vextq_s32 (int32x4_t a, int32x4_t b, const int n);
int64x2_t vextq_s64 (int64x2_t a, int64x2_t b, const int n);
```

```c
uint8x16_t vextq_u8 (uint8x16_t a, uint8x16_t b, const int n);
uint16x8_t vextq_u16 (uint16x8_t a, uint16x8_t b, const int n);
uint32x4_t vextq_u32 (uint32x4_t a, uint32x4_t b, const int n);
uint64x2_t vextq_u64 (uint64x2_t a, uint64x2_t b, const int n);
```

```c
float16x8_t vextq_f16 (float16x8_t a, float16x8_t b, const int n);
float32x4_t vextq_f32 (float32x4_t a, float32x4_t b, const int n);
float64x2_t vextq_f64 (float64x2_t a, float64x2_t b, const int n);
```

```c
poly8x16_t vextq_p8 (poly8x16_t a, poly8x16_t b, const int n);
poly16x8_t vextq_p16 (poly16x8_t a, poly16x8_t b, const int n);
poly64x2_t vextq_p64 (poly64x2_t a, poly64x2_t b, const int n);
```

## copy替换指令

### 短指令替换

#### vcopy_lane

* 运算： `ret[i] = a[i]; then ret[lane1] = b[lane2]`

```c
int8x8_t vcopy_lane_s8 (int8x8_t a, const int lane1, int8x8_t b, const int lane2);
int16x4_t vcopy_lane_s16 (int16x4_t a, const int lane1, int16x4_t b, const int lane2);
int32x2_t vcopy_lane_s32 (int32x2_t a, const int lane1, int32x2_t b, const int lane2);
int64x1_t vcopy_lane_s64 (int64x1_t a, const int lane1, int64x1_t b, const int lane2);
```

```c
uint8x8_t vcopy_lane_u8 (uint8x8_t a, const int lane1, uint8x8_t b, const int lane2);
uint16x4_t vcopy_lane_u16 (uint16x4_t a, const int lane1, uint16x4_t b, const int lane2);
uint32x2_t vcopy_lane_u32 (uint32x2_t a, const int lane1, uint32x2_t b, const int lane2);
uint64x1_t vcopy_lane_u64 (uint64x1_t a, const int lane1, uint64x1_t b, const int lane2);
```

```c
float32x2_t vcopy_lane_f32 (float32x2_t a, const int lane1, float32x2_t b, const int lane2);
float64x1_t vcopy_lane_f64 (float64x1_t a, const int lane1, float64x1_t b, const int lane2);

bfloat16x4_t vcopy_lane_bf16 (bfloat16x4_t a, const int lane1, bfloat16x4_t b, const int lane2);
```

```c
poly8x8_t vcopy_lane_p8 (poly8x8_t a, const int lane1, poly8x8_t b, const int lane2);
poly16x4_t vcopy_lane_p16 (poly16x4_t a, const int lane1, poly16x4_t b, const int lane2);
poly64x1_t vcopy_lane_p64 (poly64x1_t a, const int lane1, poly64x1_t b, const int lane2);
```

```c
int8x8_t vcopy_laneq_s8 (int8x8_t a, const int lane1, int8x16_t b, const int lane2);
int16x4_t vcopy_laneq_s16 (int16x4_t a, const int lane1, int16x8_t b, const int lane2);
int32x2_t vcopy_laneq_s32 (int32x2_t a, const int lane1, int32x4_t b, const int lane2);
int64x1_t vcopy_laneq_s64 (int64x1_t a, const int lane1, int64x2_t b, const int lane2);
```

```c
uint8x8_t vcopy_laneq_u8 (uint8x8_t a, const int lane1, uint8x16_t b, const int lane2);
uint16x4_t vcopy_laneq_u16 (uint16x4_t a, const int lane1, uint16x8_t b, const int lane2);
uint32x2_t vcopy_laneq_u32 (uint32x2_t a, const int lane1, uint32x4_t b, const int lane2);
uint64x1_t vcopy_laneq_u64 (uint64x1_t a, const int lane1, uint64x2_t b, const int lane2);
```

```c
float32x2_t vcopy_laneq_f32 (float32x2_t a, const int lane1, float32x4_t b, const int lane2);
float64x1_t vcopy_laneq_f64 (float64x1_t a, const int lane1, float64x2_t b, const int lane2);

bfloat16x4_t vcopy_laneq_bf16 (bfloat16x4_t a, const int lane1,  bfloat16x8_t b, const int lane2);
```

```c
poly8x8_t vcopy_laneq_p8 (poly8x8_t a, const int lane1, poly8x16_t b, const int lane2);
poly16x4_t vcopy_laneq_p16 (poly16x4_t a, const int lane1, poly16x8_t b, const int lane2);
poly64x1_t vcopy_laneq_p64 (poly64x1_t a, const int lane1, poly64x2_t b, const int lane2);
```

### 全指令替换

#### vcopyq_lane

* 运算： `ret[i] = a[i]; then ret[lane1] = b[lane2]`

```c
int8x16_t vcopyq_lane_s8 (int8x16_t a, const int lane1, int8x8_t b, const int lane2);
int16x8_t vcopyq_lane_s16 (int16x8_t a, const int lane1, int16x4_t b, const int lane2);
int32x4_t vcopyq_lane_s32 (int32x4_t a, const int lane1, int32x2_t b, const int lane2);
int64x2_t vcopyq_lane_s64 (int64x2_t a, const int lane1, int64x1_t b, const int lane2);
```

```c
uint8x16_t vcopyq_lane_u8 (uint8x16_t a, const int lane1, uint8x8_t b, const int lane2);
uint16x8_t vcopyq_lane_u16 (uint16x8_t a, const int lane1, uint16x4_t b, const int lane2);
uint32x4_t vcopyq_lane_u32 (uint32x4_t a, const int lane1, uint32x2_t b, const int lane2);
uint64x2_t vcopyq_lane_u64 (uint64x2_t a, const int lane1, uint64x1_t b, const int lane2);
```

```c
float32x4_t vcopyq_lane_f32 (float32x4_t a, const int lane1, float32x2_t b, const int lane2);
float64x2_t vcopyq_lane_f64 (float64x2_t a, const int lane1, float64x1_t b, const int lane2);

bfloat16x8_t vcopyq_lane_bf16 (bfloat16x8_t a, const int lane1, bfloat16x4_t b, const int lane2);
```

```c
poly8x16_t vcopyq_lane_p8 (poly8x16_t a, const int lane1, poly8x8_t b, const int lane2);
poly16x8_t vcopyq_lane_p16 (poly16x8_t a, const int lane1, poly16x4_t b, const int lane2);
poly64x2_t vcopyq_lane_p64 (poly64x2_t a, const int lane1, poly64x1_t b, const int lane2);
```

```c
/* vcopyq_laneq.  */
int8x16_t vcopyq_laneq_s8 (int8x16_t a, const int lane1, int8x16_t b, const int lane2);
int16x8_t vcopyq_laneq_s16 (int16x8_t a, const int lane1, int16x8_t b, const int lane2);
int32x4_t vcopyq_laneq_s32 (int32x4_t a, const int lane1, int32x4_t b, const int lane2);
int64x2_t vcopyq_laneq_s64 (int64x2_t a, const int lane1, int64x2_t b, const int lane2);
```

```c
uint8x16_t vcopyq_laneq_u8 (uint8x16_t a, const int lane1, uint8x16_t b, const int lane2);
uint16x8_t vcopyq_laneq_u16 (uint16x8_t a, const int lane1, uint16x8_t b, const int lane2);
uint32x4_t vcopyq_laneq_u32 (uint32x4_t a, const int lane1, uint32x4_t b, const int lane2);
uint64x2_t vcopyq_laneq_u64 (uint64x2_t a, const int lane1, uint64x2_t b, const int lane2);
```

```c
float32x4_t vcopyq_laneq_f32 (float32x4_t a, const int lane1, float32x4_t b, const int lane2);
float64x2_t vcopyq_laneq_f64 (float64x2_t a, const int lane1, float64x2_t b, const int lane2);

bfloat16x8_t vcopyq_laneq_bf16 (bfloat16x8_t a, const int lane1, bfloat16x8_t b, const int lane2);
```

```c
poly8x16_t vcopyq_laneq_p8 (poly8x16_t a, const int lane1, poly8x16_t b, const int lane2);
poly16x8_t vcopyq_laneq_p16 (poly16x8_t a, const int lane1, poly16x8_t b, const int lane2);
poly64x2_t vcopyq_laneq_p64 (poly64x2_t a, const int lane1, poly64x2_t b, const int lane2);
```

## cvt类型变换指令

* 函数名后缀和参数n表示舍入方式
    * ` `   : 向零舍入(默认方式)，即直接丢弃小数部分
    * `a`   : 最近舍入，四舍五入，即舍入离得最近的整数
    * `m`   : 向下舍入，即舍入到较小的整数
    * `n`   : 最近舍入，偶数舍入，即离得都近时舍入到偶数
    * `p`   : 向上舍入，即舍入到较大的整数

### 短指令类型变换

#### vcvt?_s16

```c
int16x4_t vcvt_s16_f16 (float16x4_t a);
int16x4_t vcvta_s16_f16 (float16x4_t a);
int16x4_t vcvtm_s16_f16 (float16x4_t a);
int16x4_t vcvtn_s16_f16 (float16x4_t a);
int16x4_t vcvtp_s16_f16 (float16x4_t a);
int16x4_t vcvt_n_s16_f16 (float16x4_t a, const int n);
```

#### vcvt?_u16

```c

uint16x4_t vcvt_u16_f16 (float16x4_t a);
uint16x4_t vcvta_u16_f16 (float16x4_t a);
uint16x4_t vcvtm_u16_f16 (float16x4_t a);
uint16x4_t vcvtn_u16_f16 (float16x4_t a);
uint16x4_t vcvtp_u16_f16 (float16x4_t a);
uint16x4_t vcvt_n_u16_f16 (float16x4_t a, const int n);
```

#### vcvt?_f16

```c
float16x4_t vcvt_f16_s16 (int16x4_t a);
float16x4_t vcvt_f16_u16 (uint16x4_t a);
float16x4_t vcvt_f16_f32 (float32x4_t a);
float16x4_t vcvt_n_f16_s16 (int16x4_t a, const int n);
float16x4_t vcvt_n_f16_u16 (uint16x4_t a, const int n);
```

```c
bfloat16x4_t vcvt_bf16_f32 (float32x4_t a);
```

#### vcvt?_s32

```c
uint32x2_t vcvt_u32_f32 (float32x2_t a);
uint32x2_t vcvta_u32_f32 (float32x2_t a);
uint32x2_t vcvtm_u32_f32 (float32x2_t a);
uint32x2_t vcvtn_u32_f32 (float32x2_t a);
uint32x2_t vcvtp_u32_f32 (float32x2_t a);
uint32x2_t vcvt_n_u32_f32 (float32x2_t a, const int n);
```

#### vcvt?_u32

```c
int32x2_t vcvt_s32_f32 (float32x2_t a);
int32x2_t vcvta_s32_f32 (float32x2_t a);
int32x2_t vcvtm_s32_f32 (float32x2_t a);
int32x2_t vcvtn_s32_f32 (float32x2_t a);
int32x2_t vcvtp_s32_f32 (float32x2_t a);
int32x2_t vcvt_n_s32_f32 (float32x2_t a, const int n);
```

#### vcvt?_f32

```c
float32x2_t vcvt_f32_s32 (int32x2_t a);
float32x2_t vcvt_f32_u32 (uint32x2_t a);
float32x2_t vcvt_f32_f64 (float64x2_t a);
float32x4_t vcvt_f32_bf16 (bfloat16x4_t a);

float32x2_t vcvtx_f32_f64 (float64x2_t a);
float32x2_t vcvt_n_f32_s32 (int32x2_t a, const int n);
float32x2_t vcvt_n_f32_u32 (uint32x2_t a, const int n);
```

#### vcvt?_s64

```c
int64x1_t vcvt_s64_f64 (float64x1_t a);
int64x1_t vcvta_s64_f64 (float64x1_t a);
int64x1_t vcvtm_s64_f64 (float64x1_t a);
int64x1_t vcvtn_s64_f64 (float64x1_t a);
int64x1_t vcvtp_s64_f64 (float64x1_t a);
int64x1_t vcvt_n_s64_f64 (float64x1_t a, const int n);
```

#### vcvt?_u64

```c
uint64x1_t vcvt_u64_f64 (float64x1_t a);
uint64x1_t vcvta_u64_f64 (float64x1_t a);
uint64x1_t vcvtm_u64_f64 (float64x1_t a);
uint64x1_t vcvtn_u64_f64 (float64x1_t a);
uint64x1_t vcvtp_u64_f64 (float64x1_t a);
uint64x1_t vcvt_n_u64_f64 (float64x1_t a, const int n);
```

#### vcvt?_f64

```c
float64x1_t vcvt_f64_s64 (int64x1_t a);
float64x1_t vcvt_f64_u64 (uint64x1_t a);
float64x1_t vcvt_n_f64_s64 (int64x1_t a, const int n);
float64x1_t vcvt_n_f64_u64 (uint64x1_t a, const int n);
```

### 长指令类型变换

#### vcvt?q_s16

```c
int16x8_t vcvtq_s16_f16 (float16x8_t a);
int16x8_t vcvtaq_s16_f16 (float16x8_t a);
int16x8_t vcvtmq_s16_f16 (float16x8_t a);
int16x8_t vcvtnq_s16_f16 (float16x8_t a);
int16x8_t vcvtpq_s16_f16 (float16x8_t a);
int16x8_t vcvtq_n_s16_f16 (float16x8_t a, const int n);
```

#### vcvt?q_u16

```c
uint16x8_t vcvtq_u16_f16 (float16x8_t a);
uint16x8_t vcvtaq_u16_f16 (float16x8_t a);
uint16x8_t vcvtmq_u16_f16 (float16x8_t a);
uint16x8_t vcvtnq_u16_f16 (float16x8_t a);
uint16x8_t vcvtpq_u16_f16 (float16x8_t a);
uint16x8_t vcvtq_n_u16_f16 (float16x8_t a, const int n);
```

#### vcvt?q_f16

```c
float16x8_t vcvtq_f16_s16 (int16x8_t a);
float16x8_t vcvtq_f16_u16 (uint16x8_t a);
float16x8_t vcvtq_n_f16_s16 (int16x8_t a, const int n);
float16x8_t vcvtq_n_f16_u16 (uint16x8_t a, const int n);
float16x8_t vcvt_high_f16_f32 (float16x4_t a, float32x4_t b);
```

```c
bfloat16x8_t vcvtq_low_bf16_f32 (float32x4_t a);
bfloat16x8_t vcvtq_high_bf16_f32 (bfloat16x8_t inactive, float32x4_t a);
```

#### vcvt?q_s32

```c
int32x4_t vcvtq_s32_f32 (float32x4_t a);
int32x4_t vcvtaq_s32_f32 (float32x4_t a);
int32x4_t vcvtmq_s32_f32 (float32x4_t a);
int32x4_t vcvtnq_s32_f32 (float32x4_t a);
int32x4_t vcvtpq_s32_f32 (float32x4_t a);
int32x4_t vcvtq_n_s32_f32 (float32x4_t a, const int n);
```

#### vcvt?q_u32

```c
uint32x4_t vcvtq_u32_f32 (float32x4_t a);
uint32x4_t vcvtaq_u32_f32 (float32x4_t a);
uint32x4_t vcvtmq_u32_f32 (float32x4_t a);
uint32x4_t vcvtnq_u32_f32 (float32x4_t a);
uint32x4_t vcvtpq_u32_f32 (float32x4_t a);
uint32x4_t vcvtq_n_u32_f32 (float32x4_t a, const int n);
```

#### vcvt?q_f32

```c
float32x4_t vcvtq_f32_s32 (int32x4_t a);
float32x4_t vcvtq_f32_u32 (uint32x4_t a);
float32x4_t vcvtq_n_f32_s32 (int32x4_t a, const int n);
float32x4_t vcvtq_n_f32_u32 (uint32x4_t a, const int n);

float32x4_t vcvt_f32_f16 (float16x4_t a);
float32x4_t vcvt_high_f32_f16 (float16x8_t a);
float32x4_t vcvt_high_f32_f64 (float32x2_t a, float64x2_t b);
float32x4_t vcvtx_high_f32_f64 (float32x2_t a, float64x2_t b);
```

```c
float32x4_t vcvtq_low_f32_bf16 (bfloat16x8_t a);
float32x4_t vcvtq_high_f32_bf16 (bfloat16x8_t a);
```

#### vcvt?q_s64

```c
int64x2_t vcvtq_s64_f64 (float64x2_t a);
int64x2_t vcvtaq_s64_f64 (float64x2_t a);
int64x2_t vcvtmq_s64_f64 (float64x2_t a);
int64x2_t vcvtnq_s64_f64 (float64x2_t a);
int64x2_t vcvtpq_s64_f64 (float64x2_t a);
int64x2_t vcvtq_n_s64_f64 (float64x2_t a, const int n);
```

#### vcvt?q_u64

```c
uint64x2_t vcvtq_u64_f64 (float64x2_t a);
uint64x2_t vcvtaq_u64_f64 (float64x2_t a);
uint64x2_t vcvtmq_u64_f64 (float64x2_t a);
uint64x2_t vcvtnq_u64_f64 (float64x2_t a);
uint64x2_t vcvtpq_u64_f64 (float64x2_t a);
uint64x2_t vcvtq_n_u64_f64 (float64x2_t a, const int n);
```

#### vcvt?q_f64

```c
float64x2_t vcvtq_f64_s64 (int64x2_t a);
float64x2_t vcvtq_f64_u64 (uint64x2_t a);
float64x2_t vcvt_f64_f32 (float32x2_t a);
float64x2_t vcvt_high_f64_f32 (float32x4_t a);
float64x2_t vcvtq_n_f64_s64 (int64x2_t a, const int n);
float64x2_t vcvtq_n_f64_u64 (uint64x2_t a, const int n);
```

### 单指令类型变换

#### vcvt??_s32

```c
int32_t vcvts_s32_f32 (float32_t a);
int32_t vcvtas_s32_f32 (float32_t a);
int32_t vcvtms_s32_f32 (float32_t a);
int32_t vcvtns_s32_f32 (float32_t a);
int32_t vcvtps_s32_f32 (float32_t a);
int32_t vcvts_n_s32_f32 (float32_t a, const int n);
```

#### vcvt??_u32

```c
uint32_t vcvts_u32_f32 (float32_t a);
uint32_t vcvtas_u32_f32 (float32_t a);
uint32_t vcvtms_u32_f32 (float32_t a);
uint32_t vcvtns_u32_f32 (float32_t a);
uint32_t vcvtps_u32_f32 (float32_t a);
uint32_t vcvts_n_u32_f32 (float32_t a, const int n);
```

#### vcvt??_f32

```c
float32_t vcvts_f32_s32 (int32_t a);
float32_t vcvts_f32_u32 (uint32_t a);
float32_t vcvtxd_f32_f64 (float64_t a);
float32_t vcvts_n_f32_s32 (int32_t a, const int n);
float32_t vcvts_n_f32_u32 (uint32_t a, const int n);
```

#### vcvt??_s64

```c
int64_t vcvtd_s64_f64 (float64_t a);
int64_t vcvtad_s64_f64 (float64_t a);
int64_t vcvtmd_s64_f64 (float64_t a);
int64_t vcvtnd_s64_f64 (float64_t a);
int64_t vcvtpd_s64_f64 (float64_t a);
int64_t vcvtd_n_s64_f64 (float64_t a, const int n);
```

#### vcvt??_u64

```c
uint64_t vcvtd_u64_f64 (float64_t a);
uint64_t vcvtad_u64_f64 (float64_t a);
uint64_t vcvtmd_u64_f64 (float64_t a);
uint64_t vcvtnd_u64_f64 (float64_t a);
uint64_t vcvtpd_u64_f64 (float64_t a);
uint64_t vcvtd_n_u64_f64 (float64_t a, const int n);
```

#### vcvt??_f64

```c
float64_t vcvtd_f64_s64 (int64_t a);
float64_t vcvtd_f64_u64 (uint64_t a);
float64_t vcvtd_n_f64_s64 (int64_t a, const int n);
float64_t vcvtd_n_f64_u64 (uint64_t a, const int n);
```

## rnd浮点变换指令

* 函数名后缀和参数n表示舍入方式
    * ` `   : 向零舍入(默认方式)，即直接丢弃小数部分
    * `a`   : 最近舍入，四舍五入，即舍入离得最近的整数
    * `i`   : 基于当前的舍入模式舍入
    * `m`   : 向下舍入，即舍入到较小的整数
    * `n`   : 最近舍入，偶数舍入，即离得都近时舍入到偶数
    * `p`   : 向上舍入，即舍入到较大的整数
    * `x`   : exactct舍入，即舍入到较大的整数

### 短指令浮点变换

#### vrnd?_f16

```c
float16x4_t vrnd_f16 (float16x4_t a);
float16x4_t vrnda_f16 (float16x4_t a);
float16x4_t vrndi_f16 (float16x4_t a);
float16x4_t vrndm_f16 (float16x4_t a);
float16x4_t vrndn_f16 (float16x4_t a);
float16x4_t vrndp_f16 (float16x4_t a);
float16x4_t vrndx_f16 (float16x4_t a);
```

#### vrnd?_f32

```c
float32x2_t vrnd_f32 (float32x2_t a);
float32x2_t vrnda_f32 (float32x2_t a);
float32x2_t vrndi_f32 (float32x2_t a);
float32x2_t vrndm_f32 (float32x2_t a);
float32x2_t vrndn_f32 (float32x2_t a);
float32x2_t vrndp_f32 (float32x2_t a);
float32x2_t vrndx_f32 (float32x2_t a);

float32x2_t vrnd32z_f32 (float32x2_t a);
float32x2_t vrnd32x_f32 (float32x2_t a);
float32x2_t vrnd64z_f32 (float32x2_t a);
float32x2_t vrnd64x_f32 (float32x2_t a);
```

#### vrnd?_f64

```c
float64x1_t vrnd_f64 (float64x1_t a);
float64x1_t vrnda_f64 (float64x1_t a);
float64x1_t vrndi_f64 (float64x1_t a);
float64x1_t vrndm_f64 (float64x1_t a);
float64x1_t vrndn_f64 (float64x1_t a);
float64x1_t vrndp_f64 (float64x1_t a);
float64x1_t vrndx_f64 (float64x1_t a);

float64x1_t vrnd32z_f64 (float64x1_t a);
float64x1_t vrnd32x_f64 (float64x1_t a);
float64x1_t vrnd64z_f64 (float64x1_t a);
float64x1_t vrnd64x_f64 (float64x1_t a);
```

### 全指令浮点变换

#### vrnd?q_f16

```c
float16x8_t vrndq_f16 (float16x8_t a);
float16x8_t vrndaq_f16 (float16x8_t a);
float16x8_t vrndiq_f16 (float16x8_t a);
float16x8_t vrndmq_f16 (float16x8_t a);
float16x8_t vrndnq_f16 (float16x8_t a);
float16x8_t vrndpq_f16 (float16x8_t a);
float16x8_t vrndxq_f16 (float16x8_t a);
```

#### vrnd?q_f32

```c
float32x4_t vrndq_f32 (float32x4_t a);
float32x4_t vrndaq_f32 (float32x4_t a);
float32x4_t vrndiq_f32 (float32x4_t a);
float32x4_t vrndmq_f32 (float32x4_t a); // _mm_floor_ps | _mm256_floor_ps
float32x4_t vrndnq_f32 (float32x4_t a);
float32x4_t vrndpq_f32 (float32x4_t a); // _mm_ceil_ps  | _mm256_ceil_ps
float32x4_t vrndxq_f32 (float32x4_t a);

float32x4_t vrnd32zq_f32 (float32x4_t a);
float32x4_t vrnd32xq_f32 (float32x4_t a);
float32x4_t vrnd64zq_f32 (float32x4_t a);
float32x4_t vrnd64xq_f32 (float32x4_t a);
```

#### vrnd?q_f64

```c
float64x2_t vrndq_f64 (float64x2_t a);
float64x2_t vrndaq_f64 (float64x2_t a);
float64x2_t vrndiq_f64 (float64x2_t a);
float64x2_t vrndmq_f64 (float64x2_t a); // _mm_floor_pd | _mm256_floor_pd
float64x2_t vrndnq_f64 (float64x2_t a);
float64x2_t vrndpq_f64 (float64x2_t a); // _mm_ceil_pd  | _mm256_ceil_pd
float64x2_t vrndxq_f64 (float64x2_t a);

float64x2_t vrnd32zq_f64 (float64x2_t a);
float64x2_t vrnd32xq_f64 (float64x2_t a);
float64x2_t vrnd64zq_f64 (float64x2_t a);
float64x2_t vrnd64xq_f64 (float64x2_t a);
```

### 单指令浮点变换

#### vrnd??_f32

```c
float32_t vrndns_f32 (float32_t a);
```

## rev顺序反转指令

### 短指令顺序反转

#### vrev16

* 运算：  8位数: `V = {a[1], a[0], a[3], a[2], a[5], a[4], a[7], a[6]}`

```c
int8x8_t vrev16_s8 (int8x8_t a);
```

```c
uint8x8_t vrev16_u8 (uint8x8_t a);
```

```c
poly8x8_t vrev16_p8 (poly8x8_t a);
```

#### vrev32

* 运算：  8位数: `V = {a[3], a[2], a[1], a[0], a[7], a[6], a[5], a[4]}`
* 运算： 16位数: `V = {a[1], a[0], a[3], a[2]}`

```c
int8x8_t vrev32_s8 (int8x8_t a);
int16x4_t vrev32_s16 (int16x4_t a);
```

```c
uint8x8_t vrev32_u8 (uint8x8_t a);
uint16x4_t vrev32_u16 (uint16x4_t a);
```

```c
poly8x8_t vrev32_p8 (poly8x8_t a);
poly16x4_t vrev32_p16 (poly16x4_t a);
```

#### vrev64

* 运算：  8位数: `V = {a[7], a[6], a[5], a[4], a[3], a[2], a[1], a[0]}`
* 运算： 16位数: `V = {a[3], a[2], a[1], a[0]}`
* 运算： 32位数: `V = {a[1], a[0]}`

```c
int8x8_t vrev64_s8 (int8x8_t a);
int16x4_t vrev64_s16 (int16x4_t a);
int32x2_t vrev64_s32 (int32x2_t a);
```

```c
uint8x8_t vrev64_u8 (uint8x8_t a);
uint16x4_t vrev64_u16 (uint16x4_t a);
uint32x2_t vrev64_u32 (uint32x2_t a);
```

```c
float16x4_t vrev64_f16 (float16x4_t a);
float32x2_t vrev64_f32 (float32x2_t a);
```

```c
poly8x8_t vrev64_p8 (poly8x8_t a);
poly16x4_t vrev64_p16 (poly16x4_t a);
```

### 全指令顺序反转

#### vrev16q

* 运算：  8位数: `V = {a[1], a[0], a[3], a[2], a[5], a[4], a[7], a[6], ...}`

```c
int8x16_t vrev16q_s8 (int8x16_t a);
```

```c
uint8x16_t vrev16q_u8 (uint8x16_t a);
```

```c
poly8x16_t vrev16q_p8 (poly8x16_t a);
```

#### vrev32q

* 运算：  8位数: `V = {a[3], a[2], a[1], a[0], a[7], a[6], a[5], a[4], ...}`
* 运算： 16位数: `V = {a[1], a[0], a[3], a[2], ...}`

```c
int8x16_t vrev32q_s8 (int8x16_t a);
int16x8_t vrev32q_s16 (int16x8_t a);
```

```c
uint8x16_t vrev32q_u8 (uint8x16_t a);
uint16x8_t vrev32q_u16 (uint16x8_t a);
```

```c
poly8x16_t vrev32q_p8 (poly8x16_t a);
poly16x8_t vrev32q_p16 (poly16x8_t a);
```

#### vrev64q

* 运算：  8位数: `V = {a[7], a[6], a[5], a[4], a[3], a[2], a[1], a[0], ...}`
* 运算： 16位数: `V = {a[3], a[2], a[1], a[0], ...}`
* 运算： 32位数: `V = {a[1], a[0], ...}`

```c
int8x16_t vrev64q_s8 (int8x16_t a);
int16x8_t vrev64q_s16 (int16x8_t a);
int32x4_t vrev64q_s32 (int32x4_t a);
```

```c
uint8x16_t vrev64q_u8 (uint8x16_t a);
uint16x8_t vrev64q_u16 (uint16x8_t a);
uint32x4_t vrev64q_u32 (uint32x4_t a);
```

```c
poly8x16_t vrev64q_p8 (poly8x16_t a);
poly16x8_t vrev64q_p16 (poly16x8_t a);
```

```c
float16x8_t vrev64q_f16 (float16x8_t a);
float32x4_t vrev64q_f32 (float32x4_t a);
```

## trn1选择偶数转置指令

### 短指令选择偶数转置

#### vtrn1

* 运算：  8位数: `V = {a[0], b[0], a[2], b[2], a[4], b[4], a[6], b[6]}`
* 运算： 16位数: `V = {a[0], b[0], a[2], b[2]}`
* 运算： 32位数: `V = {a[0], b[0]}`

```c
int8x8_t vtrn1_s8 (int8x8_t a, int8x8_t b);
int16x4_t vtrn1_s16 (int16x4_t a, int16x4_t b);
int32x2_t vtrn1_s32 (int32x2_t a, int32x2_t b);
```

```c
uint8x8_t vtrn1_u8 (uint8x8_t a, uint8x8_t b);
uint16x4_t vtrn1_u16 (uint16x4_t a, uint16x4_t b);
uint32x2_t vtrn1_u32 (uint32x2_t a, uint32x2_t b);
```

```c
float16x4_t vtrn1_f16 (float16x4_t a, float16x4_t b);
float32x2_t vtrn1_f32 (float32x2_t a, float32x2_t b);
```

```c
poly8x8_t vtrn1_p8 (poly8x8_t a, poly8x8_t b);
poly16x4_t vtrn1_p16 (poly16x4_t a, poly16x4_t b);
```

### 全指令选择偶数转置

#### vtrn1q

* 运算：  8位数: `V = {a[0], b[0], a[2], b[2], a[4], b[4], a[6], b[6], ...}`
* 运算： 16位数: `V = {a[0], b[0], a[2], b[2], ...}`
* 运算： 32位数: `V = {a[0], b[0], ...}`
* 运算： 64位数: `V = {a[0], b[0]}`

```c
int8x16_t vtrn1q_s8 (int8x16_t a, int8x16_t b);
int16x8_t vtrn1q_s16 (int16x8_t a, int16x8_t b);
int32x4_t vtrn1q_s32 (int32x4_t a, int32x4_t b);
int64x2_t vtrn1q_s64 (int64x2_t a, int64x2_t b);
```

```c
uint8x16_t vtrn1q_u8 (uint8x16_t a, uint8x16_t b);
uint16x8_t vtrn1q_u16 (uint16x8_t a, uint16x8_t b);
uint32x4_t vtrn1q_u32 (uint32x4_t a, uint32x4_t b);
uint64x2_t vtrn1q_u64 (uint64x2_t a, uint64x2_t b);
```

```c
float16x8_t vtrn1q_f16 (float16x8_t a, float16x8_t b);
float32x4_t vtrn1q_f32 (float32x4_t a, float32x4_t b);
float64x2_t vtrn1q_f64 (float64x2_t a, float64x2_t b);
```

```c
poly8x16_t vtrn1q_p8 (poly8x16_t a, poly8x16_t b);
poly16x8_t vtrn1q_p16 (poly16x8_t a, poly16x8_t b);
poly64x2_t vtrn1q_p64 (poly64x2_t a, poly64x2_t b);
```

## trn2选择奇数转置指令

### 短指令选择奇数转置

#### vtrn2

* 运算：  8位数: `V = {a[1], b[1], a[3], b[3], a[5], b[5], a[7], b[7]}`
* 运算： 16位数: `V = {a[1], b[1], a[3], b[3]}`
* 运算： 32位数: `V = {a[1], b[1]}`

```c
int8x8_t vtrn2_s8 (int8x8_t a, int8x8_t b);
int16x4_t vtrn2_s16 (int16x4_t a, int16x4_t b);
int32x2_t vtrn2_s32 (int32x2_t a, int32x2_t b);
```

```c
uint8x8_t vtrn2_u8 (uint8x8_t a, uint8x8_t b);
uint16x4_t vtrn2_u16 (uint16x4_t a, uint16x4_t b);
uint32x2_t vtrn2_u32 (uint32x2_t a, uint32x2_t b);
```

```c
float16x4_t vtrn2_f16 (float16x4_t a, float16x4_t b);
float32x2_t vtrn2_f32 (float32x2_t a, float32x2_t b);
```

```c
poly8x8_t vtrn2_p8 (poly8x8_t a, poly8x8_t b);
poly16x4_t vtrn2_p16 (poly16x4_t a, poly16x4_t b);
```

### 全指令选择奇数转置

#### vtrn2q

* 运算：  8位数: `V = {a[1], b[1], a[3], b[3], a[5], b[5], a[7], b[7], ...}`
* 运算： 16位数: `V = {a[1], b[1], a[3], b[3], ...}`
* 运算： 32位数: `V = {a[1], b[1], ...}`
* 运算： 64位数: `V = {a[1], b[1]}`

```c
int8x16_t vtrn2q_s8 (int8x16_t a, int8x16_t b);
int16x8_t vtrn2q_s16 (int16x8_t a, int16x8_t b);
int32x4_t vtrn2q_s32 (int32x4_t a, int32x4_t b);
int64x2_t vtrn2q_s64 (int64x2_t a, int64x2_t b);
```

```c
uint8x16_t vtrn2q_u8 (uint8x16_t a, uint8x16_t b);
uint16x8_t vtrn2q_u16 (uint16x8_t a, uint16x8_t b);
uint32x4_t vtrn2q_u32 (uint32x4_t a, uint32x4_t b);
uint64x2_t vtrn2q_u64 (uint64x2_t a, uint64x2_t b);
```

```c
float16x8_t vtrn2q_f16 (float16x8_t a, float16x8_t b);
float32x4_t vtrn2q_f32 (float32x4_t a, float32x4_t b);
float64x2_t vtrn2q_f64 (float64x2_t a, float64x2_t b);
```

```c
poly8x16_t vtrn2q_p8 (poly8x16_t a, poly8x16_t b);
poly16x8_t vtrn2q_p16 (poly16x8_t a, poly16x8_t b);
poly64x2_t vtrn2q_p64 (poly64x2_t a, poly64x2_t b);
```

## trn转置指令

### 短指令转置

#### vtrn

* 运算： `V[0] = vtrn1_??(a, b); V[1] = vtrn2_??(a, b)`

```c
int8x8x2_t vtrn_s8 (int8x8_t a, int8x8_t b);
int16x4x2_t vtrn_s16 (int16x4_t a, int16x4_t b);
int32x2x2_t vtrn_s32 (int32x2_t a, int32x2_t b);
```

```c
uint8x8x2_t vtrn_u8 (uint8x8_t a, uint8x8_t b);
uint16x4x2_t vtrn_u16 (uint16x4_t a, uint16x4_t b);
uint32x2x2_t vtrn_u32 (uint32x2_t a, uint32x2_t b);
```

```c
float16x4x2_t vtrn_f16 (float16x4_t a, float16x4_t b);
float32x2x2_t vtrn_f32 (float32x2_t a, float32x2_t b);
```

```c
poly8x8x2_t vtrn_p8 (poly8x8_t a, poly8x8_t b);
poly16x4x2_t vtrn_p16 (poly16x4_t a, poly16x4_t b);
```

### 全指令转置

#### vtrnq

* 运算： `V[0] = vtrn1q_??(a, b); V[1] = vtrn2q_??(a, b)`

```c
int8x16x2_t vtrnq_s8 (int8x16_t a, int8x16_t b);
int16x8x2_t vtrnq_s16 (int16x8_t a, int16x8_t b);
int32x4x2_t vtrnq_s32 (int32x4_t a, int32x4_t b);
```

```c
uint8x16x2_t vtrnq_u8 (uint8x16_t a, uint8x16_t b);
uint16x8x2_t vtrnq_u16 (uint16x8_t a, uint16x8_t b);
uint32x4x2_t vtrnq_u32 (uint32x4_t a, uint32x4_t b);
```

```c
float16x8x2_t vtrnq_f16 (float16x8_t a, float16x8_t b);
float32x4x2_t vtrnq_f32 (float32x4_t a, float32x4_t b);
```

```c
poly8x16x2_t vtrnq_p8 (poly8x16_t a, poly8x16_t b);
poly16x8x2_t vtrnq_p16 (poly16x8_t a, poly16x8_t b);
```

## tblN多向量查表指令

### 短指令多向量查表指令

#### vtbl1

* 运算： `ret[i] = idx[i] < n ? tab[idx[i]][i] : 0`

```c
int8x8_t vtbl1_s8 (int8x8_t tab, int8x8_t idx);
uint8x8_t vtbl1_u8 (uint8x8_t tab, uint8x8_t idx);
poly8x8_t vtbl1_p8 (poly8x8_t tab, uint8x8_t idx);
```

#### vtbl2

* 运算： `ret[i] = idx[i] < n ? tab[idx[i]][i] : 0`

```c
int8x8_t vtbl2_s8 (int8x8x2_t tab, int8x8_t idx);
uint8x8_t vtbl2_u8 (uint8x8x2_t tab, uint8x8_t idx);
poly8x8_t vtbl2_p8 (poly8x8x2_t tab, uint8x8_t idx);
```

```c
int8x8_t vqtbl2_s8 (int8x16x2_t tab, uint8x8_t idx);
uint8x8_t vqtbl2_u8 (uint8x16x2_t tab, uint8x8_t idx);
poly8x8_t vqtbl2_p8 (poly8x16x2_t tab, uint8x8_t idx);
```

#### vtbl3

* 运算： `ret[i] = idx[i] < n ? tab[idx[i]][i] : 0`

```c
int8x8_t vtbl3_s8 (int8x8x3_t tab, int8x8_t idx);
uint8x8_t vtbl3_u8 (uint8x8x3_t tab, uint8x8_t idx);
poly8x8_t vtbl3_p8 (poly8x8x3_t tab, uint8x8_t idx);
```

```c
int8x8_t vqtbl3_s8 (int8x16x3_t tab, uint8x8_t idx);
uint8x8_t vqtbl3_u8 (uint8x16x3_t tab, uint8x8_t idx);
poly8x8_t vqtbl3_p8 (poly8x16x3_t tab, uint8x8_t idx);
```

#### vtbl4

* 运算： `ret[i] = idx[i] < n ? tab[idx[i]][i] : 0`

```c
int8x8_t vtbl4_s8 (int8x8x4_t tab, int8x8_t idx);
uint8x8_t vtbl4_u8 (uint8x8x4_t tab, uint8x8_t idx);
poly8x8_t vtbl4_p8 (poly8x8x4_t tab, uint8x8_t idx);
```

```c
int8x8_t vqtbl4_s8 (int8x16x4_t tab, uint8x8_t idx);
uint8x8_t vqtbl4_u8 (uint8x16x4_t tab, uint8x8_t idx);
poly8x8_t vqtbl4_p8 (poly8x16x4_t tab, uint8x8_t idx);
```

### 全指令多向量查表指令

#### vtbl1q

```c
int8x8_t vqtbl1_s8 (int8x16_t tab, uint8x8_t idx);
uint8x8_t vqtbl1_u8 (uint8x16_t tab, uint8x8_t idx);
poly8x8_t vqtbl1_p8 (poly8x16_t tab, uint8x8_t idx);
```

#### vtbl2q

```c
int8x16_t vqtbl2q_s8 (int8x16x2_t tab, uint8x16_t idx);
uint8x16_t vqtbl2q_u8 (uint8x16x2_t tab, uint8x16_t idx);
poly8x16_t vqtbl2q_p8 (poly8x16x2_t tab, uint8x16_t idx);
```

#### vtbl3q

```c
int8x16_t vqtbl3q_s8 (int8x16x3_t tab, uint8x16_t idx);
uint8x16_t vqtbl3q_u8 (uint8x16x3_t tab, uint8x16_t idx);
poly8x16_t vqtbl3q_p8 (poly8x16x3_t tab, uint8x16_t idx);
```

#### vtbl4q

```c
int8x16_t vqtbl4q_s8 (int8x16x4_t tab, uint8x16_t idx);
uint8x16_t vqtbl4q_u8 (uint8x16x4_t tab, uint8x16_t idx);
poly8x16_t vqtbl4q_p8 (poly8x16x4_t tab, uint8x16_t idx);
```

## tbxN多向量扩展查表指令

### 短指令多向量扩展查表指令

#### vtbx1

* 运算： `ret[i] = idx[i] < n ? tab[idx[i]][i] : r[i]`

```c
int8x8_t vtbx1_s8 (int8x8_t r, int8x8_t tab, int8x8_t idx);
uint8x8_t vtbx1_u8 (uint8x8_t r, uint8x8_t tab, uint8x8_t idx);
poly8x8_t vtbx1_p8 (poly8x8_t r, poly8x8_t tab, uint8x8_t idx);
```

```c
int8x8_t vqtbx1_s8 (int8x8_t r, int8x16_t tab, uint8x8_t idx);
uint8x8_t vqtbx1_u8 (uint8x8_t r, uint8x16_t tab, uint8x8_t idx);
poly8x8_t vqtbx1_p8 (poly8x8_t r, poly8x16_t tab, uint8x8_t idx);
```

#### vtbx2

* 运算： `ret[i] = idx[i] < n ? tab[idx[i]][i] : r[i]`

```c
int8x8_t vtbx2_s8 (int8x8_t r, int8x8x2_t tab, int8x8_t idx);
uint8x8_t vtbx2_u8 (uint8x8_t r, uint8x8x2_t tab, uint8x8_t idx);
poly8x8_t vtbx2_p8 (poly8x8_t r, poly8x8x2_t tab, uint8x8_t idx);
```

```c
int8x8_t vqtbx2_s8 (int8x8_t r, int8x16x2_t tab, uint8x8_t idx);
uint8x8_t vqtbx2_u8 (uint8x8_t r, uint8x16x2_t tab, uint8x8_t idx);
poly8x8_t vqtbx2_p8 (poly8x8_t r, poly8x16x2_t tab, uint8x8_t idx);
```

#### vtbx3

* 运算： `ret[i] = idx[i] < n ? tab[idx[i]][i] : r[i]`

```c
int8x8_t vtbx3_s8 (int8x8_t r, int8x8x3_t tab, int8x8_t idx);
uint8x8_t vtbx3_u8 (uint8x8_t r, uint8x8x3_t tab, uint8x8_t idx);
poly8x8_t vtbx3_p8 (poly8x8_t r, poly8x8x3_t tab, uint8x8_t idx);
```

```c
int8x8_t vqtbx3_s8 (int8x8_t r, int8x16x3_t tab, uint8x8_t idx);
uint8x8_t vqtbx3_u8 (uint8x8_t r, uint8x16x3_t tab, uint8x8_t idx);
poly8x8_t vqtbx3_p8 (poly8x8_t r, poly8x16x3_t tab, uint8x8_t idx);
```

#### vtbx4

* 运算： `ret[i] = idx[i] < n ? tab[idx[i]][i] : r[i]`

```c
int8x8_t vtbx4_s8 (int8x8_t r, int8x8x4_t tab, int8x8_t idx);
uint8x8_t vtbx4_u8 (uint8x8_t r, uint8x8x4_t tab, uint8x8_t idx);
poly8x8_t vtbx4_p8 (poly8x8_t r, poly8x8x4_t tab, uint8x8_t idx);
```

```c
int8x8_t vqtbx4_s8 (int8x8_t r, int8x16x4_t tab, uint8x8_t idx);
uint8x8_t vqtbx4_u8 (uint8x8_t r, uint8x16x4_t tab, uint8x8_t idx);
poly8x8_t vqtbx4_p8 (poly8x8_t r, poly8x16x4_t tab, uint8x8_t idx);
```

### 全指令多向量扩展查表指令

#### vtbx1q

```c
int8x16_t vqtbx1q_s8 (int8x16_t r, int8x16_t tab, uint8x16_t idx);
uint8x16_t vqtbx1q_u8 (uint8x16_t r, uint8x16_t tab, uint8x16_t idx);
poly8x16_t vqtbx1q_p8 (poly8x16_t r, poly8x16_t tab, uint8x16_t idx);
```

#### vtbx2q

```c
int8x16_t vqtbx2q_s8 (int8x16_t r, int8x16x2_t tab, uint8x16_t idx);
uint8x16_t vqtbx2q_u8 (uint8x16_t r, uint8x16x2_t tab, uint8x16_t idx);
poly8x16_t vqtbx2q_p8 (poly8x16_t r, poly8x16x2_t tab, uint8x16_t idx);
```

#### vtbx3q

```c
int8x16_t vqtbx3q_s8 (int8x16_t r, int8x16x3_t tab, uint8x16_t idx);
uint8x16_t vqtbx3q_u8 (uint8x16_t r, uint8x16x3_t tab, uint8x16_t idx);
poly8x16_t vqtbx3q_p8 (poly8x16_t r, poly8x16x3_t tab, uint8x16_t idx);
```

#### vtbx4q

```c
int8x16_t vqtbx4q_s8 (int8x16_t r, int8x16x4_t tab, uint8x16_t idx);
uint8x16_t vqtbx4q_u8 (uint8x16_t r, uint8x16x4_t tab, uint8x16_t idx);
poly8x16_t vqtbx4q_p8 (poly8x16_t r, poly8x16x4_t tab, uint8x16_t idx);
```

## add加法指令

### 短指令加法

#### vadd

* 运算： `ret[i] = a[i] + b[i]`

```c
int8x8_t vadd_s8 (int8x8_t a, int8x8_t b);     // _mm_add_pi8  / _m_paddb
int16x4_t vadd_s16 (int16x4_t a, int16x4_t b); // _mm_add_pi16 / _m_paddw
int32x2_t vadd_s32 (int32x2_t a, int32x2_t b); // _mm_add_pi32 / _m_paddd
int64x1_t vadd_s64 (int64x1_t a, int64x1_t b); // _mm_add_si64
```

```c
uint8x8_t vadd_u8 (uint8x8_t a, uint8x8_t b);
uint16x4_t vadd_u16 (uint16x4_t a, uint16x4_t b);
uint32x2_t vadd_u32 (uint32x2_t a, uint32x2_t b);
uint64x1_t vadd_u64 (uint64x1_t a, uint64x1_t b);
```

```c
float16x4_t vadd_f16 (float16x4_t a, float16x4_t b);
float32x2_t vadd_f32 (float32x2_t a, float32x2_t b);
float64x1_t vadd_f64 (float64x1_t a, float64x1_t b);
```

```c
poly8x8_t vadd_p8 (poly8x8_t a, poly8x8_t b);
poly16x4_t vadd_p16 (poly16x4_t a, poly16x4_t b);
poly64x1_t vadd_p64 (poly64x1_t a, poly64x1_t b);
```

#### vqadd

* 运算： `ret[i] = sat(a[i] + b[i])`

```c
int8x8_t vqadd_s8 (int8x8_t a, int8x8_t b);     // _mm_adds_pi8  / _m_paddsb
int16x4_t vqadd_s16 (int16x4_t a, int16x4_t b); // _mm_adds_pi16 / _m_paddsw
int32x2_t vqadd_s32 (int32x2_t a, int32x2_t b);
int64x1_t vqadd_s64 (int64x1_t a, int64x1_t b);
```

```c
uint8x8_t vqadd_u8 (uint8x8_t a, uint8x8_t b);     // _mm_adds_pu8 / _m_paddusb
uint16x4_t vqadd_u16 (uint16x4_t a, uint16x4_t b); // _mm_adds_pu16 / _m_paddusw
uint32x2_t vqadd_u32 (uint32x2_t a, uint32x2_t b);
uint64x1_t vqadd_u64 (uint64x1_t a, uint64x1_t b);
```

#### vsqadd/vuqadd

* 运算： `ret[i] = sat(a[i] + b[i])`

```c
uint8x8_t vsqadd_u8 (uint8x8_t a, int8x8_t b);
uint16x4_t vsqadd_u16 (uint16x4_t a, int16x4_t b);
uint32x2_t vsqadd_u32 (uint32x2_t a, int32x2_t b);
uint64x1_t vsqadd_u64 (uint64x1_t a, int64x1_t b);
```

```c
int8x8_t vuqadd_s8 (int8x8_t a, uint8x8_t b);
int16x4_t vuqadd_s16 (int16x4_t a, uint16x4_t b);
int32x2_t vuqadd_s32 (int32x2_t a, uint32x2_t b);
int64x1_t vuqadd_s64 (int64x1_t a, uint64x1_t b);
```

#### vhadd

* 运算： `ret[i] = (a[i] + b[i]) >> 1`

```c
int8x8_t vhadd_s8 (int8x8_t a, int8x8_t b);
int16x4_t vhadd_s16 (int16x4_t a, int16x4_t b);
int32x2_t vhadd_s32 (int32x2_t a, int32x2_t b);
```

```c
uint8x8_t vhadd_u8 (uint8x8_t a, uint8x8_t b);
uint16x4_t vhadd_u16 (uint16x4_t a, uint16x4_t b);
uint32x2_t vhadd_u32 (uint32x2_t a, uint32x2_t b);
```

#### vrhadd

* 运算： `ret[i] = (a[i] + b[i] + 1) >> 1`

```c
int8x8_t vrhadd_s8 (int8x8_t a, int8x8_t b);
int16x4_t vrhadd_s16 (int16x4_t a, int16x4_t b);
int32x2_t vrhadd_s32 (int32x2_t a, int32x2_t b);
```

```c
uint8x8_t vrhadd_u8 (uint8x8_t a, uint8x8_t b);     // _mm_avg_pu8 / _m_pavgb
uint16x4_t vrhadd_u16 (uint16x4_t a, uint16x4_t b); // _mm_avg_pu16 / _m_pavgw
uint32x2_t vrhadd_u32 (uint32x2_t a, uint32x2_t b);
```

#### vpadd

* 运算： 先连接a、b组成新向量 `ab = {a[0], a[1], ..., b[0], b[1], ...}` ; 再临近元素相加 `ret[i] = ab[2i] + ab[2i+1]`

```c
int8x8_t vpadd_s8 (int8x8_t a, int8x8_t b);
int16x4_t vpadd_s16 (int16x4_t a, int16x4_t b); // _mm_hadd_pi16
int32x2_t vpadd_s32 (int32x2_t a, int32x2_t b); // _mm_hadd_pi32
```

```c
uint8x8_t vpadd_u8 (uint8x8_t a, uint8x8_t b);
uint16x4_t vpadd_u16 (uint16x4_t a, uint16x4_t b);
uint32x2_t vpadd_u32 (uint32x2_t a, uint32x2_t b);
```

```c
float16x4_t vpadd_f16 (float16x4_t a, float16x4_t b);
float32x2_t vpadd_f32 (float32x2_t a, float32x2_t b);
```

#### vpaddl

* 运算： `ret[i] = a[2i] + a[2i+1]`

```c
int16x4_t vpaddl_s8 (int8x8_t a);
int32x2_t vpaddl_s16 (int16x4_t a);
int64x1_t vpaddl_s32 (int32x2_t a);
```

```c
uint16x4_t vpaddl_u8 (uint8x8_t a);
uint32x2_t vpaddl_u16 (uint16x4_t a);
uint64x1_t vpaddl_u32 (uint32x2_t a);
```

#### vaddv

* 运算： `ret = ∑a[i]`

```c
int8_t vaddv_s8 (int8x8_t a);
int16_t vaddv_s16 (int16x4_t a);
int32_t vaddv_s32 (int32x2_t a);
```

```c
uint8_t vaddv_u8 (uint8x8_t a);
uint16_t vaddv_u16 (uint16x4_t a);
uint32_t vaddv_u32 (uint32x2_t a);
```

```c
float32_t vaddv_f32 (float32x2_t a);
```

#### vaddlv

* 运算： `ret = ∑a[i]`

```c
int16_t vaddlv_s8 (int8x8_t a);
int32_t vaddlv_s16 (int16x4_t a);
int64_t vaddlv_s32 (int32x2_t a);
```

```c
uint16_t vaddlv_u8 (uint8x8_t a);
uint32_t vaddlv_u16 (uint16x4_t a);
uint64_t vaddlv_u32 (uint32x2_t a);
```

#### vcadd

```c
float16x4_t vcadd_rot90_f16 (float16x4_t a, float16x4_t b);
float32x2_t vcadd_rot90_f32 (float32x2_t a, float32x2_t b);

float16x4_t vcadd_rot270_f16 (float16x4_t a, float16x4_t b);
float32x2_t vcadd_rot270_f32 (float32x2_t a, float32x2_t b);
```

### 全指令加法

#### vaddq

* 运算： `ret[i] = a[i] + b[i]`

```c
int8x16_t vaddq_s8 (int8x16_t a, int8x16_t b);  // _mm_add_epi8  | _mm256_add_epi8  | _mm512_add_epi16
int16x8_t vaddq_s16 (int16x8_t a, int16x8_t b); // _mm_add_epi16 | _mm256_add_epi16 | _mm512_add_epi16
int32x4_t vaddq_s32 (int32x4_t a, int32x4_t b); // _mm_add_epi32 | _mm256_add_epi32 | _mm512_add_epi32
int64x2_t vaddq_s64 (int64x2_t a, int64x2_t b); // _mm_add_epi64 | _mm256_add_epi64 | _mm512_add_epi64
```

```c
uint8x16_t vaddq_u8 (uint8x16_t a, uint8x16_t b);
uint16x8_t vaddq_u16 (uint16x8_t a, uint16x8_t b);
uint32x4_t vaddq_u32 (uint32x4_t a, uint32x4_t b);
uint64x2_t vaddq_u64 (uint64x2_t a, uint64x2_t b);
```

```c
float16x8_t vaddq_f16 (float16x8_t a, float16x8_t b); // _mm_add_ph | _mm256_add_ph | _mm512_add_ph
float32x4_t vaddq_f32 (float32x4_t a, float32x4_t b); // _mm_add_ps | _mm256_add_ps | _mm512_add_ps
float64x2_t vaddq_f64 (float64x2_t a, float64x2_t b); // _mm_add_pd | _mm256_add_pd | _mm512_add_pd
```

```c
poly8x16_t vaddq_p8 (poly8x16_t a, poly8x16_t b);
poly16x8_t vaddq_p16 (poly16x8_t a, poly16x8_t b);
poly64x2_t vaddq_p64 (poly64x2_t a, poly64x2_t b);
poly128_t vaddq_p128 (poly128_t a, poly128_t b);
```

#### vqaddq

* 运算： `ret[i] = sat(a[i] + b[i])`

```c
int8x16_t vqaddq_s8 (int8x16_t a, int8x16_t b);  // _mm_adds_epi8  | _mm256_adds_epi8  | _mm512_adds_epi8
int16x8_t vqaddq_s16 (int16x8_t a, int16x8_t b); // _mm_adds_epi16 | _mm256_adds_epi16 | _mm512_adds_epi16
int32x4_t vqaddq_s32 (int32x4_t a, int32x4_t b);
int64x2_t vqaddq_s64 (int64x2_t a, int64x2_t b);
```

```c
uint8x16_t vqaddq_u8 (uint8x16_t a, uint8x16_t b);  // _mm_adds_epu8  | _mm256_adds_epu8  | _mm512_adds_epu8
uint16x8_t vqaddq_u16 (uint16x8_t a, uint16x8_t b); // _mm_adds_epu16 | _mm256_adds_epu16 | _mm512_adds_epu16
uint32x4_t vqaddq_u32 (uint32x4_t a, uint32x4_t b);
uint64x2_t vqaddq_u64 (uint64x2_t a, uint64x2_t b);
```

#### vsqaddq/vuqaddq

* 运算： `ret[i] = sat(a[i] + b[i])`

```c
uint8x16_t vsqaddq_u8 (uint8x16_t a, int8x16_t b);
uint16x8_t vsqaddq_u16 (uint16x8_t a, int16x8_t b);
uint32x4_t vsqaddq_u32 (uint32x4_t a, int32x4_t b);
uint64x2_t vsqaddq_u64 (uint64x2_t a, int64x2_t b);
```

```c
int8x16_t vuqaddq_s8 (int8x16_t a, uint8x16_t b);
int16x8_t vuqaddq_s16 (int16x8_t a, uint16x8_t b);
int32x4_t vuqaddq_s32 (int32x4_t a, uint32x4_t b);
int64x2_t vuqaddq_s64 (int64x2_t a, uint64x2_t b);
```

#### vhaddq

* 运算： `ret[i] = (a[i] + b[i]) >> 1`

```c
int8x16_t vhaddq_s8 (int8x16_t a, int8x16_t b);
int16x8_t vhaddq_s16 (int16x8_t a, int16x8_t b);
int32x4_t vhaddq_s32 (int32x4_t a, int32x4_t b);
```

```c
uint8x16_t vhaddq_u8 (uint8x16_t a, uint8x16_t b);
uint16x8_t vhaddq_u16 (uint16x8_t a, uint16x8_t b);
uint32x4_t vhaddq_u32 (uint32x4_t a, uint32x4_t b);
```

#### vrhaddq

* 运算： `ret[i] = (a[i] + b[i] + 1) >> 1`

```c
int8x16_t vrhaddq_s8 (int8x16_t a, int8x16_t b);
int16x8_t vrhaddq_s16 (int16x8_t a, int16x8_t b);
int32x4_t vrhaddq_s32 (int32x4_t a, int32x4_t b);
```

```c
uint8x16_t vrhaddq_u8 (uint8x16_t a, uint8x16_t b);  // _mm_avg_epu8  | _mm256_avg_epu8  | _mm512_avg_epu8
uint16x8_t vrhaddq_u16 (uint16x8_t a, uint16x8_t b); // _mm_avg_epu16 | _mm256_avg_epu16 | _mm512_avg_epu16
uint32x4_t vrhaddq_u32 (uint32x4_t a, uint32x4_t b);
```

#### vpaddq

* 运算： 先连接a、b组成新向量 `ab = {a[0], a[1], ..., b[0], b[1], ...}` ; 再临近元素相加 `ret[i] = ab[2i] + ab[2i+1]`

```c
int8x16_t vpaddq_s8 (int8x16_t a, int8x16_t b);
int16x8_t vpaddq_s16 (int16x8_t a, int16x8_t b); // _mm_hadd_epi16 | _mm256_hadd_epi16
int32x4_t vpaddq_s32 (int32x4_t a, int32x4_t b); // _mm_hadd_epi32 | _mm256_hadd_epi32
int64x2_t vpaddq_s64 (int64x2_t a, int64x2_t b);
```

```c
uint8x16_t vpaddq_u8 (uint8x16_t a, uint8x16_t b);
uint16x8_t vpaddq_u16 (uint16x8_t a, uint16x8_t b);
uint32x4_t vpaddq_u32 (uint32x4_t a, uint32x4_t b);
uint64x2_t vpaddq_u64 (uint64x2_t a, uint64x2_t b);
```

```c
float16x8_t vpaddq_f16 (float16x8_t a, float16x8_t b);
float32x4_t vpaddq_f32 (float32x4_t a, float32x4_t b); // _mm_hadd_ps | _mm256_hadd_ps
float64x2_t vpaddq_f64 (float64x2_t a, float64x2_t b); // _mm_hadd_pd | _mm256_hadd_pd
```

#### vaddvq

* 运算： `ret = ∑a[i]`

```c
int8_t vaddvq_s8 (int8x16_t a);
int16_t vaddvq_s16 (int16x8_t a);
int32_t vaddvq_s32 (int32x4_t a);
int64_t vaddvq_s64 (int64x2_t a);
```

```c
uint8_t vaddvq_u8 (uint8x16_t a);
uint16_t vaddvq_u16 (uint16x8_t a);
uint32_t vaddvq_u32 (uint32x4_t a);
uint64_t vaddvq_u64 (uint64x2_t a);
```

```c
float32_t vaddvq_f32 (float32x4_t a);
float64_t vaddvq_f64 (float64x2_t a);
```

#### vcaddq

```c
float16x8_t vcaddq_rot90_f16 (float16x8_t a, float16x8_t b);
float32x4_t vcaddq_rot90_f32 (float32x4_t a, float32x4_t b);
float64x2_t vcaddq_rot90_f64 (float64x2_t a, float64x2_t b);
```

```c
float16x8_t vcaddq_rot270_f16 (float16x8_t a, float16x8_t b);
float32x4_t vcaddq_rot270_f32 (float32x4_t a, float32x4_t b);
float64x2_t vcaddq_rot270_f64 (float64x2_t a, float64x2_t b);
```

### 长指令加法

#### vaddl

* 运算： `ret[i] = a[i] + b[i]`

```c
int16x8_t vaddl_s8 (int8x8_t a, int8x8_t b);
int32x4_t vaddl_s16 (int16x4_t a, int16x4_t b);
int64x2_t vaddl_s32 (int32x2_t a, int32x2_t b);
```

```c
uint16x8_t vaddl_u8 (uint8x8_t a, uint8x8_t b);
uint32x4_t vaddl_u16 (uint16x4_t a, uint16x4_t b);
uint64x2_t vaddl_u32 (uint32x2_t a, uint32x2_t b);
```

#### vaddl_high

* 运算： `ret[i] = a[N+i] + b[N+i]`

```c
int16x8_t vaddl_high_s8 (int8x16_t a, int8x16_t b);
int32x4_t vaddl_high_s16 (int16x8_t a, int16x8_t b);
int64x2_t vaddl_high_s32 (int32x4_t a, int32x4_t b);
```

```c
uint16x8_t vaddl_high_u8 (uint8x16_t a, uint8x16_t b);
uint32x4_t vaddl_high_u16 (uint16x8_t a, uint16x8_t b);
uint64x2_t vaddl_high_u32 (uint32x4_t a, uint32x4_t b);
```

#### vpaddlq

* 运算： `ret[i] = a[2i] + a[2i+1]`

```c
int16x8_t vpaddlq_s8 (int8x16_t a);
int32x4_t vpaddlq_s16 (int16x8_t a);
int64x2_t vpaddlq_s32 (int32x4_t a);
```

```c
uint16x8_t vpaddlq_u8 (uint8x16_t a);
uint32x4_t vpaddlq_u16 (uint16x8_t a);
uint64x2_t vpaddlq_u32 (uint32x4_t a);
```

#### vaddlvq

* 运算： `ret = ∑a[i]`

```c
int16_t vaddlvq_s8 (int8x16_t a);
int32_t vaddlvq_s16 (int16x8_t a);
int64_t vaddlvq_s32 (int32x4_t a);
```

```c
uint16_t vaddlvq_u8 (uint8x16_t a);
uint32_t vaddlvq_u16 (uint16x8_t a);
uint64_t vaddlvq_u32 (uint32x4_t a);
```

### 宽指令加法

#### vaddw

* 运算： `ret[i] = a[i] + b[i]`

```c
int16x8_t vaddw_s8 (int16x8_t a, int8x8_t b);
int32x4_t vaddw_s16 (int32x4_t a, int16x4_t b);
int64x2_t vaddw_s32 (int64x2_t a, int32x2_t b);
```

```c
uint16x8_t vaddw_u8 (uint16x8_t a, uint8x8_t b);
uint32x4_t vaddw_u16 (uint32x4_t a, uint16x4_t b);
uint64x2_t vaddw_u32 (uint64x2_t a, uint32x2_t b);
```

#### vaddw_high

* 运算： `ret[i] = a[i] + b[N+i]`

```c
int16x8_t vaddw_high_s8 (int16x8_t a, int8x16_t b);
int32x4_t vaddw_high_s16 (int32x4_t a, int16x8_t b);
int64x2_t vaddw_high_s32 (int64x2_t a, int32x4_t b);
```

```c
uint16x8_t vaddw_high_u8 (uint16x8_t a, uint8x16_t b);
uint32x4_t vaddw_high_u16 (uint32x4_t a, uint16x8_t b);
uint64x2_t vaddw_high_u32 (uint64x2_t a, uint32x4_t b);
```

### 窄指令加法

#### vaddhn

* 运算： `ret[i] = (a[i] + b[i]) >> L`

```c
int8x8_t vaddhn_s16 (int16x8_t a, int16x8_t b);
int16x4_t vaddhn_s32 (int32x4_t a, int32x4_t b);
int32x2_t vaddhn_s64 (int64x2_t a, int64x2_t b);
```

```c
uint8x8_t vaddhn_u16 (uint16x8_t a, uint16x8_t b);
uint16x4_t vaddhn_u32 (uint32x4_t a, uint32x4_t b);
uint32x2_t vaddhn_u64 (uint64x2_t a, uint64x2_t b);
```

#### vraddhn

* 运算： `ret[i] = (a[i] + b[i] + (1<<(L-1))) >> L`

```c
int8x8_t vraddhn_s16 (int16x8_t a, int16x8_t b);
int16x4_t vraddhn_s32 (int32x4_t a, int32x4_t b);
int32x2_t vraddhn_s64 (int64x2_t a, int64x2_t b);
```

```c
uint8x8_t vraddhn_u16 (uint16x8_t a, uint16x8_t b);
uint16x4_t vraddhn_u32 (uint32x4_t a, uint32x4_t b);
uint32x2_t vraddhn_u64 (uint64x2_t a, uint64x2_t b);
```

#### vaddhn_high

* 运算： 0~N/2-1 : `ret[i] = r[i]` ; N/2~N-1 : `ret[N/2+i] = (a[i] + b[i]) >> L`

```c
int8x16_t vaddhn_high_s16 (int8x8_t r, int16x8_t a, int16x8_t b);
int16x8_t vaddhn_high_s32 (int16x4_t r, int32x4_t a, int32x4_t b);
int32x4_t vaddhn_high_s64 (int32x2_t r, int64x2_t a, int64x2_t b);
```

```c
uint8x16_t vaddhn_high_u16 (uint8x8_t r, uint16x8_t a, uint16x8_t b);
uint16x8_t vaddhn_high_u32 (uint16x4_t r, uint32x4_t a, uint32x4_t b);
uint32x4_t vaddhn_high_u64 (uint32x2_t r, uint64x2_t a, uint64x2_t b);
```

#### vraddhn_high

* 运算： 0~N/2-1 : `ret[i] = r[i]` ; N/2~N-1 : `ret[N/2+i] = (a[i] + b[i] + (1<<(L-1))) >> L`

```c
int8x16_t vraddhn_high_s16 (int8x8_t r, int16x8_t a, int16x8_t b);
int16x8_t vraddhn_high_s32 (int16x4_t r, int32x4_t a, int32x4_t b);
int32x4_t vraddhn_high_s64 (int32x2_t r, int64x2_t a, int64x2_t b);
```

```c
uint8x16_t vraddhn_high_u16 (uint8x8_t r, uint16x8_t a, uint16x8_t b);
uint16x8_t vraddhn_high_u32 (uint16x4_t r, uint32x4_t a, uint32x4_t b);
uint32x4_t vraddhn_high_u64 (uint32x2_t r, uint64x2_t a, uint64x2_t b);
```

### 单指令加法

#### vqadd?

* 运算： `ret = sat(a + b)`

```c
int8_t vqaddb_s8 (int8_t a, int8_t b);
int16_t vqaddh_s16 (int16_t a, int16_t b);
int32_t vqadds_s32 (int32_t a, int32_t b);
int64_t vqaddd_s64 (int64_t a, int64_t b);
```

```c
uint8_t vqaddb_u8 (uint8_t a, uint8_t b);
uint16_t vqaddh_u16 (uint16_t a, uint16_t b);
uint32_t vqadds_u32 (uint32_t a, uint32_t b);
uint64_t vqaddd_u64 (uint64_t a, uint64_t b);
```

#### vsqadd?/vuqadd?

* 运算： `ret = sat(a + b)`

```c
uint8_t vsqaddb_u8 (uint8_t a, int8_t b);
uint16_t vsqaddh_u16 (uint16_t a, int16_t b);
uint32_t vsqadds_u32 (uint32_t a, int32_t b);
uint64_t vsqaddd_u64 (uint64_t a, int64_t b);
```

```c
int8_t vuqaddb_s8 (int8_t a, uint8_t b);
int16_t vuqaddh_s16 (int16_t a, uint16_t b);
int32_t vuqadds_s32 (int32_t a, uint32_t b);
int64_t vuqaddd_s64 (int64_t a, uint64_t b);
```

#### vpadd?

* 运算： `ret = a[0] + a[1]`

```c
int64_t vpaddd_s64 (int64x2_t a);
```

```c
uint64_t vpaddd_u64 (uint64x2_t a);
```

```c
float32_t vpadds_f32 (float32x2_t a);
float64_t vpaddd_f64 (float64x2_t a);
```

## sub减法指令

### 短指令减法

#### vsub

* 运算： `ret[i] = a[i] - b[i]`

```c
int8x8_t vsub_s8 (int8x8_t a, int8x8_t b);     // _mm_sub_pi8 / _m_psubb
int16x4_t vsub_s16 (int16x4_t a, int16x4_t b); // _mm_sub_pi16 / _m_psubw
int32x2_t vsub_s32 (int32x2_t a, int32x2_t b); // _mm_sub_pi32 / _m_psubd
int64x1_t vsub_s64 (int64x1_t a, int64x1_t b); // _mm_sub_si64
```

```c
uint8x8_t vsub_u8 (uint8x8_t a, uint8x8_t b);
uint16x4_t vsub_u16 (uint16x4_t a, uint16x4_t b);
uint32x2_t vsub_u32 (uint32x2_t a, uint32x2_t b);
uint64x1_t vsub_u64 (uint64x1_t a, uint64x1_t b);
```

```c
float16x4_t vsub_f16 (float16x4_t a, float16x4_t b);
float32x2_t vsub_f32 (float32x2_t a, float32x2_t b);
float64x1_t vsub_f64 (float64x1_t a, float64x1_t b);
```

#### vqsub

* 运算： `ret[i] = sat(a[i] - b[i])`

```c
int8x8_t vqsub_s8 (int8x8_t a, int8x8_t b);     // _mm_subs_pi8 / _m_psubsb
int16x4_t vqsub_s16 (int16x4_t a, int16x4_t b); // _mm_subs_pi16 / _m_psubsw
int32x2_t vqsub_s32 (int32x2_t a, int32x2_t b);
int64x1_t vqsub_s64 (int64x1_t a, int64x1_t b);
```

```c
uint8x8_t vqsub_u8 (uint8x8_t a, uint8x8_t b);     // _mm_subs_pu8 / _m_psubusb
uint16x4_t vqsub_u16 (uint16x4_t a, uint16x4_t b); // _mm_subs_pu16 / _m_psubusw
uint32x2_t vqsub_u32 (uint32x2_t a, uint32x2_t b);
uint64x1_t vqsub_u64 (uint64x1_t a, uint64x1_t b);
```

#### vhsub

* 运算： `ret[i] = (a[i] - b[i]) >> 1`

```c
int8x8_t vhsub_s8 (int8x8_t a, int8x8_t b);
int16x4_t vhsub_s16 (int16x4_t a, int16x4_t b);
int32x2_t vhsub_s32 (int32x2_t a, int32x2_t b);
```

```c
uint8x8_t vhsub_u8 (uint8x8_t a, uint8x8_t b);
uint16x4_t vhsub_u16 (uint16x4_t a, uint16x4_t b);
uint32x2_t vhsub_u32 (uint32x2_t a, uint32x2_t b);
```

### 全指令减法

#### vsubq

* 运算： `ret[i] = a[i] - b[i]`

```c
int8x16_t vsubq_s8 (int8x16_t a, int8x16_t b);  // _mm_sub_epi8  | _mm256_sub_epi8  | _mm512_sub_epi8
int16x8_t vsubq_s16 (int16x8_t a, int16x8_t b); // _mm_sub_epi16 | _mm256_sub_epi16 | _mm512_sub_epi16
int32x4_t vsubq_s32 (int32x4_t a, int32x4_t b); // _mm_sub_epi32 | _mm256_sub_epi32 | _mm512_sub_epi32
int64x2_t vsubq_s64 (int64x2_t a, int64x2_t b); // _mm_sub_epi64 | _mm256_sub_epi64 | _mm512_sub_epi64
```

```c
uint8x16_t vsubq_u8 (uint8x16_t a, uint8x16_t b);
uint16x8_t vsubq_u16 (uint16x8_t a, uint16x8_t b);
uint32x4_t vsubq_u32 (uint32x4_t a, uint32x4_t b);
uint64x2_t vsubq_u64 (uint64x2_t a, uint64x2_t b);
```

```c
float16x8_t vsubq_f16 (float16x8_t a, float16x8_t b); // _mm_sub_ph | _mm256_sub_ph | _mm512_sub_ph
float32x4_t vsubq_f32 (float32x4_t a, float32x4_t b); // _mm_sub_ps | _mm256_sub_ps | _mm512_sub_ps
float64x2_t vsubq_f64 (float64x2_t a, float64x2_t b); // _mm_sub_pd | _mm256_sub_pd | _mm512_sub_pd
```

#### vqsubq

* 运算： `ret[i] = sat(a[i] - b[i])`

```c
int8x16_t vqsubq_s8 (int8x16_t a, int8x16_t b);  // _mm_subs_epi8  | _mm256_subs_epi8  | _mm512_subs_epi8
int16x8_t vqsubq_s16 (int16x8_t a, int16x8_t b); // _mm_subs_epi16 | _mm256_subs_epi16 | _mm512_subs_epi16
int32x4_t vqsubq_s32 (int32x4_t a, int32x4_t b);
int64x2_t vqsubq_s64 (int64x2_t a, int64x2_t b);
```

```c
uint8x16_t vqsubq_u8 (uint8x16_t a, uint8x16_t b);  // _mm_subs_epu8  | _mm256_subs_epu8  | _mm512_subs_epu8
uint16x8_t vqsubq_u16 (uint16x8_t a, uint16x8_t b); // _mm_subs_epu16 | _mm256_subs_epu16 | _mm512_subs_epu16
uint32x4_t vqsubq_u32 (uint32x4_t a, uint32x4_t b);
uint64x2_t vqsubq_u64 (uint64x2_t a, uint64x2_t b);
```

#### vhsubq

* 运算： `ret[i] = (a[i] - b[i]) >> 1`

```c
int8x16_t vhsubq_s8 (int8x16_t a, int8x16_t b);
int16x8_t vhsubq_s16 (int16x8_t a, int16x8_t b);
int32x4_t vhsubq_s32 (int32x4_t a, int32x4_t b);
```

```c
uint8x16_t vhsubq_u8 (uint8x16_t a, uint8x16_t b);
uint16x8_t vhsubq_u16 (uint16x8_t a, uint16x8_t b);
uint32x4_t vhsubq_u32 (uint32x4_t a, uint32x4_t b);
```

### 长指令减法

#### vsubl

* 运算： `ret[i] = a[i] - b[i]`

```c
int16x8_t vsubl_s8 (int8x8_t a, int8x8_t b);
int32x4_t vsubl_s16 (int16x4_t a, int16x4_t b);
int64x2_t vsubl_s32 (int32x2_t a, int32x2_t b);
```

```c
uint16x8_t vsubl_u8 (uint8x8_t a, uint8x8_t b);
uint32x4_t vsubl_u16 (uint16x4_t a, uint16x4_t b);
uint64x2_t vsubl_u32 (uint32x2_t a, uint32x2_t b);
```

#### vsubl_high

* 运算： `ret[i] = a[N+i] - b[N+i]`

```c
int16x8_t vsubl_high_s8 (int8x16_t a, int8x16_t b);
int32x4_t vsubl_high_s16 (int16x8_t a, int16x8_t b);
int64x2_t vsubl_high_s32 (int32x4_t a, int32x4_t b);
```

```c
uint16x8_t vsubl_high_u8 (uint8x16_t a, uint8x16_t b);
uint32x4_t vsubl_high_u16 (uint16x8_t a, uint16x8_t b);
uint64x2_t vsubl_high_u32 (uint32x4_t a, uint32x4_t b);
```

### 宽指令减法

#### vsubw

* 运算： `ret[i] = a[i] - b[i]`

```c
int16x8_t vsubw_s8 (int16x8_t a, int8x8_t b);
int32x4_t vsubw_s16 (int32x4_t a, int16x4_t b);
int64x2_t vsubw_s32 (int64x2_t a, int32x2_t b);
```

```c
uint16x8_t vsubw_u8 (uint16x8_t a, uint8x8_t b);
uint32x4_t vsubw_u16 (uint32x4_t a, uint16x4_t b);
uint64x2_t vsubw_u32 (uint64x2_t a, uint32x2_t b);
```

#### vsubw_high

* 运算： `ret[i] = a[i] - b[N+i]`

```c
int16x8_t vsubw_high_s8 (int16x8_t a, int8x16_t b);
int32x4_t vsubw_high_s16 (int32x4_t a, int16x8_t b);
int64x2_t vsubw_high_s32 (int64x2_t a, int32x4_t b);
```

```c
uint16x8_t vsubw_high_u8 (uint16x8_t a, uint8x16_t b);
uint32x4_t vsubw_high_u16 (uint32x4_t a, uint16x8_t b);
uint64x2_t vsubw_high_u32 (uint64x2_t a, uint32x4_t b);
```

### 窄指令减法

#### vsubhn

* 运算： `ret[i] = (a[i] - b[i]) >> L`

```c
int8x8_t vsubhn_s16 (int16x8_t a, int16x8_t b);
int16x4_t vsubhn_s32 (int32x4_t a, int32x4_t b);
int32x2_t vsubhn_s64 (int64x2_t a, int64x2_t b);
```

```c
uint8x8_t vsubhn_u16 (uint16x8_t a, uint16x8_t b);
uint16x4_t vsubhn_u32 (uint32x4_t a, uint32x4_t b);
uint32x2_t vsubhn_u64 (uint64x2_t a, uint64x2_t b);
```

#### vrsubhn

* 运算： `ret[i] = (a[i] - b[i] + (1<<(L-1))) >> L`

```c
int8x8_t vrsubhn_s16 (int16x8_t a, int16x8_t b);
int16x4_t vrsubhn_s32 (int32x4_t a, int32x4_t b);
int32x2_t vrsubhn_s64 (int64x2_t a, int64x2_t b);
```

```c
uint8x8_t vrsubhn_u16 (uint16x8_t a, uint16x8_t b);
uint16x4_t vrsubhn_u32 (uint32x4_t a, uint32x4_t b);
uint32x2_t vrsubhn_u64 (uint64x2_t a, uint64x2_t b);
```

#### vsubhn_high

* 运算： 0~N/2-1 : `ret[i] = r[i]` ; N/2~N-1 : `ret[N/2+i] = (a[i] - b[i]) >> L`

```c
int8x16_t vsubhn_high_s16 (int8x8_t r, int16x8_t a, int16x8_t b);
int16x8_t vsubhn_high_s32 (int16x4_t r, int32x4_t a, int32x4_t b);
int32x4_t vsubhn_high_s64 (int32x2_t r, int64x2_t a, int64x2_t b);
```

```c
uint8x16_t vsubhn_high_u16 (uint8x8_t r, uint16x8_t a, uint16x8_t b);
uint16x8_t vsubhn_high_u32 (uint16x4_t r, uint32x4_t a, uint32x4_t b);
uint32x4_t vsubhn_high_u64 (uint32x2_t r, uint64x2_t a, uint64x2_t b);
```

#### vrsubhn_high

* 运算： 0~N/2-1 : `ret[i] = r[i]` ; N/2~N-1 : `ret[N/2+i] = (a[i] - b[i] + (1<<(L-1))) >> L`

```c
int8x16_t vrsubhn_high_s16 (int8x8_t r, int16x8_t a, int16x8_t b);
int16x8_t vrsubhn_high_s32 (int16x4_t r, int32x4_t a, int32x4_t b);
int32x4_t vrsubhn_high_s64 (int32x2_t r, int64x2_t a, int64x2_t b);
```

```c
uint8x16_t vrsubhn_high_u16 (uint8x8_t r, uint16x8_t a, uint16x8_t b);
uint16x8_t vrsubhn_high_u32 (uint16x4_t r, uint32x4_t a, uint32x4_t b);
uint32x4_t vrsubhn_high_u64 (uint32x2_t r, uint64x2_t a, uint64x2_t b);
```

### 单指令减法

#### vqsub?

* 运算： `ret = sat(a - b)`

```c
int8_t vqsubb_s8 (int8_t a, int8_t b);
int16_t vqsubh_s16 (int16_t a, int16_t b);
int32_t vqsubs_s32 (int32_t a, int32_t b);
int64_t vqsubd_s64 (int64_t a, int64_t b);
```

```c
uint8_t vqsubb_u8 (uint8_t a, uint8_t b);
uint16_t vqsubh_u16 (uint16_t a, uint16_t b);
uint32_t vqsubs_u32 (uint32_t a, uint32_t b);
uint64_t vqsubd_u64 (uint64_t a, uint64_t b);
```

## mul乘法指令

### 短指令乘法

#### vmul

* 运算： `ret[i] = a[i] * b[i]`

```c
int8x8_t vmul_s8 (int8x8_t a, int8x8_t b);
int16x4_t vmul_s16 (int16x4_t a, int16x4_t b); // _mm_mullo_pi16 / _m_pmullw
int32x2_t vmul_s32 (int32x2_t a, int32x2_t b);
```

```c
uint8x8_t vmul_u8 (uint8x8_t a, uint8x8_t b);
uint16x4_t vmul_u16 (uint16x4_t a, uint16x4_t b);
uint32x2_t vmul_u32 (uint32x2_t a, uint32x2_t b);
```

```c
float16x4_t vmul_f16 (float16x4_t a, float16x4_t b);
float32x2_t vmul_f32 (float32x2_t a, float32x2_t b);
float64x1_t vmul_f64 (float64x1_t a, float64x1_t b);
```

```c
poly8x8_t vmul_p8 (poly8x8_t a, poly8x8_t b);
```

#### vmul_n

* 运算： `ret[i] = a[i] * b`

```c
int16x4_t vmul_n_s16 (int16x4_t a, int16_t b);
int32x2_t vmul_n_s32 (int32x2_t a, int32_t b);
```

```c
uint16x4_t vmul_n_u16 (uint16x4_t a, uint16_t b);
uint32x2_t vmul_n_u32 (uint32x2_t a, uint32_t b);
```

```c
float16x4_t vmul_n_f16 (float16x4_t a, float16_t b);
float32x2_t vmul_n_f32 (float32x2_t a, float32_t b);
float64x1_t vmul_n_f64  (float64x1_t a, float64_t b);
```

### vmul_lane

* 运算： `ret[i] = a[i] * v[lane]`

```c
int16x4_t vmul_lane_s16 (int16x4_t a, int16x4_t v, const int lane);
int32x2_t vmul_lane_s32 (int32x2_t a, int32x2_t v, const int lane);
```

```c
uint16x4_t vmul_lane_u16 (uint16x4_t a, uint16x4_t v, const int lane);
uint32x2_t vmul_lane_u32 (uint32x2_t a, uint32x2_t v, const int lane);
```

```c
float16x4_t vmul_lane_f16 (float16x4_t a, float16x4_t v, const int lane);
float32x2_t vmul_lane_f32 (float32x2_t a, float32x2_t v, const int lane);
float64x1_t vmul_lane_f64 (float64x1_t a, float64x1_t v, const int lane);
```

```c
int16x4_t vmul_laneq_s16 (int16x4_t a, int16x8_t v, const int lane);
int32x2_t vmul_laneq_s32 (int32x2_t a, int32x4_t v, const int lane);
```

```c
uint16x4_t vmul_laneq_u16 (uint16x4_t a, uint16x8_t v, const int lane);
uint32x2_t vmul_laneq_u32 (uint32x2_t a, uint32x4_t v, const int lane);
```

```c
float16x4_t vmul_laneq_f16 (float16x4_t a, float16x8_t v, const int lane);
float32x2_t vmul_laneq_f32 (float32x2_t a, float32x4_t v, const int lane);
float64x1_t vmul_laneq_f64 (float64x1_t a, float64x2_t v, const int lane);
```

#### vqdmulh

* 运算： `ret[i] = sat((2 * a[i] * b[i]) >> L)`

```c
int16x4_t vqdmulh_s16 (int16x4_t a, int16x4_t b);
int32x2_t vqdmulh_s32 (int32x2_t a, int32x2_t b);
```

#### vqdmulh_n

* 运算： `ret[i] = sat((2 * a[i] * b) >> L)`

```c
int16x4_t vqdmulh_n_s16 (int16x4_t a, int16_t b);
int32x2_t vqdmulh_n_s32 (int32x2_t a, int32_t b);
```

#### vqdmulh_lane

* 运算： `ret[i] = sat((2 * a[i] * v[lane]) >> L)`

```c
int16x4_t vqdmulh_lane_s16 (int16x4_t a, int16x4_t v, const int lane);
int32x2_t vqdmulh_lane_s32 (int32x2_t a, int32x2_t v, const int lane);
```

```c
int16x4_t vqdmulh_laneq_s16 (int16x4_t a, int16x8_t v, const int lane);
int32x2_t vqdmulh_laneq_s32 (int32x2_t a, int32x4_t v, const int lane);
```

#### vqrdmulh

* 运算： `ret[i] = sat((2 * a[i] * b[i] + (1<<(L-1))) >> L)`

```c
int16x4_t vqrdmulh_s16 (int16x4_t a, int16x4_t b);
int32x2_t vqrdmulh_s32 (int32x2_t a, int32x2_t b);
```

#### vqrdmulh_n

* 运算： `ret[i] = sat((2 * a[i] * b + (1<<(L-1))) >> L)`

```c
int16x4_t vqrdmulh_n_s16 (int16x4_t a, int16_t b);
int32x2_t vqrdmulh_n_s32 (int32x2_t a, int32_t b);
```

#### vqrdmulh_lane

* 运算： `ret[i] = sat((2 * a[i] * v[lane] + (1<<(L-1))) >> L)`

```c
int16x4_t vqrdmulh_lane_s16 (int16x4_t a, int16x4_t v, const int lane);
int32x2_t vqrdmulh_lane_s32 (int32x2_t a, int32x2_t v, const int lane);
```
```c
int16x4_t vqrdmulh_laneq_s16 (int16x4_t a, int16x8_t v, const int lane);
int32x2_t vqrdmulh_laneq_s32 (int32x2_t a, int32x4_t v, const int lane);
```

#### vmulx

```c
float16x4_t vmulx_f16 (float16x4_t a, float16x4_t b);
float32x2_t vmulx_f32 (float32x2_t a, float32x2_t b);
float64x1_t vmulx_f64 (float64x1_t a, float64x1_t b);
```

#### vmulx_n

```c
float16x4_t vmulx_n_f16 (float16x4_t a, float16_t b);
```

#### vmulx_lane

```c
float16x4_t vmulx_lane_f16 (float16x4_t a, float16x4_t v, const int lane);
float32x2_t vmulx_lane_f32 (float32x2_t a, float32x2_t v, const int lane);
float64x1_t vmulx_lane_f64 (float64x1_t a, float64x1_t v, const int lane);
```

```c
float16x4_t vmulx_laneq_f16 (float16x4_t a, float16x8_t v, const int lane);
float32x2_t vmulx_laneq_f32 (float32x2_t a, float32x4_t v, const int lane);
float64x1_t vmulx_laneq_f64 (float64x1_t a, float64x2_t v, const int lane);
```

### 全指令乘法

#### vmulq

* 运算： `ret[i] = a[i] * b[i]`

```c
int8x16_t vmulq_s8 (int8x16_t a, int8x16_t b);
int16x8_t vmulq_s16 (int16x8_t a, int16x8_t b); // _mm_mullo_epi16 | _mm256_mullo_epi16 | _mm512_mullo_epi16
int32x4_t vmulq_s32 (int32x4_t a, int32x4_t b); // _mm_mullo_epi32 | _mm256_mullo_epi32 | _mm512_mullo_epi32
                                      // AVX512 // _mm_mullo_epi64 | _mm256_mullo_epi64 | _mm512_mullo_epi64
```

```c
uint8x16_t vmulq_u8 (uint8x16_t a, uint8x16_t b);
uint16x8_t vmulq_u16 (uint16x8_t a, uint16x8_t b);
uint32x4_t vmulq_u32 (uint32x4_t a, uint32x4_t b);
```

```c
float16x8_t vmulq_f16 (float16x8_t a, float16x8_t b); // _mm_mul_ph | _mm256_mul_ph | _mm512_mul_ph
float32x4_t vmulq_f32 (float32x4_t a, float32x4_t b); // _mm_mul_ps | _mm256_mul_ps | _mm512_mul_ps
float64x2_t vmulq_f64 (float64x2_t a, float64x2_t b); // _mm_mul_pd | _mm256_mul_pd | _mm512_mul_pd
```

```c
poly8x16_t vmulq_p8 (poly8x16_t a, poly8x16_t b);
```

#### vmulq_n

* 运算： `ret[i] = a[i] * b`

```c
int16x8_t vmulq_n_s16 (int16x8_t a, int16_t b);
int32x4_t vmulq_n_s32 (int32x4_t a, int32_t b);
```

```c
uint16x8_t vmulq_n_u16 (uint16x8_t a, uint16_t b);
uint32x4_t vmulq_n_u32 (uint32x4_t a, uint32_t b);
```

```c
float16x8_t vmulq_n_f16 (float16x8_t a, float16_t b);
float32x4_t vmulq_n_f32 (float32x4_t a, float32_t b);
float64x2_t vmulq_n_f64 (float64x2_t a, float64_t b);
```

#### vmulq_lane

* 运算： `ret[i] = a[i] * v[lane]`

```c
int16x8_t vmulq_lane_s16 (int16x8_t a, int16x4_t v, const int lane);
int32x4_t vmulq_lane_s32 (int32x4_t a, int32x2_t v, const int lane);
```

```c
uint16x8_t vmulq_lane_u16 (uint16x8_t a, uint16x4_t v, const int lane);
uint32x4_t vmulq_lane_u32 (uint32x4_t a, uint32x2_t v, const int lane);
```

```c
float16x8_t vmulq_lane_f16 (float16x8_t a, float16x4_t v, const int lane);
float32x4_t vmulq_lane_f32 (float32x4_t a, float32x2_t v, const int lane);
float64x2_t vmulq_lane_f64 (float64x2_t a, float64x1_t v, const int lane);
```

```c
int16x8_t vmulq_laneq_s16 (int16x8_t a, int16x8_t v, const int lane);
int32x4_t vmulq_laneq_s32 (int32x4_t a, int32x4_t v, const int lane);
```

```c
uint16x8_t vmulq_laneq_u16 (uint16x8_t a, uint16x8_t v, const int lane);
uint32x4_t vmulq_laneq_u32 (uint32x4_t a, uint32x4_t v, const int lane);
```

```c
float16x8_t vmulq_laneq_f16 (float16x8_t a, float16x8_t v, const int lane);
float32x4_t vmulq_laneq_f32 (float32x4_t a, float32x4_t v, const int lane);
float64x2_t vmulq_laneq_f64 (float64x2_t a, float64x2_t v, const int lane);
```

#### vqdmulhq

* 运算： `ret[i] = sat((2 * a[i] * b[i]) >> L)`

```c
int16x8_t vqdmulhq_s16 (int16x8_t a, int16x8_t b);
int32x4_t vqdmulhq_s32 (int32x4_t a, int32x4_t b);
```

#### vqdmulhq_n

* 运算： `ret[i] = sat((2 * a[i] * b) >> L)`

```c
int16x8_t vqdmulhq_n_s16 (int16x8_t a, int16_t b);
int32x4_t vqdmulhq_n_s32 (int32x4_t a, int32_t b);
```

#### vqdmulhq_lane

* 运算： `ret[i] = sat((2 * a[i] * v[lane]) >> L)`

```c
int16x8_t vqdmulhq_lane_s16 (int16x8_t a, int16x4_t v, const int lane);
int32x4_t vqdmulhq_lane_s32 (int32x4_t a, int32x2_t v, const int lane);
```

```c
int16x8_t vqdmulhq_laneq_s16 (int16x8_t a, int16x8_t v, const int lane);
int32x4_t vqdmulhq_laneq_s32 (int32x4_t a, int32x4_t v, const int lane);
```

#### vqrdmulhq

* 运算： `ret[i] = sat((2 * a[i] * b[i] + (1<<(L-1))) >> L)`

```c
int16x8_t vqrdmulhq_s16 (int16x8_t a, int16x8_t b);
int32x4_t vqrdmulhq_s32 (int32x4_t a, int32x4_t b);
```

#### vqrdmulhq_n

* 运算： `ret[i] = sat((2 * a[i] * b + (1<<(L-1))) >> L)`

```
int16x8_t vqrdmulhq_n_s16 (int16x8_t a, int16_t b);
int32x4_t vqrdmulhq_n_s32 (int32x4_t a, int32_t b);
```

#### vqrdmulhq_lane

* 运算： `ret[i] = sat((2 * a[i] * v[lane] + (1<<(L-1))) >> L)`

```c
int16x8_t vqrdmulhq_lane_s16 (int16x8_t a, int16x4_t v, const int lane);
int32x4_t vqrdmulhq_lane_s32 (int32x4_t a, int32x2_t v, const int lane);
```

```c
int16x8_t vqrdmulhq_laneq_s16 (int16x8_t a, int16x8_t v, const int lane);
int32x4_t vqrdmulhq_laneq_s32 (int32x4_t a, int32x4_t v, const int lane);
```

#### vmulxq

```c
float16x8_t vmulxq_f16 (float16x8_t a, float16x8_t b);
float32x4_t vmulxq_f32 (float32x4_t a, float32x4_t b);
float64x2_t vmulxq_f64 (float64x2_t a, float64x2_t b);
```

#### vmulxq_n

```c
float16x8_t vmulxq_n_f16 (float16x8_t a, float16_t b);
```

#### vmulxq_lane

```c
float16x8_t vmulxq_lane_f16 (float16x8_t a, float16x4_t v, const int lane);
float32x4_t vmulxq_lane_f32 (float32x4_t a, float32x2_t v, const int lane);
float64x2_t vmulxq_lane_f64 (float64x2_t a, float64x1_t v, const int lane);
```

```c
float16x8_t vmulxq_laneq_f16 (float16x8_t a, float16x8_t v, const int lane);
float32x4_t vmulxq_laneq_f32 (float32x4_t a, float32x4_t v, const int lane);
float64x2_t vmulxq_laneq_f64 (float64x2_t a, float64x2_t v, const int lane);
```

### 长指令乘法

#### vmull

* 运算： `ret[i] = a[i] * b[i]`

```c
int16x8_t vmull_s8 (int8x8_t a, int8x8_t b);
int32x4_t vmull_s16 (int16x4_t a, int16x4_t b);
int64x2_t vmull_s32 (int32x2_t a, int32x2_t b);
```

```c
uint16x8_t vmull_u8 (uint8x8_t a, uint8x8_t b);
uint32x4_t vmull_u16 (uint16x4_t a, uint16x4_t b);
uint64x2_t vmull_u32 (uint32x2_t a, uint32x2_t b);
```

```c
poly16x8_t vmull_p8 (poly8x8_t a, poly8x8_t b);
poly128_t vmull_p64 (poly64_t a, poly64_t b);
```

#### vmull_n

* 运算： `ret[i] = a[i] * b`

```c
int32x4_t vmull_n_s16 (int16x4_t a, int16_t b);
int64x2_t vmull_n_s32 (int32x2_t a, int32_t b);
```

```c
uint32x4_t vmull_n_u16 (uint16x4_t a, uint16_t b);
uint64x2_t vmull_n_u32 (uint32x2_t a, uint32_t b);
```

#### vmull_lane

* 运算： `ret[i] = a[i] * v[lane]`

```c
int32x4_t vmull_lane_s16 (int16x4_t a, int16x4_t v, const int lane);
int64x2_t vmull_lane_s32 (int32x2_t a, int32x2_t v, const int lane);
```

```c
uint32x4_t vmull_lane_u16 (uint16x4_t a, uint16x4_t v, const int lane);
uint64x2_t vmull_lane_u32 (uint32x2_t a, uint32x2_t v, const int lane);
```

```c
int32x4_t vmull_laneq_s16 (int16x4_t a, int16x8_t v, const int lane);
int64x2_t vmull_laneq_s32 (int32x2_t a, int32x4_t v, const int lane);
```

```c
uint32x4_t vmull_laneq_u16 (uint16x4_t a, uint16x8_t v, const int lane);
uint64x2_t vmull_laneq_u32 (uint32x2_t a, uint32x4_t v, const int lane);
```

#### vmull_high

* 运算： `ret[i] = a[N+i] * b[N+i]`

```c
int16x8_t vmull_high_s8 (int8x16_t a, int8x16_t b);
int32x4_t vmull_high_s16 (int16x8_t a, int16x8_t b);
int64x2_t vmull_high_s32 (int32x4_t a, int32x4_t b);
```

```c
uint16x8_t vmull_high_u8 (uint8x16_t a, uint8x16_t b);
uint32x4_t vmull_high_u16 (uint16x8_t a, uint16x8_t b);
uint64x2_t vmull_high_u32 (uint32x4_t a, uint32x4_t b);
```

```c
poly16x8_t vmull_high_p8 (poly8x16_t a, poly8x16_t b);
poly128_t vmull_high_p64 (poly64x2_t a, poly64x2_t b);
```

#### vmull_high_n

* 运算： `ret[i] = a[N+i] * b`

```c
int32x4_t vmull_high_n_s16 (int16x8_t a, int16_t b);
int64x2_t vmull_high_n_s32 (int32x4_t a, int32_t b);
```

```c
uint32x4_t vmull_high_n_u16 (uint16x8_t a, uint16_t b);
uint64x2_t vmull_high_n_u32 (uint32x4_t a, uint32_t b);
```

#### vmull_high_lane

* 运算： `ret[i] = a[N+i] * v[lane]`

```c
int32x4_t vmull_high_lane_s16 (int16x8_t a, int16x4_t v, const int lane);
int64x2_t vmull_high_lane_s32 (int32x4_t a, int32x2_t v, const int lane);
```

```c
uint32x4_t vmull_high_lane_u16 (uint16x8_t a, uint16x4_t v, const int lane);
uint64x2_t vmull_high_lane_u32 (uint32x4_t a, uint32x2_t v, const int lane);
```

```c
int32x4_t vmull_high_laneq_s16 (int16x8_t a, int16x8_t v, const int lane);
int64x2_t vmull_high_laneq_s32 (int32x4_t a, int32x4_t v, const int lane);
```

```c
uint32x4_t vmull_high_laneq_u16 (uint16x8_t a, uint16x8_t v, const int lane);
uint64x2_t vmull_high_laneq_u32 (uint32x4_t a, uint32x4_t v, const int lane);
```

#### vqdmull

* 运算： `ret[i] = sat(2 * a[i] * b[i])`

```c
int32x4_t vqdmull_s16 (int16x4_t a, int16x4_t b);
int64x2_t vqdmull_s32 (int32x2_t a, int32x2_t b);
```

#### vqdmull_n

* 运算： `ret[i] = sat(2 * a[i] * b)`

```c
int32x4_t vqdmull_n_s16 (int16x4_t a, int16_t b);
int64x2_t vqdmull_n_s32 (int32x2_t a, int32_t b);
```

#### vqdmull_lane

* 运算： `ret[i] = sat(2 * a[i] * v[lane])`

```c
int32x4_t vqdmull_lane_s16 (int16x4_t a, int16x4_t v, const int lane);
int64x2_t vqdmull_lane_s32 (int32x2_t a, int32x2_t v, const int lane);
```

```c
int32x4_t vqdmull_laneq_s16 (int16x4_t a, int16x8_t v, const int lane);
int64x2_t vqdmull_laneq_s32 (int32x2_t a, int32x4_t v, const int lane);
```

#### vqdmull_high

* 运算： `ret[i] = sat(2 * a[N+i] * b[N+i])`

```c
int32x4_t vqdmull_high_s16 (int16x8_t a, int16x8_t b);
int64x2_t vqdmull_high_s32 (int32x4_t a, int32x4_t b);
```

#### vqdmull_high_n

* 运算： `ret[i] = sat(2 * a[N+i] * b)`

```c
int32x4_t vqdmull_high_n_s16 (int16x8_t a, int16_t b);
int64x2_t vqdmull_high_n_s32 (int32x4_t a, int32_t b);
```

#### vqdmull_high_lane

* 运算： `ret[i] = sat(2 * a[N+i] * v[lane])`

```c
int32x4_t vqdmull_high_lane_s16 (int16x8_t a, int16x4_t v, const int lane);
int64x2_t vqdmull_high_lane_s32 (int32x4_t a, int32x2_t v, const int lane);
```

```c
int32x4_t vqdmull_high_laneq_s16 (int16x8_t a, int16x8_t v, const int lane);
int64x2_t vqdmull_high_laneq_s32 (int32x4_t a, int32x4_t v, const int lane);
```

### 单指令乘法

#### vmul?_lane

* 运算： `ret = a * v[lane]`

```c
float16_t vmulh_lane_f16 (float16_t a, float16x4_t v, const int lane);
float32_t vmuls_lane_f32 (float32_t a, float32x2_t v, const int lane);
float64_t vmuld_lane_f64 (float64_t a, float64x1_t v, const int lane);
```

```c
float16_t vmulh_laneq_f16 (float16_t a, float16x8_t v, const int lane);
float32_t vmuls_laneq_f32 (float32_t a, float32x4_t v, const int lane);
float64_t vmuld_laneq_f64 (float64_t a, float64x2_t v, const int lane);
```

#### vqdmull?

* 运算： `ret = sat(2 * a * b)`

```c
int32_t vqdmullh_s16 (int16_t a, int16_t b);
int64_t vqdmulls_s32 (int32_t a, int32_t b);
```

#### vqdmull?_lane

* 运算： `ret = sat(2 * a * v[lane])`

```c
int32_t vqdmullh_lane_s16 (int16_t a, int16x4_t v, const int lane);
int64_t vqdmulls_lane_s32 (int32_t a, int32x2_t v, const int lane);
```

```c
int32_t vqdmullh_laneq_s16 (int16_t a, int16x8_t v, const int lane);
int64_t vqdmulls_laneq_s32 (int32_t a, int32x4_t v, const int lane);
```

#### vqdmulh?

* 运算： `ret = sat((2 * a * b) >> L)`

```c
int16_t vqdmulhh_s16 (int16_t a, int16_t b);
int32_t vqdmulhs_s32 (int32_t a, int32_t b);
```

#### vqdmulh?_lane

* 运算： `ret = sat((2 * a * v[lane]) >> L)`

```c
int16_t vqdmulhh_lane_s16 (int16_t a, int16x4_t v, const int lane);
int32_t vqdmulhs_lane_s32 (int32_t a, int32x2_t v, const int lane);
```

```
int16_t vqdmulhh_laneq_s16 (int16_t a, int16x8_t v, const int lane);
int32_t vqdmulhs_laneq_s32 (int32_t a, int32x4_t v, const int lane);
```

#### vqrdmulh?

* 运算： `ret = sat((2 * a * b + (1<<(L-1))) >> L)`

```c
int16_t vqrdmulhh_s16 (int16_t a, int16_t b);
int32_t vqrdmulhs_s32 (int32_t a, int32_t b);
```

#### vqrdmulh?_lane

* 运算： `ret = sat((2 * a * v[lane] + (1<<(L-1))) >> L)`

```c
int16_t vqrdmulhh_lane_s16 (int16_t a, int16x4_t v, const int lane);
int32_t vqrdmulhs_lane_s32 (int32_t a, int32x2_t v, const int lane);
```

```c
int16_t vqrdmulhh_laneq_s16 (int16_t a, int16x8_t v, const int lane);
int32_t vqrdmulhs_laneq_s32 (int32_t a, int32x4_t v, const int lane);
```

#### vmulx?

```c
float16_t vmulxh_f16 (float16_t a, float16_t b);
float32_t vmulxs_f32 (float32_t a, float32_t b);
float64_t vmulxd_f64 (float64_t a, float64_t b);
```

#### vmulx?_lane

```c
float16_t vmulxh_lane_f16 (float16_t a, float16x4_t v, const int lane);
float32_t vmulxs_lane_f32 (float32_t a, float32x2_t v, const int lane);
float64_t vmulxd_lane_f64 (float64_t a, float64x1_t v, const int lane);
```

```c
float16_t vmulxh_laneq_f16 (float16_t a, float16x8_t v, const int lane);
float32_t vmulxs_laneq_f32 (float32_t a, float32x4_t v, const int lane);
float64_t vmulxd_laneq_f64 (float64_t a, float64x2_t v, const int lane);
```

## div除法指令

### 短指令除法

#### vdiv

* 运算： `ret[i] = a[i] / b[i]`

```c
float16x4_t vdiv_f16 (float16x4_t a, float16x4_t b);
float32x2_t vdiv_f32 (float32x2_t a, float32x2_t b);
float64x1_t vdiv_f64 (float64x1_t a, float64x1_t b);
```

### 全指令除法

#### vdivq

* 运算： `ret[i] = a[i] / b[i]`

```
float16x8_t vdivq_f16 (float16x8_t a, float16x8_t b); // _mm_div_ph | _mm256_div_ph | _mm512_div_ph
float32x4_t vdivq_f32 (float32x4_t a, float32x4_t b); // _mm_div_ps | _mm256_div_ps | _mm512_div_ps
float64x2_t vdivq_f64 (float64x2_t a, float64x2_t b); // _mm_div_pd | _mm256_div_pd | _mm512_div_pd
```

## neg符号取反指令

### 短指令符号取反

#### vneg

* 运算： `ret[i] = -a[i]`

```c
int8x8_t vneg_s8 (int8x8_t a);
int16x4_t vneg_s16 (int16x4_t a);
int32x2_t vneg_s32 (int32x2_t a);
int64x1_t vneg_s64 (int64x1_t a);
```

```c
float16x4_t vneg_f16 (float16x4_t a);
float32x2_t vneg_f32 (float32x2_t a);
float64x1_t vneg_f64 (float64x1_t a);
```

#### vqneg

* 运算： `ret[i] = sat(-a[i])`

```c
int8x8_t vqneg_s8 (int8x8_t a);
int16x4_t vqneg_s16 (int16x4_t a);
int32x2_t vqneg_s32 (int32x2_t a);
int64x1_t vqneg_s64 (int64x1_t a);
```

### 全指令符号取反

#### vnegq

* 运算： `ret[i] = -a[i]`

```c
int8x16_t vnegq_s8 (int8x16_t a);
int16x8_t vnegq_s16 (int16x8_t a);
int32x4_t vnegq_s32 (int32x4_t a);
int64x2_t vnegq_s64 (int64x2_t a);
```

```c
float16x8_t vnegq_f16 (float16x8_t a);
float32x4_t vnegq_f32 (float32x4_t a);
float64x2_t vnegq_f64 (float64x2_t a);
```

#### vqnegq

* 运算： `ret[i] = sat(-a[i])`

```c
int8x16_t vqnegq_s8 (int8x16_t a);
int16x8_t vqnegq_s16 (int16x8_t a);
int32x4_t vqnegq_s32 (int32x4_t a);
int64x2_t vqnegq_s64 (int64x2_t a);
```

### 单指令符号取反

#### vneg?

* 运算： `ret = -a`

```c
int64_t vnegd_s64 (int64_t a);
```

#### vqneg?

* 运算： `ret = sat(-a)`

```c
int8_t vqnegb_s8 (int8_t a);
int16_t vqnegh_s16 (int16_t a);
int32_t vqnegs_s32 (int32_t a);
int64_t vqnegd_s64 (int64_t a);
```

## abs绝对值指令

### 短指令绝对值

#### vabs

* 运算： `ret[i] = abs(a[i])`

```c
int8x8_t vabs_s8 (int8x8_t a);
int16x4_t vabs_s16 (int16x4_t a);
int32x2_t vabs_s32 (int32x2_t a);
int64x1_t vabs_s64 (int64x1_t a);
```

```c
float16x4_t vabs_f16 (float16x4_t a);
float32x2_t vabs_f32 (float32x2_t a);
float64x1_t vabs_f64 (float64x1_t a);
```

#### vqabs

* 运算： `ret[i] = sat(abs(a[i]))`

```c
int8x8_t vqabs_s8 (int8x8_t a);    // _mm_abs_pi8
int16x4_t vqabs_s16 (int16x4_t a); // _mm_abs_pi16
int32x2_t vqabs_s32 (int32x2_t a); // _mm_abs_pi32
int64x1_t vqabs_s64 (int64x1_t a);
```

### 全指令绝对值

#### vabsq

* 运算： `ret[i] = abs(a[i])`
    * mmintrin函数 `_mm_abs_epi64` 操作为AVX指令

```c
int8x16_t vabsq_s8 (int8x16_t a);  // _mm_abs_epi8  | _mm256_abs_epi8  | _mm512_abs_epi8
int16x8_t vabsq_s16 (int16x8_t a); // _mm_abs_epi16 | _mm256_abs_epi16 | _mm512_abs_epi16
int32x4_t vabsq_s32 (int32x4_t a); // _mm_abs_epi32 | _mm256_abs_epi32 | _mm512_abs_epi32
int64x2_t vabsq_s64 (int64x2_t a); // _mm_abs_epi64 | _mm256_abs_epi64 | _mm512_abs_epi64
```

```c
float16x8_t vabsq_f16 (float16x8_t a); // _mm_abs_ph | _mm256_abs_ph | _mm512_abs_ph
float32x4_t vabsq_f32 (float32x4_t a); // ?          | ?             | _mm512_abs_ps
float64x2_t vabsq_f64 (float64x2_t a); // ?          | ?             | _mm512_abs_pd
```

#### vqabsq

* 运算： `ret[i] = sat(abs(a[i]))`

```c
int8x16_t vqabsq_s8 (int8x16_t a);
int16x8_t vqabsq_s16 (int16x8_t a);
int32x4_t vqabsq_s32 (int32x4_t a);
int64x2_t vqabsq_s64 (int64x2_t a);
```

### 单指令绝对值

#### vabs?

* 运算： `ret = abs(a)`

```c
int64_t vabsd_s64 (int64_t a);
```

#### vqabs?

* 运算： `ret = sat(abs(a))`

```c
int8_t vqabsb_s8 (int8_t a);
int16_t vqabsh_s16 (int16_t a);
int32_t vqabss_s32 (int32_t a);
int64_t vqabsd_s64 (int64_t a);
```

## abd差绝对值

### 短指令差绝对值

#### vabd

* 运算： `ret[i] = abs(a[i] - b[i])`

```c
int8x8_t vabd_s8 (int8x8_t a, int8x8_t b);
int16x4_t vabd_s16 (int16x4_t a, int16x4_t b);
int32x2_t vabd_s32 (int32x2_t a, int32x2_t b);
```

```c
uint8x8_t vabd_u8 (uint8x8_t a, uint8x8_t b);
uint16x4_t vabd_u16 (uint16x4_t a, uint16x4_t b);
uint32x2_t vabd_u32 (uint32x2_t a, uint32x2_t b);
```

```c
float16x4_t vabd_f16 (float16x4_t a, float16x4_t b);
float32x2_t vabd_f32 (float32x2_t a, float32x2_t b);
float64x1_t vabd_f64 (float64x1_t a, float64x1_t b);
```

### 全指令差绝对值

#### vabdq

* 运算： `ret[i] = abs(a[i] - b[i])`

```c
int8x16_t vabdq_s8 (int8x16_t a, int8x16_t b);
int16x8_t vabdq_s16 (int16x8_t a, int16x8_t b);
int32x4_t vabdq_s32 (int32x4_t a, int32x4_t b);
```

```c
uint8x16_t vabdq_u8 (uint8x16_t a, uint8x16_t b);
uint16x8_t vabdq_u16 (uint16x8_t a, uint16x8_t b);
uint32x4_t vabdq_u32 (uint32x4_t a, uint32x4_t b);
```

```c
float16x8_t vabdq_f16 (float16x8_t a, float16x8_t b);
float32x4_t vabdq_f32 (float32x4_t a, float32x4_t b);
float64x2_t vabdq_f64 (float64x2_t a, float64x2_t b);
```

### 长指令差绝对值

#### vabdl

* 运算： `ret[i] = abs(a[i] - b[i])`

```c
int16x8_t vabdl_s8 (int8x8_t a, int8x8_t b);
int32x4_t vabdl_s16 (int16x4_t a, int16x4_t b);
int64x2_t vabdl_s32 (int32x2_t a, int32x2_t b);
```

```c
uint16x8_t vabdl_u8 (uint8x8_t a, uint8x8_t b);
uint32x4_t vabdl_u16 (uint16x4_t a, uint16x4_t b);
uint64x2_t vabdl_u32 (uint32x2_t a, uint32x2_t b);
```

#### vabdl_high

* 运算： `ret[i] = abs(a[N+i] - b[N+i])`

```c
int16x8_t vabdl_high_s8 (int8x16_t a, int8x16_t b);
int32x4_t vabdl_high_s16 (int16x8_t a, int16x8_t b);
int64x2_t vabdl_high_s32 (int32x4_t a, int32x4_t b);
```

```c
uint16x8_t vabdl_high_u8 (uint8x16_t a, uint8x16_t b);
uint32x4_t vabdl_high_u16 (uint16x8_t a, uint16x8_t b);
uint64x2_t vabdl_high_u32 (uint32x4_t a, uint32x4_t b);
```

### 单指令差绝对值

#### vabd?

* 运算： `ret = abs(a - b)`

```c
float32_t vabds_f32 (float32_t a, float32_t b);
float64_t vabdd_f64 (float64_t a, float64_t b);
```

## aba加差绝对值

### 短指令加差绝对值

#### vaba

* 运算： `ret[i] = r[i] + abs(a[i] - b[i])`

```c
int8x8_t vaba_s8 (int8x8_t r, int8x8_t a, int8x8_t b);
int16x4_t vaba_s16 (int16x4_t r, int16x4_t a, int16x4_t b);
int32x2_t vaba_s32 (int32x2_t r, int32x2_t a, int32x2_t b);
```

```c
uint8x8_t vaba_u8 (uint8x8_t r, uint8x8_t a, uint8x8_t b);
uint16x4_t vaba_u16 (uint16x4_t r, uint16x4_t a, uint16x4_t b);
uint32x2_t vaba_u32 (uint32x2_t r, uint32x2_t a, uint32x2_t b);
```

### 全指令加差绝对值

#### vabaq

* 运算： `ret[i] = r[i] + abs(a[i] - b[i])`

```c
int8x16_t vabaq_s8 (int8x16_t r, int8x16_t a, int8x16_t b);
int16x8_t vabaq_s16 (int16x8_t r, int16x8_t a, int16x8_t b);
int32x4_t vabaq_s32 (int32x4_t r, int32x4_t a, int32x4_t b);
```

```c
uint8x16_t vabaq_u8 (uint8x16_t r, uint8x16_t a, uint8x16_t b);
uint16x8_t vabaq_u16 (uint16x8_t r, uint16x8_t a, uint16x8_t b);
uint32x4_t vabaq_u32 (uint32x4_t r, uint32x4_t a, uint32x4_t b);
```

### 长指令加差绝对值

#### vabal

* 运算： `ret[i] = r[i] + abs(a[i] - b[i])`

```c
int16x8_t vabal_s8 (int16x8_t r, int8x8_t a, int8x8_t b);
int32x4_t vabal_s16 (int32x4_t r, int16x4_t a, int16x4_t b);
int64x2_t vabal_s32 (int64x2_t r, int32x2_t a, int32x2_t b);
```

```c
uint16x8_t vabal_u8 (uint16x8_t r, uint8x8_t a, uint8x8_t b);
uint32x4_t vabal_u16 (uint32x4_t r, uint16x4_t a, uint16x4_t b);
uint64x2_t vabal_u32 (uint64x2_t r, uint32x2_t a, uint32x2_t b);
```

#### vabal_high

* 运算： `ret[i] = r[i] + abs(a[N+i] - b[N+i])`

```c
int16x8_t vabal_high_s8 (int16x8_t r, int8x16_t a, int8x16_t b);
int32x4_t vabal_high_s16 (int32x4_t r, int16x8_t a, int16x8_t b);
int64x2_t vabal_high_s32 (int64x2_t r, int32x4_t a, int32x4_t b);
```

```c
uint16x8_t vabal_high_u8 (uint16x8_t r, uint8x16_t a, uint8x16_t b);
uint32x4_t vabal_high_u16 (uint32x4_t r, uint16x8_t a, uint16x8_t b);
uint64x2_t vabal_high_u32 (uint64x2_t r, uint32x4_t a, uint32x4_t b);
```

## mla加乘指令

### 短指令加乘

#### vmla

* 运算： `ret[i] = r[i] + a[i] * b[i]`

```c
int8x8_t vmla_s8 (int8x8_t r, int8x8_t a, int8x8_t b);
int16x4_t vmla_s16 (int16x4_t r, int16x4_t a, int16x4_t b);
int32x2_t vmla_s32 (int32x2_t r, int32x2_t a, int32x2_t b);
```

```c
uint8x8_t vmla_u8 (uint8x8_t r, uint8x8_t a, uint8x8_t b);
uint16x4_t vmla_u16 (uint16x4_t r, uint16x4_t a, uint16x4_t b);
uint32x2_t vmla_u32 (uint32x2_t r, uint32x2_t a, uint32x2_t b);
```

```c
float32x2_t vmla_f32 (float32x2_t r, float32x2_t a, float32x2_t b);
float64x1_t vmla_f64 (float64x1_t r, float64x1_t a, float64x1_t b);
```

#### vmla_n

* 运算： `ret[i] = r[i] + a[i] * b`

```c
int16x4_t vmla_n_s16 (int16x4_t r, int16x4_t a, int16_t b);
int32x2_t vmla_n_s32 (int32x2_t r, int32x2_t a, int32_t b);
```

```c
uint16x4_t vmla_n_u16 (uint16x4_t r, uint16x4_t a, uint16_t b);
uint32x2_t vmla_n_u32 (uint32x2_t r, uint32x2_t a, uint32_t b);
```

```c
float32x2_t vmla_n_f32 (float32x2_t r, float32x2_t a, float32_t b);
```

#### vmla_lane

* 运算： `ret[i] = r[i] + a[i] * v[lane]`

```c
int16x4_t vmla_lane_s16 (int16x4_t r, int16x4_t a, int16x4_t v, const int lane);
int32x2_t vmla_lane_s32 (int32x2_t r, int32x2_t a, int32x2_t v, const int lane);
```

```c
uint16x4_t vmla_lane_u16 (uint16x4_t r, uint16x4_t a, uint16x4_t v, const int lane);
uint32x2_t vmla_lane_u32 (uint32x2_t r, uint32x2_t a, uint32x2_t v, const int lane);
```

```c
float32x2_t vmla_lane_f32 (float32x2_t r, float32x2_t a, float32x2_t v, const int lane);
```

```c
int16x4_t vmla_laneq_s16 (int16x4_t r, int16x4_t a, int16x8_t v, const int lane);
int32x2_t vmla_laneq_s32 (int32x2_t r, int32x2_t a, int32x4_t v, const int lane);
```

```c
uint16x4_t vmla_laneq_u16 (uint16x4_t r, uint16x4_t a, uint16x8_t v, const int lane);
uint32x2_t vmla_laneq_u32 (uint32x2_t r, uint32x2_t a, uint32x4_t v, const int lane);
```

```c
float32x2_t vmla_laneq_f32 (float32x2_t r, float32x2_t a, float32x4_t v, const int lane);
```

#### vqrdmlah

* 运算： `ret[i] = sat((r[i]<<L) + a[i] * b[i] + (1<<(L-1))) >> L)`

```c
int16x4_t vqrdmlah_s16 (int16x4_t r, int16x4_t a, int16x4_t b);
int32x2_t vqrdmlah_s32 (int32x2_t r, int32x2_t a, int32x2_t b);
```

#### vqrdmlah_lane

* 运算： `ret[i] = sat(((r[i]<<L) + a[i] * v[lane] + (1<<(L-1))) >> L)`

```c
int16x4_t vqrdmlah_lane_s16 (int16x4_t r, int16x4_t a, int16x4_t v, const int lane);
int32x2_t vqrdmlah_lane_s32 (int32x2_t r, int32x2_t a, int32x2_t v, const int lane);
```

```c
int16x4_t vqrdmlah_laneq_s16 (int16x4_t r, int16x4_t a, int16x8_t v, const int lane);
int32x2_t vqrdmlah_laneq_s32 (int32x2_t r, int32x2_t a, int32x4_t v, const int lane);
```

#### vcmla

```c
float16x4_t vcmla_f16 (float16x4_t r, float16x4_t a, float16x4_t b);
float32x2_t vcmla_f32 (float32x2_t r, float32x2_t a, float32x2_t b);
```

#### vcmla_lane

```c
float16x4_t vcmla_lane_f16 (float16x4_t r, float16x4_t a, float16x4_t v, const int lane);
float32x2_t vcmla_lane_f32 (float32x2_t r, float32x2_t a, float32x2_t v, const int lane);
```

```c
float16x4_t vcmla_laneq_f16 (float16x4_t r, float16x4_t a, float16x8_t v, const int lane);
float32x2_t vcmla_laneq_f32 (float32x2_t r, float32x2_t a, float32x4_t v, const int lane);
```

#### vcmla_rot

```c
float16x4_t vcmla_rot90_f16 (float16x4_t r, float16x4_t a, float16x4_t b);
float32x2_t vcmla_rot90_f32 (float32x2_t r, float32x2_t a, float32x2_t b);

float16x4_t vcmla_rot180_f16 (float16x4_t r, float16x4_t a, float16x4_t b);
float32x2_t vcmla_rot180_f32 (float32x2_t r, float32x2_t a, float32x2_t b);

float16x4_t vcmla_rot270_f16 (float16x4_t r, float16x4_t a, float16x4_t b);
float32x2_t vcmla_rot270_f32 (float32x2_t r, float32x2_t a, float32x2_t b);
```

#### vcmla_rot?_lane

```c
float16x4_t vcmla_rot90_lane_f16 (float16x4_t r, float16x4_t a, float16x4_t v, const int lane);
float32x2_t vcmla_rot90_lane_f32 (float32x2_t r, float32x2_t a, float32x2_t v, const int lane);

float16x4_t vcmla_rot180_lane_f16 (float16x4_t r, float16x4_t a, float16x4_t v, const int lane);
float32x2_t vcmla_rot180_lane_f32 (float32x2_t r, float32x2_t a, float32x2_t v, const int lane);

float16x4_t vcmla_rot270_lane_f16 (float16x4_t r, float16x4_t a, float16x4_t v, const int lane);
float32x2_t vcmla_rot270_lane_f32 (float32x2_t r, float32x2_t a, float32x2_t v, const int lane);
```

```c
float16x4_t vcmla_rot90_laneq_f16 (float16x4_t r, float16x4_t a, float16x8_t v, const int lane);
float32x2_t vcmla_rot90_laneq_f32 (float32x2_t r, float32x2_t a, float32x4_t v, const int lane);

float16x4_t vcmla_rot180_laneq_f16 (float16x4_t r, float16x4_t a, float16x8_t v, const int lane);
float32x2_t vcmla_rot180_laneq_f32 (float32x2_t r, float32x2_t a, float32x4_t v, const int lane);

float16x4_t vcmla_rot270_laneq_f16 (float16x4_t r, float16x4_t a, float16x8_t v, const int lane);
float32x2_t vcmla_rot270_laneq_f32 (float32x2_t r, float32x2_t a, float32x4_t v, const int lane);
```

#### vfmlal_low/hign

```c
float32x2_t vfmlal_low_f16 (float32x2_t r, float16x4_t a, float16x4_t b);
float32x2_t vfmlal_high_f16 (float32x2_t r, float16x4_t a, float16x4_t b);
```

#### vfmlal_lane?_low/hign

```c
float32x2_t vfmlal_lane_low_f16 (float32x2_t r, float16x4_t a, float16x4_t v, const int lane);
float32x2_t vfmlal_lane_high_f16 (float32x2_t r, float16x4_t a, float16x4_t v, const int lane);
```

```c
float32x2_t vfmlal_laneq_low_f16 (float32x2_t r, float16x4_t a, float16x8_t v, const int lane);
float32x2_t vfmlal_laneq_high_f16 (float32x2_t r, float16x4_t a, float16x8_t v, const int lane);
```

### 全指令加乘

#### vmlaq

* 运算： `ret[i] = r[i] + a[i] * b[i]`

```c
int8x16_t vmlaq_s8 (int8x16_t r, int8x16_t a, int8x16_t b);
int16x8_t vmlaq_s16 (int16x8_t r, int16x8_t a, int16x8_t b);
int32x4_t vmlaq_s32 (int32x4_t r, int32x4_t a, int32x4_t b);
```

```c
uint8x16_t vmlaq_u8 (uint8x16_t r, uint8x16_t a, uint8x16_t b);
uint16x8_t vmlaq_u16 (uint16x8_t r, uint16x8_t a, uint16x8_t b);
uint32x4_t vmlaq_u32 (uint32x4_t r, uint32x4_t a, uint32x4_t b);
```

```c
float32x4_t vmlaq_f32 (float32x4_t r, float32x4_t a, float32x4_t b);
float64x2_t vmlaq_f64 (float64x2_t r, float64x2_t a, float64x2_t b);
```

#### vmlaq_n

* 运算： `ret[i] = r[i] + a[i] * b`

```c
int16x8_t vmlaq_n_s16 (int16x8_t r, int16x8_t a, int16_t b);
int32x4_t vmlaq_n_s32 (int32x4_t r, int32x4_t a, int32_t b);
```

```c
uint16x8_t vmlaq_n_u16 (uint16x8_t r, uint16x8_t a, uint16_t b);
uint32x4_t vmlaq_n_u32 (uint32x4_t r, uint32x4_t a, uint32_t b);
```

```c
float32x4_t vmlaq_n_f32 (float32x4_t r, float32x4_t a, float32_t b);
```

#### vmlaq_lane

* 运算： `ret[i] = r[i] + a[i] * v[lane]`

```c
int16x8_t vmlaq_lane_s16 (int16x8_t r, int16x8_t a, int16x4_t v, const int lane);
int32x4_t vmlaq_lane_s32 (int32x4_t r, int32x4_t a, int32x2_t v, const int lane);
```

```c
uint16x8_t vmlaq_lane_u16 (uint16x8_t r, uint16x8_t a, uint16x4_t v, const int lane);
uint32x4_t vmlaq_lane_u32 (uint32x4_t r, uint32x4_t a, uint32x2_t v, const int lane);
```

```c
float32x4_t vmlaq_lane_f32 (float32x4_t r, float32x4_t a, float32x2_t v, const int lane);
```

```c
int16x8_t vmlaq_laneq_s16 (int16x8_t r, int16x8_t a, int16x8_t v, const int lane);
int32x4_t vmlaq_laneq_s32 (int32x4_t r, int32x4_t a, int32x4_t v, const int lane);
```

```c
uint16x8_t vmlaq_laneq_u16 (uint16x8_t r, uint16x8_t a, uint16x8_t v, const int lane);
uint32x4_t vmlaq_laneq_u32 (uint32x4_t r, uint32x4_t a, uint32x4_t v, const int lane);
```

```c
float32x4_t vmlaq_laneq_f32 (float32x4_t r, float32x4_t a, float32x4_t v, const int lane);
```

#### vqrdmlahq

* 运算： `ret[i] = sat(((r[i]<<L) + 2 * a[i] * b[i] + (1<<(L-1))) >> L)`

```c
int16x8_t vqrdmlahq_s16 (int16x8_t r, int16x8_t a, int16x8_t b);
int32x4_t vqrdmlahq_s32 (int32x4_t r, int32x4_t a, int32x4_t b);
```

#### vqrdmlahq_lane

* 运算： `ret[i] = sat(((r[i]<<L) + 2 * a[i] * v[lane] + (1<<(L-1))) >> L)`

```c
int16x8_t vqrdmlahq_lane_s16 (int16x8_t r, int16x8_t a, int16x4_t v, const int lane);
int32x4_t vqrdmlahq_lane_s32 (int32x4_t r, int32x4_t a, int32x2_t v, const int lane);
```

```c
int16x8_t vqrdmlahq_laneq_s16 (int16x8_t r, int16x8_t a, int16x8_t v, const int lane);
int32x4_t vqrdmlahq_laneq_s32 (int32x4_t r, int32x4_t a, int32x4_t v, const int lane);
```

#### vcmlaq

```c
float16x8_t vcmlaq_f16 (float16x8_t r, float16x8_t a, float16x8_t b);
float32x4_t vcmlaq_f32 (float32x4_t r, float32x4_t a, float32x4_t b);
float64x2_t vcmlaq_f64 (float64x2_t r, float64x2_t a, float64x2_t b);
```

#### vcmlaq_lane

```c
float16x8_t vcmlaq_lane_f16 (float16x8_t r, float16x8_t a, float16x4_t v, const int lane);
float32x4_t vcmlaq_lane_f32 (float32x4_t r, float32x4_t a, float32x2_t v, const int lane);
```

```c
float16x8_t vcmlaq_laneq_f16 (float16x8_t r, float16x8_t a, float16x8_t v, const int lane);
float32x4_t vcmlaq_laneq_f32 (float32x4_t r, float32x4_t a, float32x4_t v, const int lane);
```

#### vcmlaq_rot

```c
float16x8_t vcmlaq_rot90_f16 (float16x8_t r, float16x8_t a, float16x8_t b);
float32x4_t vcmlaq_rot90_f32 (float32x4_t r, float32x4_t a, float32x4_t b);
float64x2_t vcmlaq_rot90_f64 (float64x2_t r, float64x2_t a, float64x2_t b);

float16x8_t vcmlaq_rot180_f16 (float16x8_t r, float16x8_t a, float16x8_t b);
float32x4_t vcmlaq_rot180_f32 (float32x4_t r, float32x4_t a, float32x4_t b);
float64x2_t vcmlaq_rot180_f64 (float64x2_t r, float64x2_t a, float64x2_t b);

float16x8_t vcmlaq_rot270_f16 (float16x8_t r, float16x8_t a, float16x8_t b);
float32x4_t vcmlaq_rot270_f32 (float32x4_t r, float32x4_t a, float32x4_t b);
float64x2_t vcmlaq_rot270_f64 (float64x2_t r, float64x2_t a, float64x2_t b);
```

#### vcmlaq_rot?_lane

```c
float16x8_t vcmlaq_rot90_lane_f16 (float16x8_t r, float16x8_t a, float16x4_t v, const int lane);
float32x4_t vcmlaq_rot90_lane_f32 (float32x4_t r, float32x4_t a, float32x2_t v, const int lane);

float16x8_t vcmlaq_rot180_lane_f16 (float16x8_t r, float16x8_t a, float16x4_t v, const int lane);
float32x4_t vcmlaq_rot180_lane_f32 (float32x4_t r, float32x4_t a, float32x2_t v, const int lane);

float16x8_t vcmlaq_rot270_lane_f16 (float16x8_t r, float16x8_t a, float16x4_t v, const int lane);
float32x4_t vcmlaq_rot270_lane_f32 (float32x4_t r, float32x4_t a, float32x2_t v, const int lane);
```

```c
float16x8_t vcmlaq_rot90_laneq_f16 (float16x8_t r, float16x8_t a, float16x8_t v, const int lane);
float32x4_t vcmlaq_rot90_laneq_f32 (float32x4_t r, float32x4_t a, float32x4_t v, const int lane);

float16x8_t vcmlaq_rot180_laneq_f16 (float16x8_t r, float16x8_t a, float16x8_t v, const int lane);
float32x4_t vcmlaq_rot180_laneq_f32 (float32x4_t r, float32x4_t a, float32x4_t v, const int lane);

float16x8_t vcmlaq_rot270_laneq_f16 (float16x8_t r, float16x8_t a, float16x8_t v, const int lane);
float32x4_t vcmlaq_rot270_laneq_f32 (float32x4_t r, float32x4_t a, float32x4_t v, const int lane);
```

#### v?mmlaq

```c
int32x4_t vmmlaq_s32 (int32x4_t r, int8x16_t a, int8x16_t b);
uint32x4_t vmmlaq_u32 (uint32x4_t r, uint8x16_t a, uint8x16_t b);
int32x4_t vusmmlaq_s32 (int32x4_t r, uint8x16_t a, int8x16_t b);
```

### 长指令加乘

#### vmlal

* 运算： `ret[i] = r[i] + a[i] * b[i]`

```c
int16x8_t vmlal_s8 (int16x8_t r, int8x8_t a, int8x8_t b);
int32x4_t vmlal_s16 (int32x4_t r, int16x4_t a, int16x4_t b);
int64x2_t vmlal_s32 (int64x2_t r, int32x2_t a, int32x2_t b);
```

```c
uint16x8_t vmlal_u8 (uint16x8_t r, uint8x8_t a, uint8x8_t b);
uint32x4_t vmlal_u16 (uint32x4_t r, uint16x4_t a, uint16x4_t b);
uint64x2_t vmlal_u32 (uint64x2_t r, uint32x2_t a, uint32x2_t b);
```

#### vmlal_n

* 运算： `ret[i] = r[i] + a[i] * b`

```c
int32x4_t vmlal_n_s16 (int32x4_t r, int16x4_t a, int16_t b);
int64x2_t vmlal_n_s32 (int64x2_t r, int32x2_t a, int32_t b);
```

```c
uint32x4_t vmlal_n_u16 (uint32x4_t r, uint16x4_t a, uint16_t b);
uint64x2_t vmlal_n_u32 (uint64x2_t r, uint32x2_t a, uint32_t b);
```

#### vmlal_lane

* 运算： `ret[i] = r[i] + a[i] * v[lane]`

```c
int32x4_t vmlal_lane_s16 (int32x4_t r, int16x4_t a, int16x4_t v, const int lane);
int64x2_t vmlal_lane_s32 (int64x2_t r, int32x2_t a, int32x2_t v, const int lane);
```

```c
uint32x4_t vmlal_lane_u16 (uint32x4_t r, uint16x4_t a, uint16x4_t v, const int lane);
uint64x2_t vmlal_lane_u32 (uint64x2_t r, uint32x2_t a, uint32x2_t v, const int lane);
```

```c
int32x4_t vmlal_laneq_s16 (int32x4_t r, int16x4_t a, int16x8_t v, const int lane);
int64x2_t vmlal_laneq_s32 (int64x2_t r, int32x2_t a, int32x4_t v, const int lane);
```

```c
uint32x4_t vmlal_laneq_u16 (uint32x4_t r, uint16x4_t a, uint16x8_t v, const int lane);
uint64x2_t vmlal_laneq_u32 (uint64x2_t r, uint32x2_t a, uint32x4_t v, const int lane);
```

#### vmlal_high

* 运算： `ret[i] = r[i] + a[N+i] * b[N+i]`

```c
int16x8_t vmlal_high_s8 (int16x8_t r, int8x16_t a, int8x16_t b);
int32x4_t vmlal_high_s16 (int32x4_t r, int16x8_t a, int16x8_t b);
int64x2_t vmlal_high_s32 (int64x2_t r, int32x4_t a, int32x4_t b);
```

```c
uint16x8_t vmlal_high_u8 (uint16x8_t r, uint8x16_t a, uint8x16_t b);
uint32x4_t vmlal_high_u16 (uint32x4_t r, uint16x8_t a, uint16x8_t b);
uint64x2_t vmlal_high_u32 (uint64x2_t r, uint32x4_t a, uint32x4_t b);
```

#### vmlal_high_n

* 运算： `ret[i] = r[i] + a[N+i] * b`

```c
int32x4_t vmlal_high_n_s16 (int32x4_t r, int16x8_t a, int16_t b);
int64x2_t vmlal_high_n_s32 (int64x2_t r, int32x4_t a, int32_t b);
```

```c
uint32x4_t vmlal_high_n_u16 (uint32x4_t r, uint16x8_t a, uint16_t b);
uint64x2_t vmlal_high_n_u32 (uint64x2_t r, uint32x4_t a, uint32_t b);
```

#### vmlal_high_lane

* 运算： `ret[i] = r[i] + a[N+i] * v[lane]`

```c
int32x4_t vmlal_high_lane_s16(int32x4_t r, int16x8_t a, int16x4_t v, const int lane);
int64x2_t vmlal_high_lane_s32(int64x2_t r, int32x4_t a, int32x2_t v, const int lane);
```

```c
uint32x4_t vmlal_high_lane_u16(uint32x4_t r, uint16x8_t a, uint16x4_t v, const int lane);
uint64x2_t vmlal_high_lane_u32(uint64x2_t r, uint32x4_t a, uint32x2_t v, const int lane);
```

```c
int32x4_t vmlal_high_laneq_s16(int32x4_t r, int16x8_t a, int16x8_t v, const int lane);
int64x2_t vmlal_high_laneq_s32(int64x2_t r, int32x4_t a, int32x4_t v, const int lane);
```

```c
uint32x4_t vmlal_high_laneq_u16(uint32x4_t r, uint16x8_t a, uint16x8_t v, const int lane);
uint64x2_t vmlal_high_laneq_u32(uint64x2_t r, uint32x4_t a, uint32x4_t v, const int lane);
```

#### vqdmlal

* 运算： `ret[i] = sat(r[i] + 2 * a[i] * b[i])`

```c
int32x4_t vqdmlal_s16 (int32x4_t r, int16x4_t a, int16x4_t b);
int64x2_t vqdmlal_s32 (int64x2_t r, int32x2_t a, int32x2_t b);
```

#### vqdmlal_n

* 运算： `ret[i] = sat(r[i] + 2 * a[i] * b)`

```c
int32x4_t vqdmlal_n_s16 (int32x4_t r, int16x4_t a, int16_t b);
int64x2_t vqdmlal_n_s32 (int64x2_t r, int32x2_t a, int32_t b);
```

#### vqdmlal_lane

* 运算： `ret[i] = sat(r[i] + 2 * a[i] * v[lane])`

```c
int32x4_t vqdmlal_lane_s16 (int32x4_t r, int16x4_t a, int16x4_t v, const int lane);
int64x2_t vqdmlal_lane_s32 (int64x2_t r, int32x2_t a, int32x2_t v, const int lane);
```

```c
int32x4_t vqdmlal_laneq_s16 (int32x4_t r, int16x4_t a, int16x8_t v, const int lane);
int64x2_t vqdmlal_laneq_s32 (int64x2_t r, int32x2_t a, int32x4_t v, const int lane);
```

#### vqdmlal_high

* 运算： `ret[i] = sat(r[i] + 2 * a[N+i] * b[N+i])`

```c
int32x4_t vqdmlal_high_s16 (int32x4_t r, int16x8_t a, int16x8_t b);
int64x2_t vqdmlal_high_s32 (int64x2_t r, int32x4_t a, int32x4_t b);
```

#### vqdmlal_high_n

* 运算： `ret[i] = sat(r[i] + 2 * a[N+i] * b)`

```c
int32x4_t vqdmlal_high_n_s16 (int32x4_t r, int16x8_t a, int16_t b);
int64x2_t vqdmlal_high_n_s32 (int64x2_t r, int32x4_t a, int32_t b);
```

#### vqdmlal_high_lane

* 运算： `ret[i] = sat(r[i] + 2 * a[N+i] * v[lane])`

```c
int32x4_t vqdmlal_high_lane_s16 (int32x4_t r, int16x8_t a, int16x4_t v, const int lane);
int64x2_t vqdmlal_high_lane_s32 (int64x2_t r, int32x4_t a, int32x2_t v, const int lane);
```

```c
int32x4_t vqdmlal_high_laneq_s16 (int32x4_t r, int16x8_t a, int16x8_t v, const int lane);
int64x2_t vqdmlal_high_laneq_s32 (int64x2_t r, int32x4_t a, int32x4_t v, const int lane);
```

#### vfmlalq_low/hign

```c
float32x4_t vfmlalq_low_f16 (float32x4_t r, float16x8_t a, float16x8_t b);
float32x4_t vfmlalq_high_f16 (float32x4_t r, float16x8_t a, float16x8_t b);
```

#### vfmlalq_lane?_low/hign

```c
float32x4_t vfmlalq_lane_low_f16 (float32x4_t r, float16x8_t a, float16x4_t v, const int lane);
float32x4_t vfmlalq_lane_high_f16 (float32x4_t r, float16x8_t a, float16x4_t v, const int lane);
```

```c
float32x4_t vfmlalq_laneq_low_f16 (float32x4_t r, float16x8_t a, float16x8_t v, const int lane);
float32x4_t vfmlalq_laneq_high_f16 (float32x4_t r, float16x8_t a, float16x8_t v, const int lane);
```

#### vbfmlal_*_f32

```c
float32x4_t vbfmmlaq_f32 (float32x4_t r, bfloat16x8_t r, bfloat16x8_t b);
float32x4_t vbfmlalbq_f32 (float32x4_t r, bfloat16x8_t r, bfloat16x8_t b);
float32x4_t vbfmlaltq_f32 (float32x4_t r, bfloat16x8_t r, bfloat16x8_t b);
```

```c
float32x4_t vbfmlalbq_lane_f32 (float32x4_t r, bfloat16x8_t r, bfloat16x4_t a, const int lane);
float32x4_t vbfmlaltq_lane_f32 (float32x4_t r, bfloat16x8_t r, bfloat16x4_t a, const int lane);
float32x4_t vbfmlalbq_laneq_f32 (float32x4_t r, bfloat16x8_t r, bfloat16x8_t a, const int lane);
float32x4_t vbfmlaltq_laneq_f32 (float32x4_t r, bfloat16x8_t r, bfloat16x8_t a, const int lane);
```

### 单指令加乘

#### vqdmlal?

* 运算： `ret = sat(r + 2 * a * b)`

```c
int32_t vqdmlalh_s16 (int32_t r, int16_t a, int16_t b);
int64_t vqdmlals_s32 (int64_t r, int32_t a, int32_t b);
```

#### vqdmlal?_lane

* 运算： `ret = sat(r + 2 * a * v[lane])`

```c
int32_t vqdmlalh_lane_s16 (int32_t r, int16_t a, int16x4_t v, const int lane);
int64_t vqdmlals_lane_s32 (int64_t r, int32_t a, int32x2_t v, const int lane);
```

```c
int32_t vqdmlalh_laneq_s16 (int32_t r, int16_t a, int16x8_t v, const int lane);
int64_t vqdmlals_laneq_s32 (int64_t r, int32_t a, int32x4_t v, const int lane);
```

#### vqrdmlah?

* 运算： `ret = sat(((r<<L) + 2 * a * b + (1<<(L-1))) >> L)`

```c
int16_t vqrdmlahh_s16 (int16_t r, int16_t a, int16_t b);
int32_t vqrdmlahs_s32 (int32_t r, int32_t a, int32_t b);
```

#### vqrdmlah?_lane

* 运算： `ret = sat(((r<<L) + 2 * a * v[lane] + (1<<(L-1))) >> L)`

```c
int16_t vqrdmlahh_lane_s16 (int16_t r, int16_t a, int16x4_t v, const int lane);
int32_t vqrdmlahs_lane_s32 (int32_t r, int32_t a, int32x2_t v, const int lane);
```

```c
int16_t vqrdmlahh_laneq_s16 (int16_t r, int16_t a, int16x8_t v, const int lane);
int32_t vqrdmlahs_laneq_s32 (int32_t r, int32_t a, int32x4_t v, const int lane);
```

## mls减乘指令

### 短指令减乘

#### vmls

* 运算： `ret[i] = r[i] - a[i] * b[i]`

```c
int8x8_t vmls_s8 (int8x8_t r, int8x8_t a, int8x8_t b);
int16x4_t vmls_s16 (int16x4_t r, int16x4_t a, int16x4_t b);
int32x2_t vmls_s32 (int32x2_t r, int32x2_t a, int32x2_t b);
```

```c
uint8x8_t vmls_u8 (uint8x8_t r, uint8x8_t a, uint8x8_t b);
uint16x4_t vmls_u16 (uint16x4_t r, uint16x4_t a, uint16x4_t b);
uint32x2_t vmls_u32 (uint32x2_t r, uint32x2_t a, uint32x2_t b);
```

```c
float32x2_t vmls_f32 (float32x2_t r, float32x2_t a, float32x2_t b);
float64x1_t vmls_f64 (float64x1_t r, float64x1_t a, float64x1_t b);
```

#### vmls_n

* 运算： `ret[i] = r[i] - a[i] * b`

```c
int16x4_t vmls_n_s16 (int16x4_t r, int16x4_t a, int16_t b);
int32x2_t vmls_n_s32 (int32x2_t r, int32x2_t a, int32_t b);
```

```c
uint16x4_t vmls_n_u16 (uint16x4_t r, uint16x4_t a, uint16_t b);
uint32x2_t vmls_n_u32 (uint32x2_t r, uint32x2_t a, uint32_t b);
```

```c
float32x2_t vmls_n_f32 (float32x2_t r, float32x2_t a, float32_t b);
```

#### vmls_lane

* 运算： `ret[i] = r[i] - a[i] * v[lane]`

```c
int16x4_t vmls_lane_s16 (int16x4_t r, int16x4_t a, int16x4_t v, const int lane);
int32x2_t vmls_lane_s32 (int32x2_t r, int32x2_t a, int32x2_t v, const int lane);
```

```c
uint16x4_t vmls_lane_u16 (uint16x4_t r, uint16x4_t a, uint16x4_t v, const int lane);
uint32x2_t vmls_lane_u32 (uint32x2_t r, uint32x2_t a, uint32x2_t v, const int lane);
```

```c
float32x2_t vmls_lane_f32 (float32x2_t r, float32x2_t a, float32x2_t v, const int lane);
```

```c
int16x4_t vmls_laneq_s16 (int16x4_t r, int16x4_t a, int16x8_t v, const int lane);
int32x2_t vmls_laneq_s32 (int32x2_t r, int32x2_t a, int32x4_t v, const int lane);
```

```c
uint16x4_t vmls_laneq_u16 (uint16x4_t r, uint16x4_t a, uint16x8_t v, const int lane);
uint32x2_t vmls_laneq_u32 (uint32x2_t r, uint32x2_t a, uint32x4_t v, const int lane);
```

```c
float32x2_t vmls_laneq_f32 (float32x2_t r, float32x2_t a, float32x4_t v, const int lane);
```

#### vqrdmlsh

* 运算： `ret[i] = sat(((r[i]<<L) - 2 * a[i] * b[i] + (1<<(L-1))) >> L)`

```c
int16x4_t vqrdmlsh_s16 (int16x4_t r, int16x4_t a, int16x4_t b);
int32x2_t vqrdmlsh_s32 (int32x2_t r, int32x2_t a, int32x2_t b);
```

#### vqrdmlsh_lane

* 运算： `ret[i] = sat(((r[i]<<L) - 2 * a[i] * v[lane] + (1<<(L-1))) >> L)`

```c
int16x4_t vqrdmlsh_lane_s16 (int16x4_t r, int16x4_t a, int16x4_t v, const int lane);
int32x2_t vqrdmlsh_lane_s32 (int32x2_t r, int32x2_t a, int32x2_t v, const int lane);
```

```c
int16x4_t vqrdmlsh_laneq_s16 (int16x4_t r, int16x4_t a, int16x8_t v, const int lane);
int32x2_t vqrdmlsh_laneq_s32 (int32x2_t r, int32x2_t a, int32x4_t v, const int lane);
```

#### vfmlsl_low/hign

```c
float32x2_t vfmlsl_low_f16 (float32x2_t r, float16x4_t a, float16x4_t b);
float32x2_t vfmlsl_high_f16 (float32x2_t r, float16x4_t a, float16x4_t b);
```

#### vfmlsl_lane?_low/hign

```c
float32x2_t vfmlsl_lane_low_f16 (float32x2_t r, float16x4_t a, float16x4_t v, const int lane);
float32x2_t vfmlsl_lane_high_f16 (float32x2_t r, float16x4_t a, float16x4_t v, const int lane);
```

```c
float32x2_t vfmlsl_laneq_low_f16 (float32x2_t r, float16x4_t a, float16x8_t v, const int lane);
float32x2_t vfmlsl_laneq_high_f16 (float32x2_t r, float16x4_t a, float16x8_t v, const int lane);
```

### 全指令减乘

#### vmlsq

* 运算： `ret[i] = r[i] - a[i] * b[i]`

```c
int8x16_t vmlsq_s8 (int8x16_t r, int8x16_t a, int8x16_t b);
int16x8_t vmlsq_s16 (int16x8_t r, int16x8_t a, int16x8_t b);
int32x4_t vmlsq_s32 (int32x4_t r, int32x4_t a, int32x4_t b);
```

```c
uint8x16_t vmlsq_u8 (uint8x16_t r, uint8x16_t a, uint8x16_t b);
uint16x8_t vmlsq_u16 (uint16x8_t r, uint16x8_t a, uint16x8_t b);
uint32x4_t vmlsq_u32 (uint32x4_t r, uint32x4_t a, uint32x4_t b);
```

```c
float32x4_t vmlsq_f32 (float32x4_t r, float32x4_t a, float32x4_t b);
float64x2_t vmlsq_f64 (float64x2_t r, float64x2_t a, float64x2_t b);
```

#### vmlsq_n

* 运算： `ret[i] = r[i] - a[i] * b`

```c
int16x8_t vmlsq_n_s16 (int16x8_t r, int16x8_t a, int16_t b);
int32x4_t vmlsq_n_s32 (int32x4_t r, int32x4_t a, int32_t b);
```

```c
uint16x8_t vmlsq_n_u16 (uint16x8_t r, uint16x8_t a, uint16_t b);
uint32x4_t vmlsq_n_u32 (uint32x4_t r, uint32x4_t a, uint32_t b);
```

```c
float32x4_t vmlsq_n_f32 (float32x4_t r, float32x4_t a, float32_t b);
```

#### vmlsq_lane

* 运算： `ret[i] = r[i] - a[i] * v[lane]`

```c
int16x8_t vmlsq_lane_s16 (int16x8_t r, int16x8_t a, int16x4_t v, const int lane);
int32x4_t vmlsq_lane_s32 (int32x4_t r, int32x4_t a, int32x2_t v, const int lane);
```

```c
uint16x8_t vmlsq_lane_u16 (uint16x8_t r, uint16x8_t a, uint16x4_t v, const int lane);
uint32x4_t vmlsq_lane_u32 (uint32x4_t r, uint32x4_t a, uint32x2_t v, const int lane);
```

```c
float32x4_t vmlsq_lane_f32 (float32x4_t r, float32x4_t a, float32x2_t v, const int lane);
```

```c
int16x8_t vmlsq_laneq_s16 (int16x8_t r, int16x8_t a, int16x8_t v, const int lane);
int32x4_t vmlsq_laneq_s32 (int32x4_t r, int32x4_t a, int32x4_t v, const int lane);
```

```c
uint16x8_t vmlsq_laneq_u16 (uint16x8_t r, uint16x8_t a, uint16x8_t v, const int lane);
uint32x4_t vmlsq_laneq_u32 (uint32x4_t r, uint32x4_t a, uint32x4_t v, const int lane);
```

```c
float32x4_t vmlsq_laneq_f32 (float32x4_t r, float32x4_t a, float32x4_t v, const int lane);
```

#### vqrdmlshq

* 运算： `ret[i] = sat(((r[i]<<L) - 2 * a[i] * b[i] + (1<<(L-1))) >> L)`

```c
int16x8_t vqrdmlshq_s16 (int16x8_t r, int16x8_t a, int16x8_t b);
int32x4_t vqrdmlshq_s32 (int32x4_t r, int32x4_t a, int32x4_t b);
```

#### vqrdmlshq_lane

* 运算： `ret[i] = sat(((r[i]<<L) - 2 * a[i] * v[lane] + (1<<(L-1))) >> L)`

```c
int16x8_t vqrdmlshq_lane_s16 (int16x8_t r, int16x8_t a, int16x4_t v, const int lane);
int32x4_t vqrdmlshq_lane_s32 (int32x4_t r, int32x4_t a, int32x2_t v, const int lane);
```

```c
int16x8_t vqrdmlshq_laneq_s16 (int16x8_t r, int16x8_t a, int16x8_t v, const int lane);
int32x4_t vqrdmlshq_laneq_s32 (int32x4_t r, int32x4_t a, int32x4_t v, const int lane);
```

### 长指令减乘

#### vmlsl

* 运算： `ret[i] = r[i] - a[i] * b[i]`

```c
int16x8_t vmlsl_s8 (int16x8_t r, int8x8_t a, int8x8_t b);
int32x4_t vmlsl_s16 (int32x4_t r, int16x4_t a, int16x4_t b);
int64x2_t vmlsl_s32 (int64x2_t r, int32x2_t a, int32x2_t b);
```

```c
uint16x8_t vmlsl_u8 (uint16x8_t r, uint8x8_t a, uint8x8_t b);
uint32x4_t vmlsl_u16 (uint32x4_t r, uint16x4_t a, uint16x4_t b);
uint64x2_t vmlsl_u32 (uint64x2_t r, uint32x2_t a, uint32x2_t b);
```

#### vmlsl_n

* 运算： `ret[i] = r[i] - a[i] * b`

```c
int32x4_t vmlsl_n_s16 (int32x4_t r, int16x4_t a, int16_t b);
int64x2_t vmlsl_n_s32 (int64x2_t r, int32x2_t a, int32_t b);
```

```c
uint32x4_t vmlsl_n_u16 (uint32x4_t r, uint16x4_t a, uint16_t b);
uint64x2_t vmlsl_n_u32 (uint64x2_t r, uint32x2_t a, uint32_t b);
```

#### vmlsl_lane

* 运算： `ret[i] = r[i] - a[i] * v[lane]`

```c
int32x4_t vmlsl_lane_s16 (int32x4_t r, int16x4_t a, int16x4_t v, const int lane);
int64x2_t vmlsl_lane_s32 (int64x2_t r, int32x2_t a, int32x2_t v, const int lane);
```

```c
uint32x4_t vmlsl_lane_u16 (uint32x4_t r, uint16x4_t a, uint16x4_t v, const int lane);
uint64x2_t vmlsl_lane_u32 (uint64x2_t r, uint32x2_t a, uint32x2_t v, const int lane);
```

```c
int32x4_t vmlsl_laneq_s16 (int32x4_t r, int16x4_t a, int16x8_t v, const int lane);
int64x2_t vmlsl_laneq_s32 (int64x2_t r, int32x2_t a, int32x4_t v, const int lane);
```

```c
uint32x4_t vmlsl_laneq_u16 (uint32x4_t r, uint16x4_t a, uint16x8_t v, const int lane);
uint64x2_t vmlsl_laneq_u32 (uint64x2_t r, uint32x2_t a, uint32x4_t v, const int lane);
```

#### vmlsl_high

* 运算： `ret[i] = r[i] - a[N+i] * b[N+i]`

```c
int16x8_t vmlsl_high_s8 (int16x8_t r, int8x16_t a, int8x16_t b);
int32x4_t vmlsl_high_s16 (int32x4_t r, int16x8_t a, int16x8_t b);
int64x2_t vmlsl_high_s32 (int64x2_t r, int32x4_t a, int32x4_t b);
```

```c
uint16x8_t vmlsl_high_u8 (uint16x8_t r, uint8x16_t a, uint8x16_t b);
uint32x4_t vmlsl_high_u16 (uint32x4_t r, uint16x8_t a, uint16x8_t b);
uint64x2_t vmlsl_high_u32 (uint64x2_t r, uint32x4_t a, uint32x4_t b);
```

#### vmlsl_high_n

* 运算： `ret[i] = r[i] - a[N+i] * b`

```c
int32x4_t vmlsl_high_n_s16 (int32x4_t r, int16x8_t a, int16_t b);
int64x2_t vmlsl_high_n_s32 (int64x2_t r, int32x4_t a, int32_t b);
```

```c
uint32x4_t vmlsl_high_n_u16 (uint32x4_t r, uint16x8_t a, uint16_t b);
uint64x2_t vmlsl_high_n_u32 (uint64x2_t r, uint32x4_t a, uint32_t b);
```

#### vmlsl_high_lane

* 运算： `ret[i] = r[i] - a[N+i] * v[lane]`

```c
int32x4_t vmlsl_high_lane_s16(int32x4_t r, int16x8_t a, int16x4_t v, const int lane);
int64x2_t vmlsl_high_lane_s32(int64x2_t r, int32x4_t a, int32x2_t v, const int lane);
```

```c
uint32x4_t vmlsl_high_lane_u16(uint32x4_t r, uint16x8_t a, uint16x4_t v, const int lane);
uint64x2_t vmlsl_high_lane_u32(uint64x2_t r, uint32x4_t a, uint32x2_t v, const int lane);
```

```c
int32x4_t vmlsl_high_laneq_s16(int32x4_t r, int16x8_t a, int16x8_t v, const int lane);
int64x2_t vmlsl_high_laneq_s32(int64x2_t r, int32x4_t a, int32x4_t v, const int lane);
```

```c
uint32x4_t vmlsl_high_laneq_u16(uint32x4_t r, uint16x8_t a, uint16x8_t v, const int lane);
uint64x2_t vmlsl_high_laneq_u32(uint64x2_t r, uint32x4_t a, uint32x4_t v, const int lane);
```

#### vqdmlsl

* 运算： `ret[i] = sat(r[i] - 2 * a[i] * b[i])`

```c
int32x4_t vqdmlsl_s16 (int32x4_t r, int16x4_t a, int16x4_t b);
int64x2_t vqdmlsl_s32 (int64x2_t r, int32x2_t a, int32x2_t b);
```

#### vqdmlsl_n

* 运算： `ret[i] = sat(r[i] - 2 * a[i] * b)`

```c
int32x4_t vqdmlsl_n_s16 (int32x4_t r, int16x4_t a, int16_t b);
int64x2_t vqdmlsl_n_s32 (int64x2_t r, int32x2_t a, int32_t b);
```

#### vqdmlsl_lane

* 运算： `ret[i] = sat(r[i] - 2 * a[i] * v[lane])`

```c
int32x4_t vqdmlsl_lane_s16 (int32x4_t r, int16x4_t a, int16x4_t v, const int lane);
int64x2_t vqdmlsl_lane_s32 (int64x2_t r, int32x2_t a, int32x2_t v, const int lane);
```

```c
int32x4_t vqdmlsl_laneq_s16 (int32x4_t r, int16x4_t a, int16x8_t v, const int lane);
int64x2_t vqdmlsl_laneq_s32 (int64x2_t r, int32x2_t a, int32x4_t v, const int lane);
```

#### vqdmlsl_high

* 运算： `ret[i] = sat(r[i] - 2 * a[N+i] * b[N+i])`

```c
int32x4_t vqdmlsl_high_s16 (int32x4_t r, int16x8_t a, int16x8_t b);
int64x2_t vqdmlsl_high_s32 (int64x2_t r, int32x4_t a, int32x4_t b);
```

#### vqdmlsl_high_n

* 运算： `ret[i] = sat(r[i] - 2 * a[N+i] * b)`

```c
int32x4_t vqdmlsl_high_n_s16 (int32x4_t r, int16x8_t a, int16_t b);
int64x2_t vqdmlsl_high_n_s32 (int64x2_t r, int32x4_t a, int32_t b);
```

#### vqdmlsl_high_lane

* 运算： `ret[i] = sat(r[i] - 2 * a[N+i] * v[lane])`

```c
int32x4_t vqdmlsl_high_lane_s16 (int32x4_t r, int16x8_t a, int16x4_t v, const int lane);
int64x2_t vqdmlsl_high_lane_s32 (int64x2_t r, int32x4_t a, int32x2_t v, const int lane);
```

```c
int32x4_t vqdmlsl_high_laneq_s16 (int32x4_t r, int16x8_t a, int16x8_t v, const int lane);
int64x2_t vqdmlsl_high_laneq_s32 (int64x2_t r, int32x4_t a, int32x4_t v, const int lane);
```

#### vfmlslq_low/hign

```c
float32x4_t vfmlslq_low_f16 (float32x4_t r, float16x8_t a, float16x8_t b);
float32x4_t vfmlslq_high_f16 (float32x4_t r, float16x8_t a, float16x8_t b);
```

#### vfmlslq_lane?_low/hign

```c
float32x4_t vfmlslq_lane_low_f16 (float32x4_t r, float16x8_t a, float16x4_t v, const int lane);
float32x4_t vfmlslq_lane_high_f16 (float32x4_t r, float16x8_t a, float16x4_t v, const int lane);
```

```c
float32x4_t vfmlslq_laneq_low_f16 (float32x4_t r, float16x8_t a, float16x8_t v, const int lane);
float32x4_t vfmlslq_laneq_high_f16 (float32x4_t r, float16x8_t a, float16x8_t v, const int lane);
```

### 单指令减乘

#### vqdmlsh?

* 运算： `ret = sat(r - 2 * a * b)`

```c
int32_t vqdmlslh_s16 (int32_t r, int16_t a, int16_t b);
int64_t vqdmlsls_s32 (int64_t r, int32_t a, int32_t b);
```

#### vqdmlsh?_lane

* 运算： `ret = sat(r - 2 * a * v[lane])`

```c
int32_t vqdmlslh_lane_s16 (int32_t r, int16_t a, int16x4_t v, const int lane);
int64_t vqdmlsls_lane_s32 (int64_t r, int32_t a, int32x2_t v, const int lane);
```

```c
int64_t vqdmlsls_laneq_s32 (int64_t r, int32_t a, int32x4_t v, const int lane);
int32_t vqdmlslh_laneq_s16 (int32_t r, int16_t a, int16x8_t v, const int lane);
```

#### vqrdmlsh?

* 运算： `ret = sat(((r<<L) - 2 * a * b + (1<<(L-1))) >> L)`

```c
int16_t vqrdmlshh_s16 (int16_t r, int16_t a, int16_t b);
int32_t vqrdmlshs_s32 (int32_t r, int32_t a, int32_t b);
```

#### vqrdmlsh?_lane

* 运算： `ret = sat(((r<<L) - 2 * a * v[lane] + (1<<(L-1))) >> L)`

```c
int16_t vqrdmlshh_lane_s16 (int16_t r, int16_t a, int16x4_t v, const int lane);
int32_t vqrdmlshs_lane_s32 (int32_t r, int32_t a, int32x2_t v, const int lane);
```

```c
int16_t vqrdmlshh_laneq_s16 (int16_t r, int16_t a, int16x8_t v, const int lane);
int32_t vqrdmlshs_laneq_s32 (int32_t r, int32_t a, int32x4_t v, const int lane);
```

## fma加浮点乘指令

### 短指令加浮点乘

#### vfma

* 运算： `ret[i] = r[i] + a[i] * b[i]`

```c
float16x4_t vfma_f16 (float16x4_t r, float16x4_t a, float16x4_t b);
float32x2_t vfma_f32 (float32x2_t r, float32x2_t a, float32x2_t b);
float64x1_t vfma_f64 (float64x1_t r, float64x1_t a, float64x1_t b);
```

#### vfma_n

* 运算： `ret[i] = r[i] + a[i] * b`

```c
float16x4_t vfma_n_f16 (float16x4_t r, float16x4_t a, float16_t b);
float32x2_t vfma_n_f32 (float32x2_t r, float32x2_t a, float32_t b);
float64x1_t vfma_n_f64 (float64x1_t r, float64x1_t a, float64_t b);
```

#### vfma_lane

* 运算： `ret[i] = r[i] + a[i] * v[lane]`

```c
float16x4_t vfma_lane_f16 (float16x4_t r, float16x4_t a, float16x4_t v, const int lane);
float32x2_t vfma_lane_f32 (float32x2_t r, float32x2_t a, float32x2_t v, const int lane);
float64x1_t vfma_lane_f64 (float64x1_t r, float64x1_t a, float64x1_t v, const int lane);
```

```c
float16x4_t vfma_laneq_f16 (float16x4_t r, float16x4_t a, float16x8_t v, const int lane);
float32x2_t vfma_laneq_f32 (float32x2_t r, float32x2_t a, float32x4_t v, const int lane);
float64x1_t vfma_laneq_f64 (float64x1_t r, float64x1_t a, float64x2_t v, const int lane);
```

### 全指令加浮点乘

#### vfmaq

* 运算： `ret[i] = r[i] + a[i] * b[i]`
    * `_mm_fmadd_??` 为AVX256指令，mmintrin函数是  `r[i] + a[i] * b[i]`
    * `_mm_fnmsub_??` 为AVX256指令，mmintrin函数是 `-(r[i] + a[i] * b[i])`

```c
// _mm_fmadd_ph(a,b,r)   | _mm256_fmadd_ph   | _mm512_fmadd_ph
// -_mm_fnmsub_ph(a,b,r) | -_mm256_fnmsub_ph | -_mm512_fnmsub_ph
float16x8_t vfmaq_f16 (float16x8_t r, float16x8_t a, float16x8_t b);
// _mm_fmadd_ps(a,b,r)   | _mm256_fmadd_ps   | _mm512_fmadd_ps
// -_mm_fnmsub_ps(a,b,r) | -_mm256_fnmsub_ps | -_mm512_fnmsub_ps
float32x4_t vfmaq_f32 (float32x4_t r, float32x4_t a, float32x4_t b);
// _mm_fmadd_pd(a,b,r)   | _mm256_fmadd_pd   | _mm512_fmadd_pd
// -_mm_fnmsub_pd(a,b,r) | -_mm256_fnmsub_pd | -_mm512_fnmsub_pd
float64x2_t vfmaq_f64 (float64x2_t r, float64x2_t a, float64x2_t b);
```

#### vfmaq_n

* 运算： `ret[i] = r[i] + a[i] * b`

```c
float16x8_t vfmaq_n_f16 (float16x8_t r, float16x8_t a, float16_t b);
float32x4_t vfmaq_n_f32 (float32x4_t r, float32x4_t a, float32_t b);
float64x2_t vfmaq_n_f64 (float64x2_t r, float64x2_t a, float64_t b);
```

#### vfmaq_lane

* 运算： `ret[i] = r[i] + a[i] * v[lane]`

```c
float16x8_t vfmaq_lane_f16 (float16x8_t r, float16x8_t a, float16x4_t v, const int lane);
float32x4_t vfmaq_lane_f32 (float32x4_t r, float32x4_t a, float32x2_t v, const int lane);
float64x2_t vfmaq_lane_f64 (float64x2_t r, float64x2_t a, float64x1_t v, const int lane);
```

```c
float16x8_t vfmaq_laneq_f16 (float16x8_t r, float16x8_t a, float16x8_t v, const int lane);
float32x4_t vfmaq_laneq_f32 (float32x4_t r, float32x4_t a, float32x4_t v, const int lane);
float64x2_t vfmaq_laneq_f64 (float64x2_t r, float64x2_t a, float64x2_t v, const int lane);
```

### 单指令加浮点乘

#### vfma?_lane

* 运算： `ret = r + a * v[lane]`

```c
float16_t vfmah_lane_f16 (float16_t r, float16_t a, float16x4_t v, const int lane);
float32_t vfmas_lane_f32 (float32_t r, float32_t a, float32x2_t v, const int lane);
float64_t vfmad_lane_f64 (float64_t r, float64_t a, float64x1_t v, const int lane);
```

```c
float16_t vfmah_laneq_f16 (float16_t r, float16_t a, float16x8_t v, const int lane);
float32_t vfmas_laneq_f32 (float32_t r, float32_t a, float32x4_t v, const int lane);
float64_t vfmad_laneq_f64 (float64_t r, float64_t a, float64x2_t v, const int lane);
```

## fms减浮点乘指令

### 短指令减浮点乘

#### vfms

* 运算： `ret[i] = r[i] - a[i] * b[i]`

```c
float16x4_t vfms_f16 (float16x4_t r, float16x4_t a, float16x4_t b);
float32x2_t vfms_f32 (float32x2_t r, float32x2_t a, float32x2_t b);
float64x1_t vfms_f64 (float64x1_t r, float64x1_t a, float64x1_t b);
```

#### vfms_n

* 运算： `ret[i] = r[i] - a[i] * b`

```c
float16x4_t vfms_n_f16 (float16x4_t r, float16x4_t a, float16_t b);
float32x2_t vfms_n_f32 (float32x2_t r, float32x2_t a, float32_t b);
float64x1_t vfms_n_f64 (float64x1_t r, float64x1_t a, float64_t b);
```

#### vfms_lane

* 运算： `ret[i] = r[i] - a[i] * v[lane]`

```c
float16x4_t vfms_lane_f16 (float16x4_t r, float16x4_t a, float16x4_t v, const int lane);
float32x2_t vfms_lane_f32 (float32x2_t r, float32x2_t a, float32x2_t v, const int lane);
float64x1_t vfms_lane_f64 (float64x1_t r, float64x1_t a, float64x1_t v, const int lane);
```

```c
float16x4_t vfms_laneq_f16 (float16x4_t r, float16x4_t a, float16x8_t v, const int lane);
float32x2_t vfms_laneq_f32 (float32x2_t r, float32x2_t a, float32x4_t v, const int lane);
float64x1_t vfms_laneq_f64 (float64x1_t r, float64x1_t a, float64x2_t v, const int lane);
```

### 全指令减浮点乘

#### vfmsq

* 运算： `ret[i] = r[i] - a[i] * b[i]`
    * `_mm_fnmadd_??` 为AVX256指令，mmintrin函数是 `r[i] - a[i] * b[i]`
    * `_mm_fmsub_??` 为AVX256指令，mmintrin函数是  `a[i] * b[i] - r[i]`

```c
// _mm_fnmadd_ph(a,b,r) | _mm256_fnmadd_ph | _mm512_fnmadd_ph
// -_mm_fmsub_ph(a,b,r) | -_mm256_fmsub_ph | -_mm512_fmsub_ph
float16x8_t vfmsq_f16 (float16x8_t r, float16x8_t a, float16x8_t b);
// _mm_fnmadd_ps(a,b,r) | _mm256_fnmadd_ps | _mm512_fnmadd_ps
// -_mm_fmsub_ps(a,b,r) | -_mm256_fmsub_ps | -_mm512_fmsub_ps
float32x4_t vfmsq_f32 (float32x4_t r, float32x4_t a, float32x4_t b);
// _mm_fnmadd_pd(a,b,r) | _mm256_fnmadd_pd | _mm512_fnmadd_pd
// -_mm_fmsub_pd(a,b,r) | -_mm256_fmsub_pd | -_mm512_fmsub_pd
float64x2_t vfmsq_f64 (float64x2_t r, float64x2_t a, float64x2_t b);
```

#### vfmsq_n

* 运算： `ret[i] = r[i] - a[i] * b`

```c
float16x8_t vfmsq_n_f16 (float16x8_t r, float16x8_t a, float16_t b);
float32x4_t vfmsq_n_f32 (float32x4_t r, float32x4_t a, float32_t b);
float64x2_t vfmsq_n_f64 (float64x2_t r, float64x2_t a, float64_t b);
```

#### vfmsq_lane

* 运算： `ret[i] = r[i] - a[i] * v[lane]`

```c
float16x8_t vfmsq_lane_f16 (float16x8_t r, float16x8_t a, float16x4_t v, const int lane);
float32x4_t vfmsq_lane_f32 (float32x4_t r, float32x4_t a, float32x2_t v, const int lane);
float64x2_t vfmsq_lane_f64 (float64x2_t r, float64x2_t a, float64x1_t v, const int lane);
```

```c
float16x8_t vfmsq_laneq_f16 (float16x8_t r, float16x8_t a, float16x8_t v, const int lane);
float32x4_t vfmsq_laneq_f32 (float32x4_t r, float32x4_t a, float32x4_t v, const int lane);
float64x2_t vfmsq_laneq_f64 (float64x2_t r, float64x2_t a, float64x2_t v, const int lane);
```

### 单指令减浮点乘

#### vfms?_lane

* 运算： `ret = r - a * v[lane]`

```c
float16_t vfmsh_lane_f16 (float16_t r, float16_t a, float16x4_t v, const int lane);
float32_t vfmss_lane_f32 (float32_t r, float32_t a, float32x2_t v, const int lane);
float64_t vfmsd_lane_f64 (float64_t r, float64_t a, float64x1_t v, const int lane);
```

```c
float16_t vfmsh_laneq_f16 (float16_t r, float16_t a, float16x8_t v, const int lane);
float32_t vfmss_laneq_f32 (float32_t r, float32_t a, float32x4_t v, const int lane);
float64_t vfmsd_laneq_f64 (float64_t r, float64_t a, float64x2_t v, const int lane);
```

## dot点积累加指令

### 单指令点积累加

#### vdot

* 运算： `ret[i] = r[i] + (a[4i] * b[4i] + ... + a[4i+3] * b[4i+3]`

```c
int32x2_t vdot_s32 (int32x2_t r, int8x8_t a, int8x8_t b);
uint32x2_t vdot_u32 (uint32x2_t r, uint8x8_t a, uint8x8_t b);

int32x2_t vusdot_s32 (int32x2_t r, uint8x8_t a, int8x8_t b);

float32x2_t vbfdot_f32 (float32x2_t r, bfloat16x4_t a, bfloat16x4_t b);
```

#### vdot_lane

* 运算： `ret[i] = r[i] + (a[4i] * v[lane] + ... + a[4i+3] * v[lane]`

```c
int32x2_t vdot_lane_s32 (int32x2_t r, int8x8_t a, int8x8_t v, const int lane);
uint32x2_t vdot_lane_u32 (uint32x2_t r, uint8x8_t a, uint8x8_t v, const int lane);

int32x2_t vdot_laneq_s32 (int32x2_t r, int8x8_t a, int8x16_t v, const int lane);
uint32x2_t vdot_laneq_u32 (uint32x2_t r, uint8x8_t a, uint8x16_t v, const int lane);
```

```c
int32x2_t vusdot_lane_s32 (int32x2_t r, uint8x8_t a, int8x8_t v, const int lane);
int32x2_t vusdot_laneq_s32 (int32x2_t r, uint8x8_t a, int8x16_t v, const int lane);

int32x2_t vsudot_lane_s32 (int32x2_t r, int8x8_t a, uint8x8_t v, const int lane);
int32x2_t vsudot_laneq_s32 (int32x2_t r, int8x8_t a, uint8x16_t v, const int lane);
```

```c
float32x2_t vbfdot_lane_f32 (float32x2_t r, bfloat16x4_t a, bfloat16x4_t v, const int lane);
float32x2_t vbfdot_laneq_f32 (float32x2_t r, bfloat16x4_t a, bfloat16x8_t v, const int lane);
```

### 全指令点积累加

#### vdotq

* 运算： `ret[i] = r[i] + (a[4i] * b[4i] + ... + a[4i+3] * b[4i+3]`

```c
int32x4_t vdotq_s32 (int32x4_t r, int8x16_t a, int8x16_t b);
uint32x4_t vdotq_u32 (uint32x4_t r, uint8x16_t a, uint8x16_t b);

int32x4_t vusdotq_s32 (int32x4_t r, uint8x16_t a, int8x16_t b);

float32x4_t vbfdotq_f32 (float32x4_t r, bfloat16x8_t a, bfloat16x8_t b);
```

#### vdotq_lane

* 运算： `ret[i] = r[i] + (a[4i] * v[lane] + ... + a[4i+3] * v[lane]`

```c
int32x4_t vdotq_lane_s32 (int32x4_t r, int8x16_t a, int8x8_t v, const int lane);
uint32x4_t vdotq_lane_u32 (uint32x4_t r, uint8x16_t a, uint8x8_t v, const int lane);

int32x4_t vdotq_laneq_s32 (int32x4_t r, int8x16_t a, int8x16_t v, const int lane);
uint32x4_t vdotq_laneq_u32 (uint32x4_t r, uint8x16_t a, uint8x16_t v, const int lane);
```

```c
int32x4_t vusdotq_lane_s32 (int32x4_t r, uint8x16_t a, int8x8_t v, const int lane);
int32x4_t vusdotq_laneq_s32 (int32x4_t r, uint8x16_t a, int8x16_t v, const int lane);

int32x4_t vsudotq_lane_s32 (int32x4_t r, int8x16_t a, uint8x8_t v, const int lane);
int32x4_t vsudotq_laneq_s32 (int32x4_t r, int8x16_t a, uint8x16_t v, const int lane);
```

```c
float32x4_t vbfdotq_lane_f32 (float32x4_t r, bfloat16x8_t a, bfloat16x4_t v, const int lane);
float32x4_t vbfdotq_laneq_f32 (float32x4_t r, bfloat16x8_t a, bfloat16x8_t v, const int lane);
```

## pada一对二加法

### 短指令一对二加法

#### vpadal

* 运算： `ret[i] = a[i] + b[2i] + b[2i+1]`

```c
int16x4_t vpadal_s8 (int16x4_t a, int8x8_t b);
int32x2_t vpadal_s16 (int32x2_t a, int16x4_t b);
int64x1_t vpadal_s32 (int64x1_t a, int32x2_t b);
```

```c
uint16x4_t vpadal_u8 (uint16x4_t a, uint8x8_t b);
uint32x2_t vpadal_u16 (uint32x2_t a, uint16x4_t b);
uint64x1_t vpadal_u32 (uint64x1_t a, uint32x2_t b);
```

### 长指令一对二加法

#### vpadalq

* 运算： `ret[i] = a[i] + b[2i] + b[2i+1]`

```c
int16x8_t vpadalq_s8 (int16x8_t a, int8x16_t b);
int32x4_t vpadalq_s16 (int32x4_t a, int16x8_t b);
int64x2_t vpadalq_s32 (int64x2_t a, int32x4_t b);
```

```c
uint16x8_t vpadalq_u8 (uint16x8_t a, uint8x16_t b);
uint32x4_t vpadalq_u16 (uint32x4_t a, uint16x8_t b);
uint64x2_t vpadalq_u32 (uint64x2_t a, uint32x4_t b);
```

## sqrt平方根指令

* 前缀 `r` (reciprocal) 表示倒数
* 后缀 `e` (estimate) 表示估算值

### 短指令平方根

#### vsqrt

* 运算： `ret[i] = sqrt(a[i])`

```c
float16x4_t vsqrt_f16 (float16x4_t a);
float32x2_t vsqrt_f32 (float32x2_t a);
float64x1_t vsqrt_f64 (float64x1_t a);
```

#### vrsqrte

* 运算： `ret[i] = sqrt(1 / a[i])`

```c
float16x4_t vrsqrte_f16 (float16x4_t a);
float32x2_t vrsqrte_f32 (float32x2_t a); // _mm_rsqrt_ps | _mm256_rsqrt_ps
float64x1_t vrsqrte_f64 (float64x1_t a);
uint32x2_t vrsqrte_u32 (uint32x2_t a);
```

#### vrsqrts

* `ret[i] = sqrt(1 / ((3.0 - a[i] * b[i]) / 2.0))` (是否对)

```c
float16x4_t vrsqrts_f16 (float16x4_t a, float16x4_t b);
float32x2_t vrsqrts_f32 (float32x2_t a, float32x2_t b);
float64x1_t vrsqrts_f64 (float64x1_t a, float64x1_t b);
```

### 全指令平方根

#### vsqrtq

* 运算： `ret[i] = sqrt(a[i])`

```c
float16x8_t vsqrtq_f16 (float16x8_t a); // _mm_sqrt_ph | _mm256_sqrt_ph | _mm512_sqrt_ph
float32x4_t vsqrtq_f32 (float32x4_t a); // _mm_sqrt_ps | _mm256_sqrt_ps | _mm512_sqrt_ps
float64x2_t vsqrtq_f64 (float64x2_t a); // _mm_sqrt_pd | _mm256_sqrt_pd | _mm512_sqrt_pd
```

#### vrsqrteq

* 运算： `ret[i] = sqrt(1 / a[i])`

```c
float16x8_t vrsqrteq_f16 (float16x8_t a);
float32x4_t vrsqrteq_f32 (float32x4_t a);
float64x2_t vrsqrteq_f64 (float64x2_t a);
uint32x4_t vrsqrteq_u32 (uint32x4_t a);
```

#### vrsqrtsq

* `ret[i] = sqrt(1 / ((3.0 - a[i] * b[i]) / 2.0))` (是否对)

```c
float16x8_t vrsqrtsq_f16 (float16x8_t a, float16x8_t b);
float32x4_t vrsqrtsq_f32 (float32x4_t a, float32x4_t b);
float64x2_t vrsqrtsq_f64 (float64x2_t a, float64x2_t b);
```

### 单指令平方根

#### vrsqrte?

* 运算： `ret = sqrt(1 / a)`

```c
float32_t vrsqrtes_f32 (float32_t a);
float64_t vrsqrted_f64 (float64_t a);
```

#### vrsqrts?

* `ret = sqrt(1 / ((3.0 - a * b) / 2.0))` (是否对)

```c
float32_t vrsqrtss_f32 (float32_t a, float32_t b);
float64_t vrsqrtsd_f64 (float64_t a, float64_t b);
```

## recp倒数指令

### 单指令倒数

#### vrecpe

* 运算： `ret[i] = 1 / a[i]`

```c
uint32x2_t vrecpe_u32 (uint32x2_t a);
float16x4_t vrecpe_f16 (float16x4_t a);
float32x2_t vrecpe_f32 (float32x2_t a);
float64x1_t vrecpe_f64 (float64x1_t a);
```

#### vrecps

* 运算： `ret[i] = 1 / (2.0 - a[i] * b[i])` (是否对)

```c
float16x4_t vrecps_f16 (float16x4_t a, float16x4_t b);
float32x2_t vrecps_f32 (float32x2_t a, float32x2_t b);
float64x1_t vrecps_f64 (float64x1_t a, float64x1_t b);
```

### 全指令倒数

#### vrecpeq

* 运算： `ret[i] = 1 / a[i]`

```c
uint32x4_t vrecpeq_u32 (uint32x4_t a);

float16x8_t vrecpeq_f16 (float16x8_t a); // _mm_rcp_ph | _mm256_rcp_ph | _mm512_rcp_ph
float32x4_t vrecpeq_f32 (float32x4_t a); // _mm_rcp_ps | _mm256_rcp_ps
float64x2_t vrecpeq_f64 (float64x2_t a);
```

#### vrecpsq

* 运算： `ret[i] = 1 / (2.0 - a[i] * b[i])` (是否对)

```c
float16x8_t vrecpsq_f16 (float16x8_t a, float16x8_t b);
float32x4_t vrecpsq_f32 (float32x4_t a, float32x4_t b);
float64x2_t vrecpsq_f64 (float64x2_t a, float64x2_t b);
```

### 单指令倒数

#### vrecpe?

* 运算： `ret = 1 / a`

```c
float32_t vrecpes_f32 (float32_t a);
float64_t vrecped_f64 (float64_t a);
```

#### vrecps?

* 运算： `ret = 1 / (2.0 - a * b)` (是否对)

```c
float32_t vrecpss_f32 (float32_t a, float32_t b);
float64_t vrecpsd_f64 (float64_t a, float64_t b);
```

#### vrecpx?

```c
float32_t vrecpxs_f32 (float32_t a);
float64_t vrecpxd_f64 (float64_t a);
```

## min最小值指令

* 后缀 `nm` 不考虑浮点数的非规范化表示形式可能带来的精度差异

### 短指令最小值

#### vmin

* 运算： `ret[i] = a[i] < b[i] ? a[i] : b[i]`

```c
int8x8_t vmin_s8 (int8x8_t a, int8x8_t b);
int16x4_t vmin_s16 (int16x4_t a, int16x4_t b); // _mm_min_pi16 / _m_pminsw
int32x2_t vmin_s32 (int32x2_t a, int32x2_t b);
```

```c
uint8x8_t vmin_u8 (uint8x8_t a, uint8x8_t b); // _mm_min_pu8 / _m_pminub
uint16x4_t vmin_u16 (uint16x4_t a, uint16x4_t b);
uint32x2_t vmin_u32 (uint32x2_t a, uint32x2_t b);
```

```c
float16x4_t vmin_f16 (float16x4_t a, float16x4_t b);
float32x2_t vmin_f32 (float32x2_t a, float32x2_t b);
float64x1_t vmin_f64 (float64x1_t a, float64x1_t b);
```

#### vminnm

```c
float16x4_t vminnm_f16 (float16x4_t a, float16x4_t b);
float32x2_t vminnm_f32 (float32x2_t a, float32x2_t b);
float64x1_t vminnm_f64 (float64x1_t a, float64x1_t b);
```

#### vpmin

* 运算： 先连接a、b组成新向量 `ab = {a[0], a[1], ..., b[0], b[1], ...}` ; 再临近元素比较 `ret[i] = ab[2i] < ab[2i+1] ? ab[2i] : ab[2i+1]`

```c
int8x8_t vpmin_s8 (int8x8_t a, int8x8_t b);
int16x4_t vpmin_s16 (int16x4_t a, int16x4_t b);
int32x2_t vpmin_s32 (int32x2_t a, int32x2_t b);
```

```c
uint8x8_t vpmin_u8 (uint8x8_t a, uint8x8_t b);
uint16x4_t vpmin_u16 (uint16x4_t a, uint16x4_t b);
uint32x2_t vpmin_u32 (uint32x2_t a, uint32x2_t b);
```

```c
float16x4_t vpmin_f16 (float16x4_t a, float16x4_t b);
float32x2_t vpmin_f32 (float32x2_t a, float32x2_t b);
```

#### vpminnm

```c
float16x4_t vpminnm_f16 (float16x4_t a, float16x4_t b);
float32x2_t vpminnm_f32 (float32x2_t a, float32x2_t b);
```

#### vminv

* 运算： `ret[i] = min(a[0], a[1], a[2], ...)`

```c
int8_t vminv_s8 (int8x8_t a);
int16_t vminv_s16 (int16x4_t a);
int32_t vminv_s32 (int32x2_t a);
```

```c
uint8_t vminv_u8 (uint8x8_t a);
uint16_t vminv_u16 (uint16x4_t a);
uint32_t vminv_u32 (uint32x2_t a);
```

```c
float16_t vminv_f16 (float16x4_t a);
float32_t vminv_f32 (float32x2_t a);
```

#### vminnmv

```c
float16_t vminnmv_f16 (float16x4_t a);
float32_t vminnmv_f32 (float32x2_t a);
```

### 全指令最小值

#### vminq

* 运算： `ret[i] = a[i] < b[i] ? a[i] : b[i]`

```c
int8x16_t vminq_s8 (int8x16_t a, int8x16_t b);  // _mm_min_epi8  | _mm256_min_epi8  | _mm512_min_epi8
int16x8_t vminq_s16 (int16x8_t a, int16x8_t b); // _mm_min_epi16 | _mm256_min_epi16 | _mm512_min_epi16
int32x4_t vminq_s32 (int32x4_t a, int32x4_t b); // _mm_min_epi32 | _mm256_min_epi32 | _mm512_min_epi32
                                    // (AVX512) // _mm_min_epi64 | _mm256_min_epi64 | _mm512_min_epi64
```

```c
uint8x16_t vminq_u8 (uint8x16_t a, uint8x16_t b);  // _mm_min_epu8  | _mm256_min_epu8  | _mm512_min_epu8
uint16x8_t vminq_u16 (uint16x8_t a, uint16x8_t b); // _mm_min_epu16 | _mm256_min_epu16 | _mm512_min_epu16
uint32x4_t vminq_u32 (uint32x4_t a, uint32x4_t b); // _mm_min_epu32 | _mm256_min_epu32 | _mm512_min_epu32
                                       // (AVX512) // _mm_min_epu64 | _mm256_min_epu64 | _mm512_min_epu64
```

```c
float16x8_t vminq_f16 (float16x8_t a, float16x8_t b); // _mm_min_ph | _mm256_min_ph | _mm512_min_ph
float32x4_t vminq_f32 (float32x4_t a, float32x4_t b); // _mm_min_ps | _mm256_min_ps | _mm512_min_ps
float64x2_t vminq_f64 (float64x2_t a, float64x2_t b); // _mm_min_pd | _mm256_min_pd | _mm512_min_pd
```

#### vminnmq

* 不考虑浮点数的非规范化表示形式可能带来的精度差异

```c
float16x8_t vminnmq_f16 (float16x8_t a, float16x8_t b);
float32x4_t vminnmq_f32 (float32x4_t a, float32x4_t b);
float64x2_t vminnmq_f64 (float64x2_t a, float64x2_t b);
```

#### vpminq

* 运算： 先连接a、b组成新向量 `ab = {a[0], a[1], ..., b[0], b[1], ...}` ; 再临近元素比较 `ret[i] = ab[2i] < ab[2i+1] ? ab[2i] : ab[2i+1]`

```c
int8x16_t vpminq_s8 (int8x16_t a, int8x16_t b);
int16x8_t vpminq_s16 (int16x8_t a, int16x8_t b);
int32x4_t vpminq_s32 (int32x4_t a, int32x4_t b);
```

```c
uint8x16_t vpminq_u8 (uint8x16_t a, uint8x16_t b);
uint16x8_t vpminq_u16 (uint16x8_t a, uint16x8_t b);
uint32x4_t vpminq_u32 (uint32x4_t a, uint32x4_t b);
```

```c
float16x8_t vpminq_f16 (float16x8_t a, float16x8_t b);
float32x4_t vpminq_f32 (float32x4_t a, float32x4_t b);
float64x2_t vpminq_f64 (float64x2_t a, float64x2_t b);
```

#### vpminnmq

* 不考虑浮点数的非规范化表示形式可能带来的精度差异

```c
float16x8_t vpminnmq_f16 (float16x8_t a, float16x8_t b);
float32x4_t vpminnmq_f32 (float32x4_t a, float32x4_t b);
float64x2_t vpminnmq_f64 (float64x2_t a, float64x2_t b);
```

#### vminvq

* 运算： `ret[i] = min(a[0], a[1], a[2], ...)`

```c
int8_t vminvq_s8 (int8x16_t a);
int16_t vminvq_s16 (int16x8_t a);
int32_t vminvq_s32 (int32x4_t a);
```

```c
uint8_t vminvq_u8 (uint8x16_t a);
uint16_t vminvq_u16 (uint16x8_t a);
uint32_t vminvq_u32 (uint32x4_t a);
```

```c
float16_t vminvq_f16 (float16x8_t a);
float32_t vminvq_f32 (float32x4_t a);
float64_t vminvq_f64 (float64x2_t a);
```

#### vminnmvq

```c
float16_t vminnmvq_f16 (float16x8_t a);
float32_t vminnmvq_f32 (float32x4_t a);
float64_t vminnmvq_f64 (float64x2_t a);
```

### 单指令最小值

#### vpmin?

* 运算： `ret = a[0] < a[1] ? a[0] : a[1]`

```c
float32_t vpmins_f32 (float32x2_t a);
float64_t vpminqd_f64 (float64x2_t a);
```

#### vpminnm?

```c
float32_t vpminnms_f32 (float32x2_t a);
float64_t vpminnmqd_f64 (float64x2_t a);
```

## max最大值指令

* 后缀 `nm` 不考虑浮点数的非规范化表示形式可能带来的精度差异

### 短指令最大值

#### vmax

* 运算： `ret[i] = a[i] > b[i] ? a[i] : b[i]`

```c
int8x8_t vmax_s8 (int8x8_t a, int8x8_t b);
int16x4_t vmax_s16 (int16x4_t a, int16x4_t b); // _m_pmaxsw
int32x2_t vmax_s32 (int32x2_t a, int32x2_t b);
```

```c
uint8x8_t vmax_u8 (uint8x8_t a, uint8x8_t b); // _m_pmaxub
uint16x4_t vmax_u16 (uint16x4_t a, uint16x4_t b);
uint32x2_t vmax_u32 (uint32x2_t a, uint32x2_t b);
```

```c
float16x4_t vmax_f16 (float16x4_t a, float16x4_t b);
float32x2_t vmax_f32 (float32x2_t a, float32x2_t b);
float64x1_t vmax_f64 (float64x1_t a, float64x1_t b);
```

#### vmaxnm

```c
float16x4_t vmaxnm_f16 (float16x4_t a, float16x4_t b);
float32x2_t vmaxnm_f32 (float32x2_t a, float32x2_t b);
float64x1_t vmaxnm_f64 (float64x1_t a, float64x1_t b);
```

#### vpmax

* 运算： 先连接a、b组成新向量 `ab = {a[0], a[1], ..., b[0], b[1], ...}` ; 再临近元素比较 `ret[i] = ab[2i] > ab[2i+1] ? ab[2i] : ab[2i+1]`

```c
int8x8_t vpmax_s8 (int8x8_t a, int8x8_t b);
int16x4_t vpmax_s16 (int16x4_t a, int16x4_t b);
int32x2_t vpmax_s32 (int32x2_t a, int32x2_t b);
```

```c
uint8x8_t vpmax_u8 (uint8x8_t a, uint8x8_t b);
uint16x4_t vpmax_u16 (uint16x4_t a, uint16x4_t b);
uint32x2_t vpmax_u32 (uint32x2_t a, uint32x2_t b);
```

```c
float16x4_t vpmax_f16 (float16x4_t a, float16x4_t b);
float32x2_t vpmax_f32 (float32x2_t a, float32x2_t b);
```

#### vpmaxnm

```c
float16x4_t vpmaxnm_f16 (float16x4_t a, float16x4_t b);
float32x2_t vpmaxnm_f32 (float32x2_t a, float32x2_t b);
```

#### vmaxv

* 运算： `ret[i] = max(a[0], a[1], a[2], ...)`

```c
int8_t vmaxv_s8 (int8x8_t a);
int16_t vmaxv_s16 (int16x4_t a); // _mm_max_pi16
int32_t vmaxv_s32 (int32x2_t a);
```

```c
uint8_t vmaxv_u8 (uint8x8_t a); // _mm_max_pu8
uint16_t vmaxv_u16 (uint16x4_t a);
uint32_t vmaxv_u32 (uint32x2_t a);
```

```c
float16_t vmaxv_f16 (float16x4_t a);
float32_t vmaxv_f32 (float32x2_t a);
```

#### vmaxnmv

```c
float16_t vmaxnmv_f16 (float16x4_t a);
float32_t vmaxnmv_f32 (float32x2_t a);
```

### 全指令最大值

#### vmaxq

* 运算： `ret[i] = a[i] > b[i] ? a[i] : b[i]`

```c
int8x16_t vmaxq_s8 (int8x16_t a, int8x16_t b);  // _mm_max_epi8  | _mm256_max_epi8  | _mm512_max_epi8
int16x8_t vmaxq_s16 (int16x8_t a, int16x8_t b); // _mm_max_epi16 | _mm256_max_epi16 | _mm512_max_epi16
int32x4_t vmaxq_s32 (int32x4_t a, int32x4_t b); // _mm_max_epi32 | _mm256_max_epi32 | _mm512_max_epi32
                                    // (AVX512) // _mm_max_epi64 | _mm256_max_epi64 | _mm512_max_epi64
```

```c
uint8x16_t vmaxq_u8 (uint8x16_t a, uint8x16_t b);  // _mm_max_epu8  | _mm256_max_epu8  | _mm512_max_epu8
uint16x8_t vmaxq_u16 (uint16x8_t a, uint16x8_t b); // _mm_max_epu16 | _mm256_max_epu16 | _mm512_max_epu16
uint32x4_t vmaxq_u32 (uint32x4_t a, uint32x4_t b); // _mm_max_epu32 | _mm256_max_epu32 | _mm512_max_epu32
                                       // (AVX512) // _mm_max_epu64 | _mm256_max_epu64 | _mm512_max_epu64
```

```c
float16x8_t vmaxq_f16 (float16x8_t a, float16x8_t b); // _mm_max_ph | _mm256_max_ph | _mm512_max_ph
float32x4_t vmaxq_f32 (float32x4_t a, float32x4_t b); // _mm_max_ps | _mm256_max_ps | _mm512_max_ps
float64x2_t vmaxq_f64 (float64x2_t a, float64x2_t b); // _mm_max_pd | _mm256_max_pd | _mm512_max_pd
```

#### vmaxnmq

```c
float16x8_t vmaxnmq_f16 (float16x8_t a, float16x8_t b);
float32x4_t vmaxnmq_f32 (float32x4_t a, float32x4_t b);
float64x2_t vmaxnmq_f64 (float64x2_t a, float64x2_t b);
```

#### vpmaxq

* 运算： 先连接a、b组成新向量 `ab = {a[0], a[1], ..., b[0], b[1], ...}` ; 再临近元素比较 `ret[i] = ab[2i] > ab[2i+1] ? ab[2i] : ab[2i+1]`

```c
int8x16_t vpmaxq_s8 (int8x16_t a, int8x16_t b);
int16x8_t vpmaxq_s16 (int16x8_t a, int16x8_t b);
int32x4_t vpmaxq_s32 (int32x4_t a, int32x4_t b);
```

```c
uint8x16_t vpmaxq_u8 (uint8x16_t a, uint8x16_t b);
uint16x8_t vpmaxq_u16 (uint16x8_t a, uint16x8_t b);
uint32x4_t vpmaxq_u32 (uint32x4_t a, uint32x4_t b);
```

```c
float16x8_t vpmaxq_f16 (float16x8_t a, float16x8_t b);
float32x4_t vpmaxq_f32 (float32x4_t a, float32x4_t b);
float64x2_t vpmaxq_f64 (float64x2_t a, float64x2_t b);
```

#### vpmaxnmq

* 不考虑浮点数的非规范化表示形式可能带来的精度差异

```c
float16x8_t vpmaxnmq_f16 (float16x8_t a, float16x8_t b);
float32x4_t vpmaxnmq_f32 (float32x4_t a, float32x4_t b);
float64x2_t vpmaxnmq_f64 (float64x2_t a, float64x2_t b);
```

#### vmaxvq

* 运算： `ret[i] = max(a[0], a[1], a[2], ...)`

```c
int8_t vmaxvq_s8 (int8x16_t a);
int16_t vmaxvq_s16 (int16x8_t a);
int32_t vmaxvq_s32 (int32x4_t a);
```

```c
uint8_t vmaxvq_u8 (uint8x16_t a);
uint16_t vmaxvq_u16 (uint16x8_t a);
uint32_t vmaxvq_u32 (uint32x4_t a);
```

```c
float16_t vmaxvq_f16 (float16x8_t a);
float32_t vmaxvq_f32 (float32x4_t a);
float64_t vmaxvq_f64 (float64x2_t a);
```

#### vmaxnmvq

```c
float16_t vmaxnmvq_f16 (float16x8_t a);
float32_t vmaxnmvq_f32 (float32x4_t a);
float64_t vmaxnmvq_f64 (float64x2_t a);
```

### 单指令最大值

#### vpmax?

* 运算： `ret = a[0] > a[1] ? a[0] : a[1]`

```c
float32_t vpmaxs_f32 (float32x2_t a);
float64_t vpmaxqd_f64 (float64x2_t a);
```

#### vpmaxnm?

```c
float32_t vpmaxnms_f32 (float32x2_t a);
float64_t vpmaxnmqd_f64 (float64x2_t a);
```

## ceq相等比较指令

### 短指令相等比较

#### vceq

* 运算： `ret[i] = a[i] == b[i] ? 0xFF... : 0`

```c
uint8x8_t vceq_s8 (int8x8_t a, int8x8_t b);     // _mm_cmpeq_pi8 / _m_pcmpeqb
uint16x4_t vceq_s16 (int16x4_t a, int16x4_t b); // _mm_cmpeq_pi16 / _m_pcmpeqw
uint32x2_t vceq_s32 (int32x2_t a, int32x2_t b); // _mm_cmpeq_pi32 / _m_pcmpeqd
uint64x1_t vceq_s64 (int64x1_t a, int64x1_t b);
```

```c
uint8x8_t vceq_u8 (uint8x8_t a, uint8x8_t b);
uint16x4_t vceq_u16 (uint16x4_t a, uint16x4_t b);
uint32x2_t vceq_u32 (uint32x2_t a, uint32x2_t b);
uint64x1_t vceq_u64 (uint64x1_t a, uint64x1_t b);
```

```c
uint16x4_t vceq_f16 (float16x4_t a, float16x4_t b);
uint32x2_t vceq_f32 (float32x2_t a, float32x2_t b);
uint64x1_t vceq_f64 (float64x1_t a, float64x1_t b);
```

```c
uint8x8_t vceq_p8 (poly8x8_t a, poly8x8_t b);
uint64x1_t vceq_p64 (poly64x1_t a, poly64x1_t b);
```

### 全指令相等比较

#### vceqq

* 运算： `ret[i] = a[i] == b[i] ? 0xFF... : 0`

```c
uint8x16_t vceqq_s8 (int8x16_t a, int8x16_t b);  // _mm_cmpeq_epi8  | _mm256_cmpeq_epi8
uint16x8_t vceqq_s16 (int16x8_t a, int16x8_t b); // _mm_cmpeq_epi16 | _mm256_cmpeq_epi16
uint32x4_t vceqq_s32 (int32x4_t a, int32x4_t b); // _mm_cmpeq_epi32 | _mm256_cmpeq_epi32
uint64x2_t vceqq_s64 (int64x2_t a, int64x2_t b); // _mm_cmpeq_epi64 | _mm256_cmpeq_epi64
```

```c
uint8x16_t vceqq_u8 (uint8x16_t a, uint8x16_t b);
uint16x8_t vceqq_u16 (uint16x8_t a, uint16x8_t b);
uint32x4_t vceqq_u32 (uint32x4_t a, uint32x4_t b);
uint64x2_t vceqq_u64 (uint64x2_t a, uint64x2_t b);
```

```c
uint16x8_t vceqq_f16 (float16x8_t a, float16x8_t b);
uint32x4_t vceqq_f32 (float32x4_t a, float32x4_t b); // _mm_cmpeq_ps | no256
uint64x2_t vceqq_f64 (float64x2_t a, float64x2_t b); // _mm_cmpeq_pd | no256
```

```c
uint8x16_t vceqq_p8 (poly8x16_t a, poly8x16_t b);
uint64x2_t vceqq_p64 (poly64x2_t a, poly64x2_t b);
```

#### cmpeq_mask(mmintrin)

* 运算： `ret.b[i] = a[i] == b[i] ? 1 : 0` (AVX512)

```c
__mmask16 _mm_cmpeq_epi8_mask (__m128i a, __m128i b); // | _mm256_cmpeq_epi8_mask  | _mm512_cmpeq_epi8_mask
__mmask8 _mm_cmpeq_epi16_mask (__m128i a, __m128i b); // | _mm256_cmpeq_epi16_mask | _mm512_cmpeq_epi16_mask
__mmask8 _mm_cmpeq_epi32_mask (__m128i a, __m128i b); // | _mm256_cmpeq_epi32_mask | _mm512_cmpeq_epi32_mask
__mmask8 _mm_cmpeq_epi64_mask (__m128i a, __m128i b); // | _mm256_cmpeq_epi64_mask | _mm512_cmpeq_epi64_mask
```

```c
__mmask16 _mm_cmpeq_epu8_mask (__m128i a, __m128i b); // | _mm256_cmpeq_epu8_mask  | _mm512_cmpeq_epu8_mask
__mmask8 _mm_cmpeq_epu16_mask (__m128i a, __m128i b); // | _mm256_cmpeq_epu16_mask | _mm512_cmpeq_epu16_mask
__mmask8 _mm_cmpeq_epu32_mask (__m128i a, __m128i b); // | _mm256_cmpeq_epu32_mask | _mm512_cmpeq_epu32_mask
__mmask8 _mm_cmpeq_epu64_mask (__m128i a, __m128i b); // | _mm256_cmpeq_epu64_mask | _mm512_cmpeq_epu64_mask
```

```c
__mmask16 _mm512_cmpeq_ps_mask (__m512 a, __m512 b);
__mmask8 _mm512_cmpeq_pd_mask (__m512d a, __m512d b);
```

#### cmpneq_mask(mmintrin)

* 运算： `ret.b[i] = a[i] != b[i] ? 1 : 0` (AVX512)

```c
__mmask16 _mm_cmpneq_epi8_mask (__m128i a, __m128i b); // | _mm256_cmpneq_epi8_mask  | _mm512_cmpneq_epi8_mask
__mmask8 _mm_cmpneq_epi16_mask (__m128i a, __m128i b); // | _mm256_cmpneq_epi16_mask | _mm512_cmpneq_epi16_mask
__mmask8 _mm_cmpneq_epi32_mask (__m128i a, __m128i b); // | _mm256_cmpneq_epi32_mask | _mm512_cmpneq_epi32_mask
__mmask8 _mm_cmpneq_epi64_mask (__m128i a, __m128i b); // | _mm256_cmpneq_epi64_mask | _mm512_cmpneq_epi64_mask
```

```c
__mmask16 _mm_cmpneq_epu8_mask (__m128i a, __m128i b); // | _mm256_cmpneq_epu8_mask  | _mm512_cmpneq_epu8_mask
__mmask8 _mm_cmpneq_epu16_mask (__m128i a, __m128i b); // | _mm256_cmpneq_epu16_mask | _mm512_cmpneq_epu16_mask
__mmask8 _mm_cmpneq_epu32_mask (__m128i a, __m128i b); // | _mm256_cmpneq_epu32_mask | _mm512_cmpneq_epu32_mask
__mmask8 _mm_cmpneq_epu64_mask (__m128i a, __m128i b); // | _mm256_cmpneq_epu64_mask | _mm512_cmpneq_epu64_mask
```

```c
__mmask16 _mm512_cmpneq_ps_mask (__m512 a, __m512 b);
__mmask8 _mm512_cmpneq_pd_mask (__m512d a, __m512d b);
```

### 单指令相等比较

#### vceq?

* 运算： `ret = a == b ? 0xFF... : 0`

```c
uint64_t vceqd_s64 (int64_t a, int64_t b);
uint64_t vceqd_u64 (uint64_t a, uint64_t b);
```

```c
uint32_t vceqs_f32 (float32_t a, float32_t b);
uint64_t vceqd_f64 (float64_t a, float64_t b);
```

## ceqz相等零比较指令

### 短指令相等零比较

#### vceqz

* 运算： `ret[i] = a[i] == 0 ? 0xFF... : 0`

```c
uint8x8_t vceqz_s8 (int8x8_t a);
uint16x4_t vceqz_s16 (int16x4_t a);
uint32x2_t vceqz_s32 (int32x2_t a);
uint64x1_t vceqz_s64 (int64x1_t a);
```

```c
uint8x8_t vceqz_u8 (uint8x8_t a);
uint16x4_t vceqz_u16 (uint16x4_t a);
uint32x2_t vceqz_u32 (uint32x2_t a);
uint64x1_t vceqz_u64 (uint64x1_t a);
```

```c
uint16x4_t vceqz_f16 (float16x4_t a);
uint32x2_t vceqz_f32 (float32x2_t a);
uint64x1_t vceqz_f64 (float64x1_t a);
```

```c
uint8x8_t vceqz_p8 (poly8x8_t a);
uint64x1_t vceqz_p64 (poly64x1_t a);
```

### 全指令相等零比较

#### vceqzq

* 运算： `ret[i] = a[i] == 0 ? 0xFF... : 0`

```c
uint8x16_t vceqzq_s8 (int8x16_t a);
uint16x8_t vceqzq_s16 (int16x8_t a);
uint32x4_t vceqzq_s32 (int32x4_t a);
uint64x2_t vceqzq_s64 (int64x2_t a);
```

```c
uint8x16_t vceqzq_u8 (uint8x16_t a);
uint16x8_t vceqzq_u16 (uint16x8_t a);
uint32x4_t vceqzq_u32 (uint32x4_t a);
uint64x2_t vceqzq_u64 (uint64x2_t a);
```

```c
uint16x8_t vceqzq_f16 (float16x8_t a);
uint32x4_t vceqzq_f32 (float32x4_t a);
uint64x2_t vceqzq_f64 (float64x2_t a);
```

```c
uint8x16_t vceqzq_p8 (poly8x16_t a);
uint64x2_t vceqzq_p64 (poly64x2_t a);
```

### 单指令相等零比较

#### vceqz?

* 运算： `ret = a == 0 ? 0xFF... : 0`

```c
uint64_t vceqzd_s64 (int64_t a);
uint64_t vceqzd_u64 (uint64_t a);
```

```c
uint32_t vceqzs_f32 (float32_t a);
uint64_t vceqzd_f64 (float64_t a);
```

## cgt大于比较指令

### 短指令大于比较

#### vcgt

* 运算： `ret[i] = a[i] > b[i] ? 0xFF... : 0`

```c
uint8x8_t vcgt_s8 (int8x8_t a, int8x8_t b);     // _mm_cmpgt_pi8 / _m_pcmpgtb
uint16x4_t vcgt_s16 (int16x4_t a, int16x4_t b); // _mm_cmpgt_pi16 / _m_pcmpgtw
uint32x2_t vcgt_s32 (int32x2_t a, int32x2_t b); // _mm_cmpgt_pi32 / _m_pcmpgtd
uint64x1_t vcgt_s64 (int64x1_t a, int64x1_t b);
```

```c
uint8x8_t vcgt_u8 (uint8x8_t a, uint8x8_t b);
uint16x4_t vcgt_u16 (uint16x4_t a, uint16x4_t b);
uint32x2_t vcgt_u32 (uint32x2_t a, uint32x2_t b);
uint64x1_t vcgt_u64 (uint64x1_t a, uint64x1_t b);
```

```c
uint16x4_t vcgt_f16 (float16x4_t a, float16x4_t b);
uint32x2_t vcgt_f32 (float32x2_t a, float32x2_t b);
uint64x1_t vcgt_f64 (float64x1_t a, float64x1_t b);
```

### 全指令大于比较

#### vcgtq

* 运算： `ret[i] = a[i] > b[i] ? 0xFF... : 0`

```c
uint8x16_t vcgtq_s8 (int8x16_t a, int8x16_t b);  // _mm_cmpgt_epi8  | _mm256_cmpgt_epi8
uint16x8_t vcgtq_s16 (int16x8_t a, int16x8_t b); // _mm_cmpgt_epi16 | _mm256_cmpgt_epi16
uint32x4_t vcgtq_s32 (int32x4_t a, int32x4_t b); // _mm_cmpgt_epi32 | _mm256_cmpgt_epi32
uint64x2_t vcgtq_s64 (int64x2_t a, int64x2_t b); // _mm_cmpgt_epi64 | _mm256_cmpgt_epi64
```

```c
uint8x16_t vcgtq_u8 (uint8x16_t a, uint8x16_t b);
uint16x8_t vcgtq_u16 (uint16x8_t a, uint16x8_t b);
uint32x4_t vcgtq_u32 (uint32x4_t a, uint32x4_t b);
uint64x2_t vcgtq_u64 (uint64x2_t a, uint64x2_t b);
```

```c
uint16x8_t vcgtq_f16 (float16x8_t a, float16x8_t b);
uint32x4_t vcgtq_f32 (float32x4_t a, float32x4_t b); // _mm_cmpgt_ps / _mm_cmpnle_ps
uint64x2_t vcgtq_f64 (float64x2_t a, float64x2_t b); // _mm_cmpgt_pd / _mm_cmpnle_pd
```

#### cmpgt_mask(mmintrin)

* 运算： `ret.b[i] = a[i] > b[i] ? 1 : 0` (AVX512)

```c
__mmask16 _mm_cmpgt_epi8_mask (__m128i a, __m128i b); // | _mm256_cmpgt_epi8_mask  | _mm512_cmpgt_epi8_mask
__mmask8 _mm_cmpgt_epi16_mask (__m128i a, __m128i b); // | _mm256_cmpgt_epi16_mask | _mm512_cmpgt_epi16_mask
__mmask8 _mm_cmpgt_epi32_mask (__m128i a, __m128i b); // | _mm256_cmpgt_epi32_mask | _mm512_cmpgt_epi32_mask
__mmask8 _mm_cmpgt_epi64_mask (__m128i a, __m128i b); // | _mm256_cmpgt_epi64_mask | _mm512_cmpgt_epi64_mask
```

```c
__mmask16 _mm_cmpgt_epu8_mask (__m128i a, __m128i b); // | _mm256_cmpgt_epu8_mask  | _mm512_cmpgt_epu8_mask
__mmask8 _mm_cmpgt_epu16_mask (__m128i a, __m128i b); // | _mm256_cmpgt_epu16_mask | _mm512_cmpgt_epu16_mask
__mmask8 _mm_cmpgt_epu32_mask (__m128i a, __m128i b); // | _mm256_cmpgt_epu32_mask | _mm512_cmpgt_epu32_mask
__mmask8 _mm_cmpgt_epu64_mask (__m128i a, __m128i b); // | _mm256_cmpgt_epu64_mask | _mm512_cmpgt_epu64_mask
```

```c
__mmask16 _mm512_cmpnle_ps_mask (__m512 a, __m512 b);
__mmask8 _mm512_cmpnle_pd_mask (__m512d a, __m512d b);
```

### 单指令大于比较

#### vcgt?

* 运算： `ret = a > b ? 0xFF... : 0`

```c
uint64_t vcgtd_s64 (int64_t a, int64_t b);
uint64_t vcgtd_u64 (uint64_t a, uint64_t b);
```

```c
uint32_t vcgts_f32 (float32_t a, float32_t b);
uint64_t vcgtd_f64 (float64_t a, float64_t b);
```

## cgtz大于零比较指令

### 短指令大于零比较

#### vcgtz

* 运算： `ret[i] = a[i] > 0 ? 0xFF... : 0`

```c
uint8x8_t vcgtz_s8 (int8x8_t a);
uint16x4_t vcgtz_s16 (int16x4_t a);
uint32x2_t vcgtz_s32 (int32x2_t a);
uint64x1_t vcgtz_s64 (int64x1_t a);
```

```c
uint16x4_t vcgtz_f16 (float16x4_t a);
uint32x2_t vcgtz_f32 (float32x2_t a);
uint64x1_t vcgtz_f64 (float64x1_t a);
```

### 全指令大于零比较

#### vcgtzq

* 运算： `ret[i] = a[i] > 0 ? 0xFF... : 0`

```c
uint8x16_t vcgtzq_s8 (int8x16_t a);
uint16x8_t vcgtzq_s16 (int16x8_t a);
uint32x4_t vcgtzq_s32 (int32x4_t a);
uint64x2_t vcgtzq_s64 (int64x2_t a);
```

```c
uint16x8_t vcgtzq_f16 (float16x8_t a);
uint32x4_t vcgtzq_f32 (float32x4_t a);
uint64x2_t vcgtzq_f64 (float64x2_t a);
```

### 单指令大于零比较

#### vcgtz?

* 运算： `ret = a > 0 ? 0xFF... : 0`

```c
uint64_t vcgtzd_s64 (int64_t a);
```

```c
uint32_t vcgtzs_f32 (float32_t a);
uint64_t vcgtzd_f64 (float64_t a);
```

## cge大于等于比较指令

### 短指令大于等于比较

#### vcge

* 运算： `ret[i] = a[i] >= b[i] ? 0xFF... : 0`

```c
uint8x8_t vcge_s8 (int8x8_t a, int8x8_t b);
uint16x4_t vcge_s16 (int16x4_t a, int16x4_t b);
uint32x2_t vcge_s32 (int32x2_t a, int32x2_t b);
uint64x1_t vcge_s64 (int64x1_t a, int64x1_t b);
```

```c
uint8x8_t vcge_u8 (uint8x8_t a, uint8x8_t b);
uint16x4_t vcge_u16 (uint16x4_t a, uint16x4_t b);
uint32x2_t vcge_u32 (uint32x2_t a, uint32x2_t b);
uint64x1_t vcge_u64 (uint64x1_t a, uint64x1_t b);
```

```c
uint16x4_t vcge_f16 (float16x4_t a, float16x4_t b);
uint32x2_t vcge_f32 (float32x2_t a, float32x2_t b);
uint64x1_t vcge_f64 (float64x1_t a, float64x1_t b);
```

### 全指令大于等于比较

#### vcgeq

* 运算： `ret[i] = a[i] >= b[i] ? 0xFF... : 0`

```c
uint8x16_t vcgeq_s8 (int8x16_t a, int8x16_t b);
uint16x8_t vcgeq_s16 (int16x8_t a, int16x8_t b);
uint32x4_t vcgeq_s32 (int32x4_t a, int32x4_t b);
uint64x2_t vcgeq_s64 (int64x2_t a, int64x2_t b);
```

```c
uint8x16_t vcgeq_u8 (uint8x16_t a, uint8x16_t b);
uint16x8_t vcgeq_u16 (uint16x8_t a, uint16x8_t b);
uint32x4_t vcgeq_u32 (uint32x4_t a, uint32x4_t b);
uint64x2_t vcgeq_u64 (uint64x2_t a, uint64x2_t b);
```

```c
uint16x8_t vcgeq_f16 (float16x8_t a, float16x8_t b);
uint32x4_t vcgeq_f32 (float32x4_t a, float32x4_t b); // _mm_cmpge_ps / _mm_cmpnlt_ps
uint64x2_t vcgeq_f64 (float64x2_t a, float64x2_t b); // _mm_cmpge_pd / _mm_cmpnlt_pd
```

#### cmpge_mask(mmintrin)

* 运算： `ret.b[i] = a[i] >= b[i] ? 1 : 0` (AVX512)

```c
__mmask16 _mm_cmpge_epi8_mask (__m128i a, __m128i b); // | _mm256_cmpge_epi8_mask  | _mm512_cmpge_epi8_mask
__mmask8 _mm_cmpge_epi16_mask (__m128i a, __m128i b); // | _mm256_cmpge_epi16_mask | _mm512_cmpge_epi16_mask
__mmask8 _mm_cmpge_epi32_mask (__m128i a, __m128i b); // | _mm256_cmpge_epi32_mask | _mm512_cmpge_epi32_mask
__mmask8 _mm_cmpge_epi64_mask (__m128i a, __m128i b); // | _mm256_cmpge_epi64_mask | _mm512_cmpge_epi64_mask
```

```c
__mmask16 _mm_cmpge_epu8_mask (__m128i a, __m128i b); // | _mm256_cmpge_epu8_mask  | _mm512_cmpge_epu8_mask
__mmask8 _mm_cmpge_epu16_mask (__m128i a, __m128i b); // | _mm256_cmpge_epu16_mask | _mm512_cmpge_epu16_mask
__mmask8 _mm_cmpge_epu32_mask (__m128i a, __m128i b); // | _mm256_cmpge_epu32_mask | _mm512_cmpge_epu32_mask
__mmask8 _mm_cmpge_epu64_mask (__m128i a, __m128i b); // | _mm256_cmpge_epu64_mask | _mm512_cmpge_epu64_mask
```

```c
__mmask16 _mm512_cmpnlt_ps_mask (__m512 a, __m512 b);
__mmask8 _mm512_cmpnlt_pd_mask (__m512d a, __m512d b);
```

### 单指令大于等于比较

#### vcge?

* 运算： `ret = a >= b ? 0xFF... : 0`

```c
uint64_t vcged_s64 (int64_t a, int64_t b);
uint64_t vcged_u64 (uint64_t a, uint64_t b);
```

```c
uint32_t vcges_f32 (float32_t a, float32_t b);
uint64_t vcged_f64 (float64_t a, float64_t b);
```

## cgez大于等于零比较指令

### 短指令大于等于零比较

#### vcgez

* 运算： `ret[i] = a[i] >= 0 ? 0xFF... : 0`

```c
uint8x8_t vcgez_s8 (int8x8_t a);
uint16x4_t vcgez_s16 (int16x4_t a);
uint32x2_t vcgez_s32 (int32x2_t a);
uint64x1_t vcgez_s64 (int64x1_t a);
```

```c
uint16x4_t vcgez_f16 (float16x4_t a);
uint32x2_t vcgez_f32 (float32x2_t a);
uint64x1_t vcgez_f64 (float64x1_t a);
```

### 全指令大于等于零比较

#### vcgezq

* 运算： `ret[i] = a[i] >= 0 ? 0xFF... : 0`

```c
uint8x16_t vcgezq_s8 (int8x16_t a);
uint16x8_t vcgezq_s16 (int16x8_t a);
uint32x4_t vcgezq_s32 (int32x4_t a);
uint64x2_t vcgezq_s64 (int64x2_t a);
```

```c
uint16x8_t vcgezq_f16 (float16x8_t a);
uint32x4_t vcgezq_f32 (float32x4_t a);
uint64x2_t vcgezq_f64 (float64x2_t a);
```

### 单指令大于等于零比较

#### vcgez?

* 运算： `ret = a >= 0 ? 0xFF... : 0`

```c
uint64_t vcgezd_s64 (int64_t a);
```

```c
uint32_t vcgezs_f32 (float32_t a);
uint64_t vcgezd_f64 (float64_t a);
```

## clt小于比较指令

### 短指令小于比较

#### vclt

* 运算： `ret[i] = a[i] < b[i] ? 0xFF... : 0`

```c
uint8x8_t vclt_s8 (int8x8_t a, int8x8_t b);
uint16x4_t vclt_s16 (int16x4_t a, int16x4_t b);
uint32x2_t vclt_s32 (int32x2_t a, int32x2_t b);
uint64x1_t vclt_s64 (int64x1_t a, int64x1_t b);
```

```c
uint8x8_t vclt_u8 (uint8x8_t a, uint8x8_t b);
uint16x4_t vclt_u16 (uint16x4_t a, uint16x4_t b);
uint32x2_t vclt_u32 (uint32x2_t a, uint32x2_t b);
uint64x1_t vclt_u64 (uint64x1_t a, uint64x1_t b);
```

```c
uint16x4_t vclt_f16 (float16x4_t a, float16x4_t b);
uint32x2_t vclt_f32 (float32x2_t a, float32x2_t b);
uint64x1_t vclt_f64 (float64x1_t a, float64x1_t b);
```

### 全指令小于比较

#### vcltq

* 运算： `ret[i] = a[i] < b[i] ? 0xFF... : 0`

```c
uint8x16_t vcltq_s8 (int8x16_t a, int8x16_t b); // _mm_cmplt_epi8
uint16x8_t vcltq_s16 (int16x8_t a, int16x8_t b); // _mm_cmplt_epi16
uint32x4_t vcltq_s32 (int32x4_t a, int32x4_t b); // _mm_cmplt_epi32
uint64x2_t vcltq_s64 (int64x2_t a, int64x2_t b);
```

```c
uint8x16_t vcltq_u8 (uint8x16_t a, uint8x16_t b);
uint16x8_t vcltq_u16 (uint16x8_t a, uint16x8_t b);
uint32x4_t vcltq_u32 (uint32x4_t a, uint32x4_t b);
uint64x2_t vcltq_u64 (uint64x2_t a, uint64x2_t b);
```

```c
uint16x8_t vcltq_f16 (float16x8_t a, float16x8_t b);
uint32x4_t vcltq_f32 (float32x4_t a, float32x4_t b); // _mm_cmplt_ps / _mm_cmpnge_ps
uint64x2_t vcltq_f64 (float64x2_t a, float64x2_t b); // _mm_cmplt_pd / _mm_cmpnge_pd
```

#### cmplt_mask(mmintrin)

* 运算： `ret.b[i] = a[i] < b[i] ? 1 : 0` (AVX512)

```c
__mmask16 _mm_cmplt_epi8_mask (__m128i a, __m128i b); // | _mm256_cmplt_epi8_mask  | _mm512_cmplt_epi8_mask
__mmask8 _mm_cmplt_epi16_mask (__m128i a, __m128i b); // | _mm256_cmplt_epi16_mask | _mm512_cmplt_epi16_mask
__mmask8 _mm_cmplt_epi32_mask (__m128i a, __m128i b); // | _mm256_cmplt_epi32_mask | _mm512_cmplt_epi32_mask
__mmask8 _mm_cmplt_epi64_mask (__m128i a, __m128i b); // | _mm256_cmplt_epi64_mask | _mm512_cmplt_epi64_mask
```

```c
__mmask16 _mm_cmplt_epu8_mask (__m128i a, __m128i b); // | _mm256_cmplt_epu8_mask  | _mm512_cmplt_epu8_mask
__mmask8 _mm_cmplt_epu16_mask (__m128i a, __m128i b); // | _mm256_cmplt_epu16_mask | _mm512_cmplt_epu16_mask
__mmask8 _mm_cmplt_epu32_mask (__m128i a, __m128i b); // | _mm256_cmplt_epu32_mask | _mm512_cmplt_epu32_mask
__mmask8 _mm_cmplt_epu64_mask (__m128i a, __m128i b); // | _mm256_cmplt_epu64_mask | _mm512_cmplt_epu64_mask
```

```c
__mmask16 _mm512_cmplt_ps_mask (__m512 a, __m512 b);
__mmask8 _mm512_cmplt_pd_mask (__m512d a, __m512d b);
```

### 单指令小于比较

#### vclt?

* 运算： `ret = a < b ? 0xFF... : 0`

```c
uint64_t vcltd_s64 (int64_t a, int64_t b);
uint64_t vcltd_u64 (uint64_t a, uint64_t b);
```

```c
uint32_t vclts_f32 (float32_t a, float32_t b);
uint64_t vcltd_f64 (float64_t a, float64_t b);
```

## cltz小于零比较指令

### 短指令小于零比较

#### vcltz

* 运算： `ret[i] = a[i] < 0 ? 0xFF... : 0`

```c
uint8x8_t vcltz_s8 (int8x8_t a);
uint16x4_t vcltz_s16 (int16x4_t a);
uint32x2_t vcltz_s32 (int32x2_t a);
uint64x1_t vcltz_s64 (int64x1_t a);
```

```c
uint16x4_t vcltz_f16 (float16x4_t a);
uint32x2_t vcltz_f32 (float32x2_t a);
uint64x1_t vcltz_f64 (float64x1_t a);
```

### 全指令小于零比较

#### vcltzq

* 运算： `ret[i] = a[i] < 0 ? 0xFF... : 0`

```c
uint8x16_t vcltzq_s8 (int8x16_t a);
uint16x8_t vcltzq_s16 (int16x8_t a);
uint32x4_t vcltzq_s32 (int32x4_t a);
uint64x2_t vcltzq_s64 (int64x2_t a);
```

```c
uint16x8_t vcltzq_f16 (float16x8_t a);
uint32x4_t vcltzq_f32 (float32x4_t a);
uint64x2_t vcltzq_f64 (float64x2_t a);
```

### 单指令小于零比较

#### vcltz?

* 运算： `ret = a < 0 ? 0xFF... : 0`

```c
uint64_t vcltzd_s64 (int64_t a);
```

```c
uint32_t vcltzs_f32 (float32_t a);
uint64_t vcltzd_f64 (float64_t a);
```

## cle小于等于比较指令

### 短指令小于等于比较

#### vcle

* 运算： `ret[i] = a[i] <= b[i] ? 0xFF... : 0`

```c
uint8x8_t vcle_s8 (int8x8_t a, int8x8_t b);
uint16x4_t vcle_s16 (int16x4_t a, int16x4_t b);
uint32x2_t vcle_s32 (int32x2_t a, int32x2_t b);
uint64x1_t vcle_s64 (int64x1_t a, int64x1_t b);
```

```c
uint8x8_t vcle_u8 (uint8x8_t a, uint8x8_t b);
uint16x4_t vcle_u16 (uint16x4_t a, uint16x4_t b);
uint32x2_t vcle_u32 (uint32x2_t a, uint32x2_t b);
uint64x1_t vcle_u64 (uint64x1_t a, uint64x1_t b);
```

```c
uint16x4_t vcle_f16 (float16x4_t a, float16x4_t b);
uint32x2_t vcle_f32 (float32x2_t a, float32x2_t b);
uint64x1_t vcle_f64 (float64x1_t a, float64x1_t b);
```

### 全指令小于等于比较

#### vcleq

* 运算： `ret[i] = a[i] <= b[i] ? 0xFF... : 0`

```c
uint8x16_t vcleq_s8 (int8x16_t a, int8x16_t b);
uint16x8_t vcleq_s16 (int16x8_t a, int16x8_t b);
uint32x4_t vcleq_s32 (int32x4_t a, int32x4_t b);
uint64x2_t vcleq_s64 (int64x2_t a, int64x2_t b);
```

```c
uint8x16_t vcleq_u8 (uint8x16_t a, uint8x16_t b);
uint16x8_t vcleq_u16 (uint16x8_t a, uint16x8_t b);
uint32x4_t vcleq_u32 (uint32x4_t a, uint32x4_t b);
uint64x2_t vcleq_u64 (uint64x2_t a, uint64x2_t b);
```

```c
uint16x8_t vcleq_f16 (float16x8_t a, float16x8_t b);
uint32x4_t vcleq_f32 (float32x4_t a, float32x4_t b); // _mm_cmple_ps / _mm_cmpngt_ps
uint64x2_t vcleq_f64 (float64x2_t a, float64x2_t b); // _mm_cmple_pd / _mm_cmpngt_pd
```

#### cmple_mask(mmintrin)

* 运算： `ret.b[i] = a[i] <= b[i] ? 1 : 0` (AVX512)

```c
__mmask16 _mm_cmple_epi8_mask (__m128i a, __m128i b); // | _mm256_cmple_epi8_mask  | _mm512_cmple_epi8_mask
__mmask8 _mm_cmple_epi16_mask (__m128i a, __m128i b); // | _mm256_cmple_epi16_mask | _mm512_cmple_epi16_mask
__mmask8 _mm_cmple_epi32_mask (__m128i a, __m128i b); // | _mm256_cmple_epi32_mask | _mm512_cmple_epi32_mask
__mmask8 _mm_cmple_epi64_mask (__m128i a, __m128i b); // | _mm256_cmple_epi64_mask | _mm512_cmple_epi64_mask
```

```c
__mmask16 _mm_cmple_epu8_mask (__m128i a, __m128i b); // | _mm256_cmple_epu8_mask  | _mm512_cmple_epu8_mask
__mmask8 _mm_cmple_epu16_mask (__m128i a, __m128i b); // | _mm256_cmple_epu16_mask | _mm512_cmple_epu16_mask
__mmask8 _mm_cmple_epu32_mask (__m128i a, __m128i b); // | _mm256_cmple_epu32_mask | _mm512_cmple_epu32_mask
__mmask8 _mm_cmple_epu64_mask (__m128i a, __m128i b); // | _mm256_cmple_epu64_mask | _mm512_cmple_epu64_mask
```

```c
__mmask16 _mm512_cmple_ps_mask (__m512 a, __m512 b);
__mmask8 _mm512_cmple_pd_mask (__m512d a, __m512d b);
```

### 单指令小于等于比较

#### vcle?

* 运算： `ret = a <= b ? 0xFF... : 0`

```c
uint64_t vcled_s64 (int64_t a, int64_t b);
uint64_t vcled_u64 (uint64_t a, uint64_t b);
```

```c
uint32_t vcles_f32 (float32_t a, float32_t b);
uint64_t vcled_f64 (float64_t a, float64_t b);
```

## clez小于等于零比较指令

### 短指令小于等于零比较

#### vclez

* 运算： `ret[i] = a[i] <= 0 ? 0xFF... : 0`

```c
uint8x8_t vclez_s8 (int8x8_t a);
uint16x4_t vclez_s16 (int16x4_t a);
uint32x2_t vclez_s32 (int32x2_t a);
uint64x1_t vclez_s64 (int64x1_t a);
```

```c
uint16x4_t vclez_f16 (float16x4_t a);
uint32x2_t vclez_f32 (float32x2_t a);
uint64x1_t vclez_f64 (float64x1_t a);
```

### 全指令小于等于零比较

#### vclezq

* 运算： `ret[i] = a[i] <= 0 ? 0xFF... : 0`

```c
uint8x16_t vclezq_s8 (int8x16_t a);
uint16x8_t vclezq_s16 (int16x8_t a);
uint32x4_t vclezq_s32 (int32x4_t a);
uint64x2_t vclezq_s64 (int64x2_t a);
```

```c
uint16x8_t vclezq_f16 (float16x8_t a);
uint32x4_t vclezq_f32 (float32x4_t a);
uint64x2_t vclezq_f64 (float64x2_t a);
```

### 单指令小于等于零比较

#### vclez?

* 运算： `ret = a <= 0 ? 0xFF... : 0`

```c
uint64_t vclezd_s64 (int64_t a);
```

```c
uint32_t vclezs_f32 (float32_t a);
uint64_t vclezd_f64 (float64_t a);
```

## cagt绝对值大于

### 短指令绝对值大于

#### vcagt

* 运算： `ret[i] = |a[i]| > |b[i]| ? 0xFF... : 0`

```c
uint32x2_t vcagt_f32 (float32x2_t a, float32x2_t b);
uint64x1_t vcagt_f64 (float64x1_t a, float64x1_t b);
uint16x4_t vcagt_f16 (float16x4_t a, float16x4_t b);
```

### 全指令绝对值大于

#### vcagtq

* 运算： `ret[i] = |a[i]| > |b[i]| ? 0xFF... : 0`

```c
uint16x8_t vcagtq_f16 (float16x8_t a, float16x8_t b);
uint32x4_t vcagtq_f32 (float32x4_t a, float32x4_t b);
uint64x2_t vcagtq_f64 (float64x2_t a, float64x2_t b);
```

### 单指令绝对值大于

#### vcagt?

* 运算： `ret = |a| > |b| ? 0xFF... : 0`

```c
uint32_t vcagts_f32 (float32_t a, float32_t b);
uint64_t vcagtd_f64 (float64_t a, float64_t b);
```

## cage绝对值大于等于

### 短指令绝对值大于等于

#### vcage

* 运算： `ret[i] = |a[i]| >= |b[i]| ? 0xFF... : 0`

```c
uint16x4_t vcage_f16 (float16x4_t a, float16x4_t b);
uint32x2_t vcage_f32 (float32x2_t a, float32x2_t b);
uint64x1_t vcage_f64 (float64x1_t a, float64x1_t b);
```

### 全指令绝对值大于等于

#### vcageq

* 运算： `ret[i] = |a[i]| >= |b[i]| ? 0xFF... : 0`

```c
uint16x8_t vcageq_f16 (float16x8_t a, float16x8_t b);
uint32x4_t vcageq_f32 (float32x4_t a, float32x4_t b);
uint64x2_t vcageq_f64 (float64x2_t a, float64x2_t b);
```

### 单指令绝对值大于等于

#### vcage

* 运算： `ret = |a| >= |b| ? 0xFF... : 0`

```c
uint32_t vcages_f32 (float32_t a, float32_t b);
uint64_t vcaged_f64 (float64_t a, float64_t b);
```

## calt绝对值小于

### 短指令绝对值小于

#### vcalt

* 运算： `ret[i] = |a[i]| < |b[i]| ? 0xFF... : 0`

```c
uint16x4_t vcalt_f16 (float16x4_t a, float16x4_t b);
uint32x2_t vcalt_f32 (float32x2_t a, float32x2_t b);
uint64x1_t vcalt_f64 (float64x1_t a, float64x1_t b);
```

### 全指令绝对值小于

#### vcaltq

* 运算： `ret[i] = |a[i]| < |b[i]| ? 0xFF... : 0`

```c
uint16x8_t vcaltq_f16 (float16x8_t a, float16x8_t b);
uint32x4_t vcaltq_f32 (float32x4_t a, float32x4_t b);
uint64x2_t vcaltq_f64 (float64x2_t a, float64x2_t b);
```

### 单指令绝对值小于

#### vcalt?

* 运算： `ret = |a| < |b| ? 0xFF... : 0`

```c
uint64_t vcaltd_f64 (float64_t a, float64_t b);
uint32_t vcalts_f32 (float32_t a, float32_t b);
```

## cale绝对值小于等于

### 短指令绝对值小于等于

#### vcale

* 运算： `ret[i] = |a[i]| <= |b[i]| ? 0xFF... : 0`

```c
uint16x4_t vcale_f16 (float16x4_t a, float16x4_t b);
uint32x2_t vcale_f32 (float32x2_t a, float32x2_t b);
uint64x1_t vcale_f64 (float64x1_t a, float64x1_t b);
```

### 全指令绝对值小于等于

#### vcaleq

* 运算： `ret[i] = |a[i]| <= |b[i]| ? 0xFF... : 0`

```c
uint16x8_t vcaleq_f16 (float16x8_t a, float16x8_t b);
uint32x4_t vcaleq_f32 (float32x4_t a, float32x4_t b);
uint64x2_t vcaleq_f64 (float64x2_t a, float64x2_t b);
```

### 单指令绝对值小于等于

#### vcale

* 运算： `ret = |a| <= |b| ? 0xFF... : 0`

```c
uint64_t vcaled_f64 (float64_t a, float64_t b);
uint32_t vcales_f32 (float32_t a, float32_t b);
```

## cls前导符号位计数指令

* 从符号位之后开始(即不含符号位)，计算高位部分和符号位相同的连续bit个数

### 短指令前导符号位计数

#### vcls

* 运算： `ret[i] = `CountLeadingSignBits(a[i])`

```c
int8x8_t vcls_s8 (int8x8_t a);
int16x4_t vcls_s16 (int16x4_t a);
int32x2_t vcls_s32 (int32x2_t a);
```

```c
int8x8_t vcls_u8 (uint8x8_t a);
int16x4_t vcls_u16 (uint16x4_t a);
int32x2_t vcls_u32 (uint32x2_t a);
```

### 全指令前导符号位计数

#### vclsq

* 运算： `ret[i] = `CountLeadingSignBits(a[i])`

```c
int8x16_t vclsq_s8 (int8x16_t a);
int16x8_t vclsq_s16 (int16x8_t a);
int32x4_t vclsq_s32 (int32x4_t a);
```

```c
int8x16_t vclsq_u8 (uint8x16_t a);
int16x8_t vclsq_u16 (uint16x8_t a);
int32x4_t vclsq_u32 (uint32x4_t a);
```

## clz前导零位计数指令

* 计算前导零的连续bit个数

### 短指令前导零位计数

#### vclz

* 运算： `ret[i] = `CountLeadingZeroBits(a[i])`

```c
int8x8_t vclz_s8 (int8x8_t a);
int16x4_t vclz_s16 (int16x4_t a);
int32x2_t vclz_s32 (int32x2_t a);
```

```c
uint8x8_t vclz_u8 (uint8x8_t a);
uint16x4_t vclz_u16 (uint16x4_t a);
uint32x2_t vclz_u32 (uint32x2_t a);
```

### 全指令前导零位计数

#### vclzq

* 运算： `ret[i] = `CountLeadingZeroBits(a[i])`

```c
int8x16_t vclzq_s8 (int8x16_t a);
int16x8_t vclzq_s16 (int16x8_t a);
int32x4_t vclzq_s32 (int32x4_t a);
```

```c
uint8x16_t vclzq_u8 (uint8x16_t a);
uint16x8_t vclzq_u16 (uint16x8_t a);
uint32x4_t vclzq_u32 (uint32x4_t a);
```

## cnt位1计数指令

### 短指令位1计数

* 计算位为1的bit个数

#### vcnt

* 运算： `ret[i] = `BitCount(a[i])`

```c
int8x8_t vcnt_s8 (int8x8_t a);
uint8x8_t vcnt_u8 (uint8x8_t a);
poly8x8_t vcnt_p8 (poly8x8_t a);
```

### 全指令位1计数

#### vcntq

* 运算： `ret[i] = `BitCount(a[i])`

```c
int8x16_t vcntq_s8 (int8x16_t a);
uint8x16_t vcntq_u8 (uint8x16_t a);
poly8x16_t vcntq_p8 (poly8x16_t a);
```

## tst逐位测试指令

### 短指令逐位测试

#### vtst

* 运算： `ret[i] = (a[i] & b[i]) != 0 ? 0xFF... : 0`

```c
uint8x8_t vtst_s8 (int8x8_t a, int8x8_t b);
uint16x4_t vtst_s16 (int16x4_t a, int16x4_t b);
uint32x2_t vtst_s32 (int32x2_t a, int32x2_t b);
uint64x1_t vtst_s64 (int64x1_t a, int64x1_t b);
```

```c
uint8x8_t vtst_u8 (uint8x8_t a, uint8x8_t b);
uint16x4_t vtst_u16 (uint16x4_t a, uint16x4_t b);
uint32x2_t vtst_u32 (uint32x2_t a, uint32x2_t b);
uint64x1_t vtst_u64 (uint64x1_t a, uint64x1_t b);
```

```c
uint8x8_t vtst_p8 (poly8x8_t a, poly8x8_t b);
uint16x4_t vtst_p16 (poly16x4_t a, poly16x4_t b);
uint64x1_t vtst_p64 (poly64x1_t a, poly64x1_t b);
```

### 全指令逐位测试

#### vtstq

* 运算： `ret[i] = (a[i] & b[i]) != 0 ? 0xFF... : 0`

```c
uint8x16_t vtstq_s8 (int8x16_t a, int8x16_t b);
uint16x8_t vtstq_s16 (int16x8_t a, int16x8_t b);
uint32x4_t vtstq_s32 (int32x4_t a, int32x4_t b);
uint64x2_t vtstq_s64 (int64x2_t a, int64x2_t b);
```

```c
uint8x16_t vtstq_u8 (uint8x16_t a, uint8x16_t b);
uint16x8_t vtstq_u16 (uint16x8_t a, uint16x8_t b);
uint32x4_t vtstq_u32 (uint32x4_t a, uint32x4_t b);
uint64x2_t vtstq_u64 (uint64x2_t a, uint64x2_t b);
```

```c
uint8x16_t vtstq_p8 (poly8x16_t a, poly8x16_t b);
uint16x8_t vtstq_p16 (poly16x8_t a, poly16x8_t b);
uint64x2_t vtstq_p64 (poly64x2_t a, poly64x2_t b);
```

### 单指令逐位测试

* 运算： `ret = (a & b) != 0 ? 0xFF... : 0`

```c
uint64_t vtstd_s64 (int64_t a, int64_t b);
uint64_t vtstd_u64 (uint64_t a, uint64_t b);
```

## and按位与指令

### 短指令按位与

#### vand

* 运算： `ret[i] = a[i] & b[i]`

```c
// _mm_and_si64 / _m_pand
int8x8_t vand_s8 (int8x8_t a, int8x8_t b);
int16x4_t vand_s16 (int16x4_t a, int16x4_t b);
int32x2_t vand_s32 (int32x2_t a, int32x2_t b);
int64x1_t vand_s64 (int64x1_t a, int64x1_t b);
```

```c
uint8x8_t vand_u8 (uint8x8_t a, uint8x8_t b);
uint16x4_t vand_u16 (uint16x4_t a, uint16x4_t b);
uint32x2_t vand_u32 (uint32x2_t a, uint32x2_t b);
uint64x1_t vand_u64 (uint64x1_t a, uint64x1_t b);
```

### 全指令按位与

#### vandq

* 运算： `ret[i] = a[i] & b[i]`

```c
// _mm_and_si128 | _mm256_and_si256 | _mm512_and_si512
int8x16_t vandq_s8 (int8x16_t a, int8x16_t b);
int16x8_t vandq_s16 (int16x8_t a, int16x8_t b);
int32x4_t vandq_s32 (int32x4_t a, int32x4_t b);
int64x2_t vandq_s64 (int64x2_t a, int64x2_t b);
```

```c
uint8x16_t vandq_u8 (uint8x16_t a, uint8x16_t b);
uint16x8_t vandq_u16 (uint16x8_t a, uint16x8_t b);
uint32x4_t vandq_u32 (uint32x4_t a, uint32x4_t b);
uint64x2_t vandq_u64 (uint64x2_t a, uint64x2_t b);
```

## orr按位或指令

### 短指令按位或

#### vorr

* 运算： `ret[i] = a[i] | b[i]`

```c
// _mm_or_si64 / _m_por
int8x8_t vorr_s8 (int8x8_t a, int8x8_t b);
int16x4_t vorr_s16 (int16x4_t a, int16x4_t b);
int32x2_t vorr_s32 (int32x2_t a, int32x2_t b);
int64x1_t vorr_s64 (int64x1_t a, int64x1_t b);
```

```c
uint8x8_t vorr_u8 (uint8x8_t a, uint8x8_t b);
uint16x4_t vorr_u16 (uint16x4_t a, uint16x4_t b);
uint32x2_t vorr_u32 (uint32x2_t a, uint32x2_t b);
uint64x1_t vorr_u64 (uint64x1_t a, uint64x1_t b);
```

### 全指令按位或

#### vorrq

* 运算： `ret[i] = a[i] | b[i]`

```c
// _mm_or_si128 | _mm256_or_si256 | _mm512_or_si512
int8x16_t vorrq_s8 (int8x16_t a, int8x16_t b);
int16x8_t vorrq_s16 (int16x8_t a, int16x8_t b);
int32x4_t vorrq_s32 (int32x4_t a, int32x4_t b);
int64x2_t vorrq_s64 (int64x2_t a, int64x2_t b);
```

```c
uint8x16_t vorrq_u8 (uint8x16_t a, uint8x16_t b);
uint16x8_t vorrq_u16 (uint16x8_t a, uint16x8_t b);
uint32x4_t vorrq_u32 (uint32x4_t a, uint32x4_t b);
uint64x2_t vorrq_u64 (uint64x2_t a, uint64x2_t b);
```

## eor按位异或指令

### 短指令按位异或

#### veor

* 运算： `ret[i] = a[i] ^ b[i]`

```c
// _mm_xor_si64 / _m_pxor
int8x8_t veor_s8 (int8x8_t a, int8x8_t b);
int16x4_t veor_s16 (int16x4_t a, int16x4_t b);
int32x2_t veor_s32 (int32x2_t a, int32x2_t b);
int64x1_t veor_s64 (int64x1_t a, int64x1_t b);
```

```c
uint8x8_t veor_u8 (uint8x8_t a, uint8x8_t b);
uint16x4_t veor_u16 (uint16x4_t a, uint16x4_t b);
uint32x2_t veor_u32 (uint32x2_t a, uint32x2_t b);
uint64x1_t veor_u64 (uint64x1_t a, uint64x1_t b);
```

### 全指令按位异或

#### veorq

* 运算： `ret[i] = a[i] ^ b[i]`
    * `_mm_xor_epi32` 和 `_mm_xor_epi64`为AVX512指令

```c
// _mm_xor_si128 | _mm256_xor_si256 | _mm512_xor_si512
int8x16_t veorq_s8 (int8x16_t a, int8x16_t b);
int16x8_t veorq_s16 (int16x8_t a, int16x8_t b);
int32x4_t veorq_s32 (int32x4_t a, int32x4_t b); // _mm_xor_epi32 | _mm256_xor_epi32 | _mm512_xor_epi32
int64x2_t veorq_s64 (int64x2_t a, int64x2_t b); // _mm_xor_epi64 | _mm256_xor_epi64 | _mm512_xor_epi64
```

```c
uint8x16_t veorq_u8 (uint8x16_t a, uint8x16_t b);
uint16x8_t veorq_u16 (uint16x8_t a, uint16x8_t b);
uint32x4_t veorq_u32 (uint32x4_t a, uint32x4_t b);
uint64x2_t veorq_u64 (uint64x2_t a, uint64x2_t b);
```

#### veor3q

* 运算： `ret[i] = a[i] ^ b[i] ^ c[i]`

```c
int8x16_t veor3q_s8 (int8x16_t a, int8x16_t b, int8x16_t c);
int16x8_t veor3q_s16 (int16x8_t a, int16x8_t b, int16x8_t c);
int32x4_t veor3q_s32 (int32x4_t a, int32x4_t b, int32x4_t c);
int64x2_t veor3q_s64 (int64x2_t a, int64x2_t b, int64x2_t c);
```

```c
uint8x16_t veor3q_u8 (uint8x16_t a, uint8x16_t b, uint8x16_t c);
uint16x8_t veor3q_u16 (uint16x8_t a, uint16x8_t b, uint16x8_t c);
uint32x4_t veor3q_u32 (uint32x4_t a, uint32x4_t b, uint32x4_t c);
uint64x2_t veor3q_u64 (uint64x2_t a, uint64x2_t b, uint64x2_t c);
```

## bic按位清零指令

### 短指令按位清零

#### vbic

* 运算： `ret[i] = a[i] & (~b[i])`

```c
// _mm_andnot_si64 (b, a) / _m_pandn (b, a)
int8x8_t vbic_s8 (int8x8_t a, int8x8_t b);
int16x4_t vbic_s16 (int16x4_t a, int16x4_t b);
int32x2_t vbic_s32 (int32x2_t a, int32x2_t b);
int64x1_t vbic_s64 (int64x1_t a, int64x1_t b);
```

```c
uint8x8_t vbic_u8 (uint8x8_t a, uint8x8_t b);
uint16x4_t vbic_u16 (uint16x4_t a, uint16x4_t b);
uint32x2_t vbic_u32 (uint32x2_t a, uint32x2_t b);
uint64x1_t vbic_u64 (uint64x1_t a, uint64x1_t b);
```

### 全指令按位清零

#### vbicq

* 运算： `ret[i] = a[i] & (~b[i])`

```c
// _mm_andnot_si128(b, a) | _mm256_andnot_si256 | _mm512_andnot_si512
int8x16_t vbicq_s8 (int8x16_t a, int8x16_t b);
int16x8_t vbicq_s16 (int16x8_t a, int16x8_t b);
int32x4_t vbicq_s32 (int32x4_t a, int32x4_t b);
int64x2_t vbicq_s64 (int64x2_t a, int64x2_t b);
```

```c
uint8x16_t vbicq_u8 (uint8x16_t a, uint8x16_t b);
uint16x8_t vbicq_u16 (uint16x8_t a, uint16x8_t b);
uint32x4_t vbicq_u32 (uint32x4_t a, uint32x4_t b);
uint64x2_t vbicq_u64 (uint64x2_t a, uint64x2_t b);
```

## orn按位或非指令

### 短指令按位或非

* 运算： `ret[i] = a[i] | (~b[i])`

#### vorn

```c
int8x8_t vorn_s8 (int8x8_t a, int8x8_t b);
int16x4_t vorn_s16 (int16x4_t a, int16x4_t b);
int32x2_t vorn_s32 (int32x2_t a, int32x2_t b);
int64x1_t vorn_s64 (int64x1_t a, int64x1_t b);
```

```c
uint8x8_t vorn_u8 (uint8x8_t a, uint8x8_t b);
uint16x4_t vorn_u16 (uint16x4_t a, uint16x4_t b);
uint32x2_t vorn_u32 (uint32x2_t a, uint32x2_t b);
uint64x1_t vorn_u64 (uint64x1_t a, uint64x1_t b);
```

### 全指令按位或非

#### vornq

* 运算： `ret[i] = a[i] | (~b[i])`

```c
int8x16_t vornq_s8 (int8x16_t a, int8x16_t b);
int16x8_t vornq_s16 (int16x8_t a, int16x8_t b);
int32x4_t vornq_s32 (int32x4_t a, int32x4_t b);
int64x2_t vornq_s64 (int64x2_t a, int64x2_t b);
```

```c
uint8x16_t vornq_u8 (uint8x16_t a, uint8x16_t b);
uint16x8_t vornq_u16 (uint16x8_t a, uint16x8_t b);
uint32x4_t vornq_u32 (uint32x4_t a, uint32x4_t b);
uint64x2_t vornq_u64 (uint64x2_t a, uint64x2_t b);
```

## mvn按位取反指令

### 短指令按位取反

#### vmvn

* 运算： `ret[i] = ~a[i]`

```c
int8x8_t vmvn_s8 (int8x8_t a);
int16x4_t vmvn_s16 (int16x4_t a);
int32x2_t vmvn_s32 (int32x2_t a);
```

```c
uint8x8_t vmvn_u8 (uint8x8_t a);
uint16x4_t vmvn_u16 (uint16x4_t a);
uint32x2_t vmvn_u32 (uint32x2_t a);
```

```c
poly8x8_t vmvn_p8 (poly8x8_t a);
```

### 全指令按位取反

#### vmvnq

* 运算： `ret[i] = ~a[i]`

```c
int8x16_t vmvnq_s8 (int8x16_t a);
int16x8_t vmvnq_s16 (int16x8_t a);
int32x4_t vmvnq_s32 (int32x4_t a);
```

```c
uint8x16_t vmvnq_u8 (uint8x16_t a);
uint16x8_t vmvnq_u16 (uint16x8_t a);
uint32x4_t vmvnq_u32 (uint32x4_t a);
```

```c
poly8x16_t vmvnq_p8 (poly8x16_t a);
```

## rbit位翻转指令

### 短指令位翻转

#### vrbit

* 运算： `ret[i] = BitReverse(a[i])`

```c
int8x8_t vrbit_s8 (int8x8_t a);
uint8x8_t vrbit_u8 (uint8x8_t a);
poly8x8_t vrbit_p8 (poly8x8_t a);
```

### 全指令位翻转

#### vrbitq

* 运算： `ret[i] = BitReverse(a[i])`

```c
int8x16_t vrbitq_s8 (int8x16_t a);
uint8x16_t vrbitq_u8 (uint8x16_t a);
poly8x16_t vrbitq_p8 (poly8x16_t a);
```

## bsl按位选择指令

### 短指令按位选择

#### vbsl

```c
int8x8_t vbsl_s8 (uint8x8_t a, int8x8_t b, int8x8_t c);
int16x4_t vbsl_s16 (uint16x4_t a, int16x4_t b, int16x4_t c);
int32x2_t vbsl_s32 (uint32x2_t a, int32x2_t b, int32x2_t c);
int64x1_t vbsl_s64 (uint64x1_t a, int64x1_t b, int64x1_t c);
```

```c
uint8x8_t vbsl_u8 (uint8x8_t a, uint8x8_t b, uint8x8_t c);
uint16x4_t vbsl_u16 (uint16x4_t a, uint16x4_t b, uint16x4_t c);
uint32x2_t vbsl_u32 (uint32x2_t a, uint32x2_t b, uint32x2_t c);
uint64x1_t vbsl_u64 (uint64x1_t a, uint64x1_t b, uint64x1_t c);
```

```c
float16x4_t vbsl_f16 (uint16x4_t a, float16x4_t b, float16x4_t c);
float32x2_t vbsl_f32 (uint32x2_t a, float32x2_t b, float32x2_t c);
float64x1_t vbsl_f64 (uint64x1_t a, float64x1_t b, float64x1_t c);
```

```c
poly8x8_t vbsl_p8 (uint8x8_t a, poly8x8_t b, poly8x8_t c);
poly16x4_t vbsl_p16 (uint16x4_t a, poly16x4_t b, poly16x4_t c);
poly64x1_t vbsl_p64 (uint64x1_t a, poly64x1_t b, poly64x1_t c);
```

### 全指令按位选择

#### vbslq

```c
int8x16_t vbslq_s8 (uint8x16_t a, int8x16_t b, int8x16_t c);
int16x8_t vbslq_s16 (uint16x8_t a, int16x8_t b, int16x8_t c);
int32x4_t vbslq_s32 (uint32x4_t a, int32x4_t b, int32x4_t c);
int64x2_t vbslq_s64 (uint64x2_t a, int64x2_t b, int64x2_t c);
```

```c
uint8x16_t vbslq_u8 (uint8x16_t a, uint8x16_t b, uint8x16_t c);
uint16x8_t vbslq_u16 (uint16x8_t a, uint16x8_t b, uint16x8_t c);
uint32x4_t vbslq_u32 (uint32x4_t a, uint32x4_t b, uint32x4_t c);
uint64x2_t vbslq_u64 (uint64x2_t a, uint64x2_t b, uint64x2_t c);
```

```c
float16x8_t vbslq_f16 (uint16x8_t a, float16x8_t b, float16x8_t c);
float32x4_t vbslq_f32 (uint32x4_t a, float32x4_t b, float32x4_t c);
float64x2_t vbslq_f64 (uint64x2_t a, float64x2_t b, float64x2_t c);
```

```c
poly8x16_t vbslq_p8 (uint8x16_t a, poly8x16_t b, poly8x16_t c);
poly16x8_t vbslq_p16 (uint16x8_t a, poly16x8_t b, poly16x8_t c);
poly64x2_t vbslq_p64 (uint64x2_t a, poly64x2_t b, poly64x2_t c);
```

## shl左移

### 短指令左移

### vshl

* 运算： `ret[i] = a[i] << b[i]`

```c
int8x8_t vshl_s8 (int8x8_t a, int8x8_t b);
int16x4_t vshl_s16 (int16x4_t a, int16x4_t b);
int32x2_t vshl_s32 (int32x2_t a, int32x2_t b);
int64x1_t vshl_s64 (int64x1_t a, int64x1_t b);
```

```c
uint8x8_t vshl_u8 (uint8x8_t a, int8x8_t b);
uint16x4_t vshl_u16 (uint16x4_t a, int16x4_t b);
uint32x2_t vshl_u32 (uint32x2_t a, int32x2_t b);
uint64x1_t vshl_u64 (uint64x1_t a, int64x1_t b);
```

#### vqshl

* 运算： `ret[i] = sat(a[i] << b[i])`

```c
int8x8_t vqshl_s8 (int8x8_t a, int8x8_t b);
int16x4_t vqshl_s16 (int16x4_t a, int16x4_t b);
int32x2_t vqshl_s32 (int32x2_t a, int32x2_t b);
int64x1_t vqshl_s64 (int64x1_t a, int64x1_t b);
```

```c
uint8x8_t vqshl_u8 (uint8x8_t a, int8x8_t b);
uint16x4_t vqshl_u16 (uint16x4_t a, int16x4_t b);
uint32x2_t vqshl_u32 (uint32x2_t a, int32x2_t b);
uint64x1_t vqshl_u64 (uint64x1_t a, int64x1_t b);
```

#### vrshl

* 运算： `ret[i] = a[i] << b[i]`

```c
int8x8_t vrshl_s8 (int8x8_t a, int8x8_t b);
int16x4_t vrshl_s16 (int16x4_t a, int16x4_t b);
int32x2_t vrshl_s32 (int32x2_t a, int32x2_t b);
int64x1_t vrshl_s64 (int64x1_t a, int64x1_t b);
```

```c
uint8x8_t vrshl_u8 (uint8x8_t a, int8x8_t b);
uint16x4_t vrshl_u16 (uint16x4_t a, int16x4_t b);
uint32x2_t vrshl_u32 (uint32x2_t a, int32x2_t b);
uint64x1_t vrshl_u64 (uint64x1_t a, int64x1_t b);
```

#### vqrshl

* 运算： `ret[i] = sat(a[i] << b[i])`

```c
int8x8_t vqrshl_s8 (int8x8_t a, int8x8_t b);
int16x4_t vqrshl_s16 (int16x4_t a, int16x4_t b);
int32x2_t vqrshl_s32 (int32x2_t a, int32x2_t b);
int64x1_t vqrshl_s64 (int64x1_t a, int64x1_t b);
```

```c
uint8x8_t vqrshl_u8 (uint8x8_t a, int8x8_t b);
uint16x4_t vqrshl_u16 (uint16x4_t a, int16x4_t b);
uint32x2_t vqrshl_u32 (uint32x2_t a, int32x2_t b);
uint64x1_t vqrshl_u64 (uint64x1_t a, int64x1_t b);
```

#### vshl_n

* 运算： `ret[i] = a[i] << n`

```c
int8x8_t vshl_n_s8 (int8x8_t a, const int n);
int16x4_t vshl_n_s16 (int16x4_t a, const int n); // _mm_slli_pi16 / _m_psllwi
                                                 // _mm_sll_pi16  / _m_psllw
int32x2_t vshl_n_s32 (int32x2_t a, const int n); // _mm_slli_pi32 / _m_pslldi
                                                 // _mm_sll_pi32  / _m_pslld
int64x1_t vshl_n_s64 (int64x1_t a, const int n); // _mm_slli_pi32 / _m_pslldi
                                                 // _mm_sll_pi32  / _m_pslld
```

```c
uint8x8_t vshl_n_u8 (uint8x8_t a, const int n);
uint16x4_t vshl_n_u16 (uint16x4_t a, const int n);
uint32x2_t vshl_n_u32 (uint32x2_t a, const int n);
uint64x1_t vshl_n_u64 (uint64x1_t a, const int n);
```

#### vqshl_n

* 运算： `ret[i] = sat(a[i] << n)`

```c
int8x8_t vqshl_n_s8 (int8x8_t a, const int n);
int16x4_t vqshl_n_s16 (int16x4_t a, const int n);
int32x2_t vqshl_n_s32 (int32x2_t a, const int n);
int64x1_t vqshl_n_s64 (int64x1_t a, const int n);
```

```c
uint8x8_t vqshl_n_u8 (uint8x8_t a, const int n);
uint16x4_t vqshl_n_u16 (uint16x4_t a, const int n);
uint32x2_t vqshl_n_u32 (uint32x2_t a, const int n);
uint64x1_t vqshl_n_u64 (uint64x1_t a, const int n);
```

#### vqshlu_n

* 运算： `ret[i] = sat(a[i] << n)`

```c
uint8x8_t vqshlu_n_s8 (int8x8_t a, const int n);
uint16x4_t vqshlu_n_s16 (int16x4_t a, const int n);
uint32x2_t vqshlu_n_s32 (int32x2_t a, const int n);
uint64x1_t vqshlu_n_s64 (int64x1_t a, const int n);
```

### 全指令左移

#### vshlq

* 运算： `ret[i] = a[i] << b[i]`
    * `_mm_sllv_epi32` `_mm_sllv_epi64` 为AVX指令
    * 16位操作为AVX512指令

```c
int8x16_t vshlq_s8 (int8x16_t a, int8x16_t b);
int16x8_t vshlq_s16 (int16x8_t a, int16x8_t b); // _mm_sllv_epi16 | _mm256_sllv_epi16 | _mm512_sllv_epi16
int32x4_t vshlq_s32 (int32x4_t a, int32x4_t b); // _mm_sllv_epi32 | _mm256_sllv_epi32 | _mm512_sllv_epi32
int64x2_t vshlq_s64 (int64x2_t a, int64x2_t b); // _mm_sllv_epi64 | _mm256_sllv_epi64 | _mm512_sllv_epi64
```

```c
uint8x16_t vshlq_u8 (uint8x16_t a, int8x16_t b);
uint16x8_t vshlq_u16 (uint16x8_t a, int16x8_t b);
uint32x4_t vshlq_u32 (uint32x4_t a, int32x4_t b);
uint64x2_t vshlq_u64 (uint64x2_t a, int64x2_t b);
```

#### vqshlq

* 运算： `ret[i] = sat(a[i] << b[i])`

```c
int8x16_t vqshlq_s8 (int8x16_t a, int8x16_t b);
int16x8_t vqshlq_s16 (int16x8_t a, int16x8_t b);
int32x4_t vqshlq_s32 (int32x4_t a, int32x4_t b);
int64x2_t vqshlq_s64 (int64x2_t a, int64x2_t b);
```

```c
uint8x16_t vqshlq_u8 (uint8x16_t a, int8x16_t b);
uint16x8_t vqshlq_u16 (uint16x8_t a, int16x8_t b);
uint32x4_t vqshlq_u32 (uint32x4_t a, int32x4_t b);
uint64x2_t vqshlq_u64 (uint64x2_t a, int64x2_t b);
```

#### vrshlq

* 运算： `ret[i] = a[i] << b[i]`

```c
int8x16_t vrshlq_s8 (int8x16_t a, int8x16_t b);
int16x8_t vrshlq_s16 (int16x8_t a, int16x8_t b);
int32x4_t vrshlq_s32 (int32x4_t a, int32x4_t b);
int64x2_t vrshlq_s64 (int64x2_t a, int64x2_t b);
```

```c
uint8x16_t vrshlq_u8 (uint8x16_t a, int8x16_t b);
uint16x8_t vrshlq_u16 (uint16x8_t a, int16x8_t b);
uint32x4_t vrshlq_u32 (uint32x4_t a, int32x4_t b);
uint64x2_t vrshlq_u64 (uint64x2_t a, int64x2_t b);
```

#### vqrshlq

* 运算： `ret[i] = sat(a[i] << b[i])`

```c
int8x16_t vqrshlq_s8 (int8x16_t a, int8x16_t b);
int16x8_t vqrshlq_s16 (int16x8_t a, int16x8_t b);
int32x4_t vqrshlq_s32 (int32x4_t a, int32x4_t b);
int64x2_t vqrshlq_s64 (int64x2_t a, int64x2_t b);
```

```c
uint8x16_t vqrshlq_u8 (uint8x16_t a, int8x16_t b);
uint16x8_t vqrshlq_u16 (uint16x8_t a, int16x8_t b);
uint32x4_t vqrshlq_u32 (uint32x4_t a, int32x4_t b);
uint64x2_t vqrshlq_u64 (uint64x2_t a, int64x2_t b);
```

#### vshlq_n

* 运算： `ret[i] = a[i] << n`

```c
int8x16_t vshlq_n_s8 (int8x16_t a, const int n);
int16x8_t vshlq_n_s16 (int16x8_t a, const int n); // _mm_slli_epi16 | _mm256_slli_epi16 | _mm512_slli_epi16
                                                  // _mm_sll_epi16  | _mm256_sll_epi16  | _mm512_sll_epi16
int32x4_t vshlq_n_s32 (int32x4_t a, const int n); // _mm_slli_epi32 | _mm256_slli_epi32 | _mm512_slli_epi32
                                                  // _mm_sll_epi32  | _mm256_sll_epi32  | _mm512_sll_epi32
int64x2_t vshlq_n_s64 (int64x2_t a, const int n); // _mm_slli_epi64 | _mm256_slli_epi64 | _mm512_slli_epi64
                                                  // _mm_sll_epi64  | _mm256_sll_epi64  | _mm512_sll_epi64
```

```c
uint8x16_t vshlq_n_u8 (uint8x16_t a, const int n);
uint16x8_t vshlq_n_u16 (uint16x8_t a, const int n);
uint32x4_t vshlq_n_u32 (uint32x4_t a, const int n);
uint64x2_t vshlq_n_u64 (uint64x2_t a, const int n);
```

#### vqshlq_n

* 运算： `ret[i] = sat(a[i] << n)`

```c
int8x16_t vqshlq_n_s8 (int8x16_t a, const int n);
int16x8_t vqshlq_n_s16 (int16x8_t a, const int n);
int32x4_t vqshlq_n_s32 (int32x4_t a, const int n);
int64x2_t vqshlq_n_s64 (int64x2_t a, const int n);
```

```c
uint8x16_t vqshlq_n_u8 (uint8x16_t a, const int n);
uint16x8_t vqshlq_n_u16 (uint16x8_t a, const int n);
uint32x4_t vqshlq_n_u32 (uint32x4_t a, const int n);
uint64x2_t vqshlq_n_u64 (uint64x2_t a, const int n);
```

#### vqshluq_n

* 运算： `ret[i] = sat(a[i] << n)`

```c
uint8x16_t vqshluq_n_s8 (int8x16_t a, const int n);
uint16x8_t vqshluq_n_s16 (int16x8_t a, const int n);
uint32x4_t vqshluq_n_s32 (int32x4_t a, const int n);
uint64x2_t vqshluq_n_s64 (int64x2_t a, const int n);
```

### 长指令左移

#### vshll_n

* 运算： `ret[i] = a[i] << n`

```c
int16x8_t vshll_n_s8 (int8x8_t a, const int n);
int32x4_t vshll_n_s16 (int16x4_t a, const int n);
int64x2_t vshll_n_s32 (int32x2_t a, const int n);
```

```c
uint16x8_t vshll_n_u8 (uint8x8_t a, const int n);
uint32x4_t vshll_n_u16 (uint16x4_t a, const int n);
uint64x2_t vshll_n_u32 (uint32x2_t a, const int n);
```

#### vshll_high_n

* 运算： `ret[i] = a[N+i] << n`

```c
int16x8_t vshll_high_n_s8 (int8x16_t a, const int n);
int32x4_t vshll_high_n_s16 (int16x8_t a, const int n);
int64x2_t vshll_high_n_s32 (int32x4_t a, const int n);
```

```c
uint16x8_t vshll_high_n_u8 (uint8x16_t a, const int n);
uint32x4_t vshll_high_n_u16 (uint16x8_t a, const int n);
uint64x2_t vshll_high_n_u32 (uint32x4_t a, const int n);
```

### 单指令左移

#### vshl?

* 运算： `ret = a << b`

```c
int64_t vshld_s64 (int64_t a, int64_t b);
uint64_t vshld_u64 (uint64_t a, int64_t b);
```

#### vqshl?

* 运算： `ret = sat(a << b)`

```c
int8_t vqshlb_s8 (int8_t a, int8_t b);
int16_t vqshlh_s16 (int16_t a, int16_t b);
int32_t vqshls_s32 (int32_t a, int32_t b);
int64_t vqshld_s64 (int64_t a, int64_t b);
```

```c
uint8_t vqshlb_u8 (uint8_t a, int8_t b);
uint16_t vqshlh_u16 (uint16_t a, int16_t b);
uint32_t vqshls_u32 (uint32_t a, int32_t b);
uint64_t vqshld_u64 (uint64_t a, int64_t b);
```

#### vrshl?

* 运算： `ret = a << b`

```c
int64_t vrshld_s64 (int64_t a, int64_t b);
uint64_t vrshld_u64 (uint64_t a, int64_t b);
```

#### vqrshl?

* 运算： `ret = sat(a << b)`

```c
int8_t vqrshlb_s8 (int8_t a, int8_t b);
int16_t vqrshlh_s16 (int16_t a, int16_t b);
int32_t vqrshls_s32 (int32_t a, int32_t b);
int64_t vqrshld_s64 (int64_t a, int64_t b);
```

```c
uint8_t vqrshlb_u8 (uint8_t a, int8_t b);
uint16_t vqrshlh_u16 (uint16_t a, int16_t b);
uint32_t vqrshls_u32 (uint32_t a, int32_t b);
uint64_t vqrshld_u64 (uint64_t a, int64_t b);
```

#### vshl?_n

* 运算： `ret = a << n`

```c
int64_t vshld_n_s64 (int64_t a, const int n);
uint64_t vshld_n_u64 (uint64_t a, const int n);
```

#### vqshl?_n

* 运算： `ret = sat(a << n)`

```c
int8_t vqshlb_n_s8 (int8_t a, const int n);
int16_t vqshlh_n_s16 (int16_t a, const int n);
int32_t vqshls_n_s32 (int32_t a, const int n);
int64_t vqshld_n_s64 (int64_t a, const int n);
```

```c
uint8_t vqshlb_n_u8 (uint8_t a, const int n);
uint16_t vqshlh_n_u16 (uint16_t a, const int n);
uint32_t vqshls_n_u32 (uint32_t a, const int n);
uint64_t vqshld_n_u64 (uint64_t a, const int n);
```

#### vqshlun?_n

* 运算： `ret = sat(a << n)`

```c
int8_t vqshlub_n_s8 (int8_t a, const int n);
int16_t vqshluh_n_s16 (int16_t a, const int n);
int32_t vqshlus_n_s32 (int32_t a, const int n);
uint64_t vqshlud_n_s64 (int64_t a, const int n);
```

## shr右移

### 短指令右移

#### vshr_n

* 运算： `ret[i] = a[i] >> n`
    * `srl` 高位补0，`sra` 高位补符号位

```c
int8x8_t vshr_n_s8 (int8x8_t a, const int n);
int16x4_t vshr_n_s16 (int16x4_t a, const int n);   // _mm_srai_pi16 / _m_psrawi
                                                   // _mm_sra_pi16  / _m_psraw
int32x2_t vshr_n_s32 (int32x2_t a, const int n);   // _mm_srai_pi32 / _m_psradi
                                                   // _mm_sra_pi32  / _m_psrad
int64x1_t vshr_n_s64 (int64x1_t a, const int n);
```

```c
uint8x8_t vshr_n_u8 (uint8x8_t a, const int n);
uint16x4_t vshr_n_u16 (uint16x4_t a, const int n); // _mm_srli_pi16 / _m_psrlwi
                                                   // _mm_srl_pi16  / _m_psrlw
uint32x2_t vshr_n_u32 (uint32x2_t a, const int n); // _mm_srli_pi32 / _m_psrldi
                                                   // _mm_srl_pi32  / _m_psrld
uint64x1_t vshr_n_u64 (uint64x1_t a, const int n); // _mm_srli_si64 / _m_psrlqi
                                                   // _mm_srl_si64  / _m_psrlq
```

#### vrshr_n

* 运算： `ret[i] = (a[i] + (1<<(n-1))) >> n`

```c
int8x8_t vrshr_n_s8 (int8x8_t a, const int n);
int16x4_t vrshr_n_s16 (int16x4_t a, const int n);
int32x2_t vrshr_n_s32 (int32x2_t a, const int n);
int64x1_t vrshr_n_s64 (int64x1_t a, const int n);
```

```c
uint8x8_t vrshr_n_u8 (uint8x8_t a, const int n);
uint16x4_t vrshr_n_u16 (uint16x4_t a, const int n);
uint32x2_t vrshr_n_u32 (uint32x2_t a, const int n);
uint64x1_t vrshr_n_u64 (uint64x1_t a, const int n);
```

### 全指令右移

#### vshrq_n

* 运算： `ret[i] = a[i] >> n`
    * `srl` 高位补0，`sra` 高位补符号位

```c
int8x16_t vshrq_n_s8 (int8x16_t a, const int n);
int16x8_t vshrq_n_s16 (int16x8_t a, const int n);   // _mm_srai_epi16 | _mm256_srai_epi16 | _mm512_srai_epi16
                                                    // _mm_sra_epi16  | _mm256_sra_epi16  | _mm512_sra_epi16
int32x4_t vshrq_n_s32 (int32x4_t a, const int n);   // _mm_srai_epi32 | _mm256_srai_epi32 | _mm512_srai_epi32
                                                    // _mm_sra_epi32  | _mm256_sra_epi32  | _mm512_sra_epi32
int64x2_t vshrq_n_s64 (int64x2_t a, const int n);
```

```c
uint8x16_t vshrq_n_u8 (uint8x16_t a, const int n);
uint16x8_t vshrq_n_u16 (uint16x8_t a, const int n); // _mm_srli_epi16 | _mm256_srli_epi16 | _mm512_srli_epi16
                                                    // _mm_srl_epi16  | _mm256_srl_epi16  | _mm512_srl_epi16
uint32x4_t vshrq_n_u32 (uint32x4_t a, const int n); // _mm_srli_epi32 | _mm256_srli_epi32 | _mm512_srli_epi32
                                                    // _mm_srl_epi32  | _mm256_srl_epi32  | _mm512_srl_epi32
uint64x2_t vshrq_n_u64 (uint64x2_t a, const int n); // _mm_srli_epi64 | _mm256_srli_epi64 | _mm512_srli_epi64
                                                    // _mm_srl_epi64  | _mm256_srl_epi64  | _mm512_srl_epi64
```

#### vrshrq_n

* 运算： `ret[i] = (a[i] + (1<<(n-1))) >> n`

```c
int8x16_t vrshrq_n_s8 (int8x16_t a, const int n);
int16x8_t vrshrq_n_s16 (int16x8_t a, const int n);
int32x4_t vrshrq_n_s32 (int32x4_t a, const int n);
int64x2_t vrshrq_n_s64 (int64x2_t a, const int n);
```

```c
uint8x16_t vrshrq_n_u8 (uint8x16_t a, const int n);
uint16x8_t vrshrq_n_u16 (uint16x8_t a, const int n);
uint32x4_t vrshrq_n_u32 (uint32x4_t a, const int n);
uint64x2_t vrshrq_n_u64 (uint64x2_t a, const int n);
```

### 窄指令右移

#### vshrn_n

* 运算： `ret[i] = a[i] >> n`

```c
int8x8_t vshrn_n_s16 (int16x8_t a, const int n);
int16x4_t vshrn_n_s32 (int32x4_t a, const int n);
int32x2_t vshrn_n_s64 (int64x2_t a, const int n);
```

```c
uint8x8_t vshrn_n_u16 (uint16x8_t a, const int n);
uint16x4_t vshrn_n_u32 (uint32x4_t a, const int n);
uint32x2_t vshrn_n_u64 (uint64x2_t a, const int n);
```

#### vqshrn_n

* 运算： `ret[i] = sat(a[i] >> n)`

```c
int8x8_t vqshrn_n_s16 (int16x8_t a, const int n);
int16x4_t vqshrn_n_s32 (int32x4_t a, const int n);
int32x2_t vqshrn_n_s64 (int64x2_t a, const int n);
```

```c
uint8x8_t vqshrn_n_u16 (uint16x8_t a, const int n);
uint16x4_t vqshrn_n_u32 (uint32x4_t a, const int n);
uint32x2_t vqshrn_n_u64 (uint64x2_t a, const int n);
```

#### vqshrun_n

* 运算： `ret[i] = sat(a[i] >> n)`

```c
uint8x8_t vqshrun_n_s16 (int16x8_t a, const int n);
uint16x4_t vqshrun_n_s32 (int32x4_t a, const int n);
uint32x2_t vqshrun_n_s64 (int64x2_t a, const int n);
```

#### vrshrn_n

* 运算： `ret[i] = (a[i] + (1<<(n-1))) >> n`

```c
int8x8_t vrshrn_n_s16 (int16x8_t a, const int n);
int16x4_t vrshrn_n_s32 (int32x4_t a, const int n);
int32x2_t vrshrn_n_s64 (int64x2_t a, const int n);
```

```c
uint8x8_t vrshrn_n_u16 (uint16x8_t a, const int n);
uint16x4_t vrshrn_n_u32 (uint32x4_t a, const int n);
uint32x2_t vrshrn_n_u64 (uint64x2_t a, const int n);
```

#### vqrshrn_n

* 运算： `ret[i] = sat((a[i] + (1<<(n-1))) >> n)`

```c
int8x8_t vqrshrn_n_s16 (int16x8_t a, const int n);
int16x4_t vqrshrn_n_s32 (int32x4_t a, const int n);
int32x2_t vqrshrn_n_s64 (int64x2_t a, const int n);
```

```c
uint8x8_t vqrshrn_n_u16 (uint16x8_t a, const int n);
uint16x4_t vqrshrn_n_u32 (uint32x4_t a, const int n);
uint32x2_t vqrshrn_n_u64 (uint64x2_t a, const int n);
```

#### vqrshrun_n

* 运算： `ret[i] = sat((a[i] + (1<<(n-1))) >> n)`

```c
uint8x8_t vqrshrun_n_s16 (int16x8_t a, const int n);
uint16x4_t vqrshrun_n_s32 (int32x4_t a, const int n);
uint32x2_t vqrshrun_n_s64 (int64x2_t a, const int n);
```

#### vshrn_high_n

* 运算： 0~N/2-1 : `ret[i] = r[i]` ; N/2~N-1 : `ret[N/2+i] = a[i] >> n`

```c
int8x16_t vshrn_high_n_s16 (int8x8_t r, int16x8_t a, const int n);
int16x8_t vshrn_high_n_s32 (int16x4_t r, int32x4_t a, const int n);
int32x4_t vshrn_high_n_s64 (int32x2_t r, int64x2_t a, const int n);
```

```c
uint8x16_t vshrn_high_n_u16 (uint8x8_t r, uint16x8_t a, const int n);
uint16x8_t vshrn_high_n_u32 (uint16x4_t r, uint32x4_t a, const int n);
uint32x4_t vshrn_high_n_u64 (uint32x2_t r, uint64x2_t a, const int n);
```

#### vqshrn_high_n

* 运算： 0~N/2-1 : `ret[i] = r[i]` ; N/2~N-1 : `ret[N/2+i] = sat(a[i] >> n)`

```c
int8x16_t vqshrn_high_n_s16 (int8x8_t r, int16x8_t a, const int n);
int16x8_t vqshrn_high_n_s32 (int16x4_t r, int32x4_t a, const int n);
int32x4_t vqshrn_high_n_s64 (int32x2_t r, int64x2_t a, const int n);
```

```c
uint8x16_t vqshrn_high_n_u16 (uint8x8_t r, uint16x8_t a, const int n);
uint16x8_t vqshrn_high_n_u32 (uint16x4_t r, uint32x4_t a, const int n);
uint32x4_t vqshrn_high_n_u64 (uint32x2_t r, uint64x2_t a, const int n);
```

#### vqshrun_high_n

* 运算： 0~N/2-1 : `ret[i] = r[i]` ; N/2~N-1 : `ret[N/2+i] = sat(a[i] >> n)`

```c
uint8x16_t vqshrun_high_n_s16 (uint8x8_t r, int16x8_t a, const int n);
uint16x8_t vqshrun_high_n_s32 (uint16x4_t r, int32x4_t a, const int n);
uint32x4_t vqshrun_high_n_s64 (uint32x2_t r, int64x2_t a, const int n);
```

#### vrshrn_high_n

* 运算： 0~N/2-1 : `ret[i] = r[i]` ; N/2~N-1 : `ret[N/2+i] = (a[i] + (1<<(n-1))) >> n`

```c
int8x16_t vrshrn_high_n_s16 (int8x8_t r, int16x8_t a, const int n);
int16x8_t vrshrn_high_n_s32 (int16x4_t r, int32x4_t a, const int n);
int32x4_t vrshrn_high_n_s64 (int32x2_t r, int64x2_t a, const int n);
```

```c
uint8x16_t vrshrn_high_n_u16 (uint8x8_t r, uint16x8_t a, const int n);
uint16x8_t vrshrn_high_n_u32 (uint16x4_t r, uint32x4_t a, const int n);
uint32x4_t vrshrn_high_n_u64 (uint32x2_t r, uint64x2_t a, const int n);
```

#### vqrshrn_high_n

* 运算： 0~N/2-1 : `ret[i] = r[i]` ; N/2~N-1 : `ret[N/2+i] = sat((a[i] + (1<<(n-1))) >> n)`

```c
int8x16_t vqrshrn_high_n_s16 (int8x8_t r, int16x8_t a, const int n);
int16x8_t vqrshrn_high_n_s32 (int16x4_t r, int32x4_t a, const int n);
int32x4_t vqrshrn_high_n_s64 (int32x2_t r, int64x2_t a, const int n);
```

```c
uint8x16_t vqrshrn_high_n_u16 (uint8x8_t r, uint16x8_t a, const int n);
uint16x8_t vqrshrn_high_n_u32 (uint16x4_t r, uint32x4_t a, const int n);
uint32x4_t vqrshrn_high_n_u64 (uint32x2_t r, uint64x2_t a, const int n);
```

#### vqrshrun_high_n

* 运算： 0~N/2-1 : `ret[i] = r[i]` ; N/2~N-1 : `ret[N/2+i] = (a[i] + (1<<(n-1))) >> n`

```c
uint8x16_t vqrshrun_high_n_s16 (uint8x8_t r, int16x8_t a, const int n);
uint16x8_t vqrshrun_high_n_s32 (uint16x4_t r, int32x4_t a, const int n);
uint32x4_t vqrshrun_high_n_s64 (uint32x2_t r, int64x2_t a, const int n);
```

### 单指令右移

#### vshr?_n

* 运算： `ret = a >> n`

```c
int64_t vshrd_n_s64 (int64_t a, const int n);
uint64_t vshrd_n_u64 (uint64_t a, const int n);
```

#### vrshr?_n

* 运算： `ret = (a + (1<<(n-1))) >> n`

```c
int64_t vrshrd_n_s64 (int64_t a, const int n);
uint64_t vrshrd_n_u64 (uint64_t a, const int n);
```

#### vqshrn?_n

* 运算： `ret = sat(a >> n)`

```c
int8_t vqshrnh_n_s16 (int16_t a, const int n);
int16_t vqshrns_n_s32 (int32_t a, const int n);
int32_t vqshrnd_n_s64 (int64_t a, const int n);
```

```c
uint8_t vqshrnh_n_u16 (uint16_t a, const int n);
uint16_t vqshrns_n_u32 (uint32_t a, const int n);
uint32_t vqshrnd_n_u64 (uint64_t a, const int n);
```

#### vqshrun?_n

* 运算： `ret = sat(a >> n)`

```c
int8_t vqshrunh_n_s16 (int16_t a, const int n);
int16_t vqshruns_n_s32 (int32_t a, const int n);
int32_t vqshrund_n_s64 (int64_t a, const int n);
```

#### vqrshrn?_n

* 运算： `ret = sat((a + (1<<(n-1))) >> n)`

```c
int8_t vqrshrnh_n_s16 (int16_t a, const int n);
int16_t vqrshrns_n_s32 (int32_t a, const int n);
int32_t vqrshrnd_n_s64 (int64_t a, const int n);
```

```c
uint8_t vqrshrnh_n_u16 (uint16_t a, const int n);
uint16_t vqrshrns_n_u32 (uint32_t a, const int n);
uint32_t vqrshrnd_n_u64 (uint64_t a, const int n);
```

#### vqrshrun?_n

* 运算： `ret = sat((a + (1<<(n-1))) >> n)`

```c
int8_t vqrshrunh_n_s16 (int16_t a, const int n);
int16_t vqrshruns_n_s32 (int32_t a, const int n);
int32_t vqrshrund_n_s64 (int64_t a, const int n);
```

## sli左移插入

### 短指令左移插入

* 运算： `ret[i] = (a[i] & ~(~0<<n)) | (b[i] << n)`

#### vsli_n

```c
int8x8_t vsli_n_s8 (int8x8_t a, int8x8_t b, const int n);
int16x4_t vsli_n_s16 (int16x4_t a, int16x4_t b, const int n);
int32x2_t vsli_n_s32 (int32x2_t a, int32x2_t b, const int n);
int64x1_t vsli_n_s64 (int64x1_t a, int64x1_t b, const int n);
```

```c
uint8x8_t vsli_n_u8 (uint8x8_t a, uint8x8_t b, const int n);
uint16x4_t vsli_n_u16 (uint16x4_t a, uint16x4_t b, const int n);
uint32x2_t vsli_n_u32 (uint32x2_t a, uint32x2_t b, const int n);
uint64x1_t vsli_n_u64 (uint64x1_t a, uint64x1_t b, const int n);
```

```c
poly8x8_t vsli_n_p8 (poly8x8_t a, poly8x8_t b, const int n);
poly16x4_t vsli_n_p16 (poly16x4_t a, poly16x4_t b, const int n);
poly64x1_t vsli_n_p64 (poly64x1_t a, poly64x1_t b, const int n);
```

### 全指令左移插入

#### vsliq_n

* 运算： `ret[i] = (a[i] & ~(~0<<n)) | (b[i] << n)`

```c
int8x16_t vsliq_n_s8 (int8x16_t a, int8x16_t b, const int n);
int16x8_t vsliq_n_s16 (int16x8_t a, int16x8_t b, const int n);
int32x4_t vsliq_n_s32 (int32x4_t a, int32x4_t b, const int n);
int64x2_t vsliq_n_s64 (int64x2_t a, int64x2_t b, const int n);
```

```c
uint8x16_t vsliq_n_u8 (uint8x16_t a, uint8x16_t b, const int n);
uint16x8_t vsliq_n_u16 (uint16x8_t a, uint16x8_t b, const int n);
uint32x4_t vsliq_n_u32 (uint32x4_t a, uint32x4_t b, const int n);
uint64x2_t vsliq_n_u64 (uint64x2_t a, uint64x2_t b, const int n);
```

```c
poly8x16_t vsliq_n_p8 (poly8x16_t a, poly8x16_t b, const int n);
poly16x8_t vsliq_n_p16 (poly16x8_t a, poly16x8_t b, const int n);
poly64x2_t vsliq_n_p64 (poly64x2_t a, poly64x2_t b, const int n);
```

### 单指令左移插入

#### vsli?_n

* 运算： `ret = (a & ~(~0<<n)) | (b << n)`

```c
int64_t vslid_n_s64 (int64_t a, int64_t b, const int n);
uint64_t vslid_n_u64 (uint64_t a, uint64_t b, const int n);
```

## sri右移插入

### 短指令右移插入

#### vsri_n

* 运算： `ret[i] = (a[i] & (~0<<(L-n))) | (b[i] >> n)`

```c
int8x8_t vsri_n_s8 (int8x8_t a, int8x8_t b, const int n);
int16x4_t vsri_n_s16 (int16x4_t a, int16x4_t b, const int n);
int32x2_t vsri_n_s32 (int32x2_t a, int32x2_t b, const int n);
int64x1_t vsri_n_s64 (int64x1_t a, int64x1_t b, const int n);
```

```c
uint8x8_t vsri_n_u8 (uint8x8_t a, uint8x8_t b, const int n);
uint16x4_t vsri_n_u16 (uint16x4_t a, uint16x4_t b, const int n);
uint32x2_t vsri_n_u32 (uint32x2_t a, uint32x2_t b, const int n);
uint64x1_t vsri_n_u64 (uint64x1_t a, uint64x1_t b, const int n);
```

```c
poly8x8_t vsri_n_p8 (poly8x8_t a, poly8x8_t b, const int n);
poly16x4_t vsri_n_p16 (poly16x4_t a, poly16x4_t b, const int n);
poly64x1_t vsri_n_p64 (poly64x1_t a, poly64x1_t b, const int n);
```

### 全指令右移插入

#### vsriq_n

* 运算： `ret[i] = (a[i] & (~0<<(L-n))) | (b[i] >> n)`

```c
int8x16_t vsriq_n_s8 (int8x16_t a, int8x16_t b, const int n);
int16x8_t vsriq_n_s16 (int16x8_t a, int16x8_t b, const int n);
int32x4_t vsriq_n_s32 (int32x4_t a, int32x4_t b, const int n);
int64x2_t vsriq_n_s64 (int64x2_t a, int64x2_t b, const int n);
```

```c
uint8x16_t vsriq_n_u8 (uint8x16_t a, uint8x16_t b, const int n);
uint16x8_t vsriq_n_u16 (uint16x8_t a, uint16x8_t b, const int n);
uint32x4_t vsriq_n_u32 (uint32x4_t a, uint32x4_t b, const int n);
uint64x2_t vsriq_n_u64 (uint64x2_t a, uint64x2_t b, const int n);
```

```c
poly8x16_t vsriq_n_p8 (poly8x16_t a, poly8x16_t b, const int n);
poly16x8_t vsriq_n_p16 (poly16x8_t a, poly16x8_t b, const int n);
poly64x2_t vsriq_n_p64 (poly64x2_t a, poly64x2_t b, const int n);
```

### 单指令右移插入

#### vsri?_n

* 运算： `ret = (a & (~0<<(L-n))) | (b >> n)`

```c
int64_t vsrid_n_s64 (int64_t a, int64_t b, const int n);
uint64_t vsrid_n_u64 (uint64_t a, uint64_t b, const int n);
```

## sra右移累加

### 短指令右移累加

#### vsra_n

* 运算： `ret[i] = r[i] + (a[i] >> n)`

```c
int8x8_t vsra_n_s8 (int8x8_t r, int8x8_t a, const int n);
int16x4_t vsra_n_s16 (int16x4_t r, int16x4_t a, const int n);
int32x2_t vsra_n_s32 (int32x2_t r, int32x2_t a, const int n);
int64x1_t vsra_n_s64 (int64x1_t r, int64x1_t a, const int n);
```

```c
uint8x8_t vsra_n_u8 (uint8x8_t r, uint8x8_t a, const int n);
uint16x4_t vsra_n_u16 (uint16x4_t r, uint16x4_t a, const int n);
uint32x2_t vsra_n_u32 (uint32x2_t r, uint32x2_t a, const int n);
uint64x1_t vsra_n_u64 (uint64x1_t r, uint64x1_t a, const int n);
```

#### vrsra_n

* 运算： `ret[i] = r[i] + ((a[i] + (1<<(n-1))) >> n)`

```c
int8x8_t vrsra_n_s8 (int8x8_t r, int8x8_t a, const int n);
int16x4_t vrsra_n_s16 (int16x4_t r, int16x4_t a, const int n);
int32x2_t vrsra_n_s32 (int32x2_t r, int32x2_t a, const int n);
int64x1_t vrsra_n_s64 (int64x1_t r, int64x1_t a, const int n);
```

```c
uint8x8_t vrsra_n_u8 (uint8x8_t r, uint8x8_t a, const int n);
uint16x4_t vrsra_n_u16 (uint16x4_t r, uint16x4_t a, const int n);
uint32x2_t vrsra_n_u32 (uint32x2_t r, uint32x2_t a, const int n);
uint64x1_t vrsra_n_u64 (uint64x1_t r, uint64x1_t a, const int n);
```

### 全指令右移累加

#### vsraq_n

* 运算： `ret[i] = r[i] + (a[i] >> n)`

```c
int8x16_t vsraq_n_s8 (int8x16_t r, int8x16_t a, const int n);
int16x8_t vsraq_n_s16 (int16x8_t r, int16x8_t a, const int n);
int32x4_t vsraq_n_s32 (int32x4_t r, int32x4_t a, const int n);
int64x2_t vsraq_n_s64 (int64x2_t r, int64x2_t a, const int n);
```

```c
uint8x16_t vsraq_n_u8 (uint8x16_t r, uint8x16_t a, const int n);
uint16x8_t vsraq_n_u16 (uint16x8_t r, uint16x8_t a, const int n);
uint32x4_t vsraq_n_u32 (uint32x4_t r, uint32x4_t a, const int n);
uint64x2_t vsraq_n_u64 (uint64x2_t r, uint64x2_t a, const int n);
```

#### vrsraq_n

* 运算： `ret[i] = r[i] + ((a[i] + (1<<(n-1))) >> n)`

```c
int8x16_t vrsraq_n_s8 (int8x16_t r, int8x16_t a, const int n);
int16x8_t vrsraq_n_s16 (int16x8_t r, int16x8_t a, const int n);
int32x4_t vrsraq_n_s32 (int32x4_t r, int32x4_t a, const int n);
int64x2_t vrsraq_n_s64 (int64x2_t r, int64x2_t a, const int n);
```

```c
uint8x16_t vrsraq_n_u8 (uint8x16_t r, uint8x16_t a, const int n);
uint16x8_t vrsraq_n_u16 (uint16x8_t r, uint16x8_t a, const int n);
uint32x4_t vrsraq_n_u32 (uint32x4_t r, uint32x4_t a, const int n);
uint64x2_t vrsraq_n_u64 (uint64x2_t r, uint64x2_t a, const int n);
```

### 单指令右移累加

#### vsra?_n

* 运算： `ret = r + (a >> n)`

```c
int64_t vsrad_n_s64 (int64_t r, int64_t a, const int n);
uint64_t vsrad_n_u64 (uint64_t r, uint64_t a, const int n);
```

#### vrsra?_n

* 运算： `ret = r + ((a + (1<<(n-1))) >> n)`

```c
int64_t vrsrad_n_s64 (int64_t r, int64_t a, const int n);
uint64_t vrsrad_n_u64 (uint64_t r, uint64_t a, const int n);
```

## cax按位清零并异或

### 全指令按位清零并异或

### cax

* 运算： `ret[i] = a[i] ^ ( b[i] & (~c[i]))`

```c
int8x16_t vbcaxq_s8 (int8x16_t a, int8x16_t b, int8x16_t c);
int16x8_t vbcaxq_s16 (int16x8_t a, int16x8_t b, int16x8_t c);
int32x4_t vbcaxq_s32 (int32x4_t a, int32x4_t b, int32x4_t c);
int64x2_t vbcaxq_s64 (int64x2_t a, int64x2_t b, int64x2_t c);
```

```c
uint8x16_t vbcaxq_u8 (uint8x16_t a, uint8x16_t b, uint8x16_t c);
uint16x8_t vbcaxq_u16 (uint16x8_t a, uint16x8_t b, uint16x8_t c);
uint32x4_t vbcaxq_u32 (uint32x4_t a, uint32x4_t b, uint32x4_t c);
uint64x2_t vbcaxq_u64 (uint64x2_t a, uint64x2_t b, uint64x2_t c);
```

## rax/xar旋转异或

### 全指令旋转异或

#### vrax1q

```c
/* Rotate and Exclusive OR */
uint64x2_t vrax1q_u64 (uint64x2_t a, uint64x2_t b);
```

#### vxarq

```c
/* Exclusive OR and Rotate */
uint64x2_t vxarq_u64 (uint64x2_t a, uint64x2_t b, const int imm6);
```

## 未知加载存储指令

### vldap1

Load-acquire RCpc one single-element structure to one lane of one register

This instruction loads a single-element structure from memory and writes the result to the specified lane of the SIMD&FP register without affecting the other bits of the register.

```c
int64x1_t vldap1_lane_s64 (const int64_t *src, int64x1_t vec, const int lane);
uint64x1_t vldap1_lane_u64 (const uint64_t *src, uint64x1_t vec, const int lane);
float64x1_t vldap1_lane_f64 (const float64_t *src, float64x1_t vec, const int lane);
poly64x1_t vldap1_lane_p64 (const poly64_t *src, poly64x1_t vec, const int lane);
```

```c
int64x2_t vldap1q_lane_s64 (const int64_t *src, int64x2_t vec, const int lane);
uint64x2_t vldap1q_lane_u64 (const uint64_t *src, uint64x2_t vec, const int lane);
float64x2_t vldap1q_lane_f64 (const float64_t *src, float64x2_t vec, const int lane);
poly64x2_t vldap1q_lane_p64 (const poly64_t *src, poly64x2_t vec, const int lane);
```

### vstl1

```c
void vstl1_lane_s64 (int64_t *src, int64x1_t vec, const int lane);
void vstl1_lane_u64 (uint64_t *src, uint64x1_t vec, const int lane);
void vstl1_lane_f64 (float64_t *src, float64x1_t vec, const int lane);
void vstl1_lane_p64 (poly64_t *src, poly64x1_t vec, const int lane);
```

```c
void vstl1q_lane_s64 (int64_t *src, int64x2_t vec, const int lane);
void vstl1q_lane_u64 (uint64_t *src, uint64x2_t vec, const int lane);
void vstl1q_lane_f64 (float64_t *src, float64x2_t vec, const int lane);
void vstl1q_lane_p64 (poly64_t *src, poly64x2_t vec, const int lane);
```

## 压缩解压指令

### zip1

```c
int8x8_t vzip1_s8 (int8x8_t a, int8x8_t b);
int16x4_t vzip1_s16 (int16x4_t a, int16x4_t b);
int32x2_t vzip1_s32 (int32x2_t a, int32x2_t b);
```

```c
uint8x8_t vzip1_u8 (uint8x8_t a, uint8x8_t b);
uint16x4_t vzip1_u16 (uint16x4_t a, uint16x4_t b);
uint32x2_t vzip1_u32 (uint32x2_t a, uint32x2_t b);
```

```c
float16x4_t vzip1_f16 (float16x4_t a, float16x4_t b);
float32x2_t vzip1_f32 (float32x2_t a, float32x2_t b);
```

```c
poly8x8_t vzip1_p8 (poly8x8_t a, poly8x8_t b);
poly16x4_t vzip1_p16 (poly16x4_t a, poly16x4_t b);
```

```c
int8x16_t vzip1q_s8 (int8x16_t a, int8x16_t b);
int16x8_t vzip1q_s16 (int16x8_t a, int16x8_t b);
int32x4_t vzip1q_s32 (int32x4_t a, int32x4_t b);
int64x2_t vzip1q_s64 (int64x2_t a, int64x2_t b);
```

```c
uint8x16_t vzip1q_u8 (uint8x16_t a, uint8x16_t b);
uint16x8_t vzip1q_u16 (uint16x8_t a, uint16x8_t b);
uint32x4_t vzip1q_u32 (uint32x4_t a, uint32x4_t b);
uint64x2_t vzip1q_u64 (uint64x2_t a, uint64x2_t b);
```

```c
float16x8_t vzip1q_f16 (float16x8_t a, float16x8_t b);
float32x4_t vzip1q_f32 (float32x4_t a, float32x4_t b);
float64x2_t vzip1q_f64 (float64x2_t a, float64x2_t b);
```

```c
poly8x16_t vzip1q_p8 (poly8x16_t a, poly8x16_t b);
poly16x8_t vzip1q_p16 (poly16x8_t a, poly16x8_t b);
poly64x2_t vzip1q_p64 (poly64x2_t a, poly64x2_t b);
```

### zip2

```c
int8x8_t vzip2_s8 (int8x8_t a, int8x8_t b);
int16x4_t vzip2_s16 (int16x4_t a, int16x4_t b);
int32x2_t vzip2_s32 (int32x2_t a, int32x2_t b);
```

```c
uint8x8_t vzip2_u8 (uint8x8_t a, uint8x8_t b);
uint16x4_t vzip2_u16 (uint16x4_t a, uint16x4_t b);
uint32x2_t vzip2_u32 (uint32x2_t a, uint32x2_t b);
```

```c
float16x4_t vzip2_f16 (float16x4_t a, float16x4_t b);
float32x2_t vzip2_f32 (float32x2_t a, float32x2_t b);
```

```c
poly8x8_t vzip2_p8 (poly8x8_t a, poly8x8_t b);
poly16x4_t vzip2_p16 (poly16x4_t a, poly16x4_t b);
```

```c
int8x16_t vzip2q_s8 (int8x16_t a, int8x16_t b);
int16x8_t vzip2q_s16 (int16x8_t a, int16x8_t b);
int32x4_t vzip2q_s32 (int32x4_t a, int32x4_t b);
int64x2_t vzip2q_s64 (int64x2_t a, int64x2_t b);
```

```c
uint8x16_t vzip2q_u8 (uint8x16_t a, uint8x16_t b);
uint16x8_t vzip2q_u16 (uint16x8_t a, uint16x8_t b);
uint32x4_t vzip2q_u32 (uint32x4_t a, uint32x4_t b);
uint64x2_t vzip2q_u64 (uint64x2_t a, uint64x2_t b);
```

```c
float16x8_t vzip2q_f16 (float16x8_t a, float16x8_t b);
float32x4_t vzip2q_f32 (float32x4_t a, float32x4_t b);
float64x2_t vzip2q_f64 (float64x2_t a, float64x2_t b);
```

```c
poly8x16_t vzip2q_p8 (poly8x16_t a, poly8x16_t b);
poly16x8_t vzip2q_p16 (poly16x8_t a, poly16x8_t b);
poly64x2_t vzip2q_p64 (poly64x2_t a, poly64x2_t b);
```

### uzp1

```c
int8x8_t vuzp1_s8 (int8x8_t a, int8x8_t b);
int16x4_t vuzp1_s16 (int16x4_t a, int16x4_t b);
int32x2_t vuzp1_s32 (int32x2_t a, int32x2_t b);
```

```c
uint8x8_t vuzp1_u8 (uint8x8_t a, uint8x8_t b);
uint16x4_t vuzp1_u16 (uint16x4_t a, uint16x4_t b);
uint32x2_t vuzp1_u32 (uint32x2_t a, uint32x2_t b);
```

```c
float16x4_t vuzp1_f16 (float16x4_t a, float16x4_t b);
float32x2_t vuzp1_f32 (float32x2_t a, float32x2_t b);
```

```c
poly8x8_t vuzp1_p8 (poly8x8_t a, poly8x8_t b);
poly16x4_t vuzp1_p16 (poly16x4_t a, poly16x4_t b);
```

```c
int8x16_t vuzp1q_s8 (int8x16_t a, int8x16_t b);
int16x8_t vuzp1q_s16 (int16x8_t a, int16x8_t b);
int32x4_t vuzp1q_s32 (int32x4_t a, int32x4_t b);
int64x2_t vuzp1q_s64 (int64x2_t a, int64x2_t b);
```

```c
uint8x16_t vuzp1q_u8 (uint8x16_t a, uint8x16_t b);
uint16x8_t vuzp1q_u16 (uint16x8_t a, uint16x8_t b);
uint32x4_t vuzp1q_u32 (uint32x4_t a, uint32x4_t b);
uint64x2_t vuzp1q_u64 (uint64x2_t a, uint64x2_t b);
```

```c
float16x8_t vuzp1q_f16 (float16x8_t a, float16x8_t b);
float32x4_t vuzp1q_f32 (float32x4_t a, float32x4_t b);
float64x2_t vuzp1q_f64 (float64x2_t a, float64x2_t b);
```

```c
poly8x16_t vuzp1q_p8 (poly8x16_t a, poly8x16_t b);
poly16x8_t vuzp1q_p16 (poly16x8_t a, poly16x8_t b);
poly64x2_t vuzp1q_p64 (poly64x2_t a, poly64x2_t b);
```

### uzp2

```c
int8x8_t vuzp2_s8 (int8x8_t a, int8x8_t b);
int16x4_t vuzp2_s16 (int16x4_t a, int16x4_t b);
int32x2_t vuzp2_s32 (int32x2_t a, int32x2_t b);
```

```c
uint8x8_t vuzp2_u8 (uint8x8_t a, uint8x8_t b);
uint16x4_t vuzp2_u16 (uint16x4_t a, uint16x4_t b);
uint32x2_t vuzp2_u32 (uint32x2_t a, uint32x2_t b);
```

```c
float16x4_t vuzp2_f16 (float16x4_t a, float16x4_t b);
float32x2_t vuzp2_f32 (float32x2_t a, float32x2_t b);
```

```c
poly8x8_t vuzp2_p8 (poly8x8_t a, poly8x8_t b);
poly16x4_t vuzp2_p16 (poly16x4_t a, poly16x4_t b);
```

```c
int8x16_t vuzp2q_s8 (int8x16_t a, int8x16_t b);
int16x8_t vuzp2q_s16 (int16x8_t a, int16x8_t b);
int32x4_t vuzp2q_s32 (int32x4_t a, int32x4_t b);
int64x2_t vuzp2q_s64 (int64x2_t a, int64x2_t b);
```

```c
uint8x16_t vuzp2q_u8 (uint8x16_t a, uint8x16_t b);
uint16x8_t vuzp2q_u16 (uint16x8_t a, uint16x8_t b);
uint32x4_t vuzp2q_u32 (uint32x4_t a, uint32x4_t b);
uint64x2_t vuzp2q_u64 (uint64x2_t a, uint64x2_t b);
```

```c
float16x8_t vuzp2q_f16 (float16x8_t a, float16x8_t b);
float32x4_t vuzp2q_f32 (float32x4_t a, float32x4_t b);
float64x2_t vuzp2q_f64 (float64x2_t a, float64x2_t b);
```

```c
poly8x16_t vuzp2q_p8 (poly8x16_t a, poly8x16_t b);
poly16x8_t vuzp2q_p16 (poly16x8_t a, poly16x8_t b);
poly64x2_t vuzp2q_p64 (poly64x2_t a, poly64x2_t b);
```

## 加解密指令

### aes

```c
uint8x16_t vaeseq_u8 (uint8x16_t data, uint8x16_t key);
uint8x16_t vaesdq_u8 (uint8x16_t data, uint8x16_t key);
uint8x16_t vaesmcq_u8 (uint8x16_t data);
uint8x16_t vaesimcq_u8 (uint8x16_t data);
```

### sha1

```c
uint32x4_t vsha1cq_u32 (uint32x4_t hash_abcd, uint32_t hash_e, uint32x4_t wk);
uint32x4_t vsha1mq_u32 (uint32x4_t hash_abcd, uint32_t hash_e, uint32x4_t wk);
uint32x4_t vsha1pq_u32 (uint32x4_t hash_abcd, uint32_t hash_e, uint32x4_t wk);

uint32x4_t vsha1su0q_u32 (uint32x4_t w0_3, uint32x4_t w4_7, uint32x4_t w8_11);
uint32x4_t vsha1su1q_u32 (uint32x4_t tw0_3, uint32x4_t w12_15);

uint32_t vsha1h_u32 (uint32_t hash_e);
```

### sha256

```c
uint32x4_t vsha256hq_u32 (uint32x4_t hash_abcd, uint32x4_t hash_efgh, uint32x4_t wk);
uint32x4_t vsha256h2q_u32 (uint32x4_t hash_efgh, uint32x4_t hash_abcd, uint32x4_t wk);
uint32x4_t vsha256su0q_u32 (uint32x4_t w0_3, uint32x4_t w4_7);
uint32x4_t vsha256su1q_u32 (uint32x4_t tw0_3, uint32x4_t w8_11, uint32x4_t w12_15);
```

### sha512

```c
uint64x2_t vsha512hq_u64 (uint64x2_t a, uint64x2_t b, uint64x2_t c);
uint64x2_t vsha512h2q_u64 (uint64x2_t a, uint64x2_t b, uint64x2_t c);
uint64x2_t vsha512su0q_u64 (uint64x2_t a, uint64x2_t b);
uint64x2_t vsha512su1q_u64 (uint64x2_t a, uint64x2_t b, uint64x2_t c);
```

### vsm3

```c
uint32x4_t vsm3ss1q_u32 (uint32x4_t a, uint32x4_t b, uint32x4_t c);
uint32x4_t vsm3tt1aq_u32 (uint32x4_t a, uint32x4_t b, uint32x4_t c, const int imm2);
uint32x4_t vsm3tt1bq_u32 (uint32x4_t a, uint32x4_t b, uint32x4_t c, const int imm2);
uint32x4_t vsm3tt2aq_u32 (uint32x4_t a, uint32x4_t b, uint32x4_t c, const int imm2);
uint32x4_t vsm3tt2bq_u32 (uint32x4_t a, uint32x4_t b, uint32x4_t c, const int imm2);
uint32x4_t vsm3partw1q_u32 (uint32x4_t a, uint32x4_t b, uint32x4_t c);
uint32x4_t vsm3partw2q_u32 (uint32x4_t a, uint32x4_t b, uint32x4_t c);
```

### vsm4

```c
uint32x4_t vsm4eq_u32 (uint32x4_t a, uint32x4_t b);
uint32x4_t vsm4ekeyq_u32 (uint32x4_t a, uint32x4_t b);
```

## 其它mmintrin指令

### 其它XMM指令

* 运算： 清空MMX状态，标记可用，使用完所有的MMX后调用

```c
void _mm_empty (void); // _m_empty
```

* 运算： `ret[i] = a[2i] * b[2i] + a[2i+1] * b[2i+1]`

```c
__m64 _mm_madd_pi16 (__m64 a, __m64 b); // _m_pmaddwd (s32<-s16,s16)
```

* 运算： `ret[i] = sat(a[2i] * b[2i] + a[2i+1] * b[2i+1])` (SSE)

```c
__m64 _mm_maddubs_pi16 (__m64 a, __m64 b); // (s16<-u8,s8)
```

* 运算： 连接ab， `ret[i] = sat(ab[i])` (SSE)

```c
__m64 _mm_hadds_pi16 (__m64 a, __m64 b); // (s16<-s16,s16)
```

* 运算： 连接ab， `ret[i] = ab[2i] - ab[2i+1]` (SSE)

```c
__m64 _mm_hsub_pi16 (__m64 a, __m64 b); // (s16<-s16,s16)
__m64 _mm_hsub_pi32 (__m64 a, __m64 b); // (s32<-s32,s32)
```

* 运算： 连接ab， `ret[i] = sat(ab[2i] - ab[2i+1])` (SSE)

```c
__m64 _mm_hsubs_pi16 (__m64 a, __m64 b); // (s16<-s16,s16)
```

* 运算： `ret = ∑(|a[i]-b[i]|)` (SSE)

```c
__m64 _mm_sad_pu8 (__m64 a, __m64 b); // _m_psadbw (u16<-u8,u8)
```

* 运算： `ret[i] = (a[i] * b[i]) >> L`

```c
__m64 _mm_mulhi_pi16 (__m64 a, __m64 b); // _m_pmulhw
```
* 运算： `ret = a[0] * b[0]` (SSE)

```c
__m64 _mm_mul_su32 (__m64 a, __m64 b); // (u64<-u32,u32)
```

* 运算： `ret[i] = (a[i] * b[i]) >> 16` (SSE)

```
__m64 _mm_mulhi_pu16 (__m64 a, __m64 b); // _m_pmulhuw (u16<-u16,u16)
```

* 运算： `ret[i] = (((a[i] * b[i]) >> 14) + 1) >> 1` (SSE)

```
__m64 _mm_mulhrs_pi16 (__m64 a, __m64 b); // (s16<-s16,s16)
```

* 运算： `ret[i] = 0; ret[0] = a`

```c
__m64 _mm_cvtsi32_si64 (int a); // _m_from_int
```

* 运算： `ret = a`

```c
__m64 _mm_cvtsi64_m64 (__int64 a); // _m_from_int64
```

* 运算： `ret = a[0]`

```c
int _mm_cvtsi64_si32 (__m64 a); // _m_to_int
```

* 运算： `ret = a`

```c
__int64 _mm_cvtm64_si64 (__m64 a); // _m_to_int64
```

* 运算： `V = {b[imm8], b[imm8+1], ..., b[N-1], a[0], a[1], ..., a[imm8-1]}` (SSE)

```c
__m64 _mm_alignr_pi8 (__m64 a, __m64 b, int imm8);
```

* 运算： `ret[i] = e<i>`

```c
__m64 _mm_set_pi8 (char e7, char e6, char e5, char e4, char e3, char e2, char e1, char e0);
__m64 _mm_set_pi16 (short e3, short e2, short e1, short e0);
__m64 _mm_set_pi32 (int e1, int e0);
```

* 运算： `ret[i] = e<N-1-i>`

```c
__m64 _mm_setr_pi8 (char e7, char e6, char e5, char e4, char e3, char e2, char e1, char e0);
__m64 _mm_setr_pi16 (short e3, short e2, short e1, short e0);
__m64 _mm_setr_pi32 (int e1, int e0);
```

* 运算： `ret[i] = 0`

```c
__m64 _mm_setzero_si64 (void);
```

* 运算： 操作数的宽度是结果宽度的2倍，连接ab， `ret[i] = sat(ab[i])`

```c
__m64 _mm_packs_pi16 (__m64 a, __m64 b); // _m_packsswb (s8<-s16,s16)
__m64 _mm_packs_pi32 (__m64 a, __m64 b); // _m_packssdw (s16<-s32,s32)
__m64 _mm_packs_pu16 (__m64 a, __m64 b); // _m_packuswb  (u8<-s16,s16)
```

* 运算： `ret[2i] = a[N/2+i]; ret[2i+1] = b[N/2+i]`

```c
__m64 _mm_unpackhi_pi8 (__m64 a, __m64 b); // _m_punpckhbw
__m64 _mm_unpackhi_pi16 (__m64 a, __m64 b); // _m_punpckhwd
__m64 _mm_unpackhi_pi32 (__m64 a, __m64 b); // _m_punpckhdq
```

* 运算： `ret[2i] = a[i]; ret[2i+1] = b[i]`

```c
__m64 _mm_unpacklo_pi8 (__m64 a, __m64 b); // _m_punpcklbw
__m64 _mm_unpacklo_pi16 (__m64 a, __m64 b); // _m_punpcklwd
__m64 _mm_unpacklo_pi32 (__m64 a, __m64 b); // _m_punpckldq
```

* 运算： 元素大小为8bits，`if (mask[i] & (1<<7)) mem_addr[i] = a[i]` (SSE)

```c
void _mm_maskmove_si64 (__m64 a, __m64 mask, char *mem_addr); // _m_maskmovq
```

* 运算： `ret[i] = (b[i] >> 7) ? 0 : a[b[i][2:0]]` (SSE)

```c
__m64 _mm_shuffle_pi8 (__m64 a, __m64 b); // (s8<-s8,s8)
```

* 运算： `ret[i] = a[imm8[2i+1:2i]]` (SSE)

```c
__m64 _mm_shuffle_pi16 (__m64 a, int imm8); // _m_pshufw (s16<-s16)
```

* 运算： 取第n个8bits元素的最高位作为结果的第n位 (SSE)

```c
int _mm_movemask_pi8 (__m64 a); // _m_pmovmskb
```

* 运算： `ret[i] = b[i] ? (b[i] > 0 ? a[i] : -a[i]) : 0` (SSE)

```c
__m64 _mm_sign_pi8 (__m64 a, __m64 b);
__m64 _mm_sign_pi16 (__m64 a, __m64 b);
__m64 _mm_sign_pi32 (__m64 a, __m64 b);
```

## 其它SSE指令(含AVX对照)

* 运算： 保证指令前的所有内存操作在指令之后都是可见的

```c
void _mm_lfence (void); // load从内存加载
void _mm_sfence (void); // store存储到内存
void _mm_mfence (void); // 加载和存储
```

* 运算： 提示在spin-wait 循环，可以提高效率

```c
void _mm_pause (void);
```

* 运算： 申请和释放对齐的内存

```c
void* _mm_malloc (size_t size, size_t align);
void _mm_free (void *mem_addr);
```

* 运算： 刷新内存所在的cache-line

```c
void _mm_clflush (void const* p);
```

* 运算： 预取内存到cache-line

```c
void _mm_prefetch (char const *p, int i);
```

* 运算： 获取状态控制寄存器MXCSR的值

```c

unsigned int _mm_getcsr (void);
```

* 运算： 设置状态控制寄存器MXCSR的值

```c
void _mm_setcsr (unsigned int a);
```

* 运算： `if (mask[i] & (1<<7)) mem_addr[i] = a[i]`

```c
void _mm_maskmoveu_si128 (__m128i a, __m128i mask, char *mem_addr); // (s8)
```

* 运算： `ret[0] = min(a); ret[1] = pos-of-min(a)`

```c
__m128i _mm_minpos_epu16 (__m128i a); // (u16)
```

* 运算： `ret[i] = a[2i] * b[2i] + a[2i+1] * b[2i+1]`

```c
__m128i _mm_madd_epi16 (__m128i a, __m128i b); // (s32<-s16,s16) | _mm256_madd_epi16 | _mm512_madd_epi16
```

* 运算：  `ret[i] = sat(a[2i] * b[2i] + a[2i+1] * b[2i+1])`

```c
__m128i _mm_maddubs_epi16 (__m128i a, __m128i b); // (s16<-u8,s8) | _mm256_maddubs_epi16 | _mm512_maddubs_epi16
```

* 运算： `ret[i] = a[i]; ret[0] = a[0] + b[0]`

```c
__m128h _mm_add_sh (__m128h a, __m128h b);
__m128 _mm_add_ss (__m128 a, __m128 b);
__m128d _mm_add_sd (__m128d a, __m128d b);
```

* 运算： `ret[i] = a[i]; ret[0] = a[0] - b[0]`

```c
__m128h _mm_sub_sh (__m128h a, __m128h b);
__m128 _mm_sub_ss (__m128 a, __m128 b);
__m128d _mm_sub_sd (__m128d a, __m128d b);
```

* 运算： `ret[i] = a[i]; ret[0] = a[0] / b[0]`

```c
__m128h _mm_div_sh (__m128h a, __m128h b);
__m128 _mm_div_ss (__m128 a, __m128 b);
__m128d _mm_div_sd (__m128d a, __m128d b);
```

* 运算： 连接ab， `ret[i] = sat(ab[i])`

```c
__m128i _mm_hadds_epi16 (__m128i a, __m128i b); // (s16<-s32,s32) | _mm256_hadds_epi16
```

* 运算： 连接ab， `ret[i] = ab[2i] - ab[2i+1]`

```c
__m128i _mm_hsub_epi16 (__m128i a, __m128i b); // (s16<-s16,s16) | _mm256_hsub_epi16
__m128i _mm_hsub_epi32 (__m128i a, __m128i b); // (s32<-s32,s32 | _mm256_hsub_epi32

__m128 _mm_hsub_ps (__m128 a, __m128 b);    // | _mm256_hsub_ps
__m128d _mm_hsub_pd (__m128d a, __m128d b); // | _mm256_hsub_pd
```

* 运算： 连接ab， `ret[i] = sat(ab[2i] - ab[2i+1])`

```c
__m128i _mm_hsubs_epi16 (__m128i a, __m128i b); // (s16<-s16,s16) | _mm256_hsubs_epi16
```

* 运算： `ret[2i] = a[2i] + b[2i]; ret[2i+1] = a[2i+1] - b[2i+1]`

```c
__m128 _mm_addsub_ps (__m128 a, __m128 b);    // | _mm256_addsub_ps
__m128d _mm_addsub_pd (__m128d a, __m128d b); // | _mm256_addsub_pd
```

* 运算： `ret[2i] = a[2i] * b[2i] + c[2i]; ret[2i+1] = a[2i+1] * b[2i+1] - c[2i+1]` (AVX)

```c
__m128h _mm_fmsubadd_ph (__m128h a, __m128h b, __m128h c);  // | _mm256_fmsubadd_ph | _mm512_fmsubadd_ph
__m128 _mm_fmsubadd_ps (__m128 a, __m128 b, __m128 c);      // | _mm256_fmsubadd_ps | _mm512_fmsubadd_ps
__m128d _mm_fmsubadd_pd (__m128d a, __m128d b, __m128d c);  // | _mm256_fmsubadd_pd | _mm512_fmsubadd_pd
```

* 运算： `ret[2i] = a[2i] * b[2i] - c[2i]; ret[2i+1] = a[2i+1] * b[2i+1] + c[2i+1]` (AVX)

```c
__m128h _mm_fmaddsub_ph (__m128h a, __m128h b, __m128h c);  // | _mm256_fmaddsub_ph | _mm512_fmaddsub_ph
__m128 _mm_fmaddsub_ps (__m128 a, __m128 b, __m128 c);      // | _mm256_fmaddsub_ps | _mm512_fmaddsub_ps
__m128d _mm_fmaddsub_pd (__m128d a, __m128d b, __m128d c);  // | _mm256_fmaddsub_pd | _mm512_fmaddsub_pd
```
* 运算： `ret[i] = a[i]; ret[0] = a[0] * b[0] + c[0]` (AVX)

```c
__m128h _mm_fmadd_sh (__m128h a, __m128h b, __m128h c);
__m128 _mm_fmadd_ss (__m128 a, __m128 b, __m128 c);
__m128d _mm_fmadd_sd (__m128d a, __m128d b, __m128d c);
```

* 运算： `ret[i] = a[i]; ret[0] = -(a[0] * b[0] + c[0])` (AVX)

```c
__m128h _mm_fnmsub_sh (__m128h a, __m128h b, __m128h c);
__m128 _mm_fnmsub_ss (__m128 a, __m128 b, __m128 c);
__m128d _mm_fnmsub_sd (__m128d a, __m128d b, __m128d c);
```

* 运算： `ret[i] = a[i]; ret[0] = a[0] * b[0] - c[0]` (AVX)

```c
__m128h _mm_fmsub_sh (__m128h a, __m128h b, __m128h c);
__m128 _mm_fmsub_ss (__m128 a, __m128 b, __m128 c);
__m128d _mm_fmsub_sd (__m128d a, __m128d b, __m128d c);
```

* 运算： `ret[i] = a[i]; ret[0] = -a[0] * b[0] + c[0]` (AVX)

```c
__m128h _mm_fnmadd_sh (__m128h a, __m128h b, __m128h c);
__m128 _mm_fnmadd_ss (__m128 a, __m128 b, __m128 c);
__m128d _mm_fnmadd_sd (__m128d a, __m128d b, __m128d c);
```

* 运算： `V = {b[imm8], b[imm8+1], ..., b[N-1], a[0], a[1], ..., a[imm8-1]}`

```c
__m128i _mm_alignr_epi8 (__m128i a, __m128i b, int imm8); // | _mm256_alignr_epi8 | _mm512_alignr_epi8
```

* 运算： `ret[i] = a[i] & b[i]`

```c
__m128 _mm_and_ps (__m128 a, __m128 b);    // | _mm256_and_ps | _mm512_and_ps
__m128d _mm_and_pd (__m128d a, __m128d b); // | _mm256_and_pd | _mm512_and_pd
```

* 运算： `ret[i] = (~a[i]) & b[i]`

```c
__m128 _mm_andnot_ps (__m128 a, __m128 b);    // | _mm256_andnot_ps | _mm512_andnot_ps
__m128d _mm_andnot_pd (__m128d a, __m128d b); // | _mm256_andnot_pd | _mm512_andnot_pd
```

* 运算： `ret[i] = a[i] ^ b[i]`

```c
__m128 _mm_xor_ps (__m128 a, __m128 b);    // | _mm256_xor_ps | _mm512_xor_ps
__m128d _mm_xor_pd (__m128d a, __m128d b); // | _mm256_xor_pd | _mm512_xor_pd
```

* 运算： `ret[i] = imm8 & (1<<i) ? b[i] : a[i]`

```c
__m128i _mm_blend_epi16 (__m128i a, __m128i b, const int imm8); // (s16<-s16,s16)      | _mm256_blend_epi16
__m128i _mm_blend_epi32 (__m128i a, __m128i b, const int imm8); // (s16<-s16,s16)(AVX) | _mm256_blend_epi32

__m128 _mm_blend_ps (__m128 a, __m128 b, const int imm8);       // | _mm256_blend_ps
__m128d _mm_blend_pd (__m128d a, __m128d b, const int imm8);    // | _mm256_blend_pd
```

* 运算： `ret[i] = mask[i] & (1<<(L-1);); ? b[i] : a[i]`

```c
__m128i _mm_blendv_epi8 (__m128i a, __m128i b, __m128i mask);  // | _mm256_blendv_epi8

__m128 _mm_blendv_ps (__m128 a, __m128 b, __m128 mask);        // | _mm256_blendv_ps
__m128d _mm_blendv_pd (__m128d a, __m128d b, __m128d mask);    // | _mm256_blendv_pd
```

* 运算： 将向量中的数据当做其他向量数据处理

```c
__m128i _mm_castph_si128 (__m128h a);       // | _mm256_castph_si256 | _mm512_castph_si512
__m128 _mm_castph_ps (__m128h a);           // | _mm256_castph_ps    | _mm512_castph_ps
__m128d _mm_castph_pd (__m128h a);          // | _mm256_castph_pd    | _mm512_castph_pd

__m128i _mm_castps_si128 (__m128 a);        // | _mm256_castps_si256 | _mm512_castps_si512
__m128h _mm_castps_ph (__m128 a);           // | _mm256_castps_ph    | _mm512_castps_ph
__m128d _mm_castps_pd (__m128 a);           // | _mm256_castps_pd    | _mm512_castps_pd

__m128i _mm_castpd_si128 (__m128d a);       // | _mm256_castpd_si256 | _mm512_castpd_si512
__m128h _mm_castpd_ph (__m128d a);          // | _mm256_castpd_ph    | _mm512_castpd_ph
__m128 _mm_castpd_ps (__m128d a);           // | _mm256_castpd_ps    | _mm512_castpd_ps

__m128h _mm_castsi128_ph (__m128i a);       // | _mm256_castsi256_ph | _mm512_castsi512_ph
__m128 _mm_castsi128_ps (__m128i a);        // | _mm256_castsi256_ps | _mm512_castsi512_ps
__m128d _mm_castsi128_pd (__m128i a);       // | _mm256_castsi256_pd | _mm512_castsi512_pd

__m128i _mm256_castsi256_si128 (__m256i a); // | _mm512_castsi512_si128 | _mm512_castsi512_si256
__m128h _mm256_castph256_ph128 (__m256h a); // | _mm512_castph512_ph128 | _mm512_castph512_ph256
__m128 _mm256_castps256_ps128 (__m256 a);   // | _mm512_castps512_ps128 | _mm512_castps512_ps256
__m128d _mm256_castpd256_pd128 (__m256d a); // | _mm512_castpd512_pd128 | _mm512_castpd512_pd256

__m256i _mm256_castsi128_si256 (__m128i a); // | _mm512_castsi128_si512 | _mm512_castsi256_si512
__m256h _mm256_castph128_ph256 (__m128h a); // | _mm512_castph512_ph128 | _mm512_castph256_ph512
__m256 _mm256_castps128_ps256 (__m128 a);   // | _mm512_castps128_ps512 | _mm512_castps256_ps512
__m256d _mm256_castpd128_pd256 (__m128d a); // | _mm512_castpd128_pd512 | _mm512_castpd256_pd512
```

* 运算： `ret[i] = (a[i] != b[i]) ? 0xFF... : 0`

```c
__m128 _mm_cmpneq_ps (__m128 a, __m128 b);
__m128d _mm_cmpneq_pd (__m128d a, __m128d b);
```

* 运算： `ret[i] = a[i]; ret[0] = (a[0] != b[0]) ? 0xFF... : 0`

```c
__m128 _mm_cmpneq_ss (__m128 a, __m128 b);
__m128d _mm_cmpneq_sd (__m128d a, __m128d b);
```

* 运算： `ret[i] = a[i]; ret[0] = (a[0] == b[0]) ? 0xFF... : 0`

```c
__m128 _mm_cmpeq_ss (__m128 a, __m128 b);
__m128d _mm_cmpeq_sd (__m128d a, __m128d b);
```

* 运算： `ret[i] = a[i]; ret[0] = (a[0] > b[0]) ? 0xFF... : 0`

```c
__m128 _mm_cmpgt_ss (__m128 a, __m128 b); // _mm_cmpnle_ss
__m128d _mm_cmpgt_sd (__m128d a, __m128d b); // _mm_cmpnle_sd
```

* 运算： `ret[i] = a[i]; ret[0] = (a[0] >= b[0]) ? 0xFF... : 0`

```c
__m128 _mm_cmpge_ss (__m128 a, __m128 b); // _mm_cmpnlt_ss
__m128d _mm_cmpge_sd (__m128d a, __m128d b); // _mm_cmpnlt_sd
```

* 运算： `ret[i] = a[i]; ret[0] = (a[0] < b[0]) ? 0xFF... : 0`

```c
__m128 _mm_cmplt_ss (__m128 a, __m128 b); // _mm_cmpnge_ss
__m128d _mm_cmplt_sd (__m128d a, __m128d b); // _mm_cmpnge_sd
```

* 运算： `ret[i] = a[i]; ret[0] = (a[0] <= b[0]) ? 0xFF... : 0`

```c
__m128 _mm_cmple_ss (__m128 a, __m128 b); // _mm_cmpngt_ss
__m128d _mm_cmple_sd (__m128d a, __m128d b); // _mm_cmpngt_sd
```

* 运算： `ret = (a[0] != NaN && b[0] != NaN && a[0] == b[0]) ? 1 : 0`

```c
int _mm_comieq_sh (__m128h a, __m128h b);
int _mm_comieq_ss (__m128 a, __m128 b);
int _mm_comieq_sd (__m128d a, __m128d b);
```

* 运算： `ret = (a[0] != NaN && b[0] != NaN && a[0] > b[0]) ? 1 : 0`

```c
int _mm_comigt_sh (__m128h a, __m128h b);
int _mm_comigt_ss (__m128 a, __m128 b);
int _mm_comigt_sd (__m128d a, __m128d b);
```

* 运算： `ret = (a[0] != NaN && b[0] != NaN && a[0] >= b[0]) ? 1 : 0`

```c
int _mm_comige_sh (__m128h a, __m128h b);
int _mm_comige_ss (__m128 a, __m128 b);
int _mm_comige_sd (__m128d a, __m128d b);
```

* 运算： `ret = (a[0] != NaN && b[0] != NaN && a[0] < b[0]) ? 1 : 0`

```c
int _mm_comilt_sh (__m128h a, __m128h b);
int _mm_comilt_ss (__m128 a, __m128 b);
int _mm_comilt_sd (__m128d a, __m128d b);
```

* 运算： `ret = (a[0] != NaN && b[0] != NaN && a[0] <= b[0]) ? 1 : 0`

```c
int _mm_comile_sh (__m128h a, __m128h b);
int _mm_comile_ss (__m128 a, __m128 b);
int _mm_comile_sd (__m128d a, __m128d b);
```

* 运算： `ret = (a[0] == NaN || b[0] == NaN || a[0] != b[0]) ? 1 : 0`

```c
int _mm_comineq_sh (__m128h a, __m128h b);
int _mm_comineq_ss (__m128 a, __m128 b);
int _mm_comineq_sd (__m128d a, __m128d b);
```

* 运算： `ret = (a[0] != NaN && b[0] != NaN && a[0] == b[0]) ? 1 : 0`

```c
int _mm_ucomieq_sh (__m128h a, __m128h b);
int _mm_ucomieq_ss (__m128 a, __m128 b);
int _mm_ucomieq_sd (__m128d a, __m128d b);
```

* 运算： `ret = (a[0] != NaN && b[0] != NaN && a[0] > b[0]) ? 1 : 0`

```c
int _mm_ucomigt_sh (__m128h a, __m128h b);
int _mm_ucomigt_ss (__m128 a, __m128 b);
int _mm_ucomigt_sd (__m128d a, __m128d b);
```

* 运算： `ret = (a[0] != NaN && b[0] != NaN && a[0] >= b[0]) ? 1 : 0`

```c
int _mm_ucomige_sh (__m128h a, __m128h b);
int _mm_ucomige_ss (__m128 a, __m128 b);
int _mm_ucomige_sd (__m128d a, __m128d b);
```

* 运算： `ret = (a[0] != NaN && b[0] != NaN && a[0] < b[0]) ? 1 : 0`

```c
int _mm_ucomilt_sh (__m128h a, __m128h b);
int _mm_ucomilt_ss (__m128 a, __m128 b);
int _mm_ucomilt_sd (__m128d a, __m128d b);
```

* 运算： `ret = (a[0] != NaN && b[0] != NaN && a[0] <= b[0]) ? 1 : 0`

```c
int _mm_ucomile_sh (__m128h a, __m128h b);
int _mm_ucomile_ss (__m128 a, __m128 b);
int _mm_ucomile_sd (__m128d a, __m128d b);
```

* 运算： `ret = (a[0] == NaN || b[0] == NaN || a[0] != b[0]) ? 1 : 0`

```c
int _mm_ucomineq_sh (__m128h a, __m128h b);
int _mm_ucomineq_ss (__m128 a, __m128 b);
int _mm_ucomineq_sd (__m128d a, __m128d b);
```

* 运算： `ret[i] = a[i]; ret[0] = a[0] > b[0] ? a[0] : b[0]`

```c
__m128h _mm_max_sh (__m128h a, __m128h b);
__m128 _mm_max_ss (__m128 a, __m128 b);
__m128d _mm_max_sd (__m128d a, __m128d b);
```

* 运算： `ret[i] = a[i]; ret[0] = a[0] < b[0] ? a[0] : b[0]`

```c
__m128h _mm_min_sh (__m128h a, __m128h b);
__m128 _mm_min_ss (__m128 a, __m128 b);
__m128d _mm_min_sd (__m128d a, __m128d b);
```

* 运算： `ret[i] = a[i]; ret[0] = sqrt(a[0])`

```c
__m128h _mm_sqrt_sh (__m128h a, __m128h b);
__m128 _mm_sqrt_ss (__m128 a);
```

* 运算： `ret[i] = a[i]; ret[0] = sqrt(b[0])`

```c
__m128d _mm_sqrt_sd (__m128d a, __m128d b);
```

* 运算： `ret[i] = a[i]; ret[0] = 1.0 / a[0]`

```c
__m128h _mm_rcp_sh (__m128h a, __m128h b);
__m128 _mm_rcp_ss (__m128 a);
```

* 运算： `ret[i] = a[i]; ret[0] = 1.0 / sqrt(a[0])`

```c
__m128h _mm_rsqrt_sh (__m128h a, __m128h b);
__m128 _mm_rsqrt_ss (__m128 a);
```

* 运算： `ret[i] = (a[i] != NaN && b[i] != NaN) ? 0xFF... : 0`

```c
__m128 _mm_cmpord_ps (__m128 a, __m128 b); // isNaN
__m128d _mm_cmpord_pd (__m128d a, __m128d b);
```

* 运算： `ret[i] = (a[i] == NaN || b[i] == NaN) ? 0xFF... : 0`

```c
__m128 _mm_cmpunord_ps (__m128 a, __m128 b);
__m128d _mm_cmpunord_pd (__m128d a, __m128d b);
```

* 运算： `ret[i] = a[i]; ret[0] = (a[0] != NaN && b[0] != NaN) ? 0xFF... : 0`

```c
__m128 _mm_cmpord_ss (__m128 a, __m128 b);
__m128d _mm_cmpord_sd (__m128d a, __m128d b);
```

* 运算： `ret[i] = a[i]; ret[0] = (a[0] == NaN || b[0] == NaN) ? 0xFF... : 0`

```c
__m128 _mm_cmpunord_ss (__m128 a, __m128 b);
__m128d _mm_cmpunord_sd (__m128d a, __m128d b);
```

* 运算： `ret[i] = a[i]; ret[0] = ceil(b[0])`

```c
__m128 _mm_ceil_ss (__m128 a, __m128 b);
__m128d _mm_ceil_sd (__m128d a, __m128d b);
```

* 运算： `ret[i] = a[i]; ret[0] = floor(b[0])`

```c
__m128 _mm_floor_ss (__m128 a, __m128 b);
__m128d _mm_floor_sd (__m128d a, __m128d b);
```

* 运算： `ret[i] = 0; ret[0] = mem_addr[0]`

```c
__m128h _mm_load_sh (void const* mem_addr);
__m128 _mm_load_ss (float const *mem_addr);
__m128d _mm_load_sd (double const *mem_addr);
```

* 运算： `V = {a[0], a[1], mem_addr[0][0], mem_addr[0][1]}`

```c
__m128 _mm_loadh_pi (__m128 a, __m64 const *mem_addr);
```

* 运算： `V = {a[0], mem_addr[0]}`

```c
__m128d _mm_loadh_pd (__m128d a, double const *mem_addr);
```

* 运算： `0~N/2-1: ret[i] = mem_addr[0][i];  N/2~N-1: ret[i] = 0`

```c
__m128i _mm_loadl_epi64 (__m128i const *mem_addr);
```

* 运算： `0~N/2-1: ret[i] = mem_addr[0][i];  N/2~N-1: ret[i] = a[i]`

```c
__m128 _mm_loadl_pi (__m128 a, __m64 const *mem_addr);
```

* 运算： `ret[0] = mem_addr[0]; ret[1] = a[1]`

```c
__m128d _mm_loadl_pd (__m128d a, double const *mem_addr);
```

* 运算： `ret[i] = 0; ret[0] = mem_addr[0]`

```c
__m128i _mm_loadu_si16 (void const *mem_addr);
__m128i _mm_loadu_si32 (void const *mem_addr);
__m128i _mm_loadu_si64 (void const *mem_addr);
```

* 运算： `ret[i] = mem_addr[N-1-i]` (需16字节对齐，反向加载)

```c
__m128 _mm_loadr_ps (float const *mem_addr);
__m128d _mm_loadr_pd (double const *mem_addr);
```

* 运算： `mem_addr[i] = a[0]`

```c
void _mm_store1_ps (float *mem_addr, __m128 a);   // _mm_store_ps1
void _mm_store1_pd (double *mem_addr, __m128d a); // _mm_store_pd1
```

* 运算： `mem_addr[0] = a[0]`

```c
void _mm_store_sh (void * mem_addr, __m128h a);
void _mm_store_ss (float *mem_addr, __m128 a);
void _mm_store_sd (double *mem_addr, __m128d a);
```

* 运算： `mem_addr[0][i] = a[N/2 + i]; (i < N/2)`

```c
void _mm_storeh_pi (__m64 *mem_addr, __m128 a);
```

* 运算： `mem_addr[0] = a[1]`

```c
void _mm_storeh_pd (double *mem_addr, __m128d a);
```

* 运算： `mem_addr[0][i] = a[i]; (i < N/2)`

```c
void _mm_storel_epi64 (__m128i *mem_addr, __m128i a);
```

* 运算： `mem_addr[0][i] = a[i]; (i < N/2)`

```c
void _mm_storel_pi (__m64 *mem_addr, __m128 a);
```

* 运算： `mem_addr[0] = a[0]`

```c
void _mm_storel_pd (double *mem_addr, __m128d a);
```

* 运算： `mem_addr[0] = a[0]`

```c
void _mm_storeu_si16 (void *mem_addr, __m128i a);
void _mm_storeu_si32 (void *mem_addr, __m128i a);
void _mm_storeu_si64 (void *mem_addr, __m128i a);
```

* 运算： `mem_addr[i] = a[N-1-i]`

```c
void _mm_storer_ps (float *mem_addr, __m128 a);
void _mm_storer_pd (double *mem_addr, __m128d a);
```

* 运算： `ret[i] = mem_addr[i]` 不影响当前缓存数据 (需16字节对齐)

```c
__m128i _mm_stream_load_si128 (void *mem_addr); // | _mm256_stream_load_si256 | _mm512_stream_load_si512
```

* 运算： `mem_addr[i] = a[i]`

```c
void _mm_stream_pi (void *mem_addr, __m64 a);
void _mm_stream_ps (void *mem_addr, __m128 a);  // | _mm256_stream_ps | _mm512_stream_ps
void _mm_stream_pd (void *mem_addr, __m128d a); // | _mm256_stream_pd | _mm512_stream_pd
```

* 运算： `mem_addr[0] = a`

```c
void _mm_stream_si32 (void *mem_addr, int a);
void _mm_stream_si64 (void *mem_addr, __int64 a);
```

* 运算： `mem_addr[i] = a[i]`

```c
void _mm_stream_si128 (void *mem_addr, __m128i a); // | _mm256_stream_si256 | _mm512_stream_si512
```

* 运算： `ret[i] = 0; ret[0] = a`

```c
__m128h _mm_set_sh (_Float16 a);
__m128 _mm_set_ss (float a);
__m128d _mm_set_sd (double a);
```

* 运算： `ret[i] = e<i>`

```c
__m128i _mm_set_epi8 (char e15, char e14, char e13, char e12, char e11, char e10, char e9, char e8, char e7, char e6, char e5, char e4, char e3, char e2, char e1, char e0); // | _mm256_set_epi8 | _mm512_set_epi8
__m128i _mm_set_epi16 (short e7, short e6, short e5, short e4, short e3, short e2, short e1, short e0); // | _mm256_set_epi16 | _mm512_set_epi16
__m128i _mm_set_epi32 (int e3, int e2, int e1, int e0); // | _mm256_set_epi32 | _mm512_set_epi32
__m128i _mm_set_epi64x (__int64 e1, __int64 e0); // _mm_set_epi64x | _mm256_set_epi64x | _mm512_set_epi64
__m128i _mm_set_epi64 (__m64 e1, __m64 e0);

__m128h _mm_set_ph (_Float16 e7, _Float16 e6, _Float16 e5, _Float16 e4, _Float16 e3, _Float16 e2, _Float16 e1, _Float16 e0); // | _mm256_set_ph | _mm512_set_ph
__m128 _mm_set_ps (float e3, float e2, float e1, float e0); // | _mm256_set_ps | _mm512_set_ps
__m128d _mm_set_pd (double e1, double e0); // | _mm256_set_pd | _mm512_set_pd
```

* 运算： `ret[i] = e<N-1-i>`

```c
__m128i _mm_setr_epi8 (char e15, char e14, char e13, char e12, char e11, char e10, char e9, char e8, char e7, char e6, char e5, char e4, char e3, char e2, char e1, char e0); // | _mm256_setr_epi8
__m128i _mm_setr_epi16 (short e7, short e6, short e5, short e4, short e3, short e2, short e1, short e0); // | _mm256_setr_epi16
__m128i _mm_setr_epi32 (int e3, int e2, int e1, int e0); // | _mm256_setr_epi32 | _mm512_setr_epi32
__m128i _mm_setr_epi64 (__m64 e1, __m64 e0); // | _mm256_setr_epi64x | _mm512_setr_epi64

__m128h _mm_setr_ph (_Float16 e7, _Float16 e6, _Float16 e5, _Float16 e4, _Float16 e3, _Float16 e2, _Float16 e1, _Float16 e0); // | _mm256_setr_ph | _mm512_setr_ph
__m128 _mm_setr_ps (float e3, float e2, float e1, float e0); // | _mm256_setr_ps | _mm512_setr_pd
__m128d _mm_setr_pd (double e1, double e0); // | _mm256_setr_pd | _mm512_setr_pd
```

* 运算： `ret[i] = 0`

```c
__m128i _mm_setzero_si128 (void); // | _mm256_setzero_si256 | _mm512_setzero_si512 / _mm512_setzero_epi32

__m128h _mm_setzero_ph (void);    // | _mm256_setzero_ph    | _mm512_setzero_ph
__m128 _mm_setzero_ps (void);     // | _mm256_setzero_ps    | _mm512_setzero_ps / _mm512_setzero
__m128d _mm_setzero_pd (void);    // | _mm256_setzero_pd    | _mm512_setzero_pd
```

* 运算： 连接两个向量 (AVX)

```c
__m256i _mm256_set_m128i (__m128i hi, __m128i lo);
__m256 _mm256_set_m128 (__m128 hi, __m128 lo);
__m256d _mm256_set_m128d (__m128d hi, __m128d lo);
```

* 运算： 反向连接两个向量 (AVX)

```c
__m256i _mm256_setr_m128i (__m128i lo, __m128i hi);
__m256 _mm256_setr_m128 (__m128 lo, __m128 hi);
__m256d _mm256_setr_m128d (__m128d lo, __m128d hi);
```

* 运算： `0~N/2-1: ret[i] = a[i];  N/2~N-1: ret[i] = 0`

```c
__m128i _mm_movpi64_epi64 (__m64 a);
```

* 运算： `0~N/2-1: ret[i] = a[i];  N/2~N-1: ret[i] = 0`

```c
__m128i _mm_move_epi64 (__m128i a);
```

* 运算： `ret[i] = a[i]; ret[0] = b[0]`

```c
__m128h _mm_move_sh (__m128h a, __m128h b);
__m128 _mm_move_ss (__m128 a, __m128 b);
__m128d _mm_move_sd (__m128d a, __m128d b);
```

* 运算： `ret[2i] = a[2i+1]; ret[2i+1] = a[2i+1]`

```c
__m128 _mm_movehdup_ps (__m128 a); // | _mm256_movehdup_ps  | _mm512_movehdup_ps
```

* 运算： `ret[2i] = a[2i]; ret[2i+1] = a[2i]`

```c
__m128 _mm_moveldup_ps (__m128 a);  // | _mm256_moveldup_ps | _mm512_moveldup_ps
__m128d _mm_movedup_pd (__m128d a); // | _mm256_movedup_pd  | _mm512_movedup_pd
```

* 运算： `V = {b[2], b[3], a[2], a[3]}`

```c
__m128 _mm_movehl_ps (__m128 a, __m128 b);
```

* 运算： `V = {a[0], a[1], b[0], b[1]}`

```c
__m128 _mm_movelh_ps (__m128 a, __m128 b);
```

* 运算： 取第n个元素的最高位(符号位)作为结果的第n位

```c
int _mm_movemask_epi8 (__m128i a); // (?<-s8) | _mm256_movemask_epi8

int _mm_movemask_ps (__m128 a);    // | _mm256_movemask_ps
int _mm_movemask_pd (__m128d a);   // | _mm256_movemask_pd
```

* 运算： `ret[i] = a[2i] * b[2i]`

```c
__m128i _mm_mul_epi32 (__m128i a, __m128i b); // (s64<-s32,s32) | _mm256_mul_epi32 | _mm512_mul_epi32
__m128i _mm_mul_epu32 (__m128i a, __m128i b); // (u64<-u32,u32) | _mm256_mul_epu32 | _mm512_mul_epu32
```

* 运算： `ret[i] = (a[i] * b[i]) >> L/2`

```c
__m128i _mm_mulhi_epi16 (__m128i a, __m128i b); // (s16<-s16,s16)  | _mm256_mulhi_epi16  | _mm512_mulhi_epi16
__m128i _mm_mulhi_epu16 (__m128i a, __m128i b); // (u16<-u16,u16)  | _mm256_mulhi_epu16  | _mm512_mulhi_epu16
```

* 运算： `ret[i] = (((a[i] * b[i]) >> 14) + 1) >> 1`

```c
__m128i _mm_mulhrs_epi16 (__m128i a, __m128i b); // (s16<-s16,s16) | _mm256_mulhrs_epi16 | _mm512_mulhrs_epi16
```

* 运算： `ret[i] = a[i]; ret[0] = a[0] * b[0]`

```c
__m128h _mm_mul_sh (__m128h a, __m128h b);
__m128 _mm_mul_ss (__m128 a, __m128 b);
__m128d _mm_mul_sd (__m128d a, __m128d b);
```

* 运算： `ret[i] = a[i] | b[i]`

```c
__m128 _mm_or_ps (__m128 a, __m128 b);    // | _mm256_or_ps | _mm512_or_ps
__m128d _mm_or_pd (__m128d a, __m128d b); // | _mm256_or_pd | _mm512_or_pd
```

* 运算： `ret = ∑(|a[i]-b[i]|)`

```c
__m128i _mm_sad_epu8 (__m128i a, __m128i b); // | _mm256_sad_epu8 | _mm512_sad_epu8
```

* 运算： `ret[i] = (b[i] >> 7) ? 0 : a[b[i][3:0]]`

```c
__m128i _mm_shuffle_epi8 (__m128i a, __m128i b); // (s8<-s8,s8) | _mm256_shuffle_epi8  | _mm512_shuffle_epi8
                                                 //             | _mm256_shuffle_epi32 | _mm512_shuffle_epi32
```

* 运算： `0~N/2-1: ret[i] = a[imm8[2i+1:2i]]; N/2~N-1: ret[i] = b[imm8[2i+1:2i]]`

```
__m128 _mm_shuffle_ps (__m128 a, __m128 b, unsigned int imm8); // | _mm256_shuffle_ps | _mm512_shuffle_ps
__m128d _mm_shuffle_pd (__m128d a, __m128d b, int imm8);       // | _mm256_shuffle_pd | _mm512_shuffle_pd
```

* 运算： `0~N/2-1: ret[i] = a[i];  N/2~N-1: ret[i] = a[N/2 + imm8[2(i-N/2)+1:2(i-N/2)]]`

```c
__m128i _mm_shufflehi_epi16 (__m128i a, int imm8); // | _mm256_shufflehi_epi16 | _mm512_shufflehi_epi16
```

* 运算： `0~N/2-1: ret[i] = a[imm8[2i+1:2i]];  N/2~N-1: ret[i] = a[i]`

```c
__m128i _mm_shufflelo_epi16 (__m128i a, int imm8); // | _mm256_shufflelo_epi16 | _mm512_shufflelo_epi16
```

* 运算： `ret[i] = b[i] ? (b[i] > 0 ? a[i] : -a[i]) : 0`

```c
__m128i _mm_sign_epi8 (__m128i a, __m128i b);  // | _mm256_sign_epi8
__m128i _mm_sign_epi16 (__m128i a, __m128i b); // | _mm256_sign_epi16
__m128i _mm_sign_epi32 (__m128i a, __m128i b); // | _mm256_sign_epi32
```

* 运算： `V = {0, 0, ..., a[0], a[1], ..., a[N-1-imm8]}`

```c
__m128i _mm_slli_si128 (__m128i a, int imm8);  // | _mm256_slli_si256
```

* 运算： `V = {0, 0, ..., a[0], a[1], ..., a[7-imm8], 0, 0, ..., a[N-1-imm8]}`

```c
__m128i _mm_bslli_si128 (__m128i a, int imm8); // | _mm256_bslli_epi128 | _mm512_bslli_epi128
```

* 运算： `V = {a[imm8], a[imm8+1], ..., a[N-1], 0, 0, ..., 0}`

```c
__m128i _mm_srli_si128 (__m128i a, int imm8);  // | _mm256_srli_si256
```

* 运算： `V = {a[imm8], a[imm8+1], ..., a[N-1], 0, 0, ..., 0}`

```c
__m128i _mm_bsrli_si128 (__m128i a, int imm8);     // | _mm256_bsrli_epi128 | _mm512_bslli_epi128
```

* 运算： `ret[i] = a[i] >> count[i]` (AVX)

```c
__m128i _mm_srlv_epi32 (__m128i a, __m128i count); // | _mm256_srlv_epi32
__m128i _mm_srlv_epi64 (__m128i a, __m128i count); // | _mm256_srlv_epi64
__m128i _mm_srav_epi32 (__m128i a, __m128i count); // | _mm256_srav_epi32
```

* 运算： `ret = (~a & ~0) == 0 ? 1 : 0`

```c
int _mm_test_all_ones (__m128i a);
```

* 运算： `ret = (~a & b) == 0 ? 1 : 0`

```c
int _mm_test_all_zeros (__m128i mask, __m128i a);
```

* 运算： `ret = ((a & mask) != 0) && ((~a & mask) != 0) ? 1 : 0`

```c
int _mm_test_mix_ones_zeros (__m128i mask, __m128i a);
```

* 运算： `ret = (~a & b) == 0 ? 1 : 0`

```c
int _mm_testc_si128 (__m128i a, __m128i b);   // | _mm256_testc_si256

/* AVX */
int _mm_testc_ps (__m128 a, __m128 b);        // | _mm256_testc_ps
int _mm_testc_pd (__m128d a, __m128d b);      // | _mm256_testc_pd
```

* 运算： ret = (a & b) == 0 ? 1 : 0`

```c
int _mm_testz_si128 (__m128i a, __m128i b);   // | _mm256_testz_si256

/* AVX */
int _mm_testz_ps (__m128 a, __m128 b);        // | _mm256_testz_ps
int _mm_testz_pd (__m128d a, __m128d b);      // | _mm256_testz_pd
```

* 运算： `ret = ((a & b) != 0) && ((~a & b) != 0) ? 1 : 0`

```c
int _mm_testnzc_si128 (__m128i a, __m128i b); // | _mm256_testnzc_si256

/* AVX */
int _mm_testnzc_ps (__m128 a, __m128 b);      // | _mm256_testnzc_ps
int _mm_testnzc_pd (__m128d a, __m128d b);    // | _mm256_testnzc_pd
```

* 运算： `ret[i] = random()`

```c
__m128i _mm_undefined_si128 (void); // | _mm256_undefined_si256 | ? / _mm512_undefined_epi32
__m128h _mm_undefined_ph (void);    // | _mm256_undefined_ph | _mm512_undefined_ph
__m128 _mm_undefined_ps (void);     // | _mm256_undefined_ps | _mm512_undefined_ps / _mm512_undefined
__m128d _mm_undefined_pd (void);    // | _mm256_undefined_pd | _mm512_undefined_pd
```

* 运算： 操作数的宽度是结果宽度的2倍，连接ab， `ret[i] = sat(ab[i])`

```c
__m128i _mm_packs_epi16 (__m128i a, __m128i b); // (s8<-s16,s16)   | _mm256_packs_epi16 | _mm512_packs_epi16
__m128i _mm_packs_epi32 (__m128i a, __m128i b); // (s16<-s32,s32)  | _mm256_packs_epi32 | _mm512_packs_epi32

__m128i _mm_packus_epi16 (__m128i a, __m128i b); // (u8<-s16,s16)  | _mm256_packus_epi16 | _mm512_packus_epi16
__m128i _mm_packus_epi32 (__m128i a, __m128i b); // (u16<-s32,s32) | _mm256_packus_epi32 | _mm512_packus_epi32
```

* 运算： `ret[2i] = a[N/2+i]; ret[2i+1] = b[N/2+i]`

```c
__m128i _mm_unpackhi_epi8 (__m128i a, __m128i b);  // | _mm256_unpackhi_epi8  | _mm512_unpackhi_epi8
__m128i _mm_unpackhi_epi16 (__m128i a, __m128i b); // | _mm256_unpackhi_epi16 | _mm512_unpackhi_epi16
__m128i _mm_unpackhi_epi32 (__m128i a, __m128i b); // | _mm256_unpackhi_epi32 | _mm512_unpackhi_epi32
__m128i _mm_unpackhi_epi64 (__m128i a, __m128i b); // | _mm256_unpackhi_epi64 | _mm512_unpackhi_epi64

__m128 _mm_unpackhi_ps (__m128 a, __m128 b);       // | _mm256_unpackhi_ps    | _mm512_unpackhi_ps
__m128d _mm_unpackhi_pd (__m128d a, __m128d b);    // | _mm256_unpackhi_pd    | _mm512_unpackhi_pd
```

* 运算： `ret[2i] = a[i]; ret[2i+1] = b[i]`

```c
__m128i _mm_unpacklo_epi8 (__m128i a, __m128i b);  // | _mm256_unpacklo_epi8  | _mm512_unpacklo_epi8
__m128i _mm_unpacklo_epi16 (__m128i a, __m128i b); // | _mm256_unpacklo_epi16 | _mm512_unpacklo_epi16
__m128i _mm_unpacklo_epi32 (__m128i a, __m128i b); // | _mm256_unpacklo_epi32 | _mm512_unpacklo_epi32
__m128i _mm_unpacklo_epi64 (__m128i a, __m128i b); // | _mm256_unpacklo_epi64 | _mm512_unpacklo_epi64

__m128 _mm_unpacklo_ps (__m128 a, __m128 b);       // | _mm256_unpacklo_ps    | _mm512_unpacklo_ps
__m128d _mm_unpacklo_pd (__m128d a, __m128d b);    // | _mm256_unpacklo_pd    | _mm512_unpacklo_pd
```

### 转换

* 运算： `V = {b[0], b[1], a[2], a[3]}`

```c
__m128 _mm_cvt_pi2ps (__m128 a, __m64 b); // _mm_cvtpi32_ps (f32<-f32,s32)
```

* 运算： `V = {a[0], a[1], b[0], b[1]}`

```c
__m128 _mm_cvtpi32x2_ps (__m64 a, __m64 b); // (f32<-s32,s32)
```

* 运算： `ret[i] = a[i]; ret[0] = b`

```c
__m128 _mm_cvt_si2ss (__m128 a, int b); // (f32<-f32,s32)
```

* 运算： `ret[i] = a[i]; ret[0] = b[0]`

```c
__m128h _mm_cvtsd_sh (__m128h a, __m128d b);
__m128 _mm_cvtsd_ss (__m128 a, __m128d b); // (f32<-f32,f64)

__m128h _mm_cvtss_sh (__m128h a, __m128 b);
__m128d _mm_cvtss_sd (__m128d a, __m128 b); // (f64<-f64,f32)

__m128 _mm_cvtsi32_ss (__m128 a, int b); // (f32<-f32,s32)
__m128d _mm_cvtsi32_sd (__m128d a, int b); // (f64<-f64,s32)

__m128 _mm_cvtsi64_ss (__m128 a, __int64 b); // (f32<-f32,s64)
__m128d _mm_cvtsi64_sd (__m128d a, __int64 b); // _mm_cvtsi64x_sd (f64<-f32,s64)
```

* 运算： `ret[i] = 0; ret[0] = a`

```c
__m128i _mm_cvtsi32_si128 (int a); // (s32<-s32)
__m128i _mm_cvtsi64_si128 (__int64 a); // _mm_cvtsi64x_si128  (s64<-s64)
```

* 运算： `ret[i] = a[i]`

```c
__m128i _mm_cvtepi8_epi16 (__m128i a); // (s16<-s8) | _mm256_cvtepi8_epi16
__m128i _mm_cvtepi8_epi32 (__m128i a); // (s32<-s8) | _mm256_cvtepi8_epi32
__m128i _mm_cvtepi8_epi64 (__m128i a); // (s64<-s8) | _mm256_cvtepi8_epi64

__m128i _mm_cvtepu8_epi16 (__m128i a); // (s16<-u8) | _mm256_cvtepu8_epi16
__m128i _mm_cvtepu8_epi32 (__m128i a); // (s32<-u8) | _mm256_cvtepu8_epi32
__m128i _mm_cvtepu8_epi64 (__m128i a); // (s64<-u8) | _mm256_cvtepu8_epi16

__m128i _mm_cvtepi16_epi32 (__m128i a); // (s32<-s16) | _mm256_cvtepi16_epi32
__m128i _mm_cvtepi16_epi64 (__m128i a); // (s64<-s16) | _mm256_cvtepi16_epi64
__m128i _mm_cvtepi32_epi64 (__m128i a); // (s32<-s32) | _mm256_cvtepi32_epi64

__m128i _mm_cvtepu16_epi32 (__m128i a); // (s32<-u16) | _mm256_cvtepu16_epi32
__m128i _mm_cvtepu16_epi64 (__m128i a); // (s64<-u16) | _mm256_cvtepu16_epi64
__m128i _mm_cvtepu32_epi64 (__m128i a); // (s64<-u32) | _mm256_cvtepu32_epi64

__m128 _mm_cvtepi32_ps (__m128i a); // (f32<-s32) | _mm256_cvtepi32_ps
__m128d _mm_cvtepi32_pd (__m128i a); // (f64<-s32) | _mm256_cvtepi32_pd

__m64 _mm_cvtpd_pi32 (__m128d a); // (s32<-f64)
__m128i _mm_cvtpd_epi32 (__m128d a); // (s32<-f64) | _mm256_cvtpd_epi32

__m128 _mm_cvtpi8_ps (__m64 a); // (f32<-s8)
__m128 _mm_cvtpi16_ps (__m64 a); // (f32<-s16)
__m128d _mm_cvtpi32_pd (__m64 a); // (f64<-s32)

__m128 _mm_cvtpd_ps (__m128d a); // (f32<-f64) | _mm256_cvtpd_ps
__m128d _mm_cvtps_pd (__m128 a); // (f64<-f32) | _mm256_cvtps_pd

__m64 _mm_cvtps_pi8 (__m128 a); // 限定范围 (s8<-f32)
__m64 _mm_cvtps_pi16 (__m128 a); // 限定范围 (s16<-f32)
__m64 _mm_cvtps_pi32 (__m128 a); // _mm_cvt_ps2pi (s32<-f32)

__m128i _mm_cvtps_epi32 (__m128 a); // (s32<-f32) | _mm256_cvtps_epi32

__m128 _mm_cvtpu8_ps (__m64 a); // (f32<-u8)
__m128 _mm_cvtpu16_ps (__m64 a); // (f32<-u16)
```

* 运算： `ret = a[0]`

```c
int _mm_cvtss_si32 (__m128 a); // _mm_cvt_ss2si (s32<-f32)
int _mm_cvtsd_si32 (__m128d a); // (s32<-f64)

__int64 _mm_cvtss_si64 (__m128 a); // (s64<-f32)
__int64 _mm_cvtsd_si64 (__m128d a); // _mm_cvtsd_si64x (s64<-f64)

int _mm_cvtsi128_si32 (__m128i a); // (s32<-s32) | _mm256_cvtsi256_si32
__int64 _mm_cvtsi128_si64 (__m128i a); // _mm_cvtsi128_si64x (s64<-s64)

float _mm_cvtss_f32 (__m128 a); // (f32<-f32) | _mm256_cvtss_f32
double _mm_cvtsd_f64 (__m128d a); // (f64<-f64) | _mm256_cvtsd_f64
```

* 运算： `ret[i] = a[i]` 截断

```c
__m64 _mm_cvttps_pi32 (__m128 a); // _mm_cvtt_ps2pi (s32<-f32)
__m64 _mm_cvttpd_pi32 (__m128d a); // (s32<-f64)

__m128i _mm_cvttps_epi32 (__m128 a); // _mm_cvtt_ps2pi (s32<-f32) | _mm256_cvttps_epi32
__m128i _mm_cvttpd_epi32 (__m128d a); // (s32<-f64) | _mm256_cvttpd_epi32
```

* 运算： `ret[i] = a[0]` 截断

```c
int _mm_cvttss_si32 (__m128 a); // _mm_cvtt_ss2si (s32<-f32)
int _mm_cvttsd_si32 (__m128d a); // (s32<-f64)
__int64 _mm_cvttss_si64 (__m128 a); // (s64<-f32)
__int64 _mm_cvttsd_si64 (__m128d a); // _mm_cvttsd_si64x (s64<-f64)
```

* 运算： 关于绝对值的复杂运算

```c
__m128i _mm_mpsadbw_epu8 (__m128i a, __m128i b, const int imm8); // | _mm256_mpsadbw_epu8
```

* 运算：  关于乘法的复杂运算

```c
__m128 _mm_dp_ps (__m128 a, __m128 b, const int imm8);  // | _mm256_dp_ps
__m128d _mm_dp_pd (__m128d a, __m128d b, const int imm8);
```

* 运算： 复杂运算

```c
int _mm_cmpestra (__m128i a, int la, __m128i b, int lb, const int imm8);
int _mm_cmpestrc (__m128i a, int la, __m128i b, int lb, const int imm8);
int _mm_cmpestri (__m128i a, int la, __m128i b, int lb, const int imm8);
__m128i _mm_cmpestrm (__m128i a, int la, __m128i b, int lb, const int imm8);
int _mm_cmpestro (__m128i a, int la, __m128i b, int lb, const int imm8);
int _mm_cmpestrs (__m128i a, int la, __m128i b, int lb, const int imm8);
int _mm_cmpestrz (__m128i a, int la, __m128i b, int lb, const int imm8);
```

* 运算： 复杂运算

```c
int _mm_cmpistra (__m128i a, __m128i b, const int imm8);
int _mm_cmpistrc (__m128i a, __m128i b, const int imm8);
int _mm_cmpistri (__m128i a, __m128i b, const int imm8);
__m128i _mm_cmpistrm (__m128i a, __m128i b, const int imm8);
int _mm_cmpistro (__m128i a, __m128i b, const int imm8);
int _mm_cmpistrs (__m128i a, __m128i b, const int imm8);
int _mm_cmpistrz (__m128i a, __m128i b, const int imm8);
```

* 运算： 舍入

```c
__m128 _mm_round_ps (__m128 a, int rounding);   // | _mm256_round_ps
__m128d _mm_round_pd (__m128d a, int rounding); // | _mm256_round_pd
```

* 运算： 舍入

```c
__m128 _mm_round_ss (__m128 a, __m128 b, int rounding);
__m128d _mm_round_sd (__m128d a, __m128d b, int rounding);
```

* 运算： CRC32

```c
unsigned int _mm_crc32_u8 (unsigned int crc, unsigned char v);
unsigned int _mm_crc32_u16 (unsigned int crc, unsigned short v);
unsigned int _mm_crc32_u32 (unsigned int crc, unsigned int v);
unsigned __int64 _mm_crc32_u64 (unsigned __int64 crc, unsigned __int64 v);
```

### 其它AVX256指令

```c
__m128 _mm_cmp_ps (__m128 a, __m128 b, const int imm8);    // | _mm256_cmp_ps
__m128d _mm_cmp_pd (__m128d a, __m128d b, const int imm8); // | _mm256_cmp_pd

__m128 _mm_cmp_ss (__m128 a, __m128 b, const int imm8);
__m128d _mm_cmp_sd (__m128d a, __m128d b, const int imm8);

__m128 _mm_bcstnebf16_ps (const __bf16 *__A);       // | _mm256_bcstnebf16_ps
__m128 _mm_bcstnesh_ps (const _Float16 *__A);       // | _mm256_bcstnesh_ps

__m128 _mm_cvtneebf16_ps (const __m128bh *__A); // | _mm256_cvtneebf16_ps
__m128 _mm_cvtneeph_ps (const __m128h *__A);    // | _mm256_cvtneeph_ps
__m128 _mm_cvtneobf16_ps (const __m128bh *__A); // | _mm256_cvtneobf16_ps
__m128 _mm_cvtneoph_ps (const __m128h *__A);    // | _mm256_cvtneoph_ps
__m128bh _mm_cvtneps_avx_pbh (__m128 __A);      // | _mm256_cvtneps_avx_pbh
__m128bh _mm_cvtneps_pbh (__m128 __A);          // | _mm256_cvtneps_pbh
__m128 _mm_cvtph_ps (__m128i a);                // | _mm256_cvtph_ps
__m128i _mm_cvtps_ph (__m128 a, int imm8);      // | _mm256_cvtps_ph

__m128i _mm_broadcastb_epi8 (__m128i a);            // | _mm256_broadcastb_epi8  | _mm512_broadcastb_epi8
__m128i _mm_broadcastw_epi16 (__m128i a);           // | _mm256_broadcastw_epi16 | _mm512_broadcastw_epi16
__m128i _mm_broadcastd_epi32 (__m128i a);           // | _mm256_broadcastd_epi32 | _mm512_broadcastd_epi32
__m128i _mm_broadcastq_epi64 (__m128i a);           // | _mm256_broadcastq_epi64 | _mm512_broadcastq_epi64
__m128 _mm_broadcastss_ps (__m128 a);               // | _mm256_broadcastss_ps   | _mm512_broadcastss_ps
__m128d _mm_broadcastsd_pd (__m128d a);             // | _mm256_broadcastsd_pd   | _mm512_broadcastss_pd

__m256i _mm_broadcastsi128_si256 (__m128i a);       // | _mm256_broadcastsi128_si256

__m256 _mm256_broadcast_ps (__m128 const  *mem_addr);
__m256d _mm256_broadcast_pd (__m128d const  *mem_addr);

__m128 _mm_broadcast_ss (float const  *mem_addr);   // | _mm256_broadcast_ss |
__m256d _mm256_broadcast_sd (double const  *mem_addr);

__m128i _mm_dpbssd_epi32 (__m128i __W, __m128i __A, __m128i __B);   // | _mm256_dpbssd_epi32
__m128i _mm_dpbssds_epi32 (__m128i __W, __m128i __A, __m128i __B);  // | _mm256_dpbssds_epi32
__m128i _mm_dpbsud_epi32 (__m128i __W, __m128i __A, __m128i __B);   // | _mm256_dpbsud_epi32
__m128i _mm_dpbsuds_epi32 (__m128i __W, __m128i __A, __m128i __B);  // | _mm256_dpbsuds_epi32
__m128i _mm_dpbusd_avx_epi32 (__m128i src, __m128i a, __m128i b);   // | _mm256_dpbusd_avx_epi32
__m128i _mm_dpbusd_epi32 (__m128i src, __m128i a, __m128i b);       // | _mm256_dpbusd_epi32
__m128i _mm_dpbusds_avx_epi32 (__m128i src, __m128i a, __m128i b);  // | _mm256_dpbusds_avx_epi32
__m128i _mm_dpbusds_epi32 (__m128i src, __m128i a, __m128i b);      // | _mm256_dpbusds_epi32
__m128i _mm_dpbuud_epi32 (__m128i __W, __m128i __A, __m128i __B);   // | _mm256_dpbuud_epi32
__m128i _mm_dpbuuds_epi32 (__m128i __W, __m128i __A, __m128i __B);  // | _mm256_dpbuuds_epi32
__m128i _mm_dpwssd_avx_epi32 (__m128i src, __m128i a, __m128i b);   // | _mm256_dpwssd_avx_epi32
__m128i _mm_dpwssd_epi32 (__m128i src, __m128i a, __m128i b);       // | _mm256_dpwssd_epi32
__m128i _mm_dpwssds_avx_epi32 (__m128i src, __m128i a, __m128i b);  // | _mm256_dpwssds_avx_epi32
__m128i _mm_dpwssds_epi32 (__m128i src, __m128i a, __m128i b);      // | _mm256_dpwssds_epi32
__m128i _mm_dpwsud_epi32 (__m128i __W, __m128i __A, __m128i __B);   // | _mm256_dpwsud_epi32
__m128i _mm_dpwsuds_epi32 (__m128i __W, __m128i __A, __m128i __B);  // | _mm256_dpwsuds_epi32
__m128i _mm_dpwusd_epi32 (__m128i __W, __m128i __A, __m128i __B);   // | _mm256_dpwusd_epi32
__m128i _mm_dpwusds_epi32 (__m128i __W, __m128i __A, __m128i __B);  // | _mm256_dpwusds_epi32
__m128i _mm_dpwuud_epi32 (__m128i __W, __m128i __A, __m128i __B);   // | _mm256_dpwuud_epi32
__m128i _mm_dpwuuds_epi32 (__m128i __W, __m128i __A, __m128i __B);  // | _mm256_dpwuuds_epi32

__m128 _mm256_extractf128_ps (__m256 a, const int imm8);
__m128d _mm256_extractf128_pd (__m256d a, const int imm8);
__m128i _mm256_extractf128_si256 (__m256i a, const int imm8);
__m128i _mm256_extracti128_si256 (__m256i a, const int imm8);

void _mm256_zeroall (void);
void _mm256_zeroupper (void);

__m256i _mm256_zextsi128_si256 (__m128i a);
__m256 _mm256_zextps128_ps256 (__m128 a);
__m256d _mm256_zextpd128_pd256 (__m128d a);

__m256 _mm256_insertf128_ps (__m256 a, __m128 b, int imm8);
__m256d _mm256_insertf128_pd (__m256d a, __m128d b, int imm8);
__m256i _mm256_insertf128_si256 (__m256i a, __m128i b, int imm8);
__m256i _mm256_inserti128_si256 (__m256i a, __m128i b, const int imm8);

__m256i _mm256_loadu2_m128i (__m128i const *hiaddr, __m128i const *loaddr);
__m256 _mm256_loadu2_m128 (float const *hiaddr, float const *loaddr);
__m256d _mm256_loadu2_m128d (double const *hiaddr, double const *loaddr);

void _mm256_storeu2_m128i (__m128i *hiaddr, __m128i *loaddr, __m256i a);
void _mm256_storeu2_m128 (float *hiaddr, float *loaddr, __m256 a);
void _mm256_storeu2_m128d (double *hiaddr, double *loaddr, __m256d a);

__m128i _mm_madd52hi_avx_epu64 (__m128i __X, __m128i __Y, __m128i __Z); // | _mm256_madd52hi_avx_epu64
__m128i _mm_madd52hi_epu64 (__m128i __X, __m128i __Y, __m128i __Z); // | _mm256_madd52hi_epu64
__m128i _mm_madd52lo_avx_epu64 (__m128i __X, __m128i __Y, __m128i __Z); // | _mm256_madd52lo_avx_epu64
__m128i _mm_madd52lo_epu64 (__m128i __X, __m128i __Y, __m128i __Z); // | _mm256_madd52lo_epu64

__m128i _mm_maskload_epi32 (int const *mem_addr, __m128i mask); // | _mm256_maskload_epi32
__m128i _mm_maskload_epi64 (__int64 const *mem_addr, __m128i mask); // | _mm256_maskload_epi64
__m128 _mm_maskload_ps (float const  *mem_addr, __m128i mask); // | _mm256_maskload_ps
__m128d _mm_maskload_pd (double const  *mem_addr, __m128i mask); // | _mm256_maskload_pd

void _mm_maskstore_epi32 (int *mem_addr, __m128i mask, __m128i a); // | _mm256_maskstore_epi32
void _mm_maskstore_epi64 (__int64 *mem_addr, __m128i mask, __m128i a); // | _mm256_maskstore_epi64
void _mm_maskstore_ps (float  *mem_addr, __m128i mask, __m128 a); // | _mm256_maskstore_ps
void _mm_maskstore_pd (double  *mem_addr, __m128i mask, __m128d a); // | _mm256_maskstore_pd

__m128 _mm_permute_ps (__m128 a, int imm8); // | _mm256_permute_ps
__m128d _mm_permute_pd (__m128d a, int imm8); // | _mm256_permute_pd

__m256 _mm256_permute2f128_ps (__m256 a, __m256 b, int imm8);
__m256d _mm256_permute2f128_pd (__m256d a, __m256d b, int imm8);
__m256i _mm256_permute2f128_si256 (__m256i a, __m256i b, int imm8);
__m256i _mm256_permute2x128_si256 (__m256i a, __m256i b, const int imm8);
__m256i _mm256_permute4x64_epi64 (__m256i a, const int imm8);
__m256d _mm256_permute4x64_pd (__m256d a, const int imm8);

__m128 _mm_permutevar_ps (__m128 a, __m128i b); // | _mm256_permutevar_ps
__m128d _mm_permutevar_pd (__m128d a, __m128i b); // | _mm256_permutevar_pd

__m256 _mm256_permutevar8x32_ps (__m256 a, __m256i idx);
__m256i _mm256_permutevar8x32_epi32 (__m256i a, __m256i idx);

__m256i _mm256_sha512msg1_epi64 (__m256i __A, __m128i __B);
__m256i _mm256_sha512msg2_epi64 (__m256i __A, __m256i __B);
__m256i _mm256_sha512rnds2_epi64 (__m256i __A, __m256i __B, __m128i __C);

__m128i _mm_sm3msg1_epi32 (__m128i __A, __m128i __B, __m128i __C);
__m128i _mm_sm3msg2_epi32 (__m128i __A, __m128i __B, __m128i __C);
__m128i _mm_sm3rnds2_epi32 (__m128i __A, __m128i __B, __m128i __C, const int imm8);

__m128i _mm_sm4key4_epi32 (__m128i __A, __m128i __B); // | _mm256_sm4key4_epi32
__m128i _mm_sm4rnds4_epi32 (__m128i __A, __m128i __B); // | _mm256_sm4rnds4_epi32

__m128i _mm_i32gather_epi32 (int const *base_addr, __m128i vindex, const int scale);
__m128i _mm_mask_i32gather_epi32 (__m128i src, int const *base_addr, __m128i vindex, __m128i mask, const int scale);
__m256i _mm256_i32gather_epi32 (int const *base_addr, __m256i vindex, const int scale);
__m256i _mm256_mask_i32gather_epi32 (__m256i src, int const *base_addr, __m256i vindex, __m256i mask, const int scale);
__m128i _mm_i32gather_epi64 (__int64 const *base_addr, __m128i vindex, const int scale);
__m128i _mm_mask_i32gather_epi64 (__m128i src, __int64 const *base_addr, __m128i vindex, __m128i mask, const int scale);
__m256i _mm256_i32gather_epi64 (__int64 const *base_addr, __m128i vindex, const int scale);
__m256i _mm256_mask_i32gather_epi64 (__m256i src, __int64 const *base_addr, __m128i vindex, __m256i mask, const int scale);
__m128d _mm_i32gather_pd (double const *base_addr, __m128i vindex, const int scale);
__m128d _mm_mask_i32gather_pd (__m128d src, double const *base_addr, __m128i vindex, __m128d mask, const int scale);
__m256d _mm256_i32gather_pd (double const *base_addr, __m128i vindex, const int scale);
__m256d _mm256_mask_i32gather_pd (__m256d src, double const *base_addr, __m128i vindex, __m256d mask, const int scale);
__m128 _mm_i32gather_ps (float const *base_addr, __m128i vindex, const int scale);
__m128 _mm_mask_i32gather_ps (__m128 src, float const *base_addr, __m128i vindex, __m128 mask, const int scale);
__m256 _mm256_i32gather_ps (float const *base_addr, __m256i vindex, const int scale);
__m256 _mm256_mask_i32gather_ps (__m256 src, float const *base_addr, __m256i vindex, __m256 mask, const int scale);
__m128i _mm_i64gather_epi32 (int const *base_addr, __m128i vindex, const int scale);
__m128i _mm_mask_i64gather_epi32 (__m128i src, int const *base_addr, __m128i vindex, __m128i mask, const int scale);
__m128i _mm256_i64gather_epi32 (int const *base_addr, __m256i vindex, const int scale);
__m128i _mm256_mask_i64gather_epi32 (__m128i src, int const *base_addr, __m256i vindex, __m128i mask, const int scale);
__m128i _mm_i64gather_epi64 (__int64 const *base_addr, __m128i vindex, const int scale);
__m128i _mm_mask_i64gather_epi64 (__m128i src, __int64 const *base_addr, __m128i vindex, __m128i mask, const int scale);
__m256i _mm256_i64gather_epi64 (__int64 const *base_addr, __m256i vindex, const int scale);
__m256i _mm256_mask_i64gather_epi64 (__m256i src, __int64 const *base_addr, __m256i vindex, __m256i mask, const int scale);
__m128d _mm_i64gather_pd (double const *base_addr, __m128i vindex, const int scale);
__m128d _mm_mask_i64gather_pd (__m128d src, double const *base_addr, __m128i vindex, __m128d mask, const int scale);
__m256d _mm256_i64gather_pd (double const *base_addr, __m256i vindex, const int scale);
__m256d _mm256_mask_i64gather_pd (__m256d src, double const *base_addr, __m256i vindex, __m256d mask, const int scale);
__m128 _mm_i64gather_ps (float const *base_addr, __m128i vindex, const int scale);
__m128 _mm_mask_i64gather_ps (__m128 src, float const *base_addr, __m128i vindex, __m128 mask, const int scale);
__m128 _mm256_i64gather_ps (float const *base_addr, __m256i vindex, const int scale);
__m128 _mm256_mask_i64gather_ps (__m128 src, float const *base_addr, __m256i vindex, __m128 mask, const int scale);
```
