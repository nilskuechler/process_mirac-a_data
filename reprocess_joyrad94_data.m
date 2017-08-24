clearvars;
clear mex;
close all; 
clc;

% create netcdf4 files from lv0 and/or lv1 files for joyrad94
% Author: Nils Küchler
% created: 08 February 2017
% modified: 24 August 2017, Nils Küchler 

% add functions in subfolders
addpath(genpath('/home/hatpro/scripts/mirac-a/data_processing/current_version/'))


% set processing variables
%   compact-flag: If compact_flag = 0: only general file is created
%                    compact_flag = 1: only compact file is generated
%                    compact_flag = 2: both files are gerenrated
compact_flag = 2;


% highest moment to be calculated
% ='off' moments taken from files if available, ='dealias' spectra are dealiased first, 
% then moments are calculated, ='spec' moments calculated from spectra
moments_cal = 'dealias';

for ii = 2017:2017 % year
    for iii = 8:8%1:12 % month
        for iv = 1:20%1:31 % day
                
            time_today = [ii, iii, iv, 0, 0, 0];
            
            path_lv0 = ['/data/obs/site/nya/mirac-a/l0/' num2str(time_today(1))...
                '/' num2str(time_today(2),'%02d') '/' num2str(time_today(3),'%02d') '/'];
            
   	     path_lv1 = ['/data/obs/site/nya/mirac-a/l1/' num2str(time_today(1))...
                '/' num2str(time_today(2),'%02d') '/' num2str(time_today(3),'%02d') '/'];     
    
                                                                                                                                                                                                                                    
    	     files_lv0 = dir([path_lv0 '*lv0']);                                                                                                                                                                                             
    	     if isempty(files_lv0)                                                                                                                                                                                                           
        	     continue                                                                                                                                                                                                                    
    	     end                                                                                                                                                                                                                             
                                                                                                                                                                                                                                    
    	     % create new subfolder if does not yet exist                                                                                                                                                                                    
    	     if ~exist(path_lv1,'dir')                                                                                                                                                                                                       
        	mkdir(path_lv1)                                                                                                                                                                                                             
    	     end
            
            
            for h = 1:numel(files_lv0)
                
                
                % ######################## start with level 0 (lv0) files
                infile = [path_lv0 files_lv0(h).name];                                                                                                                                                                                      
        	disp(infile);                                                                                                                                                                                                               
                                                                                                                                                                                                                                    
        	outfile = [path_lv1 files_lv0(h).name(1:end-3) 'nc'];                                                                                                                                                                                                                                                                                                                                                        
        	outfile = strrep(outfile,'mirac-a_','mirac-a_nya_');                                                                                                                                                                        
                                                                                                                                                                                                                                    
        	if exist(outfile,'file') == 2                                                                                                                                                                                               
            		disp([outfile ' already exists']); continue                                                                                                                                                                             
        	end                                                                                                                                                                                                                         
                                                                                                                                                                                                                                    
        	fid = fopen(infile, 'r', 'l');                                                                                                                                                                                              
        	if fid == -1                                                                                                                                                                                                                
            		disp(['could not open ' infile])
            		continue
        	end
        	filecode = int32(fread(fid,1,'int'));
        	fclose(fid);       

        	process_joyrad94_data(infile,outfile,filecode,compact_flag,'moments',moments_cal);
                
                
                
            end % h = 1:numel(files)
            
            % call plot routine for status data
            status_plot_nya_v2(time_today);
            
            
            clearvars -except ii iii iv N compact_flag moments_cal


        end % iv
    end % iii
end % ii
% close matlab
quit
