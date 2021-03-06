
function [spec_out,vel_out,moments,alias_flag,status_flag] = dealias_spectra(spec,vel,nAvg,dr,vm_prev_col,varargin)

% this function dealiases doppler spectra by
% - identifying a region where the mean doppler velocity is close to zero
% - using the mean doppler velocity of an already dealiased bin as initial
% guess for the neighbouring bins
% therefore the moments of the spectra must be calculated

% input:
%   spec = doppler spectra, rows contain different heights, columns
%    different velo-bins, units must be linear, fill value must be NaN
%   vel = doppler velocity array (matrix), rows contain velo-bins, columns
%    different chrip sequences
%   nAvg = number of spectral averages for each chirp sequence
%   varargin = can contain further specifications as highest moment that
%    should be calculated and/or the mean or peak noise factor (mnf/pnf) that is used
%    to distinguish between signal and noise. if joy94 data is
%    provided varargin must contain the range_offsets.
%       varargin{1} = 'moment_str'; varargin{2} = 'sigma'; varargin{3} = 'mnf';
%       varargin{4} = 1.2; varargin{5} = 'nbins'; varargin{6} = 6; varargin{8} =
%       'range_offsets'; varargin{9} = range_offsets;
%       moment must can be: 'Ze','vm','sigma','skew', 'kurt'
%       with this setting the function calculates the mean doppler velocity
%       and the spectral where the a signficant peak is identified when 6
%       consectutive peaks (nbins) exceed the mean noise level (mnf) by a
%       factor if 1.2. the intital guess is taken from vm being the mean
%       doppler velocity calculated from non-dealiased spectra.
%    if varargin is empty the default values are: vm, pnf = 1.2, nbins = 5
%    and vm is calculated
%   dr = range resolution which is need to concatenate layer of signal if
%   there are gaps of a few bins
%   vm_prev_col: column of mean doppler velocity of previous column

% output:
%   spec_out: dealiased spectra
%   vel_out: velocity arrays corresponding to new spectra
%   moments: radar moments of spectra
%   alias_flag == 1 where aliasing occurs
% status_flag = four bit binary/character that is converted into a real number.
%   no bit set, everything fine (bin2dec() = 0; or status_flag = '000'
%   bit 1 (2^0) = 1: '0001' no initial guess Doppler velocity
%       (vm_guess) before aliasing -> bin2dec() = 1
%   bit 2 (2^1) = 1: '0010' either sequence or upper or lower
%       bin boundary reached and vm_guess indicates too large
%       velocities, i.e. dealiasing not possible anymore
%   bit 3 (2^2) = 1: '0100' the largest values of the spectra
%       are located close to nyquist limit -> aliasing still
%       likelythe column mean difference to v_m
%       bins from the neighbouring column exceeds a threshold
%       -> i.e. dealiasing routine created too high/low v_m
%   bit 4 (2^3) = 1: the column mean difference to v_m
%       bins from the neighbouring column exceeds a threshold
%       -> i.e. dealiasing routine created too high/low v_m
%   combinations possible, e.g. '0101' = 5



% ##################### check input
% check if there is data
if all( isnan(spec(:,1)) )
    return;
end

ss = size(spec);
sv = size(vel);

if sv(2) > sv(1)
    vel = vel';
    sv = size(vel);
end

delv = vel(2,:)-vel(1,:);
vn = -vel(1,:); % nyquist velocity

[moment_string, nf, nf_string, nbins, range_offsets] = dealias_spectra_varargin_check(ss, varargin{:});

% check unit of spectra
if isempty(find(strcmp(varargin,'linear'), 1)) % convert into linear regime
    spec = 10.^(spec./10);
end

% if an isolated bin shows aliasing the next bin used as indicator has to
% be closer than max_dis
max_dis = 50;



% ####################### preallocate output data
moments.Ze = NaN(ss(1),1);
moments.vm = NaN(ss(1),1);
moments.sigma = NaN(ss(1),1);
moments.skew = NaN(ss(1),1);
moments.kurt = NaN(ss(1),1);
moments.peaknoise = NaN(ss(1),1);
moments.meannoise = NaN(ss(1),1);

spec_out = spec;
vel_out = NaN(ss);

if sv(2) > 1 
    for ii = 1:ss(1)
        % get range indexes
         r_idx = dealias_spectra_get_range_index(range_offsets, ii);
         vel_out(ii,:) = vel(:,r_idx)';
    end
end


status_flag = zeros(ss(1),1); % if aliasing could be perform properliy
status_flag = dec2bin(status_flag,4); % convert to three binary string

% ############### get Nfft
Nfft = sum(~isnan(vel(:,:)));


% ###################### check aliasing
noise.peaknoise = NaN(ss(1),1);
noise.meannoise = NaN(ss(1),1);
[alias_flag, noise] = dealias_spectra_check_aliasing(ss, spec, vel, nAvg, range_offsets);
moments.peaknoise = noise.peaknoise;
moments.meannoise = noise.meannoise;


% ###################### clean signal from artificial contaminations from the pc hardware
if ss(1) == 1021 % then it is the high res mode
    
    % indicates artificial spikes that occur at well know range gates
    cont_mat = spectra_spike_filter_high_res_mode(spec); %, noise, range_offsets, Nfft);
    
    % clear spectra with contamination but no signal
    idx_cont = all(cont_mat,2);
    spec(idx_cont,:) = NaN;
    
    % #### only necessary when in spectra_spike_filter_high_res_mode()
    % processing steps 2 and 3 are enabled.
