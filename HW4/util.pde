public void CGLine(float x1, float y1, float x2, float y2) {
    stroke(0);
    line(x1, y1, x2, y2);
}

public boolean outOfBoundary(float x, float y) {
    if (x < 0 || x >= width || y < 0 || y >= height)
        return true;
    return false;
}

public void drawPoint(float x, float y, color c) {
    int index = (int) y * width + (int) x;
    if (outOfBoundary(x, y))
        return;
    pixels[index] = c;
}

public float distance(Vector3 a, Vector3 b) {
    Vector3 c = a.sub(b);
    return sqrt(Vector3.dot(c, c));
}

boolean pnpoly(float x, float y, Vector3[] vertexes) {
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

public float getDepth(float x, float y, Vector3[] vertex) {
    // TODO HW3
    // You need to calculate the depth (z) in the triangle (vertex) based on the
    // positions x and y. and return the z value;
    
    float x0 = vertex[0].x(), y0 = vertex[0].y(), z0 = vertex[0].z();
    float x1 = vertex[1].x(), y1 = vertex[1].y(), z1 = vertex[1].z();
    float x2 = vertex[2].x(), y2 = vertex[2].y(), z2 = vertex[2].z();
    
    float area = (x1 - x0) * (y2 - y0) - (x2 - x0) * (y1 - y0);
    if (abs(area) < 1e-6) return 0.0;
    
    float w0 = ((x1 - x) * (y2 - y) - (x2 - x) * (y1 - y)) / area;
    float w1 = ((x2 - x) * (y0 - y) - (x0 - x) * (y2 - y)) / area;
    float w2 = 1.0 - w0 - w1;
    
    return w0 * z0 + w1 * z1 + w2 * z2;
}

float[] barycentric(Vector3 P, Vector4[] verts) {

    Vector3 A = verts[0].homogenized();
    Vector3 B = verts[1].homogenized();
    Vector3 C = verts[2].homogenized();

    Vector4 AW = verts[0];
    Vector4 BW = verts[1];
    Vector4 CW = verts[2];

    // TODO HW4
    // Calculate the barycentric coordinates of point P in the triangle verts using
    // the barycentric coordinate system.
    // Please notice that you should use Perspective-Correct Interpolation otherwise
    // you will get wrong answer.

    // Step 1: Calculate 2D barycentric coordinates in screen space
    // Using the cross product method to find the area ratios
    
    // Calculate twice the area of the full triangle ABC
    float areaABC = (B.x - A.x) * (C.y - A.y) - (C.x - A.x) * (B.y - A.y);
    
    // Handle degenerate triangles
    if (abs(areaABC) < 1e-10) {
        return new float[] { 1.0, 0.0, 0.0 };
    }
    
    // Calculate twice the area of sub-triangles
    // Alpha (opposite to vertex A): area of PBC / area of ABC
    float areaPBC = (B.x - P.x) * (C.y - P.y) - (C.x - P.x) * (B.y - P.y);
    float alpha_screen = areaPBC / areaABC;
    
    // Beta (opposite to vertex B): area of APC / area of ABC
    float areaAPC = (C.x - A.x) * (P.y - A.y) - (P.x - A.x) * (C.y - A.y);
    float beta_screen = areaAPC / areaABC;
    
    // Gamma (opposite to vertex C): can be derived from alpha + beta + gamma = 1
    float gamma_screen = 1.0 - alpha_screen - beta_screen;
    
    // Step 2: Perspective-Correct Interpolation
    // The correct formula is:
    // alpha_correct = (alpha_screen / w_A) / ((alpha_screen / w_A) + (beta_screen / w_B) + (gamma_screen / w_C))
    
    float wA = AW.w;
    float wB = BW.w;
    float wC = CW.w;
    
    // Calculate perspective-corrected weights
    float alpha_over_w = alpha_screen / wA;
    float beta_over_w = beta_screen / wB;
    float gamma_over_w = gamma_screen / wC;
    
    float sum = alpha_over_w + beta_over_w + gamma_over_w;
    
    // Normalize to get final perspective-correct barycentric coordinates
    float alpha = alpha_over_w / sum;
    float beta = beta_over_w / sum;
    float gamma = gamma_over_w / sum;
    
    float[] result = { alpha, beta, gamma };

    return result;
}

Vector3 interpolation(float[] abg, Vector3[] v) {
    return v[0].mult(abg[0]).add(v[1].mult(abg[1])).add(v[2].mult(abg[2]));
}

Vector4 interpolation(float[] abg, Vector4[] v) {
    return v[0].mult(abg[0]).add(v[1].mult(abg[1])).add(v[2].mult(abg[2]));
}

float interpolation(float[] abg, float[] v) {
    return v[0] * abg[0] + v[1] * abg[1] + v[2] * abg[2];
}
