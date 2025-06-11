---
title: IMU四元数解算
date: 2025-06-10 17:19:32
tags: ["Hardware", "Eular Angle", "Quaternion"]
categories: [Hardware]
thumbnail: "/post_images/IMU四元数解算/机械IMU.jpeg"
---

## 前言
图片来自于[维基百科](https://upload.wikimedia.org/wikipedia/commons/5/5d/Centrale-intertielle_missile_S3_Musee_du_Bourget_P1010652.JPG)
{% notel yellow Warn %}
本文章有基础的理论推导，过程可能存在不严谨的地方，着重对四元数的**实际应用**做讨论
此文章的观点或代码仍有瑕疵，若您有更好的解决方案或更正建议欢迎留言讨论
{% endnotel %}
{% notel yellow Warn %}
由于网页渲染出来的latex公式无法正确换行，本文件将用HTML代替latex公式，这也就导致本文件源码可读性非常差，若需要阅读源文件还请看notes文件夹下的[**markdown文件**](https://github.com/eviarch666/Blooooooooooooooog/blob/main/notes/IMU%E5%9B%9B%E5%85%83%E6%95%B0%E8%A7%A3%E7%AE%97.md)。
{% endnotel %}
{% notel green  info %}
本文前部分是关于理论推导，内容比较枯燥。若只关注实际应用请跳转到后文，查阅[**相关代码**](#实际应用于代码中)
本文的代码已通过验证，MCU为AI8051，IMU为imu660ra。角速度通过死区 + 去静态零飘抑制。实际测试静态零漂约为0.046度/秒
{% endnotel %}

## 关于四元数的介绍和理解

### 四元数的产生

对于一个复数，可以写成如下形式
<math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><mtable displaystyle="true" columnalign="right left right left right left right left right left right left" columnspacing="0em 2em 0em 2em 0em 2em 0em 2em 0em 2em 0em" rowspacing="3pt"><mtr><mtd><mi>z</mi><mo>=</mo><mi>ρ</mi><mi>cos</mi><mo data-mjx-texclass="NONE">⁡</mo><mi>α</mi><mo>+</mo><mi>i</mi><mi>ρ</mi><mi>sin</mi><mo data-mjx-texclass="NONE">⁡</mo><mi>α</mi></mtd></mtr></mtable></math>
,运用欧拉公式(Euler's formula) <math xmlns="http://www.w3.org/1998/Math/MathML" display="inline"><mi>ρ</mi><msup><mi>e</mi><mrow><mi>i</mi><mi>α</mi></mrow></msup><mo>=</mo><mi>ρ</mi><mi>cos</mi><mo data-mjx-texclass="NONE">⁡</mo><mi>α</mi><mo>+</mo><mi>i</mi><mi>ρ</mi><mi>sin</mi><mo data-mjx-texclass="NONE">⁡</mo><mi>α</mi></math> 可将三角函数形式的复数转为指数形式 <math xmlns="http://www.w3.org/1998/Math/MathML" display="inline"><mi>z</mi><mo>=</mo><mi>ρ</mi><msup><mi>e</mi><mrow><mi>i</mi><mi>α</mi></mrow></msup></math> 对该复平面内的向量进行旋转操作，假设旋转角度为<math xmlns="http://www.w3.org/1998/Math/MathML" display="inline"><mi>ϕ</mi></math>,则旋转过程如下: 

<math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><mtable displaystyle="true" columnalign="right left right left right left right left right left right left" columnspacing="0em 2em 0em 2em 0em 2em 0em 2em 0em 2em 0em" rowspacing="3pt"><mtr><mtd><mi>z</mi><mo>∗</mo><msup><mi>e</mi><mrow><mi>i</mi><mi>ϕ</mi></mrow></msup><mo>=</mo><mi>ρ</mi><msup><mi>e</mi><mrow><mi>i</mi><mi>α</mi></mrow></msup><mo>∗</mo><msup><mi>e</mi><mrow><mi>i</mi><mi>ϕ</mi></mrow></msup><mo>=</mo><mi>ρ</mi><msup><mi>e</mi><mrow><mi>i</mi><mo stretchy="false">(</mo><mi>α</mi><mo>+</mo><mi>ϕ</mi><mo stretchy="false">)</mo></mrow></msup></mtd></mtr></mtable></math>

该旋转为一个自由度下的变化，对于实际应用来说，一个物品在空间中的矢量有三个自由度。因此我们需要四个变量来描述角度的变化，其中一个实数变量表示旋转的角度大小，剩下三个为虚数，体现旋转轴的方向。我们将这样的四个变量记作： <math xmlns="http://www.w3.org/1998/Math/MathML" display="inline"><mi>q</mi><mo>=</mo><mo stretchy="false">(</mo><mi>w</mi><mo>,</mo><mi>x</mi><mo>,</mo><mi>y</mi><mo>,</mo><mi>z</mi><mo stretchy="false">)</mo></math> 对于一个旋转角度为*θ*的四元数可表示为：

<math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><mi>q</mi><mo>=</mo><mo stretchy="false">(</mo><mi>cos</mi><mo data-mjx-texclass="NONE">⁡</mo><mrow><mfrac><mi>θ</mi><mn>2</mn></mfrac></mrow><mo>,</mo><msub><mi>u</mi><mrow><mi>x</mi></mrow></msub><mi>sin</mi><mo data-mjx-texclass="NONE">⁡</mo><mrow><mfrac><mi>θ</mi><mn>2</mn></mfrac></mrow><mo>,</mo><msub><mi>u</mi><mrow><mi>y</mi></mrow></msub><mi>sin</mi><mo data-mjx-texclass="NONE">⁡</mo><mrow><mfrac><mi>θ</mi><mn>2</mn></mfrac></mrow><mo>,</mo><msub><mi>u</mi><mrow><mi>z</mi></mrow></msub><mi>sin</mi><mo data-mjx-texclass="NONE">⁡</mo><mrow><mfrac><mi>θ</mi><mn>2</mn></mfrac></mrow><mo stretchy="false">)</mo></math>



- **实部（w）**：与旋转的角度相关，体现旋转的“量”。
- **虚部（x, y, z）**：与旋转轴的方向相关，体现旋转的“方向”。

为了方便，我们有时将其简写为：
<math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><mtable displaystyle="true" columnalign="right left right left right left right left right left right left" columnspacing="0em 2em 0em 2em 0em 2em 0em 2em 0em 2em 0em" rowspacing="3pt"><mtr><mtd><mi>q</mi><mo>=</mo><mo stretchy="false">(</mo><mi>w</mi><mo>,</mo><mrow><mover><mi>v</mi><mo stretchy="false">→</mo></mover></mrow><mo stretchy="false">)</mo></mtd></mtr></mtable></math>
其中
<math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><mtable displaystyle="true" columnalign="right left right left right left right left right left right left" columnspacing="0em 2em 0em 2em 0em 2em 0em 2em 0em 2em 0em" rowspacing="3pt"><mtr><mtd><mrow><mover><mi>v</mi><mo stretchy="false">→</mo></mover></mrow><mo>=</mo><mo stretchy="false">(</mo><mi>x</mi><mo>,</mo><mi>y</mi><mo>,</mo><mi>z</mi><mo stretchy="false">)</mo></mtd></mtr></mtable></math>

这也就是我们常说的**轴角对**：

- **旋转轴**：一个单位向量，表示旋转的轴线方向。
- **旋转角**：一个标量，表示绕该轴旋转的角度。

## 用四元数表示3D旋转矩阵

并不是所有的四元数都能表示三维空间中的一个旋转，只有单位四元数才能正确表示一个旋转。所谓单位四元数即：
<math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><mtable displaystyle="true" columnalign="right left right left right left right left right left right left" columnspacing="0em 2em 0em 2em 0em 2em 0em 2em 0em 2em 0em" rowspacing="3pt"><mtr><mtd><mi>q</mi><mo>=</mo><mo stretchy="false">(</mo><mi>m</mi><mo>,</mo><mrow><mover><mi>v</mi><mo stretchy="false">→</mo></mover></mrow><mo stretchy="false">)</mo><mo>=</mo><mo stretchy="false">(</mo><mi>w</mi><mo>,</mo><mi>x</mi><mo>,</mo><mi>y</mi><mo>,</mo><mi>x</mi><mo stretchy="false">)</mo><mo stretchy="false">(</mo><mo>满足</mo><msup><mi>w</mi><mn>2</mn></msup><mo>+</mo><msup><mi>x</mi><mn>2</mn></msup><mo>+</mo><msup><mi>y</mi><mn>2</mn></msup><mo>+</mo><msup><mi>z</mi><mn>2</mn></msup><mo>=</mo><mn>1</mn><mo stretchy="false">)</mo></mtd></mtr></mtable></math>
对一个3D向量：
<math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><mtable displaystyle="true" columnalign="right left right left right left right left right left right left" columnspacing="0em 2em 0em 2em 0em 2em 0em 2em 0em 2em 0em" rowspacing="3pt"><mtr><mtd><mrow><mover><mi>p</mi><mo stretchy="false">→</mo></mover></mrow><mo>=</mo><mo stretchy="false">(</mo><msub><mi>p</mi><mrow><mi>x</mi></mrow></msub><mo>,</mo><msub><mi>p</mi><mrow><mi>y</mi></mrow></msub><mo>,</mo><msub><mi>p</mi><mrow><mi>z</mi></mrow></msub><mo stretchy="false">)</mo></mtd></mtr></mtable></math>
其旋转后的向量可表示为：
<math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><mrow><mover><msup><mi>p</mi><mrow><msup><mi></mi><mo>′</mo></msup></mrow></msup><mo stretchy="false">→</mo></mover></mrow><mo>=</mo><mi>q</mi><mo>.</mo><mrow><mover><mi>p</mi><mo stretchy="false">→</mo></mover></mrow><mo>.</mo><msup><mi>q</mi><mrow><mo>−</mo><mn>1</mn></mrow></msup></math>

### 计算旋转矩阵

**(1)计算q⋅p**

设：
<math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><mtable displaystyle="true" columnalign="right left right left right left right left right left right left" columnspacing="0em 2em 0em 2em 0em 2em 0em 2em 0em 2em 0em" rowspacing="3pt"><mtr><mtd><mrow><mover><mi>q</mi><mo stretchy="false">→</mo></mover></mrow><mo>=</mo><mi>w</mi><mo>+</mo><mi>x</mi><mi>i</mi><mo>+</mo><mi>y</mi><mi>j</mi><mo>+</mo><mi>z</mi><mi>k</mi><mo>,</mo><mstyle scriptlevel="0"><mspace width="1em"></mspace></mstyle><mrow><mover><mi>p</mi><mo stretchy="false">→</mo></mover></mrow><mo>=</mo><mn>0</mn><mo>+</mo><msub><mi>p</mi><mrow><mi>x</mi></mrow></msub><mi>i</mi><mo>+</mo><msub><mi>p</mi><mrow><mi>y</mi></mrow></msub><mi>j</mi><mo>+</mo><msub><mi>p</mi><mrow><mi>z</mi></mrow></msub><mi>k</mi></mtd></mtr></mtable></math>
则
<math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><mtable displaystyle="true" columnalign="right left right left right left right left right left right left" columnspacing="0em 2em 0em 2em 0em 2em 0em 2em 0em 2em 0em" rowspacing="3pt"><mtr><mtd><mrow><mover><mi>q</mi><mo stretchy="false">→</mo></mover></mrow><mo>.</mo><mrow><mover><mi>p</mi><mo stretchy="false">→</mo></mover></mrow></mtd><mtd><mi></mi><mo>=</mo><mo stretchy="false">(</mo><mi>w</mi><mo>+</mo><mi>x</mi><mi>i</mi><mo>+</mo><mi>y</mi><mi>j</mi><mo>+</mo><mi>z</mi><mi>k</mi><mo stretchy="false">)</mo><mo stretchy="false">(</mo><mn>0</mn><mo>+</mo><msub><mi>p</mi><mrow><mi>x</mi></mrow></msub><mi>i</mi><mo>+</mo><mo>+</mo><msub><mi>p</mi><mrow><mi>y</mi></mrow></msub><mi>j</mi><mo>+</mo><msub><mi>p</mi><mrow><mi>z</mi></mrow></msub><mi>k</mi><mo stretchy="false">)</mo></mtd></mtr><mtr><mtd></mtd><mtd><mi></mi><mo>=</mo><mo stretchy="false">(</mo><mo>−</mo><mi>x</mi><msub><mi>p</mi><mrow><mi>x</mi></mrow></msub><mo>−</mo><mi>y</mi><msub><mi>p</mi><mrow><mi>y</mi></mrow></msub><mo>−</mo><mi>z</mi><msub><mi>p</mi><mrow><mi>z</mi></mrow></msub><mo stretchy="false">)</mo><mo>+</mo><mo stretchy="false">(</mo><mi>w</mi><msub><mi>p</mi><mrow><mi>x</mi></mrow></msub><mo>+</mo><mi>y</mi><msub><mi>p</mi><mrow><mi>z</mi></mrow></msub><mo>−</mo><mi>z</mi><msub><mi>p</mi><mrow><mi>y</mi></mrow></msub><mo stretchy="false">)</mo><mi>i</mi><mo>+</mo><mo stretchy="false">(</mo><mi>w</mi><msub><mi>p</mi><mrow><mi>y</mi></mrow></msub><mo>+</mo><mi>z</mi><msub><mi>p</mi><mrow><mi>x</mi></mrow></msub><mo>−</mo><mi>x</mi><msub><mi>p</mi><mrow><mi>z</mi></mrow></msub><mo stretchy="false">)</mo><mi>j</mi><mo>+</mo><mo stretchy="false">(</mo><mi>w</mi><msub><mi>p</mi><mrow><mi>z</mi></mrow></msub><mo>+</mo><mi>x</mi><msub><mi>p</mi><mrow><mi>y</mi></mrow></msub><mo>−</mo><mi>y</mi><msub><mi>p</mi><mrow><mi>x</mi></mrow></msub><mo stretchy="false">)</mo><mi>k</mi></mtd></mtr></mtable></math>
记
<math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><mrow data-mjx-texclass="INNER"><mo data-mjx-texclass="OPEN">{</mo><mtable columnalign="left left" columnspacing="1em" rowspacing=".2em"><mtr><mtd><mi>a</mi><mo>=</mo><mo>−</mo><mi>x</mi><msub><mi>p</mi><mrow><mi>x</mi></mrow></msub><mo>−</mo><mi>y</mi><msub><mi>p</mi><mrow><mi>y</mi></mrow></msub><mo>−</mo><mi>z</mi><msub><mi>p</mi><mrow><mi>z</mi></mrow></msub></mtd></mtr><mtr><mtd><mi>b</mi><mo>=</mo><mi>w</mi><msub><mi>p</mi><mrow><mi>x</mi></mrow></msub><mo>+</mo><mi>y</mi><msub><mi>p</mi><mrow><mi>z</mi></mrow></msub><mo>−</mo><mi>z</mi><msub><mi>p</mi><mrow><mi>y</mi></mrow></msub></mtd></mtr><mtr><mtd><mi>c</mi><mo>=</mo><mi>w</mi><msub><mi>p</mi><mrow><mi>y</mi></mrow></msub><mo>+</mo><mi>z</mi><msub><mi>p</mi><mrow><mi>x</mi></mrow></msub><mo>−</mo><mi>x</mi><msub><mi>p</mi><mrow><mi>z</mi></mrow></msub></mtd></mtr><mtr><mtd><mi>d</mi><mo>=</mo><mi>w</mi><msub><mi>p</mi><mrow><mi>z</mi></mrow></msub><mo>+</mo><mi>x</mi><msub><mi>p</mi><mrow><mi>y</mi></mrow></msub><mo>−</mo><mi>y</mi><msub><mi>p</mi><mrow><mi>x</mi></mrow></msub></mtd></mtr></mtable><mo data-mjx-texclass="CLOSE" fence="true" stretchy="true" symmetric="true"></mo></mrow></math>
**(2) 计算 (q⋅p)⋅q−1**
<math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><mtable displaystyle="true" columnalign="right left right left right left right left right left right left" columnspacing="0em 2em 0em 2em 0em 2em 0em 2em 0em 2em 0em" rowspacing="3pt"><mtr><mtd></mtd><mtd><msup><mrow><mover><mi>q</mi><mo stretchy="false">→</mo></mover></mrow><mrow><mo>−</mo><mn>1</mn></mrow></msup><mo>=</mo><mi>w</mi><mo>−</mo><mi>x</mi><mi>i</mi><mo>−</mo><mi>y</mi><mi>j</mi><mo>−</mo><mi>z</mi><mi>k</mi><mo>,</mo><mo>所以：</mo></mtd></mtr><mtr><mtd></mtd><mtd><mi></mi><mo stretchy="false">(</mo><mi>a</mi><mo>+</mo><mi>b</mi><mi>i</mi><mo>+</mo><mi>c</mi><mi>j</mi><mo>+</mo><mi>d</mi><mi>k</mi><mo stretchy="false">)</mo><mo stretchy="false">(</mo><mi>w</mi><mo>−</mo><mi>x</mi><mi>i</mi><mo>−</mo><mi>y</mi><mi>j</mi><mo>−</mo><mi>z</mi><mi>k</mi><mo stretchy="false">)</mo></mtd></mtr><mtr><mtd></mtd><mtd><mi></mi><mo>展开后为：</mo></mtd></mtr><mtr><mtd></mtd><mtd><mrow data-mjx-texclass="INNER"><mo data-mjx-texclass="OPEN">{</mo><mtable displaystyle="true" columnalign="right left right left right left right left right left right left" columnspacing="0em 2em 0em 2em 0em 2em 0em 2em 0em 2em 0em" rowspacing="3pt"><mtr><mtd><msubsup><mi>p</mi><mrow><mi>x</mi></mrow><mrow><msup><mi></mi><mo>′</mo></msup></mrow></msubsup><mo>=</mo><mo stretchy="false">(</mo><mo>−</mo><mi>a</mi><mi>x</mi><mo>+</mo><mi>b</mi><mi>w</mi><mo>−</mo><mi>c</mi><mi>z</mi><mo>+</mo><mi>d</mi><mi>y</mi><mo stretchy="false">)</mo></mtd></mtr><mtr><mtd><msubsup><mi>p</mi><mrow><mi>y</mi></mrow><mrow><msup><mi></mi><mo>′</mo></msup></mrow></msubsup><mo>=</mo><mo stretchy="false">(</mo><mo>−</mo><mi>a</mi><mi>y</mi><mo>+</mo><mi>b</mi><mi>z</mi><mo>+</mo><mi>c</mi><mi>w</mi><mo>−</mo><mi>d</mi><mi>x</mi><mo stretchy="false">)</mo></mtd></mtr><mtr><mtd><msubsup><mi>p</mi><mrow><mi>z</mi></mrow><mrow><msup><mi></mi><mo>′</mo></msup></mrow></msubsup><mo>=</mo><mo stretchy="false">(</mo><mo>−</mo><mi>a</mi><mi>z</mi><mo>−</mo><mi>b</mi><mi>y</mi><mo>+</mo><mi>c</mi><mi>x</mi><mo>+</mo><mi>d</mi><mi>w</mi><mo stretchy="false">)</mo></mtd></mtr></mtable><mo data-mjx-texclass="CLOSE" fence="true" stretchy="true" symmetric="true"></mo></mrow></mtd></mtr></mtable></math>

**(3)整理成矩阵形式**

将a,b,c,d代入上方程组中，可整理出**旋转矩阵**：
<math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><msup><mrow><mover><mi>p</mi><mo stretchy="false">→</mo></mover></mrow><mrow><msup><mi></mi><mo>′</mo></msup></mrow></msup><mo>=</mo><mi>R</mi><mrow><mover><mi>p</mi><mo stretchy="false">→</mo></mover></mrow><mspace linebreak="newline"></mspace><mi>R</mi><mo>=</mo><mrow data-mjx-texclass="INNER"><mo data-mjx-texclass="OPEN">[</mo><mtable columnspacing="1em" rowspacing="4pt"><mtr><mtd><mn>1</mn><mo>−</mo><mn>2</mn><msup><mi>y</mi><mrow><mn>2</mn></mrow></msup><mo>−</mo><mn>2</mn><msup><mi>z</mi><mrow><mn>2</mn></mrow></msup></mtd><mtd><mn>2</mn><mi>x</mi><mi>y</mi><mo>−</mo><mn>2</mn><mi>w</mi><mi>z</mi></mtd><mtd><mn>2</mn><mi>x</mi><mi>y</mi><mo>+</mo><mn>2</mn><mi>w</mi><mi>z</mi></mtd></mtr><mtr><mtd><mn>2</mn><mi>x</mi><mi>y</mi><mo>+</mo><mn>2</mn><mi>w</mi><mi>z</mi></mtd><mtd><mn>1</mn><mo>−</mo><mn>2</mn><msup><mi>x</mi><mn>2</mn></msup><mo>−</mo><mn>2</mn><msup><mi>z</mi><mn>2</mn></msup></mtd><mtd><mn>2</mn><mi>y</mi><mi>z</mi><mo>−</mo><mn>2</mn><mi>w</mi><mi>x</mi></mtd></mtr><mtr><mtd><mn>2</mn><mi>x</mi><mi>z</mi><mo>−</mo><mn>2</mn><mi>w</mi><mi>y</mi></mtd><mtd><mn>2</mn><mi>y</mi><mi>z</mi><mo>+</mo><mn>2</mn><mi>w</mi><mi>x</mi></mtd><mtd><mn>1</mn><mo>−</mo><mn>2</mn><msup><mi>x</mi><mn>2</mn></msup><mo>−</mo><mn>2</mn><msup><mi>y</mi><mn>2</mn></msup></mtd></mtr></mtable><mo data-mjx-texclass="CLOSE">]</mo></mrow></math>
{% notel green  info %}
该旋转矩阵较为重要，在本文后续还会用到
{% endnotel %}

---

## 四元数的关键公式推导

1. 四元数和角速度的关系

   对于给定一个角速度，我们需要找到四元数如何随时间变化。角速度 *ω* 描述了旋转的变化率。四元数的导数 *q’* 可以通过以下方式与 *ω* 关联：

   设角速度为：
   <math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><mi>ω</mi><mo>=</mo><mo stretchy="false">[</mo><msub><mi>ω</mi><mrow><mi>x</mi></mrow></msub><mo>,</mo><msub><mi>ω</mi><mrow><mi>y</mi></mrow></msub><mo>,</mo><msub><mi>ω</mi><mrow><mi>z</mi></mrow></msub><mo stretchy="false">]</mo></math>

   1. 对于一个旋转矩阵 *R*(*t*)，其时间导数满足：
   <math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><mtable displaystyle="true" columnspacing="1em" rowspacing="3pt"><mtr><mtd><msup><mi>R</mi><mrow><msup><mi></mi><mo>′</mo></msup></mrow></msup><mo>=</mo><mo stretchy="false">[</mo><mi>ω</mi><msub><mo stretchy="false">]</mo><mrow><mo>×</mo></mrow></msub><mi>R</mi></mtd></mtr><mtr><mtd></mtd></mtr><mtr><mtd><mo>其中，</mo><mo stretchy="false">[</mo><mi>ω</mi><msub><mo stretchy="false">]</mo><mrow><mo>×</mo></mrow></msub><mo>为</mo><mi>ω</mi><mo>的反对称矩阵:</mo></mtd></mtr><mtr><mtd></mtd></mtr><mtr><mtd><mo stretchy="false">[</mo><mi>ω</mi><msub><mo stretchy="false">]</mo><mrow><mo>×</mo></mrow></msub><mo>=</mo><mrow data-mjx-texclass="INNER"><mo data-mjx-texclass="OPEN">[</mo><mtable columnspacing="1em" rowspacing="4pt"><mtr><mtd><mn>0</mn></mtd><mtd><mo>−</mo><msub><mi>ω</mi><mrow><mi>z</mi></mrow></msub></mtd><mtd><msub><mi>ω</mi><mrow><mi>y</mi></mrow></msub></mtd></mtr><mtr><mtd><msub><mi>ω</mi><mrow><mi>z</mi></mrow></msub></mtd><mtd><mn>0</mn></mtd><mtd><mo>−</mo><msub><mi>ω</mi><mrow><mi>x</mi></mrow></msub></mtd></mtr><mtr><mtd><mo>−</mo><msub><mi>ω</mi><mrow><mi>y</mi></mrow></msub></mtd><mtd><msub><mi>ω</mi><mrow><mi>x</mi></mrow></msub></mtd><mtd><mn>0</mn></mtd></mtr></mtable><mo data-mjx-texclass="CLOSE">]</mo></mrow></mtd></mtr></mtable></math>
   
   2. 四元数的倒数
   
      通过微分 *R* 并利用 *R=[*ω*]×R*，可以推导出四元数的导数 *q’*。这个过程涉及大量的代数运算，最终得到：
      <math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><mtable displaystyle="true" columnspacing="1em" rowspacing="3pt"><mtr><mtd><msup><mi>q</mi><mrow><msup><mi></mi><mo>′</mo></msup></mrow></msup><mo>=</mo><mfrac><mn>1</mn><mn>2</mn></mfrac><mi>q</mi><mo>×</mo><msub><mi>ω</mi><mrow><mi>q</mi></mrow></msub></mtd></mtr><mtr><mtd><mo>其中</mo><msub><mi>ω</mi><mrow><mi>q</mi></mrow></msub><mo>是一个纯四元数（无实部），表示为：</mo></mtd></mtr><mtr><mtd><msub><mi>ω</mi><mrow><mi>q</mi></mrow></msub><mo>=</mo><mo stretchy="false">[</mo><mn>0</mn><mo>,</mo><msub><mi>ω</mi><mrow><mi>x</mi></mrow></msub><mo>,</mo><msub><mi>ω</mi><mrow><mi>y</mi></mrow></msub><mo>,</mo><msub><mi>ω</mi><mrow><mi>z</mi></mrow></msub><mo stretchy="false">]</mo></mtd></mtr></mtable></math>

---

## 从角速度到四元数

假设当前四元数为<math xmlns="http://www.w3.org/1998/Math/MathML" display="inline"><mi>q</mi><mo>=</mo><mo stretchy="false">(</mo><mi>w</mi><mo>,</mo><mi>x</mi><mo>,</mo><mi>y</mi><mo>,</mo><mi>z</mi><mo stretchy="false">)</mo></math>,角速度为<math xmlns="http://www.w3.org/1998/Math/MathML" display="inline"><mi>ω</mi><mo>=</mo><mo stretchy="false">(</mo><mn>0</mn><mo>,</mo><msub><mi>ω</mi><mrow><mi>x</mi></mrow></msub><mo>,</mo><msub><mi>ω</mi><mrow><mi>y</mi></mrow></msub><mo>,</mo><msub><mi>ω</mi><mrow><mi>z</mi></mrow></msub><mo stretchy="false">)</mo></math>,则四元数倒数为：	<math xmlns="http://www.w3.org/1998/Math/MathML" display="inline"><msup><mi>q</mi><mrow><msup><mi></mi><mo>′</mo></msup></mrow></msup><mo>=</mo><mfrac><mn>1</mn><mn>2</mn></mfrac><mi>q</mi><mo>×</mo><msub><mi>ω</mi><mrow><mi>q</mi></mrow></msub></math> ，展开运算可得：
<math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><mtable displaystyle="true" columnalign="right left right left right left right left right left right left" columnspacing="0em 2em 0em 2em 0em 2em 0em 2em 0em 2em 0em" rowspacing="3pt"><mtr><mtd><msup><mi>w</mi><mrow><msup><mi></mi><mo>′</mo></msup></mrow></msup></mtd><mtd><mi></mi><mo>=</mo><mfrac><mn>1</mn><mn>2</mn></mfrac><mo stretchy="false">(</mo><mo>−</mo><mi>x</mi><msub><mi>ω</mi><mrow><mi>x</mi></mrow></msub><mo>−</mo><mi>y</mi><msub><mi>ω</mi><mrow><mi>y</mi></mrow></msub><mo>−</mo><mi>z</mi><msub><mi>ω</mi><mrow><mi>z</mi></mrow></msub><mo stretchy="false">)</mo></mtd></mtr><mtr><mtd><msup><mi>x</mi><mrow><msup><mi></mi><mo>′</mo></msup></mrow></msup></mtd><mtd><mi></mi><mo>=</mo><mfrac><mn>1</mn><mn>2</mn></mfrac><mo stretchy="false">(</mo><mo>+</mo><mi>w</mi><msub><mi>ω</mi><mrow><mi>x</mi></mrow></msub><mo>+</mo><mi>y</mi><msub><mi>ω</mi><mrow><mi>z</mi></mrow></msub><mo>−</mo><mi>z</mi><msub><mi>ω</mi><mrow><mi>y</mi></mrow></msub><mo stretchy="false">)</mo></mtd></mtr><mtr><mtd><msup><mi>y</mi><mrow><msup><mi></mi><mo>′</mo></msup></mrow></msup></mtd><mtd><mi></mi><mo>=</mo><mfrac><mn>1</mn><mn>2</mn></mfrac><mo stretchy="false">(</mo><mo>+</mo><mi>w</mi><msub><mi>ω</mi><mrow><mi>y</mi></mrow></msub><mo>−</mo><mi>x</mi><msub><mi>ω</mi><mrow><mi>z</mi></mrow></msub><mo>+</mo><mi>z</mi><msub><mi>ω</mi><mrow><mi>x</mi></mrow></msub><mo stretchy="false">)</mo></mtd></mtr><mtr><mtd><msup><mi>z</mi><mrow><msup><mi></mi><mo>′</mo></msup></mrow></msup></mtd><mtd><mi></mi><mo>=</mo><mfrac><mn>1</mn><mn>2</mn></mfrac><mo stretchy="false">(</mo><mo>+</mo><mi>w</mi><msub><mi>ω</mi><mrow><mi>z</mi></mrow></msub><mo>+</mo><mi>x</mi><msub><mi>ω</mi><mrow><mi>y</mi></mrow></msub><mo>−</mo><mi>y</mi><msub><mi>ω</mi><mrow><mi>x</mi></mrow></msub><mo stretchy="false">)</mo></mtd></mtr></mtable></math>
这些导数被用来更新四元数的各个分量，然后进行归一化处理，将会被用于后续的代码中

---

## 关于欧拉角的介绍和理解

### 什么是欧拉角

欧拉角是一种直观描述物体在三维空间中**姿态（Orientation）** 的方法，通过绕三个相互垂直的坐标轴依次旋转来表示。最常用的是 **俯仰角（Pitch）、偏航角（Yaw）、翻滚角（Roll）** 系统。

**三个旋转轴**：
在物体自身坐标系中定义：

- **X轴**（翻滚轴）：指向物体正右方（如飞机右翼方向）。
- **Y轴**（俯仰轴）：指向物体正前方（如飞机机头方向）。
- **Z轴**（偏航轴）：指向物体正上方（如飞机顶部方向）。

> **注意**：必须按固定顺序旋转（如 **Z→Y→X** 或 **Y→X→Z**），不同顺序会得到不同结果。

此处我们使用**ZYX顺序的旋转矩阵**，旋转矩阵 R*R* 由三个基本旋转矩阵相乘得到：

<math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><mtable displaystyle="true" columnspacing="1em" rowspacing="3pt"><mtr><mtd><mi>R</mi><mo>=</mo><msub><mi>R</mi><mrow><mi>z</mi></mrow></msub><mo stretchy="false">(</mo><mi>ψ</mi><mo stretchy="false">)</mo><mo>.</mo><msub><mi>R</mi><mrow><mi>y</mi></mrow></msub><mo stretchy="false">(</mo><mi>θ</mi><mo stretchy="false">)</mo><mo>.</mo><msub><mi>R</mi><mrow><mi>x</mi></mrow></msub><mo stretchy="false">(</mo><mi>ϕ</mi><mo stretchy="false">)</mo></mtd></mtr><mtr><mtd><msub><mi>R</mi><mrow><mi>z</mi></mrow></msub><mo stretchy="false">(</mo><mi>ψ</mi><mo stretchy="false">)</mo><mo>=</mo><mrow data-mjx-texclass="INNER"><mo data-mjx-texclass="OPEN">[</mo><mtable columnspacing="1em" rowspacing="4pt"><mtr><mtd><mi>cos</mi><mo data-mjx-texclass="NONE">⁡</mo><mi>ψ</mi></mtd><mtd><mo>−</mo><mi>sin</mi><mo data-mjx-texclass="NONE">⁡</mo><mi>ψ</mi></mtd><mtd><mn>0</mn></mtd></mtr><mtr><mtd><mi>sin</mi><mo data-mjx-texclass="NONE">⁡</mo><mi>ψ</mi></mtd><mtd><mi>cos</mi><mo data-mjx-texclass="NONE">⁡</mo><mi>ψ</mi></mtd><mtd><mn>0</mn></mtd></mtr><mtr><mtd><mn>0</mn></mtd><mtd><mn>0</mn></mtd><mtd><mn>1</mn></mtd></mtr></mtable><mo data-mjx-texclass="CLOSE">]</mo></mrow><mo>,</mo><mstyle scriptlevel="0"><mspace width="1em"></mspace></mstyle><msub><mi>R</mi><mrow><mi>y</mi></mrow></msub><mo stretchy="false">(</mo><mi>θ</mi><mo stretchy="false">)</mo><mo>=</mo><mrow data-mjx-texclass="INNER"><mo data-mjx-texclass="OPEN">[</mo><mtable columnspacing="1em" rowspacing="4pt"><mtr><mtd><mi>cos</mi><mo data-mjx-texclass="NONE">⁡</mo><mi>θ</mi></mtd><mtd><mn>0</mn></mtd><mtd><mi>sin</mi><mo data-mjx-texclass="NONE">⁡</mo><mi>θ</mi></mtd></mtr><mtr><mtd><mn>0</mn></mtd><mtd><mn>1</mn></mtd><mtd><mn>0</mn></mtd></mtr><mtr><mtd><mo>−</mo><mi>sin</mi><mo data-mjx-texclass="NONE">⁡</mo><mi>θ</mi></mtd><mtd><mn>0</mn></mtd><mtd><mi>cos</mi><mo data-mjx-texclass="NONE">⁡</mo><mi>θ</mi></mtd></mtr></mtable><mo data-mjx-texclass="CLOSE">]</mo></mrow><mo>,</mo><mstyle scriptlevel="0"><mspace width="1em"></mspace></mstyle><msub><mi>R</mi><mrow><mi>x</mi></mrow></msub><mo stretchy="false">(</mo><mi>ϕ</mi><mo stretchy="false">)</mo><mo>=</mo><mrow data-mjx-texclass="INNER"><mo data-mjx-texclass="OPEN">[</mo><mtable columnspacing="1em" rowspacing="4pt"><mtr><mtd><mn>1</mn></mtd><mtd><mn>0</mn></mtd><mtd><mn>0</mn></mtd></mtr><mtr><mtd><mn>0</mn></mtd><mtd><mi>cos</mi><mo data-mjx-texclass="NONE">⁡</mo><mi>ϕ</mi></mtd><mtd><mo>−</mo><mi>sin</mi><mo data-mjx-texclass="NONE">⁡</mo><mi>ϕ</mi></mtd></mtr><mtr><mtd><mn>0</mn></mtd><mtd><mi>sin</mi><mo data-mjx-texclass="NONE">⁡</mo><mi>ϕ</mi></mtd><mtd><mi>cos</mi><mo data-mjx-texclass="NONE">⁡</mo><mi>ϕ</mi></mtd></mtr></mtable><mo data-mjx-texclass="CLOSE">]</mo></mrow></mtd></mtr></mtable></math>

则最终R为：

<math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><mi>R</mi><mo>=</mo><mrow data-mjx-texclass="INNER"><mo data-mjx-texclass="OPEN">[</mo><mtable columnspacing="1em" rowspacing="4pt"><mtr><mtd><mi>cos</mi><mo data-mjx-texclass="NONE">⁡</mo><mi>ψ</mi><mi>cos</mi><mo data-mjx-texclass="NONE">⁡</mo><mi>θ</mi></mtd><mtd><mi>cos</mi><mo data-mjx-texclass="NONE">⁡</mo><mi>ψ</mi><mi>sin</mi><mo data-mjx-texclass="NONE">⁡</mo><mi>θ</mi><mi>sin</mi><mo data-mjx-texclass="NONE">⁡</mo><mi>ϕ</mi><mo>−</mo><mi>sin</mi><mo data-mjx-texclass="NONE">⁡</mo><mi>ψ</mi><mi>cos</mi><mo data-mjx-texclass="NONE">⁡</mo><mi>ϕ</mi></mtd><mtd><mi>cos</mi><mo data-mjx-texclass="NONE">⁡</mo><mi>ψ</mi><mi>sin</mi><mo data-mjx-texclass="NONE">⁡</mo><mi>θ</mi><mi>cos</mi><mo data-mjx-texclass="NONE">⁡</mo><mi>ϕ</mi><mo>+</mo><mi>sin</mi><mo data-mjx-texclass="NONE">⁡</mo><mi>ψ</mi><mi>sin</mi><mo data-mjx-texclass="NONE">⁡</mo><mi>ϕ</mi></mtd></mtr><mtr><mtd><mi>sin</mi><mo data-mjx-texclass="NONE">⁡</mo><mi>ψ</mi><mi>cos</mi><mo data-mjx-texclass="NONE">⁡</mo><mi>θ</mi></mtd><mtd><mi>sin</mi><mo data-mjx-texclass="NONE">⁡</mo><mi>ψ</mi><mi>sin</mi><mo data-mjx-texclass="NONE">⁡</mo><mi>θ</mi><mi>sin</mi><mo data-mjx-texclass="NONE">⁡</mo><mi>ϕ</mi><mo>+</mo><mi>cos</mi><mo data-mjx-texclass="NONE">⁡</mo><mi>ψ</mi><mi>cos</mi><mo data-mjx-texclass="NONE">⁡</mo><mi>ϕ</mi></mtd><mtd><mi>sin</mi><mo data-mjx-texclass="NONE">⁡</mo><mi>ψ</mi><mi>sin</mi><mo data-mjx-texclass="NONE">⁡</mo><mi>θ</mi><mi>cos</mi><mo data-mjx-texclass="NONE">⁡</mo><mi>ϕ</mi><mo>−</mo><mi>cos</mi><mo data-mjx-texclass="NONE">⁡</mo><mi>ψ</mi><mi>sin</mi><mo data-mjx-texclass="NONE">⁡</mo><mi>ϕ</mi></mtd></mtr><mtr><mtd><mo>−</mo><mi>sin</mi><mo data-mjx-texclass="NONE">⁡</mo><mi>θ</mi></mtd><mtd><mi>cos</mi><mo data-mjx-texclass="NONE">⁡</mo><mi>θ</mi><mi>sin</mi><mo data-mjx-texclass="NONE">⁡</mo><mi>ϕ</mi></mtd><mtd><mi>cos</mi><mo data-mjx-texclass="NONE">⁡</mo><mi>θ</mi><mi>cos</mi><mo data-mjx-texclass="NONE">⁡</mo><mi>ϕ</mi></mtd></mtr></mtable><mo data-mjx-texclass="CLOSE">]</mo></mrow></math>

读者看到这么长的旋转矩阵可能会大脑发怵，这么长的矩阵，这么多三角函数应该怎么去使用呢？对此不必担心，因为我们只需要用到该矩阵的**一部分元素**。相信读者应该注意到四元数也有一个**旋转矩阵**，我们就要**用四元数求出欧拉角**。

## 从四元数到欧拉角

为了方便表示，设旋转矩阵中的元素为：

<math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><mi>R</mi><mo>=</mo><mrow data-mjx-texclass="INNER"><mo data-mjx-texclass="OPEN">[</mo><mtable columnspacing="1em" rowspacing="4pt"><mtr><mtd><msub><mi>r</mi><mrow><mn>11</mn></mrow></msub></mtd><mtd><msub><mi>r</mi><mrow><mn>12</mn></mrow></msub></mtd><mtd><msub><mi>r</mi><mrow><mn>13</mn></mrow></msub></mtd></mtr><mtr><mtd><msub><mi>r</mi><mrow><mn>21</mn></mrow></msub></mtd><mtd><msub><mi>r</mi><mrow><mn>22</mn></mrow></msub></mtd><mtd><msub><mi>r</mi><mrow><mn>23</mn></mrow></msub></mtd></mtr><mtr><mtd><msub><mi>r</mi><mrow><mn>31</mn></mrow></msub></mtd><mtd><msub><mi>r</mi><mrow><mn>32</mn></mrow></msub></mtd><mtd><msub><mi>r</mi><mrow><mn>33</mn></mrow></msub></mtd></mtr></mtable><mo data-mjx-texclass="CLOSE">]</mo></mrow></math>

1. 计算俯仰角***θ*（Pitch）**:

   从 R*R* 的第三行第一列 r31=−sin⁡θ，得：<math xmlns="http://www.w3.org/1998/Math/MathML" display="inline"><mi>θ</mi><mo>=</mo><mi>arcsin</mi><mo data-mjx-texclass="NONE">⁡</mo><mo stretchy="false">(</mo><mo>−</mo><msub><mi>r</mi><mrow><mn>31</mn></mrow></msub><mo stretchy="false">)</mo></math>

2. 计算偏航角***ψ*（Yaw）**：

   从 R*R* 的第一行和第二行的第一列：<math xmlns="http://www.w3.org/1998/Math/MathML" display="inline"><mi>ψ</mi><mo>=</mo><mi>a</mi><mi>t</mi><mi>a</mi><mi>n</mi><mn>2</mn><mo stretchy="false">(</mo><msub><mi>r</mi><mrow><mn>21</mn></mrow></msub><mo>,</mo><msub><mi>r</mi><mrow><mn>11</mn></mrow></msub><mo stretchy="false">)</mo></math>
{% notel green  info %}
其中 atan2(y,x)atan2(*y*,*x*) 是四象限反正切函数。
{% endnotel %}

3. 计算翻滚角***ϕ*（Roll）**：

   从 R*R* 的第三行第二列和第三列：<math xmlns="http://www.w3.org/1998/Math/MathML" display="inline"><mi>θ</mi><mo>=</mo><mi>a</mi><mi>t</mi><mi>a</mi><mi>n</mi><mn>2</mn><mo stretchy="false">(</mo><msub><mi>r</mi><mrow><mn>32</mn></mrow></msub><mo>,</mo><msub><mi>r</mi><mrow><mn>33</mn></mrow></msub><mo stretchy="false">)</mo></math>

恭喜各位读者，到此时已完成了理论部分的学习，接下来是应用的部分。因为主要应用在于IMU的角度解算，所以我给出了C语言代码。

---

## 实际应用于代码中

### 初始化四元数，读取IMU的角速度值

~~~c
// 四元素参数初始化，需加入staic，保证变量的生命周期
static float q_w = 1.0f;
static float q_x = 0.0f;
static float q_y = 0.0f;
static float q_z = 0.0f;

//辅助变量
float qa, qb, qc;

float gx = DEG_TO_RAD(imu_trans_data.GTX); // 单位需转为rad/s;
float gy = DEG_TO_RAD(imu_trans_data.GTY);
float gz = DEG_TO_RAD(imu_trans_data.GTZ);
~~~

### 计算四元数的倒数，并积分求得四元数



~~~c
// 四元数导数计算
gx *= (0.5f * T);     // 预乘以减少操作，其中T代表代码执行的周期
gy *= (0.5f * T);
gz *= (0.5f * T);
qa = q_w;
qb = q_x;
qc = q_y;
q_w += (-qb * gx - qc * gy - q_z * gz);
q_x += (qa * gx + qc * gz - q_z * gy);
q_y += (qa * gy - qb * gz + q_z * gx);
q_z += (qa * gz + qb * gy - qc * gx);
~~~

### 将四元数进行归一化

单位四元数才能正确表示一个旋转，我们需要单位四元数才能求解出欧拉角

~~~c
// 归一化四元数
recipNorm = 1.0f / sqrt(q_w * q_w + q_x * q_x + q_y * q_y + q_z * q_z);
q_w *= recipNorm;
q_x *= recipNorm;
q_y *= recipNorm;
q_z *= recipNorm;
~~~

### 计算欧拉角

我们已经获得单位四元数了，根据上文的[**转换公式**](#从四元数到欧拉角)可以求得欧拉角

~~~c
// 计算欧拉角
euler_angle.Roll = RAD_TO_DEG(atan2(2.0f * (q_w * q_x + q_y * q_z), 1.0f - 2.0f * (q_x * q_x + q_y * q_y)));
euler_angle.Pitch = RAD_TO_DEG(asin(2.0f * (q_w * q_y - q_z * q_x)));
euler_angle.Yaw = RAD_TO_DEG(atan2(2.0f * (q_w * q_z + q_x * q_y), 1.0f - 2.0f * (q_y * q_y + q_z * q_z)));
~~~

到此，我们已经完成了基础的IMU四元数解算，并且求得了欧拉角的值。

---

## 代码改进

普通IMU，例如MPU6050会提供六个数据，分别是三轴的加速度和三轴的角速度。读者可以看到，上述文章中只使用了三轴的角速度，而没有使用三轴的加速度。我们可以用三轴的加速度来修正角速度误差。本文将采用Mahony互补滤波算法，通过加速度计数据修正陀螺仪的角速度误差。重力方向的测量值（来自加速度计）与当前姿态估计的重力方向之间的误差来校正陀螺仪的漂移。接下来我将直接写出完整的代码，方便各位读者使用。

~~~c
/**
 * @brief 四元素法+动态互补滤波s
 * @note 更大的浮点计算量
 * 
 */
void IMU_Get_EularAngle_Plus(void)
{
    // 四元素参数
    static float q_w = 1.0f;
    static float q_x = 0.0f;
    static float q_y = 0.0f;
    static float q_z = 0.0f;

    // 控制器参数
    static const float imu_Kp = 2.0f;    // 比例增益
    static const float imu_Ki = 0.005f;  // 积分增益
    static float integralFBx = 0.0f, integralFBy = 0.0f, integralFBz = 0.0f;

    // 将原始数据转换为弧度每秒和g
    float ax = imu_trans_data.ATX;
    float ay = imu_trans_data.ATY;  
    float az = imu_trans_data.ATZ;
    float gx = DEG_TO_RAD(imu_trans_data.GTX); // 转为rad/s;
    float gy = DEG_TO_RAD(imu_trans_data.GTY);
    float gz = DEG_TO_RAD(imu_trans_data.GTZ);

    // 辅助变量
    float recipNorm;
    float halfvx, halfvy, halfvz;
    float halfex, halfey, halfez;
    float qa, qb, qc;

    // 加速度计数据校验
    if(ax*ay*az == 0) return;

    // 归一化加速度计测量值（必须先归一化）
    recipNorm = 1.0f / sqrt(ax * ax + ay * ay + az * az);
    ax *= recipNorm;
    ay *= recipNorm;
    az *= recipNorm;

    // 估计重力的方向
    halfvx = q_x * q_z - q_w * q_y;
    halfvy = q_w * q_x + q_y * q_z;
    halfvz = q_w * q_w - 0.5f + q_z * q_z;

    // 误差是估计方向和测量方向的叉积
    halfex = (ay * halfvz - az * halfvy);
    halfey = (az * halfvx - ax * halfvz);
    halfez = (ax * halfvy - ay * halfvx);

    // 计算并应用积分反馈
    if(imu_Ki > 0.0f) {
        integralFBx += imu_Ki * halfex * halfT;    // 积分误差比例增益
        integralFBy += imu_Ki * halfey * halfT;
        integralFBz += imu_Ki * halfez * halfT;
        gx += integralFBx;    // 应用积分反馈
        gy += integralFBy;
        gz += integralFBz;
    } else {
        integralFBx = 0.0f;   // 防止积分饱和
        integralFBy = 0.0f;
        integralFBz = 0.0f;
    }

    // 应用比例反馈
    gx += imu_Kp * halfex;
    gy += imu_Kp * halfey;
    gz += imu_Kp * halfez;

    // 四元数导数计算
    gx *= (0.5f * halfT);     // 预乘以减少操作
    gy *= (0.5f * halfT);
    gz *= (0.5f * halfT);
    qa = q_w;
    qb = q_x;
    qc = q_y;
    q_w += (-qb * gx - qc * gy - q_z * gz);
    q_x += (qa * gx + qc * gz - q_z * gy);
    q_y += (qa * gy - qb * gz + q_z * gx);
    q_z += (qa * gz + qb * gy - qc * gx);

    // 归一化四元数
    recipNorm = 1.0f / sqrt(q_w * q_w + q_x * q_x + q_y * q_y + q_z * q_z);
    q_w *= recipNorm;
    q_x *= recipNorm;
    q_y *= recipNorm;
    q_z *= recipNorm;

    // 存储四元数
    quaternion.qw = q_w;
    quaternion.qx = q_x;
    quaternion.qy = q_y;
    quaternion.qz = q_z;

    // 计算欧拉角
    euler_angle.Roll = RAD_TO_DEG(atan2(2.0f * (q_w * q_x + q_y * q_z), 1.0f - 2.0f * (q_x * q_x + q_y * q_y)));
    euler_angle.Pitch = RAD_TO_DEG(asin(2.0f * (q_w * q_y - q_z * q_x)));
    euler_angle.Yaw = RAD_TO_DEG(atan2(2.0f * (q_w * q_z + q_x * q_y), 1.0f - 2.0f * (q_y * q_y + q_z * q_z)));
}
~~~