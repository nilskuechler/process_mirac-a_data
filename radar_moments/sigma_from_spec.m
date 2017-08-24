function sigma = sigma_from_spec(spec, velocity, vm, Ze)

ss = size(spec);
sv = size(velocity);

sigma = NaN(ss(1),1);

% ######## check if there is a velocity array for each spectrum
individual_velocities = false;
if eq(sv(1),ss(1)) % there is a velocity array for each spectrum    
    individual_velocities = true;
end

if ss(1) > 1 %  several range gates are provided
    
    for i = 1:ss(1)
        
        if individual_velocities == true
            
            sigma(i) = sqrt( nansum(spec(i,:).*(velocity(i,:)-vm(i)).^2 ,2)./Ze(i) );
            
        else
            
            sigma(i) = sqrt( nansum(spec(i,:).*(velocity-vm(i)).^2, 2)./Ze(i) );
        
        end
        
    end
    
else
    
    sigma = sqrt( nansum(spec.*(velocity-vm).^2, 2)./Ze );
    
end % if

end % function
