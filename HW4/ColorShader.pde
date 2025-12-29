public class PhongVertexShader extends VertexShader {
    Vector4[][] main(Object[] attribute, Object[] uniform) {
        Vector3[] aVertexPosition = (Vector3[]) attribute[0];
        Vector3[] aVertexNormal = (Vector3[]) attribute[1];
        Matrix4 MVP = (Matrix4) uniform[0];
        Matrix4 M = (Matrix4) uniform[1];
        Vector4[] gl_Position = new Vector4[3];
        Vector4[] w_position = new Vector4[3];
        Vector4[] w_normal = new Vector4[3];

        for (int i = 0; i < gl_Position.length; i++) {
            gl_Position[i] = MVP.mult(aVertexPosition[i].getVector4(1.0));
            w_position[i] = M.mult(aVertexPosition[i].getVector4(1.0));
            w_normal[i] = M.mult(aVertexNormal[i].getVector4(0.0));
        }

        Vector4[][] result = { gl_Position, w_position, w_normal };

        return result;
    }
}

public class PhongFragmentShader extends FragmentShader {
    Vector4 main(Object[] varying) {
        Vector3 position = (Vector3) varying[0];
        Vector3 w_position = (Vector3) varying[1];
        Vector3 w_normal = (Vector3) varying[2];
        Vector3 albedo = (Vector3) varying[3];
        Vector3 kdksm = (Vector3) varying[4];
        Light light = basic_light;
        Camera cam = main_camera;

        // TODO HW4
        // In this section, we have passed in all the variables you need.
        // Please use these variables to calculate the result of Phong shading
        // for that point and return it to GameObject for rendering

        // Phong shading parameters
        float Kd = kdksm.x;
        float Ks = kdksm.y;
        float shininess = kdksm.z;
        
        // Normalize interpolated normal (must normalize after interpolation)
        Vector3 N = w_normal.unit_vector();
        
        // Light direction (from fragment to light)
        Vector3 L = light.transform.position.sub(w_position).unit_vector();
        
        // View direction (from fragment to camera)
        Vector3 V = cam.transform.position.sub(w_position).unit_vector();
        
        // Reflection direction: R = 2(N·L)N - L
        float NdotL = Vector3.dot(N, L);
        Vector3 R = N.mult(2.0 * NdotL).sub(L).unit_vector();
        
        // Ambient component
        Vector3 ambient = albedo.mult(0.3);
        
        // Diffuse component: Kd * max(N·L, 0) * lightColor * albedo
        float diffuseIntensity = max(0.0, NdotL);
        Vector3 diffuse = albedo.mult(Kd * diffuseIntensity * light.intensity);
        diffuse.x *= light.light_color.x;
        diffuse.y *= light.light_color.y;
        diffuse.z *= light.light_color.z;
        
        // Specular component: Ks * (R·V)^shininess * lightColor
        float RdotV = Vector3.dot(R, V);
        float specularIntensity = pow(max(0.0, RdotV), shininess);
        Vector3 specular = light.light_color.mult(Ks * specularIntensity * light.intensity);
        
        // Final color = ambient + diffuse + specular
        Vector3 finalColor = ambient.add(diffuse).add(specular);
        
        // Clamp to [0, 1]
        float r = min(1.0, max(0.0, finalColor.x));
        float g = min(1.0, max(0.0, finalColor.y));
        float b = min(1.0, max(0.0, finalColor.z));

        return new Vector4(r, g, b, 1.0);
    }
}

