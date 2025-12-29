# Computer Graphics HW4

## 完成項目
- Barycentric Coordinates (Perspective-Correct Interpolation)
- Phong Shading
- Flat Shading
- Gouraud Shading
- Bonus: Texture Shader

## 實作過程

### Barycentric Coordinates 透視校正插值

一開始我直接用螢幕空間座標計算重心座標，結果發現在透視投影下會出錯，遠處的物體屬性都被壓縮了。後來才知道這是透視投影的特性，需要做透視校正才行。

解決方法是實作 perspective-correct interpolation。首先計算螢幕空間的重心座標 (w0, w1, w2)，然後把每個權重除以對應頂點的 w 分量，得到 `w0/v0.w, w1/v1.w, w2/v2.w`。接著把這三個值加起來做正規化，最後得到正確的插值權重。這樣一來，不管物體在螢幕上哪個位置，插值結果都會是正確的。

關鍵代碼在 util.pde 裡面：
  ```java
  // Screen-space barycentric
  float w0_screen = ((p1.x - px) * (p2.y - py) - (p2.x - px) * (p1.y - py)) / denom;
  float w1_screen = ((p2.x - px) * (p0.y - py) - (p0.x - px) * (p2.y - py)) / denom;
  float w2_screen = 1.0 - w0_screen - w1_screen;
  
  // Perspective-correct weights
  float w0_persp = w0_screen / v0.w;
  float w1_persp = w1_screen / v1.w;
  float w2_persp = w2_screen / v2.w;
  float sum = w0_persp + w1_persp + w2_persp;
  
  return new Vector3(w0_persp/sum, w1_persp/sum, w2_persp/sum);
  ```

### Phong Shading (Per-Fragment)

Phong Shading 在每個像素計算光照，提供最高視覺品質。Vertex Shader 將頂點位置與法向量轉換到世界空間後傳遞給 Fragment Shader。

Fragment Shader 執行主要光照計算。先將插值後的法向量重新正規化（插值會改變向量長度），再計算三種光照分量：環境光 (ambient) 提供基礎亮度、漫反射 (diffuse) 由表面朝向決定、鏡面高光 (specular) 由視角與反射方向決定。最終顏色為三個分量相加後乘上物體顏色。

關鍵代碼在 ColorShader.pde 的 PhongFragmentShader：
  ```java
  Vector3 N = interpolatedNormal.unit_vector();
  Vector3 L = lightDir.unit_vector();
  Vector3 V = viewDir.unit_vector();
  Vector3 R = N.mult(2.0 * N.dot(L)).sub(L);
  
  float diff = max(N.dot(L), 0.0);
  float spec = pow(max(R.dot(V), 0.0), shininess);
  
  Vector3 ambient = ka.mult(AMBIENT_LIGHT);
  Vector3 diffuse = kd.mult(diff);
  Vector3 specular = ks.mult(spec);
  Vector3 finalColor = ambient.add(diffuse).add(specular).mult(albedo);
  ```

實作過程中踩了幾個坑: 一開始忘記把插值後的法向量重新正規化就變得很怪、cube一直很怪(knod很棒)。

### Flat Shading (Per-Face)

Flat Shading 對每個三角形面使用單一顏色，呈現明顯的平面效果。實作時先計算面法向量，使用三角形兩條邊的叉積：

```java
Vector3 edge1 = v1.sub(v0);
Vector3 edge2 = v2.sub(v0);
Vector3 faceNormal = edge1.cross(edge2).unit_vector();
```

Vertex Shader 用面法向量計算一次光照，三個頂點使用相同顏色。Fragment Shader 直接輸出該顏色。

實作時發現使用頂點法向量會造成立方體面之間出現漸層。這是因為頂點法向量是周圍面的平均值，產生平滑過渡效果。改用面法向量後得到正確的平面著色效果。

### Gouraud Shading (Per-Vertex)

Gouraud Shading 在頂點計算光照，再將顏色插值到像素。效率較高，每個三角形僅需計算三次光照（三個頂點），而非像 Phong Shading 對每個像素計算。

