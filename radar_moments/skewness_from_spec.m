function skewness = skewness_from_spec(spec,velocity,vm,sigma,Ze)

ss = size(spec);
sv = size(velocity);

skewness = NaN(ss(1),1);

% ######## check if there is a velocity array for each spectrum
individual_velocities = false;
if eq(sv(1),ss(1)) % there is a velocity array for each spectrum    
    individual_velocities = true;
end

if ss(1) > 1 %  several range gates are provided

    for i = 1:ss(1)
        
        if individual_velocities == true
            
            skewness(i) = ( nansum( spec(i,:).*(velocity(i,:)-vm(i)).^3, 2 ) )/( Ze(i)*sigma(i)^3 );
            
        else
            
            skewness(i) = ( nansum( spec(i,:).*(velocity-vm(i)).^3, 2 ) )/( Ze(i)*sigma(i)^3 );
            
        end
        
    end
    
else
    
    skewness = ( nansum( spec.*(velocity-vm).^3, 2 ) )/( Ze*sigma^3 );
    
end % if

end % function