public class FlatVertexShader extends VertexShader {
    Vector4[][] main(Object[] attribute, Object[] uniform) {
        Vector3[] aVertexPosition = (Vector3[]) attribute[0];
        Vector3[] aVertexNormal = (Vector3[]) attribute[1];
        Matrix4 MVP = (Matrix4) uniform[0];
        Matrix4 M = (Matrix4) uniform[1];
        Light light = (Light) uniform[2];
        Camera cam = (Camera) uniform[3];
        Vector3 albedo = (Vector3) uniform[4];
        
        Vector4[] gl_Position = new Vector4[3];
        Vector4[] flatColor = new Vector4[3];

        // TODO HW4
        // Here you have to complete Flat shading.
        // For flat shading: compute lighting once per triangle using face normal
        
        // Transform vertices to clip space
        for (int i = 0; i < gl_Position.length; i++) {
            gl_Position[i] = MVP.mult(aVertexPosition[i].getVector4(1.0));
        }
        
        // Calculate face normal from the three vertices
        Vector3 v0 = aVertexPosition[0];
        Vector3 v1 = aVertexPosition[1];
        Vector3 v2 = aVertexPosition[2];
        Vector3 edge1 = v1.sub(v0);
        Vector3 edge2 = v2.sub(v0);
        Vector3 faceNormal = Vector3.cross(edge1, edge2).unit_vector();
        
        // Transform face normal to world space
        Vector3 w_normal = M.mult(faceNormal.getVector4(0.0)).xyz().unit_vector();
        
        // Use center of triangle for world position
        Vector3 centerPos = v0.add(v1).add(v2).mult(1.0/3.0);
        Vector3 w_position = M.mult(centerPos.getVector4(1.0)).xyz();
        
        // Calculate flat shading (simple diffuse + ambient)
        Vector3 N = w_normal;
        Vector3 L = light.transform.position.sub(w_position).unit_vector();
        
        float NdotL = max(0.0, Vector3.dot(N, L));
        
        // Ambient + Diffuse only (no specular for flat shading)
        Vector3 ambient = albedo.mult(0.3);
        Vector3 diffuse = albedo.mult(0.7 * NdotL * light.intensity);
        diffuse.x *= light.light_color.x;
        diffuse.y *= light.light_color.y;
        diffuse.z *= light.light_color.z;
        
        Vector3 finalColor = ambient.add(diffuse);
        float r = min(1.0, max(0.0, finalColor.x));
        float g = min(1.0, max(0.0, finalColor.y));
        float b = min(1.0, max(0.0, finalColor.z));
        
        // All three vertices get the same color (flat shading)
        Vector4 flatColorValue = new Vector4(r, g, b, 1.0);
        flatColor[0] = flatColorValue;
        flatColor[1] = flatColorValue;
        flatColor[2] = flatColorValue;

        Vector4[][] result = { gl_Position, flatColor };

        return result;
    }
}

public class FlatFragmentShader extends FragmentShader {
    Vector4 main(Object[] varying) {
        Vector3 position = (Vector3) varying[0];
        Vector3 flatColor = (Vector3) varying[1];
        
        // TODO HW4
        // For flat shading, the color is already computed in vertex shader
        // Just return it directly (no interpolation needed)
        
        return new Vector4(flatColor.x, flatColor.y, flatColor.z, 1.0);
    }
}