Vertex Shader 對每個頂點執行完整 Phong lighting 計算，包含環境光、漫反射、鏡面高光，輸出三個頂點各自的顏色。Fragment Shader 使用 GPU 自動以重心座標插值的頂點顏色。

視覺效果介於 Phong 和 Flat 之間，較 Flat Shading 平滑，但鏡面高光位置較不準確（由插值產生而非實際計算）。

關鍵在 ColorShader.pde 的 GouraudVertexShader：
  ```java
  for (int i = 0; i < 3; i++) {
      Vector3 N = normal[i].unit_vector();
      Vector3 L = lightDir.unit_vector();
      // ... calculate lighting per vertex
      Vector3 color = ambient.add(diffuse).add(specular);
      color_output[i] = new Vector4(color.x, color.y, color.z, 1.0);
  }
  return new Vector4[][] { gl_Position, color_output };
  ```

### Texture Shader (Bonus)

Texture Shader 使用 UV 座標從圖片採樣顏色，實現紋理映射。切換到 TextureMaterial 時會開啟檔案選擇對話框。

Vertex Shader 直接傳遞 UV 座標，不需轉換：

```java
varying_uv[i] = new Vector4(uv[i].x, uv[i].y, 0.0, 1.0);
```

Fragment Shader 將 UV 座標（範圍 0~1）轉換為像素座標，從 PImage.pixels[] 讀取顏色，再將 Processing 的 32-bit color 格式解析為 RGB 分量：

```java
int texX = int(uv.x * (texture.width - 1));
int texY = int(uv.y * (texture.height - 1));
int pixelColor = texture.pixels[texY * texture.width + texX];
float r = ((pixelColor >> 16) & 0xFF) / 255.0;
```

實作時需處理非同步檔案選擇，使用全域變數 `pendingTextureObject` 暫存物件。selectInput() 的回調函數必須定義在主檔案 HW4.pde 中。

