# Computer Graphics HW3

## 完成項目
- Rotation Matrix (Y-axis)
- Matrix4::makeRotX(float a)
- Model Transformation (Model Matrix)
- Camera Transformation (View Matrix)
- Perspective Rendering (Projection Matrix)
- Depth Buffer
- Camera Control
- Backculling
- Bonus: 3D Clipping

## 實作過程
- **Projection Matrix**: 一開始不確定 row-major 與 column-major 的差異，導致透視投影矩陣的索引位置錯誤。後來統一使用 row-major 約定，將 FOV、aspect、near/far 正確映射到 m[0], m[5], m[10], m[11], m[14]，投影才正常運作。
- **View Matrix (LookAt)**: 手動實作 normalize（因為 Vector3 沒有 .normalized()），用叉積計算 right/up/forward 三軸，組成 View = R^T * T^-1。注意相機預設看向 -Z，所以 forward 要取負號。
- **Model Matrix**: 組合順序是 T * Ry * Rx * Rz * S，但一開始 Matrix4.mult 的實作混用了 column-major 索引，導致旋轉與平移錯亂。改為統一 row-major 後，localToWorld 正確運作。
- **getDepth 深度插值**: 最初直接用 Vector3 的 .x/.y/.z 存取（但它們是 private），編譯不過。改用 .x()/.y()/.z() getter 方法。重心座標公式用面積比計算 w0/w1/w2，插值三個頂點的 z 值。
- **加入 getDepth 後模型消失**: 問題在於 DepthFragmentShader 直接輸出 position.z（範圍 -1 到 1），當 z 接近 0 或負值時顯示為黑色（看不見）。解決方法是將 z 映射到 [0, 1]：`depth = (z + 1.0) * 0.5`，再乘以 0.9x 讓整體更暗但可見。
  - **為什麼結果不明顯？** 因為 depth buffer 的視覺化依賴 fragment shader 的顏色輸出。如果 shader 只是回傳深度值本身（在 NDC 空間為 [-1, 1]），大部分像素會落在黑色或深灰色範圍，肉眼難以區分深度差異。必須將深度映射到更小的灰階範圍才能清楚看到前後關係。另外，如果場景中所有物體深度相近（如單一模型），深度變化本來就不大，需要調整相機距離或使用多個物體才能看出明顯效果。
- **相機位置問題**: 初始相機在 (0,0,-10) 看向 (0,0,1)（+Z 方向），但標準透視投影假設相機看向 -Z。改為相機在 (0,0,10) 看向 (0,0,0) 後，深度測試才正常。
- **Position bar太大**: 把bar從[-50,50]改成[-10,10]，不然拉一點點就噴飛
- **Backface Culling**: 在世界空間計算三角形法向量（edge1 × edge2），與視線方向（camera - triCenter）做點積。若 dot ≤ 0 表示背向相機，跳過繪製。

## 截圖
- ![depth buffer visualization](screenshot.png)

## 實作重點
- **Perspective Projection**:
  - FOV 轉弧度：`fovRad = radians(GH_FOV)`
  - 計算 A = 1/(aspect*tan(fov/2))、B = 1/tan(fov/2)
  - C = (far+near)/(near-far)、D = (2*far*near)/(near-far)
  - 矩陣 m[0]=A, m[5]=B, m[10]=C, m[11]=D, m[14]=-1, m[15]=0
- **LookAt (View Matrix)**:
  - forward = normalize(lookat - pos)
  - right = normalize(cross(forward, up))
  - up = cross(right, forward)
  - R^T 的行為 [right; up; -forward]（注意 forward 取負）
  - View = R^T * Trans(-pos)
- **Model Matrix**:
  - M = Trans(position) * RotY(yaw) * RotX(pitch) * RotZ(roll) * Scale
  - 使用 Matrix4.mult(Matrix4) 依序組合，確保 row-major 一致性
- **getDepth (Barycentric)**:
  - 計算三角形面積：`area = (x1-x0)*(y2-y0) - (x2-x0)*(y1-y0)`
  - 重心座標：`w0 = ((x1-x)*(y2-y) - (x2-x)*(y1-y)) / area`
  - 同理計算 w1、w2 = 1 - w0 - w1
  - 插值深度：`z = w0*z0 + w1*z1 + w2*z2`
- **Camera Control**:
  - W/S: 前後移動（cam_position.z ± 0.1）
  - A/D: 左右移動（cam_position.x ± 0.1）
  - Q/E: 上下移動（cam_position.y ± 0.1）
  - Arrow keys: 調整 lookat 位置
  - R: 重置相機到 (0,0,10) 看向 (0,0,0)
- **Backface Culling**:
  - 頂點變換到世界空間：worldVerts = M.MulPoint(localVerts)
  - 計算法向量：normal = cross(edge1, edge2)
  - 視線方向：viewDir = camPos - triCenter
  - 點積測試：if (dot(normal, viewDir) ≤ 0) skip
- **Depth Buffer**:
  - 初始化為 1.0（最遠）
  - 每幀在 setDepthBuffer() 重置
  - 比較：if (GH_DEPTH[index] > z) 更新深度與顏色
  - 視覺化：將 [-1,1] 映射到 [0,1] 再乘 0.7（更暗）

## Run

使用鍵盤控制相機：
   - **W/S**: 前進/後退
   - **A/D**: 左右移動
   - **Q/E**: 上升/下降
   - **方向鍵**: 調整觀看點
   - **R**: 重置相機


## LLM 協助
使用 GitHub Copilot：
- 快速理解透視投影矩陣的推導與索引位置
- 釐清 row-major vs column-major 的差異
- 實作 LookAt 相機矩陣（手動 normalize 與叉積計算）
- **無止盡的 debug getDepth 為何讓模型消失**（結果是眼睛不好顏色太淺了看不到）
- 實作重心座標插值與深度測試邏輯
- 完成相機控制與背面剔除功能
- 修正相機座標系統（從 +Z 看向改為標準 -Z 看向）
