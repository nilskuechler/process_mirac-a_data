function fig = pcolor_spectra_with_different_velocities(vel,spec,varargin)

% input
%   vel: matrix containing velocity arrays for spec, size = height x Nfft
%   or size = n_range_offsets x Nfft
%   spec: spectra in linear units
%   varargin: 
%       'height', followed by height array
%       'range_offsets', followed by range_offsets

ss = size(spec);

idx_height = find(strcmp(varargin,'height'), 1)+1;
idx_range_offsets = find(strcmp(varargin,'range_offsets'), 1)+1;

if ~isempty(idx_height)
    height = varargin{idx_height};
else
    height = 1:ss(1);
end

if isempty(idx_range_offsets)
    
    % get minimum velocities
    v_min = min(min(vel));
    v_max = max(max(vel));

    % get Doppler resolution
    v_res = vel(1,2) - vel(1,1);

    % crete new velocity array
    v_new = v_min:v_res:v_max;

    % create new spectra matrix
    spec_new = NaN(ss(1),numel(v_new));
    
    for ii = 1:ss(1)
        [~,idx] = min(abs(vel(ii,1)-v_new));
        if isempty(idx)
            continue
        end
        
        spec_new(ii,idx:idx+ss(2)-1) = spec(ii,:);
    end
       
    
else % interpolate spectra on same grid
    
    range_offsets = varargin{idx_range_offsets};
    
    sv = size(vel);
    
    if ne(sv(1),ss(1)) % then velocity arrays for each chirp sequence are provided
        
        vel_old = vel;
        vel = NaN(ss); 
        
        % get minimum velocities
        v_min = min(min(vel_old));
        v_max = max(max(vel_old));
        
        % get coearsest Doppler resolution
        v_res = max(vel_old(:,2) - vel_old(:,1));

    else
        
        % get minimum velocities
        v_min = min(min(vel));
        v_max = max(max(vel));
        
        % get coearsest Doppler resolution
        v_res = max(vel(range_offsets,2) - vel(range_offsets,1));
        
    end
              
   
    % create new velocity array
    v_new = v_min:v_res:v_max;

    % create new spectra matrix
    spec_new = NaN(ss(1),numel(v_new));
    
    for ii = 1:ss(1)
        
        if ne(sv(1),ss(1))
            r_idx = dealias_spectra_get_range_index([range_offsets, 10^5],ii);
            Nfft = find(~isnan(vel_old(r_idx, :)),1,'last');
            vel(ii,1:Nfft) = vel_old(r_idx, 1:Nfft);
        else
            Nfft = find(~isnan(vel(ii,:)),1,'last');
        end
        
        if isempty(Nfft)
            continue
        end
        
        spec_new(ii,:) = interp1(vel(ii,1:Nfft),spec(ii,1:Nfft),v_new);

    end

end

% get last bin with an entry
idx_last = find(any(~isnan(spec_new),2),1,'last');

fig = figure;
pcolor(v_new,height,10*log10(spec_new));
shading('flat');
cb = colorbar;
ylim([height(1), height(idx_last)])