## 截圖
- Phong Shading: 最平滑的光照效果，高光明顯
- ![image](https://github.com/KKKenja/3D_Computer-Graphics/blob/main/HW4/data/hw4_phong.png?raw=true)
- - Flat Shading: 平面化外觀，每個面顏色一致
- ![image](https://github.com/KKKenja/3D_Computer-Graphics/blob/main/HW4/data/hw4_flat.png?raw=true)
- - Gouraud Shading: 介於 Phong 與 Flat 之間，頂點間顏色平滑過渡
- ![image](https://github.com/KKKenja/3D_Computer-Graphics/blob/main/HW4/data/hw4_gouraud.png?raw=true)
- - Texture Mapping: UV 座標正確映射紋理
- ![image](https://github.com/KKKenja/3D_Computer-Graphics/blob/main/HW4/data/hw4_texture.png?raw=true)
- ![image](https://github.com/KKKenja/3D_Computer-Graphics/blob/main/HW4/data/hw4_depth.png?raw=true)






## 三種 Shading 比較

| 特性 | Flat Shading | Gouraud Shading | Phong Shading |
|------|--------------|-----------------|---------------|
| 計算位置 | 每個面 | 每個頂點 | 每個像素 |
| 視覺效果 | 平面、多邊形感明顯 | 平滑但高光不準確 | 最真實、高光清晰 |
| 效能 | 最快 | 中等 | 最慢 |
| 法向量插值 | 無（使用面法向量） | 無（插值顏色） | 有（插值法向量） |
| 適用場景 | 低多邊形風格、遠景 | 一般物體 | 高品質渲染 |

## 實作重點

### Perspective-Correct Interpolation

在透視投影裡，如果直接在螢幕空間做線性插值會出問題，遠處的東西會變形。所以要做透視校正插值，核心公式是 `I = (I0/w0 * α + I1/w1 * β + I2/w2 * γ) / (α/w0 + β/w1 + γ/w2)`。所有需要插值的屬性像是顏色、法向量、UV 座標都要用這個方法，不然渲染出來的畫面會怪怪的。

### Lighting Model (Phong Reflection Model)

Phong 光照模型包含三個部分。第一個是環境光 (Ambient)，這是場景的基礎亮度，不管光源在哪都有，公式是 `ambient = ka * AMBIENT_LIGHT * albedo`。

第二個是漫反射 (Diffuse)，跟表面朝向光源的角度有關。表面越正對光源就越亮，公式是 `diffuse = kd * max(dot(N, L), 0) * albedo`。這裡用法向量和光線方向做內積，如果是負的就代表背光，要夾到 0。

第三個是鏡面高光 (Specular)，模擬光滑表面的反光效果。要先算出反射向量 `R = 2 * (N·L) * N - L`，然後看反射方向跟視線方向有多接近，越接近就越亮。公式是 `specular = ks * pow(max(dot(R, V), 0), shininess)`。shininess 這個參數控制高光的銳利度，數值越大高光越集中。

我用的參數是 ka = (0.1, 0.1, 0.1) 給一點點環境光，kd = (0.6, 0.6, 0.6) 讓漫反射佔主導，ks = (0.8, 0.8, 0.8) 給明顯的高光，shininess = 32.0 讓高光不會太散。

### Material System

材質系統用一個列舉 `MaterialEnum { DM, FM, GM, PM, TM }` 來管理不同的材質。點擊 MaterialButton 就會循環切換，順序是 DM (DepthMaterial) → FM (FlatMaterial) → GM (GouraudMaterial) → PM (PhongMaterial) → TM (TextureMaterial)，然後又回到 DM。每種材質都綁定了對應的 VertexShader 和 FragmentShader，切換材質的時候整個渲染流程就會跟著改變。

### Shader Pipeline

整個渲染流程分三個階段。首先是 Vertex Shader，吃進頂點屬性（位置、法向量、UV）和一些統一參數（MVP 矩陣、光源），算出裁剪空間座標 (gl_Position) 和要傳給下一階段的資料 (varying)。

接著是光柵化 (Rasterization)，這個階段是自動的。GPU 會算重心座標、做透視校正插值、還有深度測試，把三角形變成一堆像素。

最後是 Fragment Shader，拿到插值好的資料和其他需要的東西（像紋理、光源），算出每個像素最終的顏色。

## Bug 修復歷程
**上次未修復的bug: 之前一直都有存在選擇obj時若未選擇任何檔案就會當掉,這次有修好這部分**
1. **NullPointerException**: cam_position 未初始化 → 在 setup() 中初始化
2. **檔案選擇崩潰**: 空路徑傳入 loadOBJ → 加入 path.isEmpty() 檢查
3. **ClassCastException**: Vector4 與 Vector3 混用 → 使用 .xyz() 轉換
4. **立方體光照不連續**: 使用插值法向量 → 改用 face normal
5. **相機 slider 不作用**: 未更新相機矩陣 → 在 slider 改變時呼叫 setPositionOrientation()
6. **Depth Material 太亮**: 直接映射深度值 → 加入 pow(depth, 0.4) 增強對比
7. **預設模型太大**: scale = 1.0 → 改為 0.1 (為了塞knod)

## 操作說明

### 載入模型
1. 點擊 "Load obj" 按鈕
2. 選擇 .obj 檔案（需包含法向量與 UV 座標）

### 切換材質
1. 點擊 "MaterialButton" 按鈕
2. 循環切換五種材質
3. 切換到 TextureMaterial 時會要求選擇紋理圖片

### 調整參數
- **Position Sliders**: 調整模型位置 (X, Y, Z: -5 ~ 5)
- **Rotation Sliders**: 調整模型旋轉 (Pitch, Yaw, Roll: -180 ~ 180)
- **Scale Slider**: 調整模型大小 (0.01 ~ 2.0)
- **Color Sliders**: 調整物體顏色 (R, G, B: 0 ~ 1)
- **Light Color Sliders**: 調整光源顏色 (R, G, B: 0 ~ 1)
- **Light Intensity Slider**: 調整光源強度 (0 ~ 3)

### 相機控制
- **W/S**: 前進/後退
- **A/D**: 左右移動
- **Q/E**: 上升/下降
- **方向鍵**: 調整觀看點
- **R**: 重置相機

## 技術挑戰與學習

1. **Perspective-Correct Interpolation**: 理解透視除法對插值的影響，必須在插值前除以 w，插值後再乘回來。
2. **Vector Normalization**: Processing 的 Vector3 沒有 .normalize() 方法，需使用 .unit_vector()。
3. **Lighting Calculation**: 手動實作完整的 Phong reflection model，包括 ambient/diffuse/specular 三個分量。
4. **Shader Architecture**: 設計可擴展的 Shader 系統，支援不同的材質與光照模型。
5. **Face vs Vertex Normal**: 理解 Flat Shading 需要使用面法向量，而非頂點法向量。
6. **Texture Sampling**: 處理 UV 座標轉換與 Processing 的 32-bit color 格式。
7. **Async Callback**: 處理 selectInput() 的非同步檔案選擇回調。

## LLM 協助
使用 GitHub Copilot：
- 理解 perspective-correct interpolation 的數學原理與實作細節
- 實作 Phong/Flat/Gouraud 三種 Shading 的 Vertex/Fragment Shader
- Debug Vector3 normalization 方法（找到正確的 unit_vector() 方法）
- 修正 Flat Shading 的面法向量計算
- 實作 Texture Shader 的 UV 座標傳遞與採樣
- 處理 selectInput 的非同步回調機制
- 優化 Depth Material 的視覺化效果
- 完成所有 bug 修復（從 NullPointerException 到相機控制）

- **Per-face lighting**: 對每個三角形面計算一次光照
- 使用**面法向量**（從三角形三個頂點計算）
- 整個三角形面使用相同的顏色
- 只計算 ambient + diffuse，通常不含 specular

#### 實作方式
```
Vertex Shader:
  - 輸入: 三個頂點位置、頂點法向量
  - 計算: 面法向量 = normalize(cross(edge1, edge2))
  - 計算: 面的中心點作為參考位置
  - 計算光照一次（ambient + diffuse）
  - 輸出: gl_Position、三個頂點相同的顏色

Fragment Shader:
  - 輸入: 插值後的顏色（但因為三個頂點相同，所以沒有插值效果）
  - 輸出: 直接返回該顏色
```

#### 特點
- 計算量最小
- 產生有稜角的視覺效果
- 適合低多邊形風格（Low-poly style）
- 在三角形邊界明顯可見
- **應用場景**: 低多邊形美術風格、預覽模式

#### 關鍵代碼實現
- 檔案：`Material.pde` - `FlatMaterial`
- 檔案：`ColorShader.pde` - `FlatVertexShader`, `FlatFragmentShader`
- **面法向量計算**: `cross(v1-v0, v2-v0).unit_vector()`
- **顏色統一**: 三個頂點都賦予相同顏色值

---

### 3. Gouraud Shading (高洛德著色)

#### 理論原理
- **Per-vertex lighting**: 對每個頂點計算光照
- 使用**頂點法向量**來計算
- 在三角形內部**插值頂點顏色**
- 完整計算 ambient + diffuse + specular

#### 實作方式
```
Vertex Shader:
  - 輸入: 頂點位置、頂點法向量
  - 對每個頂點:
    - 轉換到世界空間
    - 計算完整 Phong 光照（ambient + diffuse + specular）
  - 輸出: gl_Position、三個頂點各自的顏色

Fragment Shader:
  - 輸入: 插值後的顏色（三個頂點顏色的線性插值）
  - 輸出: 直接返回插值後的顏色
```

#### 特點
- 平滑的顏色過渡（比 Flat 好）
- 計算量適中（比 Phong 少）
- 高光效果不準確（在頂點間線性插值會失真）
- 大三角形上可能出現 Mach Band 效應
- **應用場景**: 需要平衡性能和質量的場合

#### 關鍵代碼實現
- 檔案：`Material.pde` - `GouraudMaterial`
- 檔案：`ColorShader.pde` - `GouraudVertexShader`, `GouraudFragmentShader`
- **頂點光照**: 在 vertex shader 中為每個頂點計算 Phong 公式
- **顏色插值**: GPU 自動在三角形內插值三個頂點顏色

---

## 視覺效果比較

| 特性 | Phong Shading | Flat Shading | Gouraud Shading |
|------|---------------|--------------|-----------------|
| 光照計算位置 | Fragment Shader | Vertex Shader (per-face) | Vertex Shader (per-vertex) |
| 法向量類型 | 插值頂點法向量 | 面法向量 | 頂點法向量 |
| 計算次數 | 每個像素 | 每個三角形 | 每個頂點 |
| 視覺平滑度 | 最平滑 | 有稜角 | 較平滑 |
| 高光準確性 | 最準確 | 無高光/不準確 | 不準確 |
| 性能 | 最慢 | 最快 | 中等 |
| 適用場景 | 高質量渲染 | Low-poly 風格 | 性能優先的實時渲染 |

---

## 實作細節與發現

### 1. 透視修正插值 (Perspective-Correct Interpolation)
**關鍵實現**: `util.pde` - `barycentric()` 函數

在透視投影中，直接在螢幕空間插值會產生錯誤。需要：
```
1. 計算螢幕空間重心座標 (α, β, γ)
2. 透視修正：(α/w_A) / ((α/w_A) + (β/w_B) + (γ/w_C))
3. 用修正後的座標插值所有屬性
```

### 2. 法向量變換
- **位置向量**: 使用模型矩陣 M 變換
- **法向量**: 應使用 (M^-1)^T 變換（已在框架中實現）

### 3. 插值後的法向量必須重新歸一化
```processing
Vector3 N = w_normal.unit_vector();  // 關鍵步驟！
```
插值後的向量長度可能不是 1，必須重新歸一化才能正確計算光照。

### 4. Cube 渲染問題分析
**發現**: cube.obj 沒有預定義法向量（無 `vn` 行），需要程序自動計算。

**解決方案**: 修改 `Mesh.pde` 中的 `addFace()` 函數，使用面法向量代替每個頂點獨立計算的法向量，確保同一面的兩個三角形使用一致的法向量。

---

## 渲染管線流程

```
1. GameObject.Draw()
   ↓
2. material.vertexShader(triangle, M)
   ↓ 調用對應的 VertexShader
   ↓ 返回 gl_Position + varying 數據
   ↓
3. 透視除法 (homogenized)
   ↓
4. 光柵化 (Rasterization)
   ↓ 對每個像素
   ↓
5. barycentric() - 計算重心座標（含透視修正）
   ↓
6. interpolation() - 插值 varying 數據
   ↓
7. material.fragmentShader(position, varing)
   ↓ 調用對應的 FragmentShader
   ↓
8. Z-buffer 深度測試
   ↓
9. 寫入 renderBuffer
```

---

## 使用說明

### 切換著色模型
點擊右下角 Inspector 面板中的 **MaterialButton**，會循環切換：
```
DepthMaterial → FlatMaterial → GouraudMaterial → PhongMaterial → ...
```

### 調整參數
- **Position**: 物體位置 (X, Y, Z: -5 ~ 5)
- **Rotation**: 物體旋轉 (X, Y, Z: 0 ~ 2π)
- **Scale**: 物體縮放 (X, Y, Z: 0.1 ~ 3)
- **Color**: 物體顏色 (R, G, B: 0 ~ 1)
- **Light Color**: 光源顏色 (R, G, B: 0 ~ 1)
- **Light Intensity**: 光源強度 (0 ~ 5)

### 載入模型
1. 點擊左上角的方塊圖標
2. 選擇 .obj 文件
3. 模型會以 0.1 倍縮放載入


---

## 總結
作業一至四算是不同次元，隨著作業的深入，寫作業的時間拉得很長(作業一甚至不用跟AI吵架)，不過成品也是越發厲害
完成了三種經典的光照著色，並理解他們。
