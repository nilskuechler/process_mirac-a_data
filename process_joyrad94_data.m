function process_joyrad94_data(infile,outfile,code,compact_flag,varargin)

% Author: Nils Küchler
% created: 9 February 2017
% modified: 13 Feburary 2017, Nils Küchler 

% read binary file and create netcdf file

% this is the main function calling subfunctions which process data
% according to the radar-software version with which the data was produced

% %####################### NOTE #########################
% the function must be adjusted when joyrad-94 is back at joyce and when it
% has to process data from joyrad-94 and from mirac, especially the if
% statements asking for the filecode after which the latitude and
% longitude are set


% input:
%   infile: filename of file to read in
%   outfile: filename of output file
%   code: filecode indicating the file format
%   compact-flag: If compact_flag = 0: only general file is created
%                    compact_flag = 1: only compact file is generated
%                    compact_flag = 2: both files are gerenrated
%   varargin: 
%       'moments','string': 'string' indicates how the radar moments should be
%       calculated:
%           - 'dealias': spectra are firstly dealiased and then moments are
%           calculated -> cal_mom = 1;
%           - 'spec': moments are calculated from spectra -> cal_mom = 2;
%           - 'off': radar moments are taken from files produced by rpg. for 
%                       data from software version 2, it can be that the
%                       moments were not stored, i.e. "lv1" files do not exist. then moments
%                       will be calculated from spectra. -> cal_mom = 3
%       if varargin is empty, moments are calculated from spectra. ->
%       cal_mom = 2;

% output:
%   no output


    % set if spectra are linear or not
    linflag = true;
    
    % check how moments should be calculated
    
    if any(strcmp(varargin,'moments'))
        cal_mom_string = varargin{find(strcmp(varargin,'moments')) + 1};
        if strcmp(cal_mom_string,'spec') % are calculated from spectra
            cal_mom = 2;
        elseif strcmp(cal_mom_string,'dealias') % are dealiased and the calculated from spectra
            cal_mom = 1;
        elseif strcmp(cal_mom_string,'off') % radar moments are taken from LV1 file
            cal_mom = 3;
        else % option not available calculate from spectra
            disp(['option ' cal_mom_string ' not available'])
            cal_mom = 2;
        end
    else
        cal_mom = 2;
    end

    
    % get file type, i.e. if it is netcdf or binary
    if ~isempty(strfind(infile,'.nc')) % then it is a netcdf file that contains variable created with radar softeare version 1
        
        linflag = false;
        software = 1; % indicate which software version was used to produce file
        
        % get data
        data = read_netcdf_v1(infile);
        
        % check if it is data from nya
        if data.time(1) > 486432000 % sec since 2001,1,1,0,0,0, which corresponds to 2016, June, 1st, i.e. data was collected in NyA
            data.Lat = 78.9233;
            data.Lon = 11.9222;
            data.MSL = 11.; % height above sea level
        else
            data.Lat = 50.9086;
            data.Lon = 6.4135;
            data.MSL = 111. + 19.5 + 1; % height above sea level + height of platform above ground + height of dish above platform            
        end
       
    elseif code == 789346 && isempty(strfind(infile,'.nc')) % then it is a binary file that contains variable created with radar software version 2
        
        software = 2;
        
        data = read_lv0_v2(infile);
        
        if ne(data.CompEna,0) && cal_mom == 1 % spectra are compressed, dealiasing not possible, take from LV1 files if available
            cal_mom = 3;
        end
        
        data.MSL = 111. + 19.5 + 1; % height above sea level + height of platform above ground + height of dish above platform            

       
    else
        disp(['netcdf cannot be created for this file type. skipping ' infile])
             return
    end % if ~isempty
    
    
    specsize = size(data.spec);
    
    % ############## add some variables
    data_fieldnames = fieldnames(data);
    
    % create velocity array
    dv = 2.*data.DoppMax./double(data.DoppLen);
    data.velocity = NaN(data.no_chirp_seq,max(data.DoppLen));
    for i = 1:data.no_chirp_seq
        data.velocity(i,1:data.DoppLen(i)) = -data.DoppMax(i):dv(i):data.DoppMax(i)-dv(i);
    end
    
    % number of spectral averages
    data.nAvg = data.SeqAvg./data.DoppLen; % number of spectral averages
    
    if ~any(strcmp(data_fieldnames,'MinVel'))
        data.MinVel = zeros(specsize(1),specsize(2)); % contains minimum velocity in spectra after dealiasing was applied
    else
        data.MinVel(data.MinVel == -999) = 0;
    end
    
    if ~any(strcmp(data_fieldnames,'Aliasmask'))
        data.Aliasmask = NaN(specsize(1),specsize(2)); %indicating if dealiasing was applied
    end
    
    if ~any(strcmp(data_fieldnames,'VNoisePow_mean')) % then NoisePow is not provided by RPG
        data.VNoisePow_mean = NaN(specsize(1),specsize(2)); % preallocate mean noise floor
    else
        data.VNoisePow_mean(data.VNoisePow_mean == -999) = NaN;
        for i = 1:data.no_chirp_seq % convert into bin noise power            
            if i == data.no_chirp_seq
                r_idx = data.range_offsets(i):specsize(2);
            else
                r_idx = data.range_offsets(i):data.range_offsets(i+1);
            end            
            data.VNoisePow_mean(:,r_idx) = data.VNoisePow_mean(:,r_idx)./single(data.DoppLen(i));
            if data.DualPol > 0                
                data.HNoisePow_mean(data.HNoisePow_mean == -999) = NaN;
                data.HNoisePow_mean(:,r_idx) = data.HNoisePow_mean(:,r_idx)./single(data.DoppLen(i));
            end            
        end
    end
    
    data.VNoisePow_peak = NaN(specsize(1),specsize(2)); % preallocate peak noise floor
    
    if data.DualPol > 0
        data.HNoisePow_peak = NaN(specsize(1),specsize(2)); % preallocate peak noise floor
    end
    
    % create dummy status flag
    data.AliasStatus = NaN(specsize(1),specsize(2)); % dummy variable that provides information on quality of dealiasing, not given by RPG software
    
    
    if data.AntiAlias == 1 % then dealiasing has been applied by rpg software
        if cal_mom == 1
            cal_mom = 3;
        end
        
    else % set MinVel matrix
        
            % if dealiasing was performed then the true velocity array can be
            % calculated as the following:
            % vel_true =  data.velocity + data.Minvel(i,j) - data.velocity(1)
            % note that the velocity array is different in every chrip sequence
            for ii = 1:data.no_chirp_seq % set MinVel to first entry of velocity
                if ii == data.no_chirp_seq
                    r_idx = data.range_offsets(ii):specsize(2);
                else
                    r_idx = data.range_offsets(ii):data.range_offsets(ii+1);
                end
                data.MinVel(:,r_idx) = data.velocity(ii,1);
            end

    end

    % create correction matrix for data.MinVel
    % in dealias_spectra_vm_column_quality_check.m wrongly dealiased
    % velocity bins (i.e. shifted by k*2*v_n) are corrected. the corrected
    % offset will be stored in data.MinVel_Correction. data.MinVel is
    % stored offset corrected
    % will only be modified if dealiasing is performed
   data.MinVel_Correction = zeros(specsize(1),specsize(2));    
    
    % set -999 values to NaN
    data = fill2nan_struct(data,-999); 
    
    
    % linflag == false only of data has been processed with software
    % version 1
    if linflag == false % convert spectra into linear units
        data.spec = 10.^(data.spec/10);
        data.Ze = 10.^(data.Ze/10);
    end
    
    
    if cal_mom == 3
        % check if LV1 exists
        infile_lv1 = [infile(1:end-1) '1'];
        if exist(infile_lv1,'file') == 2
            data_lv1_v2 = read_lv1_v2(infile_lv1);
            data_lv1_v2 = fill2nan_struct(data_lv1_v2,-999.);
        else  % file does not exist, calculate moments from spectra
            cal_mom = 2;
        end
    end
        
       
    
    if cal_mom == 1 % dealiase spectra and calulated higher moments
        
        data.AntiAlias = 2;
        
        % preallocate moments
        data.Ze = NaN(specsize(1:2));
        data.vm =  NaN(specsize(1:2));
        data.sigma =  NaN(specsize(1:2));
        data.skew =  NaN(specsize(1:2));
        data.kurt =  NaN(specsize(1:2));
        
        % oldspec = data.spec;  
        for i = 1:numel(data.time)
            
            temp = squeeze(data.spec(i,:,:));
            
            if all(isnan(temp(:,1)))
                continue
            end
            
