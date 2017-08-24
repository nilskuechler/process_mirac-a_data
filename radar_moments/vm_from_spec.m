function vm = vm_from_spec(spec,velocity,Ze)

% this function expects spectra in dB/m of the size [numel(velocity),1]
% velocity contains doppler velocity bins

ss = size(spec);
sv = size(velocity);

% preallocate
vm = NaN(ss(1),1);

% ######## check if there is a velocity array for each spectrum
individual_velocities = false;
if eq(sv(1),ss(1)) % there is a velocity array for each spectrum
    individual_velocities = true;
end

if ss(1) > 1 % then several range gates are provided
    
    for i = 1:ss(1)
        
        if individual_velocities == true
            
            vm(i) =  nansum(spec(i,:).*velocity(i,:),2)./Ze(i);
            
        else
            vm(i) =  nansum(spec(i,:).*velocity,2)./Ze(i);
            
        end
        
    end
    
else
    
    vm = nansum(spec.*velocity,2)./Ze;
    
end

end % function