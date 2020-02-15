# 概述
扫频信号发生器是微波雷达的重要组成部分，为微波雷达提供本地发射和接收频率源。扫频信号发生器按照一定的频率步长和扫频速率在频率上限和下限间产生频率线性递增和递减的扫频信号。
# 扫频信号特征
$f_l$为频率下限，$f_u$为频率上限，$\vartriangle f$为步进频率间隔，$\vartriangle t$为频率变化速率。一般地，频率递增扫频为正向扫频，频率递减扫频为负向扫频，正向和负向扫频可以采用不同的步进间隔频率和频率变化速率。

![1](https://github.com/TheWrangler/PSTR17R5B/blob/master/png/sweep.png)
# 设计与实现
直接数字合成技术（DDS）采用相位查找表实现频率合成，广泛用于各类型信号发生器。AD9914是一款以DDS技术为基础的频率捷变芯片，可产生高达1.4GHz的频率信号。该芯片通过数字斜坡发生器（DRG）提供频率调谐功能，可产生线性扫频信号。同时，其数字斜坡发射器也可用于产生幅度和相位线性变化的信号。
## 数字斜坡发生器工作机制
数字斜坡发生器是AD9914芯片的核心功能模块，实现频率调谐字$FTW$的累加功能从而实现扫频输出。正向累加速度为AD9914系统时钟$f_{SYS}$的计数$RATE_l$，累加步进为$STEP_l$。负向累加可采用不同的累加速度和累加步进。

![2](https://github.com/TheWrangler/PSTR17R5B/blob/master/png/drg.png)

$DRCTL$为累加控制信号，当为逻辑高时，数字斜坡发生器进行正向累加；当为逻辑低时，数字斜坡发生器进行负向累加。$DROVER$为扫频结束信号，当前频率调谐字$FTW$不等于下限频率调谐字和上限频率调谐字时，$DROVER$处于逻辑低状态，以指示当前正处于扫频过程中。

此外，AD9914的数字斜坡发生器具有非驻留斜坡发生功能。一般地，数字斜坡发生器累加至频率调谐字上限或下限后始终保持该状态不变。使能该功能后，当正向累加至上限频率调谐字时，数字斜坡发生器将自动跳转到下限频率调谐字；当负向累加至下限频率调谐字时，数字斜坡发生器将自动跳转到上限频率调谐字。
## 芯片参数配置
在不使用AD9914内部锁相环的情况下，AD9914使用外部输入参考频率$f_{REF}$的24分频作为内部工作系统时钟$f_{SYS}$，即:

$f_{SYS}=f_{REF}/24$

数字斜坡发生器关键参数包括上、下限频率调谐字$FTW_l$、$FTW_u$，正、负向累计速率$RATE_l$、$RATE_u$，正、负向累加步进$STEP_l$、$STEP_u$。其中，频率调谐字计算过程为：
+ 求$f$与$f_{REF}$的最大公约数$Y$
+ 计算$M=f/Y$，$N=f_{REF}/Y$
+ $FTW=M \times 2^{32}/N$

累加步进$STEP=\vartriangle f \times f_{SYS}/2^{32}$，累加速率$RATE=\vartriangle t \times f_{SYS}$。

以上参数均通过AD9914的并行或串行接口写入对应寄存器。在通过并行接口写入寄存器时，在写入完成后，必须置$IO\_UPDATE$为逻辑高后，数据才从接口缓冲区写入寄存器。
# 验证与测试
采用SPARTAN-6 FPGA搭建的验证测试环境，外部固定频率源为AD9914芯片提供参考频率，FPGA使用AD9914输出的系统时钟$f_{SYS}$进行工作。此时，不能使用$MASTER\_RESET$功能，当AD9914处于$MASTER\_RESET$时，其$f_{SYS}$将停止输出。

![3](https://github.com/TheWrangler/PSTR17R5B/blob/master/png/hw.png)

FPGA软件组成功能模块如图，depack模块用于接收SPI接口工作参数命令并组帧。ad9914_ctrl模块用于通过AD9914并行接口配置寄存器参数。

![4](https://github.com/TheWrangler/PSTR17R5B/blob/master/png/sw.png)

depack接收SPI接口数据并存入fifo的工作时序如图。

![5](https://github.com/TheWrangler/PSTR17R5B/blob/master/png/depack.png)

depack在完成一帧工作参数命令后，其ready信号置高并等待ad9914_ctrl进行读取，其时序如图。

![6](https://github.com/TheWrangler/PSTR17R5B/blob/master/png/cmd_recv_completed.png)

ad9914_ctrl对AD9914进行参数配置时序如图，在配置过程中$DOVER$信号会置低，配置完成后$DOVER$被置高，检测到dctrl信号为高后即开始正向扫频，此时$DOVER$信号置低指示扫频进行中。同时，OSK信号在扫频开始时同步置高允许频率输出，trig信号与OSK完全同步，用于指示扫频开始。

![7](https://github.com/TheWrangler/PSTR17R5B/blob/master/png/init_sweep.png)

在初次完成配置后AD9914即开始初次扫频。在初次扫频结束后，ad9914_ctrl通过控制dctrl信号进行重复扫频，时序如图。

![8](https://github.com/TheWrangler/PSTR17R5B/blob/master/png/resweep.png)