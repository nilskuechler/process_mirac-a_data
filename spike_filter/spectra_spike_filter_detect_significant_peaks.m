function [n_peaks, idx_peaks, block_start, block_end] = spectra_spike_filter_detect_significant_peaks(spec, noise)

% input
%   spec: linear doppler spectrum (1 x Nfft)
%   noise: struct containing fields "meannoise" and "peaknoise" of spec
%
% output
%   n_peaks: number of peaknoise separated peaks
%   idx_peaks: index of peaks' maxima
%   block_start: start of a block with signal larger than mean noise
%   block_end: end of a block with signal larger than mean noise


% preallocate
n_peaks = 0;
idx_peaks = NaN;

% get length of spectrum
ss = size(spec);


% ##### identfiy blocks of signal

% get all values above peak noise level
idx = spec > noise.peaknoise;

[block_start, block_end] = radar_moments_get_blocks_of_signal(idx, ss);

if all(isnan(block_start))
    return
end

% determine size of these blocks
blocksizes = block_end - block_start + 1;

% consider only blocks with consecutive bins larger than X-1
idx_blocks = blocksizes >= 3;

if ~any(idx_blocks) % then no signal found
    return
end

block_start = block_start(idx_blocks);
block_end = block_end(idx_blocks);



% ##### determine signal above mean noise for all blocks left
for ii = 1:numel(block_start)
    
    % first entry aboce mean noise
    startidx = find( spec(1:block_start(ii)) < noise.meannoise, 1, 'last') + 1;
    % last entry above mean noise
    endidx = find( spec(block_end(ii):end) < noise.meannoise, 1, 'first') + block_end(ii) - 2;
    
    if isempty(startidx) % then first entry is still above mean noise -> aliasing likely
        startidx = 1;
    end
    if isempty(endidx) % then last entry is still above mean noise -> aliasing likely
        endidx = ss(2);
    end
    
    block_start(ii) = startidx;
    block_end(ii) = endidx;
    
end % for ii


% #### blocks can be separated by the peak noise level while not being
% separated by the mean noise level, thus, this block is considered as one
% block; check for doubling

block_start = unique(block_start);
block_end = unique(block_end);

% #### set ouput variables
% get number of peaks
n_peaks = numel(block_start);

% get location of peaks' m
idx_peaks = NaN(1,n_peaks);

for ii = 1:n_peaks
    [~, idx_peaks(ii)] = max(spec(block_start(ii):block_end(ii)));
    idx_peaks(ii) = idx_peaks(ii) + block_start(ii) - 1;
end