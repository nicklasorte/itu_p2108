function A_h_db = p2108_equation_2a_rev1(nu)
%P2108_EQUATION_2A_REV1 Knife-edge diffraction term of the height-gain model, ITU-R P.2108 Eqn 2a.
%   A_h_db = P2108_EQUATION_2A_REV1(nu) returns J(nu) - 6.03 dB, where
%   J(nu) = 6.9 + 20 log10(sqrt((nu - 0.1)^2 + 1) + nu - 0.1) and J = 0 for nu <= -0.78.
%   Port of Equation_2a in src/HeightGainTerminalCorrectionModel.cpp (github.com/NTIA/p2108).
arguments
    nu double
end
J = zeros(size(nu));
m = nu > -0.78;
term1 = sqrt((nu(m) - 0.1).^2 + 1);
J(m) = 6.9 + 20 * log10(term1 + nu(m) - 0.1);
A_h_db = J - 6.03;
end
