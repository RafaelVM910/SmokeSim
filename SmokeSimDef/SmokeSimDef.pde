Fluid fluid;
float t = 0;

  void settings() {
      size(N * scale, N * scale);
  }

  void setup() {
      fluid = new Fluid(0.1f, 0, 0);
  }

  void mouseDragged() {
   fluid.add_density(mouseX / scale, mouseY / scale, 500);
   float amtX = mouseX - pmouseX;
   float amtY = mouseY - pmouseY;
   fluid.add_velocity(mouseX / scale, mouseY / scale, amtX, amtY);
  }

  void draw() {
      background(0);
      fluid.step();
      fluid.render();
      fluid.fade();
  }
