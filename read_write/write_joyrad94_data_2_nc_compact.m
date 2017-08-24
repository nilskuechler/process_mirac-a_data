function write_joyrad94_data_2_nc_compact(data,outfile)

% this function writes joyrad94 data into netcdf4

%################## Create a netCDF file.

ncid = netcdf.create(outfile,'NETCDF4'); 


%################# Define dimensions

did_time = netcdf.defDim(ncid,'time',data.totsamp);
did_range = netcdf.defDim(ncid,'range',data.n_levels);
did_no_seq = netcdf.defDim(ncid,'chirp_sequences',data.no_chirp_seq);
did_scalar = netcdf.defDim(ncid,'scalar',1);


% ################ get variable ids and add attributes

%%%%%%%%%% scalar variables

id_AntiAlias = netcdf.defVar(ncid,'AntiAlias','nc_byte',did_scalar);
netcdf.putAtt(ncid,id_AntiAlias,'long_name','Flag for dealiasing.');
netcdf.putAtt(ncid,id_AntiAlias,'comment',...
    '0 = no dealiasing applied, 1 = dealiasing by RPG, 2 = dealiasing in process_joyrad94_data.m');

id_cal_mom = netcdf.defVar(ncid,'cal_mom','nc_byte',did_scalar);
netcdf.putAtt(ncid,id_cal_mom,'long_name','Integer indicating how moments were calculated.');
netcdf.putAtt(ncid,id_cal_mom,'comment',...
    '1 = moments were calculated from dealiased spectra. 2 = moments were calculated from raw spectra. 3 = moments were calculated by RPG software.');

id_lat = netcdf.defVar(ncid,'Lat','nc_float',did_scalar);
netcdf.putAtt(ncid,id_lat,'long_name','Latitude in degrees north [-90,90]');
netcdf.putAtt(ncid,id_lat,'units','degrees');

id_lon = netcdf.defVar(ncid,'Lon','nc_float',did_scalar);
netcdf.putAtt(ncid,id_lon,'long_name','Longitude in degrees east [-180,180]');
netcdf.putAtt(ncid,id_lon,'units','degrees');

id_MSL = netcdf.defVar(ncid,'MSL','nc_float',did_scalar);
netcdf.putAtt(ncid,id_MSL,'long_name','Height above mean sea level');
netcdf.putAtt(ncid,id_MSL,'units','m');

id_freq = netcdf.defVar(ncid,'freq','nc_float',did_scalar);
netcdf.putAtt(ncid,id_freq,'long_name','Transmission frequency');
netcdf.putAtt(ncid,id_freq,'units','GHz');



%%%%%%% range variables

id_range = netcdf.defVar(ncid,'range','nc_float',did_range);
netcdf.putAtt(ncid,id_range,'long_name','Range from antenna to the center of each range gate');
netcdf.putAtt(ncid,id_range,'units','m');



%%%%%%%% chirp_seq_dependent variables

id_SeqAvg = netcdf.defVar(ncid,'SeqAvg','nc_int',did_no_seq);
netcdf.putAtt(ncid,id_SeqAvg,'long_name','Number of averaged chirps in each chirp sequence');

id_SeqIntTime = netcdf.defVar(ncid,'SeqIntTime','nc_float',did_no_seq);
netcdf.putAtt(ncid,id_SeqIntTime,'long_name','Integration time of each chirp sequence');
netcdf.putAtt(ncid,id_SeqIntTime,'units','seconds');

id_DoppLen = netcdf.defVar(ncid,'DoppLen','nc_int',did_no_seq);
netcdf.putAtt(ncid,id_DoppLen,'long_name','Number of samples in Dopppler spectra of each chirp sequence. Needed to calculate the Doppler resolution: DoppRes = 2*DoppMax/DoppLen');

id_nAvg = netcdf.defVar(ncid,'nAvg','nc_int',did_no_seq);
netcdf.putAtt(ncid,id_nAvg,'long_name','Number of spectra averaged');
netcdf.putAtt(ncid,id_nAvg,'comment','nAvg = SeqAvg/DoppLen')


id_range_offsets = netcdf.defVar(ncid,'range_offsets','nc_int',did_no_seq);
netcdf.putAtt(ncid,id_range_offsets,'long_name','Chirp sequence start index array in range array');
netcdf.putAtt(ncid,id_range_offsets,'comment',...
    'The command range(range_offsets) will give you the range where a new chirp sequence starts. range_offsets counts from 1 to n_levels.');




%%%%%%%% time dependend variables

id_time = netcdf.defVar(ncid,'time','nc_uint',did_time);
netcdf.putAtt(ncid,id_time,'long_name','Time in sec since 2001.01.01. 00:00:00');
netcdf.putAtt(ncid,id_time,'units','seconds UTC');
netcdf.putAtt(ncid,id_time,'comment','To get the correct time the variable sampleTms must be added: time = time + sampleTms.');

id_sampleTms = netcdf.defVar(ncid,'sampleTms','nc_int',did_time);
netcdf.putAtt(ncid,id_sampleTms,'long_name','Milliseconds of sample');
netcdf.putAtt(ncid,id_sampleTms,'units','mu s');
netcdf.putAtt(ncid,id_sampleTms,'comment','To get the correct time the variable sampleTms must be added: time = time + sampleTms.');

