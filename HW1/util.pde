color currentDrawColor = color(0, 0, 0); // 預設黑色
public void CGLine(float x1, float y1, float x2, float y2) {
    // TODO HW1
    // You need to implement the "line algorithm" in this section.
    // You can use the function line(x1, y1, x2, y2); to verify the correct answer.
    // However, remember to comment out before you submit your homework.
    // Otherwise, you will receive a score of 0 for this part.
    // Utilize the function drawPoint(x, y, color) to apply color to the pixel at
    // coordinates (x, y).
    // For instance: drawPoint(114, 514, color(255, 0, 0)); signifies drawing a red
    // point at (114, 514).

    
     stroke(0);
     noFill();
     //line(x1, y1, x2, y2);
     
     
     if (x1 > x2) {
       float temp = x2;
       x2 = x1; 
       x1 = temp;
       temp = y2;
       y2 = y1; 
       y1 = temp;
     }
     float xDis = abs(x1-x2);
     float yDis = abs(y1-y2);
     float len = sqrt(xDis*xDis + yDis*yDis);
     
     if(x1 == x2) {
         for(float i=y1;i<=y2;i+=0.01) {
            drawPoint(x1, i, currentDrawColor);
         }
     } else {
         float r = 0;
         if (xDis != 0) r = (y1-y2)/(x1-x2);
         float delta = len/1000;
         //println(delta);
         if (r>=1 || r<=-1){delta /= abs(r);} //避免斜率太大導致點數太少
         for (float i=x1; i<x1 + xDis; i+=delta){
           drawPoint(i, r*i + y1 - (r* x1), currentDrawColor);
         }
     }
  

}

public void CGCircle(float x, float y, float r) {
    // TODO HW1
    // You need to implement the "circle algorithm" in this section.
    // You can use the function circle(x, y, r); to verify the correct answer.
    // However, remember to comment out before you submit your homework.
    // Otherwise, you will receive a score of 0 for this part.
    // Utilize the function drawPoint(x, y, color) to apply color to the pixel at
    // coordinates (x, y).

    
    stroke(0);
    noFill();
    //circle(x,y,r*2);
    float dotNum = r/10000;
    for (float i= x-r ; i< x + r; i+=dotNum){
           drawPoint(i,y+sqrt(r*r-(i-x)*(i-x)),currentDrawColor);
           drawPoint(i,y-sqrt(r*r-(i-x)*(i-x)),currentDrawColor);
    }
}

public void CGEllipse(float x, float y, float r1, float r2) {
    // TODO HW1
    // You need to implement the "ellipse algorithm" in this section.
    // You can use the function ellipse(x, y, r1,r2); to verify the correct answer.
    // However, remember to comment out the function before you submit your homework.
    // Otherwise, you will receive a score of 0 for this part.
    // Utilize the function drawPoint(x, y, color) to apply color to the pixel at
    // coordinates (x, y).
    
    stroke(0);
    noFill();
    //println(r1,r2);
    //ellipse(x,y,r1*2,r2*2);
    float dotNum = r1/10000;
    for (float i= x-r1 ; i< x + r1; i+=dotNum){
           drawPoint(i,y+r2*sqrt(1-(i-x)*(i-x)/(r1*r1)),currentDrawColor);
           drawPoint(i,y-r2*sqrt(1-(i-x)*(i-x)/(r1*r1)),currentDrawColor);
    }

}

public void CGCurve(Vector3 p1, Vector3 p2, Vector3 p3, Vector3 p4) {
    // TODO HW1
    // You need to implement the "bezier curve algorithm" in this section.
    // You can use the function bezier(p1.x, p1.y, p2.x, p2.y, p3.x, p3.y, p4.x,
    // p4.y); to verify the correct answer.
    // However, remember to comment out before you submit your homework.
    // Otherwise, you will receive a score of 0 for this part.
    // Utilize the function drawPoint(x, y, color) to apply color to the pixel at
    // coordinates (x, y).

    /*
    stroke(0);
    noFill();
    bezier(p1.x,p1.y,p2.x,p2.y,p3.x,p3.y,p4.x,p4.y);
    */
    for (float i= 0 ; i< 1 ; i+=0.001){
          float x = pow(1-i,3)*p1.x + 3*i*pow((1-i),2)*p2.x + 3*i*i*(1-i)*p3.x+i*i*i*p4.x;
          float y = pow(1-i,3)*p1.y + 3*i*pow((1-i),2)*p2.y + 3*i*i*(1-i)*p3.y+i*i*i*p4.y;
          drawPoint(x,y,currentDrawColor);
    }
    
    
} 

public void CGEraser(Vector3 p1, Vector3 p2) {
    // TODO HW1
    // You need to erase the scene in the area defined by points p1 and p2 in this
    // section.
    // p1 ------
    // |       |
    // |       |
    // ------ p2
    // The background color is color(250);
    // You can use the mouse wheel to change the eraser range.
    // Utilize the function drawPoint(x, y, color) to apply color to the pixel at
    // coordinates (x, y).
    
    //for (float i=p1.x;i <= p2.x; i+=1){
    //  for (float j=p1.y; j<=p2.y;j+=1){
    //    println(i,j);
    //    drawPoint(i,j,250);
    //  }
    //}
    float w = p2.x - p1.x;
    float h = p2.y - p1.y;
    for (int i = 0; i < w * h; i++) {
      float x = p1.x + (i % w);
      float y = p1.y + (i / w);
      drawPoint(x, y, 250);
    }
        
}

public void drawPoint(float x, float y, color c) {
    stroke(c);
    point(x, y);
}

public float distance(Vector3 a, Vector3 b) {
    Vector3 c = a.sub(b);
    return sqrt(Vector3.dot(c, c));
}