%     % set contaminated values in spectra with signal and contamination to a random value around between peak and mean noise level
%     idx_cont = find(any(cont_mat,2) & ~all(cont_mat,2));
%     
%     if ~isempty(idx_cont)
%         for ii = 1:numel(idx_cont)
%             idx_cont_bin = cont_mat(idx_cont(ii),:) == true;
%             spec(idx_cont(ii),idx_cont_bin) = noise.meannoise(idx_cont(ii),1) + (1 - 2*rand(1,sum(idx_cont_bin)))*(noise.peaknoise(idx_cont(ii),1) - noise.meannoise(idx_cont(ii),1));
%         end
%     end
            
end



% #################### check if aliasing occured in the column
if sum(alias_flag) == 0 % no aliasing occured, calculate moments from input spectra
    moments = radar_moments(spec,vel,nAvg,'noise',noise,'linear','range_offsets',range_offsets(1:end-1),'moment_str',moment_string,nf_string,nf,'nbins',nbins);
    return
end



% ##################### find cloud layers
[cbh_fin, cth_fin] = dealias_spectra_find_cloud_layers(spec, range_offsets, dr, max_dis);


% #################### start dealiasing every layer
for i = 1:numel(cbh_fin)

    [tempstruct, no_clean_signal, idx_0] = dealias_spectra_find_nonaliased_bin(cth_fin(i), cbh_fin(i), spec, range_offsets, vel, nAvg, moment_string, nf_string, nf, nbins, alias_flag, noise);
    
    % write to output struct
    if no_clean_signal == false
        
        moments = dealias_spectra_write_tempmoments_to_finalmoments(moments, tempstruct, idx_0, moment_string);

    else % no clean singal was found; calculate moments for all bins
        
        for ii = cbh_fin(i):cth_fin(i)
                        
            % get range indexes
            r_idx = dealias_spectra_get_range_index(range_offsets, ii);

            if all( isnan( spec(ii,1:Nfft(r_idx)) ) ) || sum(spec(ii,1:Nfft(r_idx))) < 10^-20; % then no signal is available
                continue
            end
            
            tempnoise.meannoise = noise.meannoise(ii);
            tempnoise.peaknoise = noise.peaknoise(ii);
            
            tempstruct = radar_moments(spec(ii,1:Nfft(r_idx)),vel(1:Nfft(r_idx),r_idx),nAvg(r_idx),'noise',tempnoise,'moment_str',moment_string,'linear',nf_string,nf,'nbins',nbins);
            moments = dealias_spectra_write_tempmoments_to_finalmoments(moments, tempstruct, idx_0, moment_string);

        end
        
    end
    
    if all( isnan( moments.vm(cbh_fin(i):cth_fin(i),1) ) ) || cbh_fin(i) == cth_fin(i) % then no entry of this layer contains signal or it is only one bin
        continue
    end % if cc == nbins-1, then the lowest bin of this layer contains signal
    
    
    % ################ dealiase
    % start dealiasing topdown
    if ne(idx_0,cbh_fin(i)) && ne(idx_0,cth_fin(i)) % then dealias in both directions
        
        % top down
        [spec_out(cbh_fin(i):idx_0-1, :), vel_out(cbh_fin(i):idx_0-1, :), status_flag, moments] =...
            dealias_spectra_from_idxA_to_idxB(idx_0-1, cbh_fin(i), range_offsets, vel, delv, spec, vn,...
            moments, moment_string, nAvg, nf_string, nf, nbins, status_flag, dr, vm_prev_col, noise.peaknoise);
        
        % down top
        [spec_out(idx_0+1:cth_fin(i), :), vel_out(idx_0+1:cth_fin(i), :), status_flag, moments] =...
            dealias_spectra_from_idxA_to_idxB(idx_0+1, cth_fin(i), range_offsets, vel, delv, spec, vn,...
            moments, moment_string, nAvg, nf_string, nf, nbins, status_flag, dr, vm_prev_col, noise.peaknoise);
        
    elseif ne(idx_0,cbh_fin(i)) % only topdown
        
        [spec_out(cbh_fin(i):idx_0-1, :), vel_out(cbh_fin(i):idx_0-1, :), status_flag, moments] =...
            dealias_spectra_from_idxA_to_idxB(idx_0-1, cbh_fin(i), range_offsets, vel, delv, spec, vn,...
            moments, moment_string, nAvg, nf_string, nf, nbins, status_flag, dr, vm_prev_col, noise.peaknoise);        
        
    else % only downtop
        
        [spec_out(idx_0+1:cth_fin(i), :), vel_out(idx_0+1:cth_fin(i), :), status_flag, moments] =...
            dealias_spectra_from_idxA_to_idxB(idx_0+1, cth_fin(i), range_offsets, vel, delv, spec, vn,...
            moments, moment_string, nAvg, nf_string, nf, nbins, status_flag, dr, vm_prev_col, noise.peaknoise);
            
        
    end
    
    


end % for i = 

    

end  % function





    

