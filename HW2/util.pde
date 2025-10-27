public void CGLine(float x1, float y1, float x2, float y2) {
    // TODO HW2
    //println("CGLine");
    float dx = abs(x2 - x1), dy = abs(y2 - y1);
    float sx = x1 < x2 ? 1 : -1, sy = y1 < y2 ? 1 : -1;
    float err = dx - dy;
    float x = x1, y = y1;
    float steps = dx + dy;
    
    for (float i = 0; i <= steps; i++) {
        // 只有當點在邊界內時才畫點，超出邊界的點跳過但繼續畫線
        if (!outOfBoundary(x, y)) {
            drawPoint(x, y, color(100));
        }
        
        if (abs(x - x2) < 1 && abs(y - y2) < 1) break;
        float e2 = err * 2;
        if (e2 > -dy) { err -= dy; x += sx; }
        if (e2 < dx) { err += dx; y += sy; }
    }
}

public boolean outOfBoundary(float x, float y) {
    //println("t");
    if (x < 0 || x >= width || y < 0 || y >= height)
        return true;
    return false;
}

public void drawPoint(float x, float y, color c) {
    int index = (int) y * width + (int) x;
    if (outOfBoundary(x, y)){
        //println("test");
        return;
    }
    //print("0");
    pixels[index] = c;
}

public float distance(Vector3 a, Vector3 b) {
    Vector3 c = a.sub(b);
    return sqrt(Vector3.dot(c, c));
}

// -------- SSAA (2x2) helper buffer (viewport-scoped) --------
// Minimal super-sampling buffer with per-sample depth for the shape viewport only
int ssaaX = 0, ssaaY = 0, ssaaW = 0, ssaaH = 0;      // viewport region
boolean ssaaActive = false;
final int SSAA_SPP = 4;                               // 2x2
int[] ssaaSampleColor = null;                         // size: ssaaW*ssaaH*SSAA_SPP
float[] ssaaSampleDepth = null;                       // same size
final float SSAA_INF = 1e9;

void SSAA_begin(int vx, int vy, int vw, int vh) {
    ssaaX = int(vx); ssaaY = int(vy); ssaaW = int(vw); ssaaH = int(vh);
    int n = ssaaW * ssaaH * SSAA_SPP;
    if (ssaaSampleColor == null || ssaaSampleColor.length != n) {
        ssaaSampleColor = new int[n];
        ssaaSampleDepth = new float[n];
    }
    // init: background white, far depth
    for (int i = 0; i < n; i++) {
        ssaaSampleColor[i] = color(255);
        ssaaSampleDepth[i] = SSAA_INF;
    }
    ssaaActive = true;
}

boolean SSAA_isActive() { return ssaaActive; }

void SSAA_shadeSample(int px, int py, int sampleIdx, int col, float depth) {
    if (!ssaaActive) return;
    if (px < ssaaX || py < ssaaY || px >= ssaaX + ssaaW || py >= ssaaY + ssaaH) return;
    int localX = px - ssaaX;
    int localY = py - ssaaY;
    int base = (localY * ssaaW + localX) * SSAA_SPP;
    int idx = base + sampleIdx;
    if (depth < ssaaSampleDepth[idx]) {
        ssaaSampleDepth[idx] = depth;
        ssaaSampleColor[idx] = col;
    }
}

void SSAA_resolve() {
    if (!ssaaActive) return;
    loadPixels();
    for (int y = 0; y < ssaaH; y++) {
        int py = ssaaY + y;
        for (int x = 0; x < ssaaW; x++) {
            int px = ssaaX + x;
            int base = (y * ssaaW + x) * SSAA_SPP;
            // average RGBA
            float r = 0, g = 0, b = 0, a = 0;
            for (int s = 0; s < SSAA_SPP; s++) {
                int c = ssaaSampleColor[base + s];
                r += red(c);
                g += green(c);
                b += blue(c);
                a += alpha(c);
            }
            r /= SSAA_SPP; g /= SSAA_SPP; b /= SSAA_SPP; a /= SSAA_SPP;
            int idx = py * width + px;
            if (idx >= 0 && idx < pixels.length) {
                pixels[idx] = color(r, g, b, a);
            }
        }
    }
    updatePixels();
    ssaaActive = false;
}

