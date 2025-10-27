# Computer Graphics HW2 


## 完成項目
- 3 transformation matrices
- pnpoly 
- bounding box
- Sutherland-Hodgman 
- SSAA(bonus)

## 實作過程
- CGLine HW1使用for loop 實作，這次想改掉(程式碼部分不好看、線也不好看)
- 一開始線段偶發無限迴圈，後來發現是 float→int 的不一致比較，改為固定步數或一致的終止判斷後穩定。
- pnpoly 一直回傳 false：追到是裁剪後頂點被清空，調整 Sutherland–Hodgman 的 inside 方向（依邊界繞向切換叉積號）後恢復正常。
- Bounding Box 最初用 0/999 作初值容易誤判負座標；改為用第一個點初始化再逐點比較，同時在掃描前做 viewport clamp，效率與正確性更好。（若題目要求保留 0/999 也能運作，但需注意座標範圍）
- 黑邊來源其實是「先填充再畫銳利黑線」；在 SSAA 路徑中不再疊加黑色描邊，或描邊改用與填充一致的灰階即可消除異常邊。
- 曾出現「背景白框」：整個 AABB 都寫入像素造成的；改為只在 SSAA 的 viewport 區間初始化與 resolve，且僅對 coverage>0 的樣本寫入即可。
- per-sample depth 很關鍵：兩個形狀相交時，每個子樣本分別深度測試，才不會在邊緣出現「前後錯亂」的雜邊。

## 截圖
- data/CGLAB2.png  

## 實作重點
- CGLine：Bresenham/Midpoint 風格的誤差累積法，依 `e2=2*err` 決定 x/y 的前進，適用所有象限，輸出連續像素。
- pnpoly：Ray-casting（向右射線），遇交點反轉 inside 狀態，對水平邊加 epsilon 避免除零。
- findBoundBox：一次掃描取 `min/max`，縮小填充掃描範圍。
- Sutherland–Hodgman：逐邊裁剪，交點在外→內或內→外時插入，inside 以 cross product 決定並配合邊界繞向。
- 變換：`Trans * RotZ * Scale`，`localToWorld()` 應用於頂點。
- SSAA（2×2）：
  - 在 viewport 啟動 `SSAA_begin(x,y,w,h)` 建立每像素 4 子樣本的 color/depth buffer；shape 在繪製時於子像素 `(0.25,0.25)/(0.75,0.25)/(0.25,0.75)/(0.75,0.75)` 做 pnpoly 覆蓋測試，通過者以 `SSAA_shadeSample(...)` 寫入並做 per-sample depth 測試；最後 `SSAA_resolve()` 平均 4 個子樣本輸出。
  - 優點：邊緣以覆蓋率混色，避免硬邊；per-sample depth 消除重疊時的光暈/黑邊。

## Run
1. 以 Processing 開啟專案並執行 `HW2.pde`。
2. 以左上方按鈕新增 Rectangle/Star；在 Inspector 調 position/rotation/scale。
3. 反鋸齒：已於 viewport 自動啟用（2×2 SSAA）。如需對照關閉，可暫時註解 `ShapeRenderer.pde` 中的 `SSAA_begin/SSAA_resolve`。

## LLM 協助
可惜沒有哆啦A夢，使用Copilot-GPT5：快速拿到矩陣該長怎樣、釐清題目以及演算法細節、**無止盡的幫忙debug**，以及完成SSAA的部分。

