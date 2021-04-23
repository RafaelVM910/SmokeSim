final int N = 128;
final int iteration = 16;
final int scale = 5;

int IX(int x, int y) {
  x = constrain(x, 0, N-1);
  y = constrain(y, 0, N-1);
  return x + (y * N);
}

public class Fluid {
    float dt; // Time step
    float diff; // Difusion
    float visc; // Viscosidad

    float[] s; // Predensidad?
    float[] density;

    float[] Vx; // Velocidad en X
    float[] Vy; // Velocidad en Y

    float[] Vx0; // Velocidad previa en X
    float[] Vy0; // Velocidad previa en Y


    public Fluid(float dt, float diff, float visc) {
        this.dt = dt;
        this.diff = diff;
        this.visc = visc;

        this.s = new float[N * N];
        this.density = new float[N * N];

        this.Vx = new float[N * N];
        this.Vy = new float[N * N];

        this.Vx0 = new float[N * N];
        this.Vy0 = new float[N * N];
    }


    void step() {
        float visc = this.visc;
        float diff = this.diff;
        float dt = this.dt;
        float[] Vx = this.Vx;
        float[] Vy = this.Vy;
        float[] Vx0 = this.Vx0;
        float[] Vy0 = this.Vy0;
        float[] s = this.s;
        float[] density = this.density;

        diffuse(1, Vx0, Vx, visc, dt);
        diffuse(2, Vy0, Vy, visc, dt);

        project(Vx0, Vy0, Vx, Vy);

        advect(1, Vx, Vx0, Vx0, Vy0, dt);
        advect(2, Vy, Vy0, Vx0, Vy0, dt);

        project(Vx, Vy, Vx0, Vy0);

        diffuse(0, s, density, diff, dt);
        advect(0, density, s, Vx, Vy, dt);
    }


    void add_density(int x, int y, float amount) {
        int index = IX(x, y);
        this.density[index] += amount;
    }

    void add_velocity(int x, int y, float amountX, float amountY) {
        int index = IX(x, y);
        this.Vx[index] += amountX;
        this.Vy[index] += amountY;
    }

    void diffuse(int b, float[] x,float[] x0, float diff, float dt) {
        float a = dt * diff * (N - 2) * (N - 2);
        lin_solve(b, x, x0, a, 1 + 6 * a);
    }


    void lin_solve(int b, float[] x, float[] x0, float a, float c) {
        float cRecip = 1.0f / c;

        for(int k = 0; k < iteration; k++) {
            for(int j = 1; j < N-1; j++) {
                for(int i = 1; i < N-1; i++) {
                    x[IX(i, j)] = (x0[IX(i, j)] + a * (x[IX(i + 1, j)] + x[IX(i - 1, j)] + x[IX(i, j + 1)] + x[IX(i, j - 1)])) * cRecip;
                }
            }
            set_bnd(b, x);
        }
    }


    void project(float[] Vx, float[] Vy, float[] p, float[] div) {
        for(int j = 1; j < N-1; j++) {
            for (int i = 1; i < N - 1; i++) {
                div[IX(i, j)] = -0.5f * (Vx[IX(i + 1, j)] - Vx[IX(i - 1, j)] + Vy[IX(i, j + 1)] - Vy[IX(i, j - 1)]) / N;
                p[IX(i, j)] = 0;
            }
        }

        set_bnd(0, div);
        set_bnd(0, p);
        lin_solve(0, p, div, 1, 6);

        for(int j = 1; j < N-1; j++) {
            for (int i = 1; i < N - 1; i++) {
                Vx[IX(i, j)] -= 0.5f * (p[IX(i + 1, j)] - p[IX(i - 1, j)]) * N;
                Vy[IX(i, j)] -= 0.5f * (p[IX(i, j + 1)] - p[IX(i, j - 1)]) * N;
            }
        }
        set_bnd(1, Vx);
        set_bnd(2, Vy);
    }

    void advect(int b, float[] d, float[] d0, float[] Vx, float[] Vy, float dt) {
        float i0, i1, j0, j1;

        float dtx = dt * (N - 2);
        float dty = dt * (N - 2);

        float s0, s1, t0, t1;
        float tmp1, tmp2, x, y;

        float Nfloat = N;
        float ifloat, jfloat;
        int i, j;

        for (j = 1, jfloat = 1; j < N-1; j++, jfloat++) {
            for (i = 1, ifloat = 1; i < N - 1; i++, ifloat++) {
                tmp1 = dtx * Vx[IX(i, j)];
                tmp2 = dty * Vy[IX(i, j)];
                x = ifloat - tmp1;
                y = jfloat - tmp2;

                if (x < 0.5f) {
                    x = 0.5f;
                }
                if (x > Nfloat + 0.5f) {
                    x = Nfloat + 0.5f;
                }
                i0 = floor(x);
                i1 = i0 + 1.0f;

                if (y < 0.5f) {
                    y = 0.5f;
                }
                if (y > Nfloat + 0.5f) {
                    y = Nfloat + 0.5f;
                }
                j0 = floor(y);
                j1 = j0 + 1.0f;

                s1 = x - i0;
                s0 = 1.0f - s1;
                t1 = y - j0;
                t0 = 1.0f - t1;

                int i0i = (int) i0;
                int i1i = (int) i1;
                int j0i = (int) j0;
                int j1i = (int) j1;

                d[IX(i, j)] = s0 * (t0 * d0[IX(i0i, j0i)] + t1 * d0[IX(i0i, j1i)]) + s1 * (t0 * d0[IX(i1i, j0i)] + t1 * d0[IX(i1i, j1i)]);
            }
        }

        set_bnd(b, d);
    }

    void set_bnd(int b, float[] x) {
        for (int i = 1; i < N-1; i++) {
            x[IX(i, 0)] = b == 2 ? -x[IX(i, 1)] : x[IX(i, 1)];
            x[IX(i, N-1)] = b == 2 ? -x[IX(i, N - 2)] : x[IX(i, N - 2)];
        }
        for (int j = 1; j < N-1; j++) {
            x[IX(0, j)] = b == 1 ? -x[IX(1, j)] : x[IX(1, j)];
            x[IX(N - 1, j)] = b == 1 ? -x[IX(N - 2, j)] : x[IX(N - 2, j)];
        }

        x[IX(0, 0)] = 0.5f * (x[IX(1, 0)] + x[IX(0, 1)]);
        x[IX(0, N - 1)] = 0.5f * (x[IX(1, N - 1)] + x[IX(0, N - 2)]);
        x[IX(N - 1, 0)] = 0.5f * (x[IX(N - 2, 0)] + x[IX(N - 1, 1)]);
        x[IX(N - 1, N - 1)] = 0.5f * (x[IX(N - 2, N - 1)] + x[IX(N - 1, N - 2)]);
    }

    void render() {
        for (int i = 0; i < N; i++){
            for (int j = 0; j < N; j++){
                float x = i * scale;
                float y = j * scale;
                float d = this.density[IX(i, j)];

                fill(d);
                noStroke();
                square(x, y, scale);
            }
        }
    }

    void fade() {
        for (int i = 0; i < this.density.length; i++) {
            float d = density[i];
            density[i] = constrain(d - 0.1, 0, 255);
        }
    }
}