%             temp = squeeze(oldspec(i,:,:));           
%             fig = pcolor_spectra_with_different_velocities(data.velocity,temp,'height',data.range,'range_offsets',data.range_offsets);
%             title(num2str(i));
           % ylim([300,700])
%             
            if i > 1
                vm_prev_col = data.vm(i-1,:)';
            else
                vm_prev_col = NaN(specsize(2),1);
            end
            
            
            [tempspec,tempvel,tempmoments,alias_flag,status_flag] = dealias_spectra(temp,data.velocity',data.nAvg,data.dr,vm_prev_col,'moment_str','kurt','pnf',1.,'nbins',3,'range_offsets',data.range_offsets,'linear');
            
            %             fig = pcolor_spectra_with_different_velocities(tempvel,tempspec,'height',data.range,'range_offsets',data.range_offsets);
%             hold on;
%             plot(tempmoments.vm,data.range,'kx-')
%             title([num2str(i) ' dealiased'])
%             ylim([300,700])

            % 
            

            % update spectrum
            data.spec(i,:,:) = tempspec;
            data.MinVel(i,:) = tempvel(:,1)';
            
            % get alias mask and status
            data.Aliasmask(i,:) = alias_flag'; % alias = 1; dealiasing was applied
            
            % status_flag = four bit binary/character that is converted into a real number.
            %   no bit set, everything fine (bin2dec() = 0; or status_flag = '0000'
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
            data.AliasStatus(i,:) = bin2dec(status_flag)';   
            
            % get moments
            data.Ze(i,:) = tempmoments.Ze';
            data.vm(i,:) = tempmoments.vm';
            data.sigma(i,:) = tempmoments.sigma';
            data.skew(i,:) = tempmoments.skew';
            data.kurt(i,:) = tempmoments.kurt'; 
            data.VNoisePow_mean(i,:) = tempmoments.meannoise';
            data.VNoisePow_peak(i,:) = tempmoments.peaknoise';
           
        end % i = 1:numel
        
%         % compare adjacent columns regarding vm and correct MinVel and vm
%         if dealiasing was not performed properly
          [data.AliasStatus, data.vm, data.MinVel_Correction] = dealias_spectra_vm_column_qualitiy_check( data.vm, data.range, data.AliasStatus, abs(data.velocity(:,1)), data.MinVel_Correction, data.range_offsets );
          
          % correct MinVel
          data.MinVel = data.MinVel + data.MinVel_Correction;
          
          % set all entries to NaN
          data.mask(:,:) = 0;
          data.mask(~isnan(data.Ze)) = 1;
          
          % set all not occupied values to NaN do decrease data
          idx = data.mask == 0;
          data.MinVel(idx) = NaN;
          data.MinVel_Correction(idx) = NaN;
          data.AliasStatus(idx) = NaN;
          data.Aliasmask(idx) = NaN;
          
    elseif cal_mom == 2 % calculate moments from spectra without dealiasing
        disp('Radar moments are now calculated from spectra that neither have been dealiased nor checked for contamintation by the radar pc.')
        
        % preallocate moments
        data.Ze = NaN(specsize(1:2));
        data.vm =  NaN(specsize(1:2));
        data.sigma =  NaN(specsize(1:2));
        data.skew =  NaN(specsize(1:2));
        data.kurt =  NaN(specsize(1:2));
        
        for i = 1:numel(data.time)
            
            temp = squeeze(data.spec(i,:,:));
            
            if data.CompEna == 0
                tempmoments = radar_moments(temp,data.velocity',data.nAvg,'linear','range_offsets',data.range_offsets,'moment_str','kurt','pnf',1.,'nbins',3);
            else
                tempmoments = radar_moments(temp,data.velocity',data.nAvg,'linear','range_offsets',data.range_offsets,'moment_str','kurt','pnf',1.,'nbins',3,'compressed');
            end
            % get moments
            data.Ze(i,:) = tempmoments.Ze';
            data.vm(i,:) = tempmoments.vm';
            data.sigma(i,:) = tempmoments.sigma';
            data.skew(i,:) = tempmoments.skew';
            data.kurt(i,:) = tempmoments.kurt';
            if data.CompEna == 0
                data.VNoisePow_mean(i,:) = tempmoments.meannoise';
                data.VNoisePow_peak(i,:) = tempmoments.peaknoise';
            end
            
        end % i = 1:numel
        
        % adjust data.mask
        data.mask(:,:) = 0;
        data.mask(~isnan(data.Ze)) = 1;
        
        % set all not occupied values to NaN do decrease data
        idx = data.mask == 0;
        data.MinVel(idx) = NaN;
        data.MinVel_Correction(idx) = NaN;
        data.AliasStatus(idx) = NaN;
        data.Aliasmask(idx) = NaN;
        
        
    elseif cal_mom == 3 && software == 2 % take moments from RPG lv1_v2-file
        
        data.Ze = data_lv1_v2.Ze;
        data.vm = data_lv1_v2.vm;
        data.sigma = data_lv1_v2.sigma;
        data.skew = data_lv1_v2.skew;
        data.kurt = data_lv1_v2.kurt;
        
        % in case of a polarimetric radar, data_lv1_v2 contains further
        % variables
        
        % set all not occupied values to NaN do decrease data
        idx = data.mask == 0;
        data.MinVel(idx) = NaN;
        data.MinVel_Correction(idx) = NaN;
        data.AliasStatus(idx) = NaN;
        data.Aliasmask(idx) = NaN;
        
    end % if cal_mom == 1
    
    % store how moments were calculated
    data.cal_mom = cal_mom;
    
%    dealias_spectra_plot_control_figures(data)
    
%    dlmwrite(['vm_' num2str(data.time(1)) '.dat'],data.vm);
    

    if data.totsamp == 0 
        disp([infile ' is empty.'])
        return
    end
    % write data
    if compact_flag == 0
        
        if exist(outfile,'file')
            delete(outfile);
        end
        write_joyrad94_data_2_nc(data,outfile);
        
    elseif compact_flag == 1
        
        outfile = strrep(outfile,'_20','_compact_20');
        if exist(outfile,'file')
            delete(outfile);
        end
        write_joyrad94_data_2_nc_compact(data,outfile);
        
    elseif compact_flag == 2
        
        if exist(outfile,'file')
            delete(outfile);
        end
        write_joyrad94_data_2_nc(data,outfile);
        
        outfile = strrep(outfile,'_20','_compact_20');
        if exist(outfile,'file')
            delete(outfile);
        end
        write_joyrad94_data_2_nc_compact(data,outfile);
        
    end

end % function create
