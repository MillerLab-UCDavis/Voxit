function [xo] = dithering(x)

xlen = length(x);
dither = rand(xlen,1) + rand(xlen,1) - 1;
spow = std(x);
xo = x + 1e-6 * spow * dither;