public class GouraudVertexShader extends VertexShader {
    Vector4[][] main(Object[] attribute, Object[] uniform) {
        Vector3[] aVertexPosition = (Vector3[]) attribute[0];
        Vector3[] aVertexNormal = (Vector3[]) attribute[1];
        Matrix4 MVP = (Matrix4) uniform[0];
        Matrix4 M = (Matrix4) uniform[1];
        Light light = (Light) uniform[2];
        Camera cam = (Camera) uniform[3];
        Vector3 albedo = (Vector3) uniform[4];
        Vector3 kdksm = (Vector3) uniform[5];

        Vector4[] gl_Position = new Vector4[3];
        Vector4[] vertexColors = new Vector4[3];

        // TODO HW4
        // Gouraud shading: compute Phong lighting at each vertex
        // Then interpolate the colors in fragment shader
        
        float Kd = kdksm.x;
        float Ks = kdksm.y;
        float shininess = kdksm.z;

        for (int i = 0; i < gl_Position.length; i++) {
            // Transform vertex position
            gl_Position[i] = MVP.mult(aVertexPosition[i].getVector4(1.0));
            
            // Transform vertex to world space
            Vector3 w_position = M.mult(aVertexPosition[i].getVector4(1.0)).xyz();
            Vector3 w_normal = M.mult(aVertexNormal[i].getVector4(0.0)).xyz().unit_vector();
            
            // Calculate lighting at this vertex (same as Phong, but per vertex)
            Vector3 N = w_normal;
            Vector3 L = light.transform.position.sub(w_position).unit_vector();
            Vector3 V = cam.transform.position.sub(w_position).unit_vector();
            
            float NdotL = Vector3.dot(N, L);
            Vector3 R = N.mult(2.0 * NdotL).sub(L).unit_vector();
            
            // Ambient
            Vector3 ambient = albedo.mult(0.3);
            
            // Diffuse
            float diffuseIntensity = max(0.0, NdotL);
            Vector3 diffuse = albedo.mult(Kd * diffuseIntensity * light.intensity);
            diffuse.x *= light.light_color.x;
            diffuse.y *= light.light_color.y;
            diffuse.z *= light.light_color.z;
            
            // Specular
            float RdotV = Vector3.dot(R, V);
            float specularIntensity = pow(max(0.0, RdotV), shininess);
            Vector3 specular = light.light_color.mult(Ks * specularIntensity * light.intensity);
            
            // Final color for this vertex
            Vector3 finalColor = ambient.add(diffuse).add(specular);
            float r = min(1.0, max(0.0, finalColor.x));
            float g = min(1.0, max(0.0, finalColor.y));
            float b = min(1.0, max(0.0, finalColor.z));
            
            vertexColors[i] = new Vector4(r, g, b, 1.0);
        }

        Vector4[][] result = { gl_Position, vertexColors };

        return result;
    }
}

public class GouraudFragmentShader extends FragmentShader {
    Vector4 main(Object[] varying) {
        Vector3 position = (Vector3) varying[0];
        Vector3 interpolatedColor = (Vector3) varying[1];

        // TODO HW4
        // Gouraud shading: color is already computed at vertices
        // and interpolated across the triangle
        // Just use the interpolated color directly
        
        return new Vector4(interpolatedColor.x, interpolatedColor.y, interpolatedColor.z, 1.0);
    }
}

// Texture Shaders
public class TextureVertexShader extends VertexShader {
    Vector4[][] main(Object[] attributes, Object[] uniforms) {
        Vector3[] position = (Vector3[]) attributes[0];
        Vector3[] uv = (Vector3[]) attributes[1];  // Note: UV stored as Vector3 but only x,y are used
        Matrix4 MVP = (Matrix4) uniforms[0];

        // Output positions
        Vector4[] gl_Position = new Vector4[3];
        // Output UV coordinates
        Vector4[] varying_uv = new Vector4[3];

        for (int i = 0; i < 3; i++) {
            // Transform position
            Vector4 pos4 = new Vector4(position[i].x, position[i].y, position[i].z, 1.0);
            gl_Position[i] = MVP.mult(pos4);
            
            // Pass UV coordinates (store as Vector4 for consistency)
            varying_uv[i] = new Vector4(uv[i].x, uv[i].y, 0.0, 1.0);
        }

        return new Vector4[][] { gl_Position, varying_uv };
    }
}

public class TextureFragmentShader extends FragmentShader {
    Vector4 main(Object[] varying) {
        Vector3 position = (Vector3) varying[0];
        Vector3 uv = (Vector3) varying[1];
        PImage texture = (PImage) varying[2];

        // Sample texture using UV coordinates
        // UV coordinates are in [0,1] range, convert to pixel coordinates
        int texX = int(uv.x * (texture.width - 1));
        int texY = int(uv.y * (texture.height - 1));
        
        // Clamp to texture bounds
        texX = constrain(texX, 0, texture.width - 1);
        texY = constrain(texY, 0, texture.height - 1);
        
        // Get color from texture
        int pixelColor = texture.pixels[texY * texture.width + texX];
        
        // Extract RGB components
        float r = ((pixelColor >> 16) & 0xFF) / 255.0;
        float g = ((pixelColor >> 8) & 0xFF) / 255.0;
        float b = (pixelColor & 0xFF) / 255.0;

        return new Vector4(r, g, b, 1.0);
    }
}
