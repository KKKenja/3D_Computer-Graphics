public class Camera extends GameObject {
    Matrix4 projection = new Matrix4();
    Matrix4 worldView = new Matrix4();
    int wid;
    int hei;
    float near;
    float far;

    Camera() {
        wid = 256;
        hei = 256;
        worldView.makeIdentity();
        projection.makeIdentity();
        transform.position = new Vector3(0, 0, -50);
        name = "Camera";
    }

    Matrix4 inverseProjection() {
        Matrix4 invProjection = Matrix4.Zero();
        float a = projection.m[0];
        float b = projection.m[5];
        float c = projection.m[10];
        float d = projection.m[11];
        float e = projection.m[14];
        invProjection.m[0] = 1.0f / a;
        invProjection.m[5] = 1.0f / b;
        invProjection.m[11] = 1.0f / e;
        invProjection.m[14] = 1.0f / d;
        invProjection.m[15] = -c / (d * e);
        return invProjection;
    }

    Matrix4 Matrix() {
        return projection.mult(worldView);
    }

    void setSize(int w, int h, float n, float f) {

        // TODO HW3
        // This function takes four parameters, which are 
        // the width of the screen, the height of the screen
        // the near plane and the far plane of the camera.
        // Where GH_FOV has been declared as a global variable.
        // Finally, pass the result into projection matrix.

        // projection = Matrix4.Identity();
        wid = w;
        hei = h;
        near = n;
        far = f;

        float aspect = (float)wid / (float)hei;
        float fovRad = radians(GH_FOV);    // GH_FOV assumed in degrees
        float t = tan(fovRad * 0.5f);
        float A = 1.0f / (aspect * t);     // m[0]
        float B = 1.0f / t;                // m[5]
        float C = (far + near) / (near - far);           // m[10]
        float D = (2.0f * far * near) / (near - far);    // m[11]

        projection.makeZero();
        projection.m[0]  = A;    // row 0, col 0
        projection.m[5]  = B;    // row 1, col 1
        projection.m[10] = C;    // row 2, col 2
        projection.m[11] = D;    // row 2, col 3
        projection.m[14] = -1.0; // row 3, col 2
        projection.m[15] = 0.0;  // row 3, col 3

    }

    void setPositionOrientation(Vector3 pos, float rotX, float rotY) {
        worldView = Matrix4.RotX(rotX).mult(Matrix4.RotY(rotY)).mult(Matrix4.Trans(pos.mult(-1)));
    }

    void setPositionOrientation() {
        worldView = Matrix4.RotX(transform.rotation.x).mult(Matrix4.RotY(transform.rotation.y))
                .mult(Matrix4.Trans(transform.position.mult(-1)));
    }

    void setPositionOrientation(Vector3 pos, Vector3 lookat) {
        // Y-up, right-handed LookAt without .normalized()
        Vector3 up = new Vector3(0, 1, 0);

        // f = normalize(lookat - pos)
        Vector3 f = lookat.sub(pos);
        float fl = sqrt(f.x*f.x + f.y*f.y + f.z*f.z);
        if (fl != 0) { f.x /= fl; f.y /= fl; f.z /= fl; }

        // s = normalize(cross(f, up))
        Vector3 s = Vector3.cross(f, up);
        float sl = sqrt(s.x*s.x + s.y*s.y + s.z*s.z);
        if (sl != 0) { s.x /= sl; s.y /= sl; s.z /= sl; }

        // u = cross(s, f)  // already orthonormal if f,s normalized
        Vector3 u = Vector3.cross(s, f);

        Matrix4 Rt = Matrix4.Identity();
        // rows = [s; u; -f]
        Rt.m[0] = s.x;   Rt.m[1] = s.y;   Rt.m[2]  = s.z;
        Rt.m[4] = u.x;   Rt.m[5] = u.y;   Rt.m[6]  = u.z;
        Rt.m[8] = -f.x;  Rt.m[9] = -f.y;  Rt.m[10] = -f.z;

        Matrix4 Tinv = Matrix4.Trans(new Vector3(-pos.x, -pos.y, -pos.z));
        worldView = Rt.mult(Tinv);

        transform.position = pos;
    }
}
