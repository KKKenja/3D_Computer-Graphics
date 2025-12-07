public class GameObject {
    Transform transform;
    Mesh mesh;
    String name;
    Shader shader;

    GameObject() {
        transform = new Transform();
    }

    GameObject(String fname) {
        transform = new Transform();
        setMesh(fname);
        String[] sn = fname.split("\\\\");
        name = sn[sn.length - 1].substring(0, sn[sn.length - 1].length() - 4);
        shader = new Shader(new DepthVertexShader(), new DepthFragmentShader());
    }

    void reset() {
        transform.position.setZero();
        transform.rotation.setZero();
        transform.scale.setOnes();
    }

    void setMesh(String fname) {
        mesh = new Mesh(fname);
    }

    void Draw() {
        Matrix4 MVP = main_camera.Matrix().mult(localToWorld());
        for (int i=0; i<mesh.triangles.size(); i++) {
            Triangle triangle = mesh.triangles.get(i);
            Vector3[] position = triangle.verts;
            Vector4[] gl_Position = shader.vertex.main(new Object[]{position}, new Object[]{MVP});
            
            // 3D Clipping in clip space
            ArrayList<Vector4> clipped = clip3D(gl_Position);
            if (clipped == null || clipped.size() < 3) continue;
            
            // Triangulate clipped polygon (fan triangulation)
            for (int t = 1; t < clipped.size() - 1; t++) {
                Vector4[] triVerts = new Vector4[] { 
                    clipped.get(0), 
                    clipped.get(t), 
                    clipped.get(t + 1) 
                };
                rasterizeTriangle(triVerts);
            }
        }        
        update();
    }
    
    // Rasterize a single triangle
    void rasterizeTriangle(Vector4[] clipVerts) {
        // Perspective division to NDC
        Vector3[] s_Position = new Vector3[3];
        for (int j = 0; j < 3; j++) {
            s_Position[j] = clipVerts[j].homogenized();
        }
        
        Vector3[] boundbox = findBoundBox(s_Position);
        float minX = map(min( max(boundbox[0].x, -1.0 ), 1.0), -1.0, 1.0, 0.0, renderer_size.z - renderer_size.x);
        float maxX = map(min( max(boundbox[1].x, -1.0 ), 1.0), -1.0, 1.0, 0.0, renderer_size.z - renderer_size.x);
        float minY = map(min( max(boundbox[0].y, -1.0 ), 1.0), -1.0, 1.0, 0.0, renderer_size.w - renderer_size.y);
        float maxY = map(min( max(boundbox[1].y, -1.0 ), 1.0), -1.0, 1.0, 0.0, renderer_size.w - renderer_size.y);
        
        for (int y = int(minY); y < maxY; y++) {
            for (int x = int(minX); x < maxX; x++) {
                float rx = map(x, 0.0, renderer_size.z - renderer_size.x, -1, 1);
                float ry = map(y, 0.0, renderer_size.w - renderer_size.y, -1, 1);
                if (!pnpoly(rx, ry, s_Position)) continue;
                int index = y * int(renderer_size.z - renderer_size.x) + x;
                
                float z = getDepth(rx, ry, s_Position);
                Vector4 c = shader.fragment.main(new Object[]{new Vector3(rx, ry, z)});
                
                if (GH_DEPTH[index] > z) {
                    GH_DEPTH[index] = z;
                    renderBuffer.pixels[index] = color(c.x * 255, c.y * 255, c.z * 255);
                }
            }
        }
    }
    
    // 3D Clipping against view frustum
    ArrayList<Vector4> clip3D(Vector4[] vertices) {
        ArrayList<Vector4> input = new ArrayList<Vector4>();
        for (Vector4 v : vertices) input.add(v);
        
        // Clip against 6 frustum planes
        input = clipAgainstPlane(input, 0); // Left: x >= -w
        if (input.size() < 3) return null;
        input = clipAgainstPlane(input, 1); // Right: x <= w
        if (input.size() < 3) return null;
        input = clipAgainstPlane(input, 2); // Bottom: y >= -w
        if (input.size() < 3) return null;
        input = clipAgainstPlane(input, 3); // Top: y <= w
        if (input.size() < 3) return null;
        input = clipAgainstPlane(input, 4); // Near: z >= -w
        if (input.size() < 3) return null;
        input = clipAgainstPlane(input, 5); // Far: z <= w
        
        return input;
    }
    
    // Sutherland-Hodgman clipping for one plane
    ArrayList<Vector4> clipAgainstPlane(ArrayList<Vector4> vertices, int planeIndex) {
        ArrayList<Vector4> output = new ArrayList<Vector4>();
        if (vertices.size() == 0) return output;
        
        for (int i = 0; i < vertices.size(); i++) {
            Vector4 current = vertices.get(i);
            Vector4 next = vertices.get((i + 1) % vertices.size());
            
            boolean currentInside = isInsidePlane(current, planeIndex);
            boolean nextInside = isInsidePlane(next, planeIndex);
            
            if (currentInside && nextInside) {
                output.add(next);
            } else if (currentInside && !nextInside) {
                Vector4 intersection = intersectPlane(current, next, planeIndex);
                if (intersection != null) output.add(intersection);
            } else if (!currentInside && nextInside) {
                Vector4 intersection = intersectPlane(current, next, planeIndex);
                if (intersection != null) output.add(intersection);
                output.add(next);
            }
        }
        
        return output;
    }
    
    boolean isInsidePlane(Vector4 v, int planeIndex) {
        switch (planeIndex) {
            case 0: return v.x >= -v.w;
            case 1: return v.x <= v.w;
            case 2: return v.y >= -v.w;
            case 3: return v.y <= v.w;
            case 4: return v.z >= -v.w;
            case 5: return v.z <= v.w;
        }
        return false;
    }
    
    Vector4 intersectPlane(Vector4 v1, Vector4 v2, int planeIndex) {
        float t = 0;
        
        switch (planeIndex) {
            case 0: // Left: x = -w
                t = (-v1.w - v1.x) / ((v2.x - v1.x) + (v2.w - v1.w));
                break;
            case 1: // Right: x = w
                t = (v1.w - v1.x) / ((v2.x - v1.x) - (v2.w - v1.w));
                break;
            case 2: // Bottom: y = -w
                t = (-v1.w - v1.y) / ((v2.y - v1.y) + (v2.w - v1.w));
                break;
            case 3: // Top: y = w
                t = (v1.w - v1.y) / ((v2.y - v1.y) - (v2.w - v1.w));
                break;
            case 4: // Near: z = -w
                t = (-v1.w - v1.z) / ((v2.z - v1.z) + (v2.w - v1.w));
                break;
            case 5: // Far: z = w
                t = (v1.w - v1.z) / ((v2.z - v1.z) - (v2.w - v1.w));
                break;
        }
        
        if (Float.isNaN(t) || Float.isInfinite(t)) return null;
        
        return new Vector4(
            v1.x + t * (v2.x - v1.x),
            v1.y + t * (v2.y - v1.y),
            v1.z + t * (v2.z - v1.z),
            v1.w + t * (v2.w - v1.w)
        );
    }

    void update() {
    }

    void debugDraw() {
        Matrix4 MVP = main_camera.Matrix().mult(localToWorld());
        Matrix4 M = localToWorld();
        
        for (int i = 0; i < mesh.triangles.size(); i++) {
            Triangle triangle = mesh.triangles.get(i);
            
            // Transform vertices to world space for backface culling
            Vector3[] worldVerts = new Vector3[3];
            for (int j = 0; j < 3; j++) {
                worldVerts[j] = M.MulPoint(triangle.verts[j]);
            }
            
            // Calculate face normal in world space using cross product
            Vector3 edge1 = worldVerts[1].sub(worldVerts[0]);
            Vector3 edge2 = worldVerts[2].sub(worldVerts[0]);
            Vector3 normal = Vector3.cross(edge1, edge2);
            
            // Calculate view direction from triangle center to camera
            Vector3 triCenter = worldVerts[0].add(worldVerts[1]).add(worldVerts[2]).mult(1.0/3.0);
            Vector3 viewDir = main_camera.transform.position.sub(triCenter);
            
            // Backface culling: skip if face is pointing away from camera
            float dot = Vector3.dot(normal, viewDir);
            if (dot <= 0) continue; // Face is pointing away, skip rendering
            
            // Transform to clip space
            Vector4[] gl_Position = new Vector4[3];
            for (int j = 0; j < 3; j++) {
                gl_Position[j] = MVP.mult(triangle.verts[j].getVector4(1.0));
            }
            
            // 3D Clipping in clip space
            ArrayList<Vector4> clipped = clip3D(gl_Position);
            if (clipped == null || clipped.size() < 3) continue;
            
            // Draw clipped polygon edges
            for (int j = 0; j < clipped.size(); j++) {
                Vector4 v1 = clipped.get(j);
                Vector4 v2 = clipped.get((j + 1) % clipped.size());
                
                // Perspective division
                Vector3 p1 = v1.homogenized();
                Vector3 p2 = v2.homogenized();
                
                // Map to screen space
                float x1 = map(p1.x, -1, 1, renderer_size.x, renderer_size.z);
                float y1 = map(p1.y, -1, 1, renderer_size.y, renderer_size.w);
                float x2 = map(p2.x, -1, 1, renderer_size.x, renderer_size.z);
                float y2 = map(p2.y, -1, 1, renderer_size.y, renderer_size.w);
                
                CGLine(x1, y1, x2, y2);
            }
        }
    }

    String getGameObjectName() {
        return name;
    }

    Matrix4 localToWorld() {
        // Model = T * R_yaw(Y) * R_pitch(X) * R_roll(Z) * S
        Matrix4 T = Matrix4.Trans(transform.position);
        Matrix4 R = Matrix4.RotY(transform.rotation.y)
                        .mult(Matrix4.RotX(transform.rotation.x))
                        .mult(Matrix4.RotZ(transform.rotation.z));
        Matrix4 S = Matrix4.Scale(transform.scale);
        return T.mult(R).mult(S);
    }

    Matrix4 worldToLocal() {
        return Matrix4.Scale(transform.scale.inv()).mult(Matrix4.RotZ(-transform.rotation.z))
                .mult(Matrix4.RotX(-transform.rotation.x)).mult(Matrix4.RotY(-transform.rotation.y))
                .mult(Matrix4.Trans(transform.position.mult(-1)));
    }

    Vector3 forward() {
        return (Matrix4.RotZ(transform.rotation.z).mult(Matrix4.RotX(transform.rotation.y))
                .mult(Matrix4.RotY(transform.rotation.x)).zAxis()).mult(-1);
    }
}
