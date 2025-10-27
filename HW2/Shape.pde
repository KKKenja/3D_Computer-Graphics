
public class Shape{   
    Vector3[] vertex = new Vector3[0];
    Transform transform = new Transform();
    
    public void drawShape(){                      
        Matrix4 model_matrix = localToWorld();
        Vector3[] t_pos = new Vector3[vertex.length];
        for(int i=0;i<t_pos.length;i++){
            t_pos[i] = model_matrix.mult(vertex[i].getVector4(1)).xyz();                       
        }
        
        // If SSAA is active, rasterize into SSAA buffer and return
        if (SSAA_isActive()) {
            Vector3[] clipped = Sutherland_Hodgman_algorithm(t_pos,engine.boundary);
            if (clipped.length == 0) return;
            // map to screen
            for (int i = 0; i < clipped.length; i++) {
                clipped[i] = new Vector3(
                    map(clipped[i].x,-1,1,20,520),
                    map(clipped[i].y,-1,1,50,height-50),
                    0);
            }
            Vector3[] bb = findBoundBox(clipped);
            if (bb.length < 2) return;
            int x0 = max(0, int(bb[0].x));
            int y0 = max(0, int(bb[0].y));
            int x1 = min(width - 1, int(bb[1].x));
            int y1 = min(height - 1, int(bb[1].y));

            float[] offs = {0.25, 0.75};
            // simple depth from transform (all verts share same z here)
            float depth = transform.position.z;
            for (int ix = x0; ix <= x1; ix++) {
                for (int iy = y0; iy <= y1; iy++) {
                    int sIdx = 0;
                    for (int oy = 0; oy < 2; oy++) {
                        for (int ox = 0; ox < 2; ox++) {
                            float sx = ix + offs[ox];
                            float sy = iy + offs[oy];
                            if (pnpoly(sx, sy, clipped)) {
                                SSAA_shadeSample(ix, iy, sIdx, color(100), depth);
                            }
                            sIdx++;
                        }
                    }
                }
            }
            return;
        }

        println("原始頂點數: " + t_pos.length);
        for(int i = 0; i < t_pos.length; i++) {
            println("  頂點" + i + ": (" + t_pos[i].x + "," + t_pos[i].y + ")");
        }
        
        t_pos = Sutherland_Hodgman_algorithm(t_pos,engine.boundary);
        
        if (t_pos.length == 0) {
            println("警告: 裁剪後沒有頂點");
            return;
        }
        
        println("裁剪後頂點數: " + t_pos.length);
        
        for(int i=0;i<t_pos.length;i++){
            t_pos[i] = new Vector3(map(t_pos[i].x,-1,1,20,520),map(t_pos[i].y,-1,1,50,height-50),0);
        }

        Vector3[] minmax = findBoundBox(t_pos);
        
        if (minmax.length < 2) {
            println("警告: 邊界框無效");
            return;
        }
        
        println("開始填充多邊形，範圍: (" + int(minmax[0].x) + "," + int(minmax[0].y) + ") 到 (" + int(minmax[1].x) + "," + int(minmax[1].y) + ")");
        
        loadPixels();       
        int fillCount = 0;
        for(int i = int(minmax[0].x);i<=minmax[1].x;i++){
            for(int j = int(minmax[0].y);j<=minmax[1].y;j++){
                if(pnpoly(i,j,t_pos)){                    
                    drawPoint(i,j,color(100));
                    fillCount++;
                }
            }
        }
        
        println("填充了 " + fillCount + " 個像素");
             
        for(int i=0;i<t_pos.length;i++){          
            CGLine(t_pos[i].x,t_pos[i].y,t_pos[(i+1)%t_pos.length].x,t_pos[(i+1)%t_pos.length].y);
        }
        
        updatePixels();
        
    };    public Matrix4 localToWorld(){
        return Matrix4.Trans(transform.position).mult(Matrix4.RotZ(transform.rotation.z)).mult(Matrix4.Scale(transform.scale));
    }
    
    public String getShapeName(){
        return "";
    }
    
}

public class Rectangle extends Shape{
    
    public Rectangle(){
        vertex = new Vector3[]{new Vector3(-0.1,-0.1,0),new Vector3(-0.1,0.1,0),new Vector3(0.1,0.1,0),new Vector3(0.1,-0.1,0)};    
    }
    @Override
    public String getShapeName(){
        return "Rectangle";
    }
    
   
}

public class Star extends Shape{
    
    public Star(){
        vertex = new Vector3[]{new Vector3(0.1,0,0),new Vector3(0.0309,0.02244,0),
                               new Vector3(0.0309,0.0951,0),new Vector3(-0.01195,0.03637,0),
                               new Vector3(-0.0809,0.05877,0),new Vector3(-0.03834,0.0002,0),
                               new Vector3(-0.0809,-0.05811,0),new Vector3(-0.012,-0.03599,0),
                               new Vector3(0.0309,-0.0951,0),new Vector3(0.0309,-0.02219,0)};    

    }
    @Override
    public String getShapeName(){
        return "Star";
    }
    
   
}


public class Line extends Shape{
    Vector3 point1;
    Vector3 point2;
    
    public Line(){};
    public Line(Vector3 v1,Vector3 v2){
        point1 = v1;
        point2 = v2;
    }
    
    @Override
    public void drawShape(){
        CGLine(point1.x,point1.y,point2.x,point2.y);
    }
    
   
}



public class Polygon extends Shape{
    ArrayList<Vector3> verties = new ArrayList<Vector3>();
     public Polygon(ArrayList<Vector3> v){
        verties= v;
    }
    
    @Override
    public void drawShape(){
        if(verties.size()<=0) return;
        for(int i=0;i<=verties.size();i++){
              Vector3 p1 = verties.get(i%verties.size());
              Vector3 p2 = verties.get((i+1)%verties.size());
              CGLine(p1.x,p1.y,p2.x,p2.y);
         }
    } 
}
