ShapeButton lineButton;
ShapeButton circleButton;
ShapeButton polygonButton;
ShapeButton ellipseButton;
ShapeButton curveButton;
ShapeButton pencilButton;
ShapeButton eraserButton;

Button clearButton;

Button colorButton;
ArrayList<ColorButton> colorButtons;

ShapeRenderer shapeRenderer;
ArrayList<ShapeButton> shapeButton;
float eraserSize = 20;

public void setup() {
    size(1000, 800);
    background(255);
    shapeRenderer = new ShapeRenderer();
    initButton();
    initColorPalette();

}

public void draw() {

    background(255);
    for (ShapeButton sb : shapeButton) {
        sb.run(() -> {
            sb.beSelect();
            shapeRenderer.setRenderer(sb.getRendererType());
        });
    }

    clearButton.run(() -> {
        shapeRenderer.clear();
    });
    
    for (ColorButton cb : colorButtons) {
        cb.run(() -> {
            cb.beSelect();
        });
    }
    
    shapeRenderer.box.show();
    shapeRenderer.run();

}

void resetButton() {
    for (ShapeButton sb : shapeButton) {
        sb.setSelected(false);
    }
}

void resetColorButtons() {
    for (ColorButton cb : colorButtons) {
        cb.setSelected(false);
    }
}


public void initColorPalette() {
    colorButtons = new ArrayList<ColorButton>();
    
    // 定義顏色陣列
    color[] colors = {
        color(0, 0, 0),       // 黑色
        color(255, 255, 255), // 白色
        color(128, 128, 128), // 灰色
        color(255, 0, 0),     // 紅色
        color(255, 165, 0),   // 橘色
        color(255, 255, 0),   // 黃色
        color(0, 255, 0),     // 綠色
        color(0, 128, 0),      // 深綠色
        color(0, 255, 255),   // 青色
        color(0, 0, 255),     // 藍色
        color(255, 0, 255),   // 紫色
        color(128, 0, 128),   // 深紫色
        

        
        
    };
    
    // 調色盤位置設定（在eraser右邊）
    float startX = 260; // eraser button 在 220，寬度30，所以從260開始
    float startY = 10;
    float buttonSize = 18;
    float spacing = 2;
    int colsPerRow = 10;
    
    for (int i = 0; i < colors.length; i++) {
        int row = i / colsPerRow;
        int col = i % colsPerRow;
        
        float x = startX + col * (buttonSize + spacing);
        float y = startY + row * (buttonSize + spacing);
        
        ColorButton cb = new ColorButton(x, y, buttonSize, buttonSize, colors[i]);
        colorButtons.add(cb);
    }
    
    // 預設選中黑色
    if (colorButtons.size() > 0) {
        colorButtons.get(0).setSelected(true);
    }
}

public void initButton() {
    shapeButton = new ArrayList<ShapeButton>();
    lineButton = new ShapeButton(10, 10, 30, 30) {
        @Override
        public void show() {
            super.show();
            stroke(0);
            line(pos.x + 2, pos.y + 2, pos.x + size.x - 2, pos.y + size.y - 2);
        }

        @Override
        public Renderer getRendererType() {
            return new LineRenderer();
        }
    };

    lineButton.setBoxAndClickColor(color(250), color(150));
    shapeButton.add(lineButton);

    circleButton = new ShapeButton(45, 10, 30, 30) {
        @Override
        public void show() {
            super.show();
            stroke(0);
            circle(pos.x + size.x / 2, pos.y + size.y / 2, size.x - 2);
        }

        @Override
        public Renderer getRendererType() {
            return new CircleRenderer();
        }
    };
    circleButton.setBoxAndClickColor(color(250), color(150));
    shapeButton.add(circleButton);

    polygonButton = new ShapeButton(80, 10, 30, 30) {
        @Override
        public void show() {
            super.show();
            stroke(0);
            line(pos.x + 2, pos.y + 2, pos.x + size.x - 2, pos.y + 2);
            line(pos.x + 2, pos.y + size.y - 2, pos.x + size.x - 2, pos.y + size.y - 2);
            line(pos.x + size.x - 2, pos.y + 2, pos.x + size.x - 2, pos.y + size.y - 2);
            line(pos.x + 2, pos.y + 2, pos.x + 2, pos.y + size.y - 2);
        }

        @Override
        public Renderer getRendererType() {
            return new PolygonRenderer();
        }

    };

    polygonButton.setBoxAndClickColor(color(250), color(150));
    shapeButton.add(polygonButton);

    ellipseButton = new ShapeButton(115, 10, 30, 30) {
        @Override
        public void show() {
            super.show();
            stroke(0);
            ellipse(pos.x + size.x / 2, pos.y + size.y / 2, size.x - 2, size.y * 2 / 3);
        }

        @Override
        public Renderer getRendererType() {
            return new EllipseRenderer();
        }

    };

    ellipseButton.setBoxAndClickColor(color(250), color(150));
    shapeButton.add(ellipseButton);

    curveButton = new ShapeButton(150, 10, 30, 30) {
        @Override
        public void show() {
            super.show();
            stroke(0);
            bezier(pos.x, pos.y, pos.x, pos.y + size.y, pos.x + size.x, pos.y, pos.x + size.x, pos.y + size.y);
        }

        @Override
        public Renderer getRendererType() {
            return new CurveRenderer();
        }

    };

    curveButton.setBoxAndClickColor(color(250), color(150));
    shapeButton.add(curveButton);

    clearButton = new Button(width - 50, 10, 30, 30);
    clearButton.setBoxAndClickColor(color(250), color(150));
    clearButton.setImage(loadImage("clear.png"));
  

    pencilButton = new ShapeButton(185, 10, 30, 30) {
        @Override
        public Renderer getRendererType() {
            return new PencilRenderer();
        }
    };
    pencilButton.setImage(loadImage("pencil.png"));

    pencilButton.setBoxAndClickColor(color(250), color(150));
    shapeButton.add(pencilButton);

    eraserButton = new ShapeButton(220, 10, 30, 30) {
        @Override
        public Renderer getRendererType() {
            return new EraserRenderer();
        }
    };
    eraserButton.setImage(loadImage("eraser.png"));

    eraserButton.setBoxAndClickColor(color(250), color(150));
    shapeButton.add(eraserButton);
    
    
    
  }

public void keyPressed() {
    if (key == 'z' || key == 'Z') {
        shapeRenderer.popShape();
    }

}

void mouseWheel(MouseEvent event) {
    float e = event.getCount();
    if (e < 0)
        eraserSize += 1;
    else if (e > 0)
        eraserSize -= 1;
    eraserSize = max(min(eraserSize, 30), 4);
}