id_RR = netcdf.defVar(ncid,'RR','nc_float',did_time);
netcdf.putAtt(ncid,id_RR,'long_name','Rain rate of meteo-station');
netcdf.putAtt(ncid,id_RR,'units','mm/h');

id_Tb = netcdf.defVar(ncid,'Tb','nc_float',did_time);
netcdf.putAtt(ncid,id_Tb,'long_name','brightness temperature direct detection channel');
netcdf.putAtt(ncid,id_Tb,'units','K');

id_lwp = netcdf.defVar(ncid,'lwp','nc_float',did_time);
netcdf.putAtt(ncid,id_lwp,'long_name','Liquid water path calculated by RPG software');
netcdf.putAtt(ncid,id_lwp,'units','g/m^2');



%%%%%%%% multi-D variables


id_Ze = netcdf.defVar(ncid,'Ze','nc_float',[did_range,did_time]);
netcdf.putAtt(ncid,id_Ze,'long_name','Equivalent radar reflectivity factor Ze');
netcdf.putAtt(ncid,id_Ze,'units','mm^6/m^3');

id_vm = netcdf.defVar(ncid,'vm','nc_float',[did_range,did_time]);
netcdf.putAtt(ncid,id_vm,'long_name','Mean Doppler velocity');
netcdf.putAtt(ncid,id_vm,'units','m/s');
netcdf.putAtt(ncid,id_vm,'comment','negative values indicate falling particles towards the radar')

id_sigma = netcdf.defVar(ncid,'sigma','nc_float',[did_range,did_time]);
netcdf.putAtt(ncid,id_sigma,'long_name','Spectral width of Doppler velocity spectrum');
netcdf.putAtt(ncid,id_sigma,'units','m/s');

id_skew = netcdf.defVar(ncid,'skew','nc_float',[did_range,did_time]);
netcdf.putAtt(ncid,id_skew,'long_name','Skewness');


%######################## add global attributes
glob = netcdf.getConstant('NC_GLOBAL');
netcdf.putAtt(ncid,glob,'FillValue','NaN');
netcdf.putAtt(ncid,glob,'program_name',data.progname);
if data.modelno == 0
    model = '94 GHz single pol.';
else
    model = '94 GHz dual pol.';
end
netcdf.putAtt(ncid,glob,'model_type',model);
netcdf.putAtt(ncid,glob,'contact','Tatiana Nomokonova, tnomokon@uni-koeln.de');
netcdf.putAtt(ncid,glob,'processing script','/home/hatpro/scripts/mirac-a/data_processing/call_process_joyrad94_data.m');


%###################### initialize copression of all floats:
netcdf.defVarDeflate(ncid,id_RR,true,true,9);
netcdf.defVarDeflate(ncid,id_Tb,true,true,9);
netcdf.defVarDeflate(ncid,id_lwp,true,true,9);
netcdf.defVarDeflate(ncid,id_Ze,true,true,9);
netcdf.defVarDeflate(ncid,id_vm,true,true,9);
netcdf.defVarDeflate(ncid,id_sigma,true,true,9);
netcdf.defVarDeflate(ncid,id_skew,true,true,9);


netcdf.endDef(ncid);



%####################### put variables into file

% scalars
netcdf.putVar(ncid,id_AntiAlias,0,data.AntiAlias);
netcdf.putVar(ncid,id_cal_mom,0,data.cal_mom);
netcdf.putVar(ncid,id_freq,0,data.freq);
netcdf.putVar(ncid,id_lon,0,data.Lon);
netcdf.putVar(ncid,id_lat,0,data.Lat);
netcdf.putVar(ncid,id_MSL,0,data.MSL);

% range dependet
netcdf.putVar(ncid,id_range,0,data.n_levels,data.range);


% chrip seq dependent variables
netcdf.putVar(ncid,id_range_offsets,0,data.no_chirp_seq,data.range_offsets);
netcdf.putVar(ncid,id_SeqAvg,0,data.no_chirp_seq,data.SeqAvg);
netcdf.putVar(ncid,id_SeqIntTime,0,data.no_chirp_seq,data.SeqIntTime);
netcdf.putVar(ncid,id_DoppLen,0,data.no_chirp_seq,data.DoppLen);
netcdf.putVar(ncid,id_nAvg,0,data.no_chirp_seq,data.nAvg);


% time dependent variables
netcdf.putVar(ncid,id_time,0,data.totsamp,data.time);
netcdf.putVar(ncid,id_sampleTms,0,data.totsamp,data.sampleTms);
netcdf.putVar(ncid,id_RR,0,data.totsamp,data.RR);
netcdf.putVar(ncid,id_Tb,0,data.totsamp,data.Tb);
netcdf.putVar(ncid,id_lwp,0,data.totsamp,data.lwp);

% multidimensional variables
netcdf.putVar(ncid,id_Ze,[0,0],[data.n_levels,data.totsamp],data.Ze');
netcdf.putVar(ncid,id_vm,[0,0],[data.n_levels,data.totsamp],data.vm');
netcdf.putVar(ncid,id_sigma,[0,0],[data.n_levels,data.totsamp],data.sigma');
netcdf.putVar(ncid,id_skew,[0,0],[data.n_levels,data.totsamp],data.skew');

netcdf.close(ncid);



end
