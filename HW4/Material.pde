public abstract class Material {
    Vector3 albedo = new Vector3(0.9, 0.9, 0.9);
    Shader shader;

    Material() {
        // TODO HW4
        // In the Material, pass the relevant attribute variables and uniform variables
        // you need.
        // In the attribute variables, include relevant variables about vertices,
        // and in the uniform, pass other necessary variables.
        // Please note that a Material will be bound to the corresponding Shader.
    }

    abstract Vector4[][] vertexShader(Triangle triangle, Matrix4 M);

    abstract Vector4 fragmentShader(Vector3 position, Vector4[] varing);

    void attachShader(Shader s) {
        shader = s;
    }
}

public class DepthMaterial extends Material {
    DepthMaterial() {
        shader = new Shader(new DepthVertexShader(), new DepthFragmentShader());
    }

    Vector4[][] vertexShader(Triangle triangle, Matrix4 M) {
        Matrix4 MVP = main_camera.Matrix().mult(M);
        Vector3[] position = triangle.verts;
        Vector4[][] r = shader.vertex.main(new Object[] { position }, new Object[] { MVP });
        return r;
    }

    Vector4 fragmentShader(Vector3 position, Vector4[] varing) {
        return shader.fragment.main(new Object[] { position });
    }
}

public class PhongMaterial extends Material {
    Vector3 Ka = new Vector3(0.3, 0.3, 0.3);
    float Kd = 0.5;
    float Ks = 0.5;
    float m = 20;

    PhongMaterial() {
        shader = new Shader(new PhongVertexShader(), new PhongFragmentShader());
    }

    Vector4[][] vertexShader(Triangle triangle, Matrix4 M) {
        Matrix4 MVP = main_camera.Matrix().mult(M);
        Vector3[] position = triangle.verts;
        Vector3[] normal = triangle.normal;
        Vector4[][] r = shader.vertex.main(new Object[] { position, normal }, new Object[] { MVP, M });
        return r;
    }

    Vector4 fragmentShader(Vector3 position, Vector4[] varing) {

        return shader.fragment
                .main(new Object[] { position, varing[0].xyz(), varing[1].xyz(), albedo, new Vector3(Kd, Ks, m) });
    }

}

public class FlatMaterial extends Material {
    FlatMaterial() {
        shader = new Shader(new FlatVertexShader(), new FlatFragmentShader());
    }

    Vector4[][] vertexShader(Triangle triangle, Matrix4 M) {
        Matrix4 MVP = main_camera.Matrix().mult(M);
        Vector3[] position = triangle.verts;
        Vector3[] normal = triangle.normal;

        // TODO HW4
        // pass the uniform you need into the shader.
        // For flat shading, we need: MVP, M (model matrix), light, camera, albedo

        Vector4[][] r = shader.vertex.main(
            new Object[] { position, normal }, 
            new Object[] { MVP, M, basic_light, main_camera, albedo }
        );
        return r;
    }

    Vector4 fragmentShader(Vector3 position, Vector4[] varing) {
        // Pass the computed color from vertex shader
        return shader.fragment.main(new Object[] { position, varing[0].xyz() });
    }
}

public class GouraudMaterial extends Material {
    float Kd = 0.7;
    float Ks = 0.3;
    float shininess = 20;
    
    GouraudMaterial() {
        shader = new Shader(new GouraudVertexShader(), new GouraudFragmentShader());
    }

    Vector4[][] vertexShader(Triangle triangle, Matrix4 M) {
        Matrix4 MVP = main_camera.Matrix().mult(M);
        Vector3[] position = triangle.verts;
        Vector3[] normal = triangle.normal;
        
        // TODO HW4
        // pass the uniform you need into the shader.
        // For Gouraud shading: compute lighting at each vertex

        Vector4[][] r = shader.vertex.main(
            new Object[] { position, normal }, 
            new Object[] { MVP, M, basic_light, main_camera, albedo, new Vector3(Kd, Ks, shininess) }
        );
        return r;
    }

    Vector4 fragmentShader(Vector3 position, Vector4[] varing) {
        // Pass the interpolated color from vertex shader
        return shader.fragment.main(new Object[] { position, varing[0].xyz() });
    }
}

public enum MaterialEnum {
    DM, FM, GM, PM, TM;
}

public class TextureMaterial extends Material {
    PImage texture;
    
    TextureMaterial(String texturePath) {
        shader = new Shader(new TextureVertexShader(), new TextureFragmentShader());
        texture = loadImage(texturePath);
        if (texture == null) {
            println("Failed to load texture: " + texturePath);
            // Create a default checkerboard texture
            texture = loadImage("data/Textures/checker.png");
        }
    }
    
    TextureMaterial() {
        this("data/Textures/checker.png");
    }

    Vector4[][] vertexShader(Triangle triangle, Matrix4 M) {
        Matrix4 MVP = main_camera.Matrix().mult(M);
        Vector3[] position = triangle.verts;
        Vector3[] uv = triangle.uvs;
        
        // Pass position and UV coordinates to vertex shader
        Vector4[][] r = shader.vertex.main(
            new Object[] { position, uv }, 
            new Object[] { MVP }
        );
        return r;
    }

    Vector4 fragmentShader(Vector3 position, Vector4[] varing) {
        // Pass interpolated UV and texture to fragment shader
        return shader.fragment.main(new Object[] { position, varing[0].xyz(), texture });
    }
}
