# itu_p2108

MATLAB implementation of [Recommendation ITU-R P.2108-1](https://www.itu.int/rec/R-REC-P.2108/en), "Prediction of clutter loss." The code ports the NTIA reference implementation ([NTIA/p2108](https://github.com/NTIA/p2108), v1.1, commit `eadb58f`) and vectorizes it.

## Models

| Section | Function | Model | Valid frequency |
|---|---|---|---|
| 3.1 | `p2108_height_gain_rev1` | Height-gain terminal correction model | 0.03 GHz to 3 GHz |
| 3.2 | `p2108_terrestrial_rev1` | Statistical clutter loss for terrestrial paths | 0.5 GHz to 67 GHz |
| 3.3 | `p2108_aeronautical_rev1` | Statistical clutter loss for Earth-space and aeronautical paths | 10 GHz to 100 GHz |

Supporting functions: `p2108_inv_ccdf_rev1` (inverse complementary normal), `p2108_equation_2a_rev1`, `p2108_constants_rev1` (clutter types, default clutter heights, return codes), `p2108_expand_rev1`, and `p2108_report_rev1`.

## Use

```matlab
addpath("src")

% Section 3.2: distance column by percentile row gives a grid (400-by-5)
d_km = logspace(log10(0.25), 1, 400).';
L_ctt = p2108_terrestrial_rev1(7.9872, d_km, [1 10 50 90 99]);

% Section 3.3: drone or satellite at 30 degrees elevation, 30 GHz
L_ces = p2108_aeronautical_rev1(30, 30, 50);

% Section 3.1: 2 m antenna, 27 m street, urban clutter (R = 15 m)
A_h = p2108_height_gain_rev1(1.5, 2, 27, 15, 4);

% Return codes instead of errors
[L, rtn] = p2108_terrestrial_rev1([8 80], 1, 50, error_mode="code");   % rtn = [0 48]
```

All three models follow MATLAB implicit expansion, so any input can be a scalar, a vector, or an N-D array of compatible size.

### Options

- `error_mode`: `"error"` (default) raises `p2108:invalidInput` on the first invalid element. `"code"` returns `NaN` and the NTIA return code for each element.
- `q_inverse` (sections 3.2 and 3.3): `"ntia"` (default) uses the Abramowitz and Stegun rational approximation of the reference code. `"exact"` uses `sqrt(2)*erfcinv(2*q)`. The two differ by less than 0.003 dB.

## Validation

Run `runtests("tests")` from the repository root. All 15 tests pass in MATLAB R2025b.

| Evidence | Cases | Tolerance |
|---|---|---|
| NTIA official test vectors ([NTIA/p2108-test-data](https://github.com/NTIA/p2108-test-data)) | All three models | 0.1 dB, as in NTIA's own tests |
| Compiled NTIA C++ v1.1 (`tools/p2108_reference_driver.cpp`) | 1,270 cases, including 1,200 seeded random cases and every return code | 1e-10 dB, and identical return codes |
| NTIA unit values for Equation 2a | 3 values | 1e-13 |
| Vectorized output against a scalar loop | 200 random cases | Exact |
| Properties: 2 km cap, increase with location percentage, grid and N-D shapes | Swept | Exact |

To regenerate the C++ reference files, compile the driver against the NTIA source:

```bash
g++ -O2 -std=c++17 -DLIBRARY_NAME='"P2108"' -DLIBRARY_VERSION='"1.1"' \
    -I p2108/include tools/p2108_reference_driver.cpp p2108/src/*.cpp -o drv2108
./drv2108 < tests/reference_cases_input.txt
```

## Behavior that follows the reference code

- **Section 3.2 distance limit.** The loss is `min(L(2 km), L(d))`, not `L(min(d, 2 km))`. These differ because at high location percentages (about 90% and above) the loss falls with distance before 2 km. Capping the distance instead returns up to 1.05 dB more loss for paths shorter than 2 km and up to 0.03 dB more beyond 2 km.
- **Section 3.2 short paths.** Distances below 0.25 km are invalid (return code 49). The model doesn't return 0 dB.
- **Section 3.1 clutter type.** When the antenna is at or above the clutter height, the model returns 0 dB and success without checking the clutter type, as the reference does.
- **Inverse CCDF at q = 0.5.** The approximation returns about ±1.0e-7 depending on the branch, as the reference does.

## License and attribution

This port follows the NTIA reference implementation, which is a work of the U.S. Government and isn't subject to copyright in the United States. See the [NTIA/p2108 license](https://github.com/NTIA/p2108/blob/main/LICENSE.md). Changes from the reference: vectorized MATLAB, implicit expansion, an optional exact inverse CCDF, and errors or return codes selected by `error_mode`.
