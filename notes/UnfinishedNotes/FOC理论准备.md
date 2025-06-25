# FOC理论准备

前言：作者本人也是在网上找资料学习的这部分内容，如有错误还请指正。本文中有对其他作者的文章的引用说明，具体引用请看文章中说明，如有忘记声明处还请大家指出。这里也非常推荐大家去看看[稚晖君的教程](https://zhuanlan.zhihu.com/p/147659820)，写得非常详尽。

## 电机的机械角度和电角度

由硬件篇电机部分所描述的，极数的差异而产生了机械角度和电角度（电周期）的概念。机械角度”就是电机旋转一圈的空间几何角度。转子轴从某个位置开始旋转并返回到原位置的角度是360度。而电角度则是将对绕组（线圈）施加电压的开关的一个切换周期视为360度。

> 如果是2极3槽的电机，那么其机械角度和电角度是一致的。而如果是4极6槽，则其机械角度是360度，其电角度是两个周期（也可以表达为“当机械角度为180度时，电角度达到360度”，或者说“在一个电周期内转子只转半圈”）。![ElectricAngle](E:\personal_project\Website\eviarch-blog\notes\UnfinishedNotes\FOC理论准备\ElectricAngle.png)

对于电机的编码器，其角度都是来表示转子的机械角度位置。而电机驱动器输出的电信号则是基于电角度的，因为电信号源于开关一个切换周期的反复。**角度的概念已经变得非常重要**，所以我们需要清楚地了解这些概念以及它们之间的关系。

## 无刷电机控制方式和差异

### 六步换相

无刷电机的**六步换相（Six-Step Commutation）**是一种经典的控制方式，主要用于三相无刷直流电机（BLDC）。它也被称为梯形波控制（Trapezoidal Commutation），因其电压或电流波形呈梯形得名。

#### 六步换相的工作方式

三相BLDC电机有3根绕组（A、B、C），电机驱动器每次**只通电两相，悬空一相**，电流在6个步骤中按顺序换相，从而驱动电机旋转。每个**电周期（Electrical Cycle）**中包含6个换相步骤，每步持续60电角度，因此称为“六步”。

| 步骤 | A相  | B相  | C相  |
| ---- | ---- | ---- | ---- |
| 1    | +    | -    | Z    |
| 2    | +    | Z    | -    |
| 3    | Z    | +    | -    |
| 4    | -    | +    | Z    |
| 5    | -    | Z    | +    |
| 6    | Z    | -    | +    |
> 说明：+为上桥导通，-为下桥导通，Z为高阻/不通电

- 优点：控制算法简单，成本低
- 缺点：精度差，运行不一定流畅平滑，该控制方式很难做到对电机的电流（力矩），位置做到闭环控制。采用方波控制，噪声较大。

### FOC（Field-Oriented Control）控制

- 优点：转矩平稳，噪声小，响应快速。可以进行电流（力矩）、速度、位置三个闭环控制。
- 缺点：成本高，控制算法难度大

## FOC控制原理

对于FOC控制过程来说，最重要的就是对电机相电流的变换和反变换。

### 关键前置知识

#### PWM, SPWM, SVPWM

1. PWM（Pulse Width Modulation 脉冲宽度调制）

   按一定规律改变脉冲序列的脉冲宽度，以调节输出量和波形的一种调制方式。PWM是脉冲宽度调制也就是具有一定脉冲宽度的连续的方波组成。![PWM](E:\personal_project\Website\eviarch-blog\notes\UnfinishedNotes\FOC理论准备\PWM.png)

2. SPWM（Sinusoidal PWM 正弦脉宽调制）

   该技术是基于PWM的，是对脉冲宽度进行正弦规律排列的调制方式。这样其输出可以近似为正弦波。![SVPWM](E:\personal_project\Website\eviarch-blog\notes\UnfinishedNotes\FOC理论准备\SVPWM.png)

   其产生的方式为正弦波和三角波相交而成，其中正弦波相当于调制波，三角波相当于载波，其生成过程如下图。![SVPWM_Generate](E:\personal_project\Website\eviarch-blog\notes\UnfinishedNotes\FOC理论准备\SVPWM_Generate.webp)

   这里我们要注意，三角波（载波）的振幅要大于正弦波（调制波）的振幅，否则正弦波的波峰和波谷就会被“削去”。![SVPWM_FalseGenerate](E:\personal_project\Website\eviarch-blog\notes\UnfinishedNotes\FOC理论准备\SVPWM_FalseGenerate.webp)

3. SVPWM（Space Vector Pulse Width Modulation 电压空间矢量PWM）

   SVPWM和SPWM虽然名字很像，但是其时没有很大的关系。SPWM着重于生成一个可以近似于正弦波的PWM波，对于电机控制来说其关注点只在于它自己需要调制的那个正弦波。而SVPWM则是关注于电机整体，使得输出电压波形尽可能接近于理想的正弦波形，**着眼于如何使电机获得理想圆形磁链轨迹！**对于目前来说，只需要了解这个名词即可，具体学习还在本文后面。

#### Clark变换，Park变换，反Park变换

##### Clark变换

三相电路计算困难，将三相等效成二相。根据基尔霍夫电流定律（KCL）：任意时刻流入节点的电流和等于流出节点的电流和。因此我们只需要知道其中两个电流就可以推导出第三相的电流。其变换过程和变换矩阵如下：
$$
\begin{bmatrix} I_{\alpha} \\ I_{\beta}\end{bmatrix} = K\begin{bmatrix} \cos 0^{\circ}  & -\cos 60^{\circ} & -\cos 60^{\circ} \\ \sin 0^{\circ} & \sin 60^{\circ} & -\sin 60^{\circ}\end{bmatrix}\begin{bmatrix} i_{A} \\ i_{B} \\ i_{C}\end{bmatrix}
$$
比例系数K的值为$\frac{2}{3}$ ，则转换矩阵为：
$$
\begin{bmatrix} \frac{2}{3} & -\frac{1}{3} & -\frac{1}{3} \\ 0 & \frac{1}{\sqrt{3}} & -\frac{1}{\sqrt{3}}\end{bmatrix}
$$


