function [olo] = mlp_fwd(D,weights12,weights23,bias2,bias3,ofs,sca)
%    function [olo] = mlp_fwd(D,weights12,weights23,bias2,bias3,ofs,sca)
%
% Forward Multi-Layer Perceptrom (MLP)
%
% [2012-04-11] Byung Suk Lee bsl@ee.columbia.edu

nfrms = size(D,1);
%% Normalize with offsets and scales
Dn = (D - repmat(ofs',nfrms,1))*diag(sca);

%% the first layer
hl = (Dn * weights12' + repmat(bias2,nfrms,1));
hlo = 1 ./ (1 + exp(-hl));

%% the second layer
ol = (hlo * weights23' + repmat(bias3,nfrms,1));
ole = exp(ol);
olo = ole ./ repmat(sum(ole,2),1,size(ole,2));

% figure, imagesc(olo'), colormap(1-gray), axis xy, grid on

