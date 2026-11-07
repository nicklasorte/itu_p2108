// Reference driver for the NTIA P.2108 C++ library (github.com/NTIA/p2108).
// Reads lines "<model> args..." from stdin; prints inputs, return code, and result at full precision.
//   asm  f__ghz theta__deg p
//   tsm  f__ghz d__km p
//   hgt  f__ghz h__meter w_s__meter R__meter clutter_type
#include "P2108.h"
#include <cstdio>
#include <cstring>
using namespace ITS::ITU::PSeries::P2108;
int main() {
    char m[8];
    while (scanf("%7s", m) == 1) {
        if (!strcmp(m, "asm")) { double f, t, p, L = 0; scanf("%lf %lf %lf", &f, &t, &p);
            int r = AeronauticalStatisticalModel(f, t, p, L); printf("asm,%.17g,%.17g,%.17g,%d,%.17g\n", f, t, p, r, L); }
        else if (!strcmp(m, "tsm")) { double f, d, p, L = 0; scanf("%lf %lf %lf", &f, &d, &p);
            int r = TerrestrialStatisticalModel(f, d, p, L); printf("tsm,%.17g,%.17g,%.17g,%d,%.17g\n", f, d, p, r, L); }
        else if (!strcmp(m, "hgt")) { double f, h, w, R, A = 0; int c; scanf("%lf %lf %lf %lf %d", &f, &h, &w, &R, &c);
            int r = HeightGainTerminalCorrectionModel(f, h, w, R, static_cast<ClutterType>(c), A); printf("hgt,%.17g,%.17g,%.17g,%.17g,%d,%d,%.17g\n", f, h, w, R, c, r, A); }
    }
}