boolean pnpoly(float x, float y, Vector3[] vertexes) {
    // TODO HW2 
    // You need to check the coordinate p(x,v) if inside the vertices. 
    // If yes return true, vice versa.

    // Defensive: need at least a triangle
    if (vertexes == null || vertexes.length < 3) return false;

    boolean inside = false;
    // Ray-casting to the right
    for (int i = 0, j = vertexes.length - 1; i < vertexes.length; j = i++) {
        float xi = vertexes[i].x, yi = vertexes[i].y;
        float xj = vertexes[j].x, yj = vertexes[j].y;

        boolean intersect = ((yi > y) != (yj > y)) &&
                            (x < (xj - xi) * (y - yi) / ((yj - yi) == 0 ? 1e-6f : (yj - yi)) + xi);
        if (intersect) inside = !inside;
    }
    return inside;
}

public Vector3[] findBoundBox(Vector3[] v) {
    // TODO HW2 
    // You need to find the bounding box of the vertices v.
    // r1 -------
    //   |   /\  |
    //   |  /  \ |
    //   | /____\|
    //    ------- r2

    if (v == null || v.length == 0) return new Vector3[0];

    float minX = v[0].x, maxX = v[0].x;
    float minY = v[0].y, maxY = v[0].y;

    for (Vector3 p : v) {
        if (p.x < minX) minX = p.x;
        if (p.x > maxX) maxX = p.x;
        if (p.y < minY) minY = p.y;
        if (p.y > maxY) maxY = p.y;
    }

    return new Vector3[]{ new Vector3(minX, minY, 0), new Vector3(maxX, maxY, 0) };
}

public Vector3[] Sutherland_Hodgman_algorithm(Vector3[] points, Vector3[] boundary) {
    // TODO HW2
    // Classic Sutherland–Hodgman polygon clipping
    if (points == null || boundary == null || points.length == 0 || boundary.length == 0)
        return new Vector3[0];

    // Start with the subject polygon
    ArrayList<Vector3> output = new ArrayList<Vector3>();
    for (Vector3 p : points) output.add(p);

    // Clip against each edge of the boundary (assumed convex, here the viewport)
    for (int e = 0; e < boundary.length; e++) {
        Vector3 A = boundary[e];
        Vector3 B = boundary[(e + 1) % boundary.length];

        if (output.size() == 0) break;

        ArrayList<Vector3> input = new ArrayList<Vector3>(output);
        output.clear();

        Vector3 S = input.get(input.size() - 1); // start with previous = last
        for (int i = 0; i < input.size(); i++) {
            Vector3 E = input.get(i);
            boolean S_in = inside(S, A, B);   // For our CW clip boundary, inside means cross <= 0
            boolean E_in = inside(E, A, B);

            if (E_in) {
                if (!S_in) {
                    Vector3 I = getIntersection(S, E, A, B);
                    if (I != null) output.add(I);
                }
                output.add(E);
            } else if (S_in) {
                Vector3 I = getIntersection(S, E, A, B);
                if (I != null) output.add(I);
            }
            S = E;
        }
    }

    Vector3[] result = new Vector3[output.size()];
    for (int i = 0; i < output.size(); i++) result[i] = output.get(i);
    return result;
}

boolean inside(Vector3 point, Vector3 edgeStart, Vector3 edgeEnd) {
    // 對於這個特定的邊界框，我們可以直接檢查點是否在矩形內
    // 邊界: (-1,-1) 到 (1,1)
    // 但我們使用更通用的叉積方法，修正方向
    float cross = (edgeEnd.x - edgeStart.x) * (point.y - edgeStart.y) - 
                  (edgeEnd.y - edgeStart.y) * (point.x - edgeStart.x);
    
    // 由於邊界是逆時針定義的，我們需要檢查點是否在邊的左側
    // 但從調試結果看，我們需要反轉邏輯
    return cross <= 0;
}

Vector3 getIntersection(Vector3 p1, Vector3 p2, Vector3 edgeStart, Vector3 edgeEnd) {
    float dx1 = p2.x - p1.x;
    float dy1 = p2.y - p1.y;
    float dx2 = edgeEnd.x - edgeStart.x;
    float dy2 = edgeEnd.y - edgeStart.y;
    
    float denom = dx1 * dy2 - dy1 * dx2;
    if (abs(denom) < 0.0001) return null;
    
    float t = ((edgeStart.x - p1.x) * dy2 - (edgeStart.y - p1.y) * dx2) / denom;
    return new Vector3(p1.x + t * dx1, p1.y + t * dy1, 0);
}
