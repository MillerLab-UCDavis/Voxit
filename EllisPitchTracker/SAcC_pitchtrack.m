function [pfreq, pvx, lobs, D, obslik, newtransmat] = SAcC_pitchtrack(x, sr, mapping, fbank, net, P)
% [pfreq, pvx, lobs, D] = SAcC_pitchtrack(x, sr, mapping, fbank, n_s, verbose)
%  Subfunction does the actual work of running SAcC for SAcC_main
% 2012-11-01 Dan Ellis dpwe@ee.columbia.edu

%twin = 0.025;
%thop = 0.010;

% do we actually need to do neural net, or are we just calculating
% features?
if P.write_pitch || P.write_pvx || P.write_posteriors
  need_classif = 1;
else
  need_classif = 0;
end

% Calculate subband PCA feature
[D] = cal_ac(x, sr, mapping, fbank, P.twin, P.thop, P.n_s, P.verbose);

if need_classif
  % Calculate MLP forward output
  [obs] = mlp_fwd(D, net.IH', net.HO', net.HB', net.OB', net.ofs, net.sca);

  pvx = 1-obs(:,1);

  lobs = log(obs);

  % HMM pitch tracking
  [pitch,posterior,zobslik,obslik,newtransmat] = tracking_pitch_candidates(normalise(lobs'), P.hmm_vp);
  % [pitch] = tracking_pitch_candidates(obslik,...
  %         transfloor, wdyn, wobs, maxplags, prior, uvtrp, vutrp, transmat);

  freqs = dlmread(P.pcf_file);
  pfreq = pitch2freq(pitch,freqs)';

else
  % no pitch output - fake pitch returns
  lobs = zeros(size(D,1), P.nmlp);
  pvx = zeros(size(D,1));
  pfreq = zeros(size(D,1));
end

  
% dpwe - no plot ??
if P.disp == 1
  subplot(311)
  specgram(x,512,sr);
  ax = axis();
  ax(4) = 2000;
  axis(ax);
  subplot(312)
  tt = P.thop*[1:length(pfreq)];
  plot(pfreq');
  ylabel('Pitch / Hz');
  ax = axis;
  ax(3) = 0; ax(4) = 400;
  axis(ax)
  subplot(313)
  imagesc(obs')
  colormap(1-gray)
  xlabel('Frame')
  ylabel('Pitch Index')
  axis xy
%  [out_dir,out_name,out_ext] = fileparts(out_file);
%  title([out_name,out_ext])
%  outfile = [out_dir,'/',out_name];
%  print('-dpng',[outfile,'.png']);
end
