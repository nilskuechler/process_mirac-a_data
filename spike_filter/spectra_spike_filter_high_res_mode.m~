function cont_mat = spectra_spike_filter_high_res_mode(spec) %, noise, range_offsets, Nfft, varargin)

% input:
%   spec: linear Doppler spectra of full column (height x Nfft)
    % ##### only needed when steps 2 and 3 are enabled:
    %   noise: struct containing fields meannoise and peaknoise
    %   range_offsets: indexes indicating start of new chirp sequence
    %   Nfft: numvber of velocity bins in each chirp sequence
    %   varargin: index in spec where contamination is expected
%
% output:
%   cont_mat: contaminated bins; if there is no cloud but contamination
%   then all entries are true

% the following rangebins are known to contain contamination
% idx = [224, 225, 765, 766];

% 1) check if there is signal above/below; if not then just set to NAN

    % ##### points 2 and 3 are not executed!
    % 2) if there is signal check if there are two separate peaks; then
    % compare to adjacent spectra to identifcy artificial peak

    % 3) if there is only one peak compare magnitude with adjacent bins; if so
    % interpolate spectra and flag

ss = size(spec);

% create output matrix
cont_mat = false(ss);

    % % check size
    % if numel(range_offsets) == numel(Nfft) % then add range offset required by function dealias_spectra_get_range_index.m
    %     range_offsets(end+1) = 10^5;
    % end

% flag empty range bins
flag = isnan(spec(:,1));

if all(flag(221:223)) && all(flag(226:227)) && (flag(224) == false || flag(225) == false) % check where signal occurs
    
    % 1) ###################
    if flag(224) == false
        cont_mat(224,:) = true;
    end
    
    if flag(225) == false
        cont_mat(225,:) = true;
    end
%     
% else 
%     % 2) ###################
%     
% 
%     % 3) ###################

end

% check if neighbouring bins are occupied
if all(flag(762:764)) && all(flag(767:769)) && (flag(765) == false || flag(766) == false) % check where signal occurs
    
    % 1) ###################    
    if flag(765) == false
        cont_mat(765,:) = true;
    end
    
    if flag(766) == false
        cont_mat(766,:) = true;
    end
    
% else
%     
%     % 2) ###################
%     
%     for ii = 765:766
%         
%         %## determine number of peaks in considered bin
%         idx_bin = ii;
%         
%         if isnan(spec(idx_bin,1))
%             continue
%         end
% 
%         %## get which chirp sequence
%         r_idx = dealias_spectra_get_range_index(range_offsets, idx_bin);
% 
%         % get noise of this bin
%         tempnoise.meannoise = noise.meannoise(idx_bin);
%         tempnoise.peaknoise = noise.peaknoise(idx_bin);
% 
%         [n_peaks, idx_peaks, block_start, block_end] = spectra_spike_filter_detect_significant_peaks(spec(idx_bin,1:Nfft(r_idx)), tempnoise);
% 
%         if n_peaks == 0
%             continue
%         end
%         
%         %## determine number of peaks in adjacent bins
%         % get next bin going upwards
%         idx_next = find(~isnan(spec(767:771,1)),1,'first') + 767 - 1;
%         if isempty(idx_next) % go downwards
%             idx_next = find(~isnan(spec(760:764,1)),1,'last') + 760 - 1;
%         end
%         [n_peaks_neigh, idx_peaks_neigh] = spectra_spike_filter_detect_significant_peaks(spec(idx_next,1:Nfft(r_idx)), tempnoise);
% 
%         % compare number of sigificant peaks
%         if n_peaks > n_peaks_neigh % then additional peak is assumed to be contamination
% 
%             % identify contamination:
% 
%             % get distances between peaks in adjacent bins: create a matrix
%             % containing all differences, i.e. abs(idx_peak(i) -
%             % idx_peak_neigh(j))
%             diffmat = abs(idx_peaks_neigh'*ones(1,n_peaks)-ones(n_peaks_neigh,1)*idx_peaks);
%             % get minima of eachcolumn
%             min_diffmat = min(diffmat,[],1);
% 
%             % maximum of min_diffmat is contaminated peak
%             [~,idx_cont] = max(min_diffmat);
% 
%             % set spectral values of contamination
%             cont_mat(idx_bin,block_start(idx_cont):block_end(idx_cont)) = true;
% 
%         end      
%         
%     end % for ii    

end







end