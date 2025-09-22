# HW1

![image](https://hackmd.io/_uploads/rkqhV_Rixg.png)


## Task Table


| Task     | Finished(v/x) |
| -------- | -------- | 
| Line algorithm  |   V |
| Circle Algorithm     | V     |
| Ellipse Algorithm     | V     |
| Bézier Curve Algorithm    | V     |
| Eraser     | V     |


### info of task

**1. CGLine**
**先確保x1<=x2，不然由右向左的線無法正常運作**
接下來是先確認斜率，若等於0或無限大則需額外處理

in ```util.pde```:
```java=19
if (x1 > x2) {            // 使x1 <= x2 
   float temp = x2;
   x2 = x1; 
   x1 = temp;
   temp = y2;
   y2 = y1; 
   y1 = temp;
 }                                
 float xDis = abs(x1-x2);
 float yDis = abs(y1-y2);
 float len = sqrt(xDis*xDis + yDis*yDis);

 if(x1 == x2) { //將垂直線(斜率=inf)額外處理
     for(float i=y1;i<=y2;i+=0.01) {
        drawPoint(x1, i, currentDrawColor);
     }
 } else {
     float r = 0;
     if (xDis != 0) r = (y1-y2)/(x1-x2);
     float delta = len/1000;
     if (r>=1 || r<=-1){delta /= abs(r);} //斜率太大會導致點不夠(虛線) 這樣處理能有效增加點數
     for (float i=x1; i<x1 + xDis; i+=delta){
       drawPoint(i, r*i + y1 - (r* x1), currentDrawColor);//線從x1 畫到x2 , y值透過直線方程式計算
     }
 }
```

**2. CGCircle**
**迭代X軸的值，計算Y落在哪後drawPoint**
因為Y值有正負所以要畫兩次
```java=62
float dotNum = r/10000; // 控制點與點的距離
for (float i= x-r ; i< x + r; i+=dotNum){
       drawPoint(i,y+sqrt(r*r-(i-x)*(i-x)),currentDrawColor);
       drawPoint(i,y-sqrt(r*r-(i-x)*(i-x)),currentDrawColor);// 圓形分成上下半圓在畫 (由於圓形方程式有平方導致正負問題)
}
```
**3. CGEllipse**


**解釋同圓形(CGCircle)**，不過換了橢圓方程式

```java=82
float dotNum = r1/10000;
for (float i= x-r1 ; i< x + r1; i+=dotNum){
       drawPoint(i,y+r2*sqrt(1-(i-x)*(i-x)/(r1*r1)),currentDrawColor);
       drawPoint(i,y-r2*sqrt(1-(i-x)*(i-x)/(r1*r1)),currentDrawColor);
}
```


**4. CGCurve**

==先跟gpt要了XY參數式==
![image](https://hackmd.io/_uploads/Bk_bcuCilg.png)
接著就是跟圓形 橢圓一樣的情況

```java=105
for (float i= 0 ; i< 1 ; i+=0.001){
      float x = pow(1-i,3)*p1.x + 3*i*pow((1-i),2)*p2.x + 3*i*i*(1-i)*p3.x+i*i*i*p4.x;
      float y = pow(1-i,3)*p1.y + 3*i*pow((1-i),2)*p2.y + 3*i*i*(1-i)*p3.y+i*i*i*p4.y;
      drawPoint(x,y,currentDrawColor);
}
```

**5. Eraser**

**原本使用了雙重迴圈，因為太卡了所以一維化(請LLM幫我)**
基本上就是掃方塊內的Pixel改成底色
```java=133
float w = p2.x - p1.x;
float h = p2.y - p1.y;
for (int i = 0; i < w * h; i++) {
    float x = p1.x + (i % w);
    float y = p1.y + (i / w);
    drawPoint(x, y, 250);
}
```


---


## Bonus
### **color palette**
![image](https://hackmd.io/_uploads/rkUzB_Coel.png)
You can select color from **12** colors (default : Black)

==使用LLM來寫大致架構==

#### problem
1. 一開始換顏色時，之前畫過的圖形顏色也會改變 => class加入記憶顏色的部分
2. 寫的時候沒用midpoint...

## assistance of LLMs 
1. 貝茲曲線的參數式
2. Eraser的雙重迴圈一階化
3. 調色盤架構及debug



