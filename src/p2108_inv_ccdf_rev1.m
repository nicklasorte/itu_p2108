function Q = p2108_inv_ccdf_rev1(q, method)
%P2108_INV_CCDF_REV1 Inverse complementary cumulative normal distribution, as used by ITU-R P.2108.
%   Q = P2108_INV_CCDF_REV1(q) returns Q^-1(q) for 0 < q < 1 (any size),
%   using the Abramowitz and Stegun 26.2.23 rational approximation with the
%   constants of the NTIA reference implementation
%   (src/InverseComplementaryCumulativeDistribution.cpp, github.com/NTIA/p2108).
%   Absolute error is below 4.5e-4 against the exact value.
%
%   Q = P2108_INV_CCDF_REV1(q, "exact") returns sqrt(2)*erfcinv(2*q), the
%   exact value from the built-in erfcinv. The default "ntia" keeps the
%   approximation so results match the reference implementation.
arguments
    q double
    method (1,1) string {mustBeMember(method, ["ntia", "exact"])} = "ntia"
end
if any(q <= 0 | q >= 1, 'all')
    error('p2108:outOfRange', 'Input q must be between 0.0 and 1.0 (exclusive).');
end
if method == "exact"
    Q = sqrt(2) * erfcinv(2 * q);
    return
end
C_0 = 2.515517; C_1 = 0.802853; C_2 = 0.010328;
D_1 = 1.432788; D_2 = 0.189269; D_3 = 0.001308;
x = q;
hi = q > 0.5;
x(hi) = 1.0 - x(hi);
T_x = sqrt(-2.0 * log(x));
zeta_x = ((C_2 * T_x + C_1) .* T_x + C_0) ./ (((D_3 * T_x + D_2) .* T_x + D_1) .* T_x + 1.0);
Q = T_x - zeta_x;
Q(hi) = -Q(hi);
end
