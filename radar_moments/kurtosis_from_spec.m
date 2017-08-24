function kurt = kurtosis_from_spec(spec,velocity,vm,sigma,Ze)

ss = size(spec);
sv = size(velocity);

kurt = NaN(ss(1),1);

% ######## check if there is a velocity array for each spectrum
individual_velocities = false;
if eq(sv(1),ss(1)) % there is a velocity array for each spectrum    
    individual_velocities = true;
end

if ss(1) > 1 %  several range gates are provided
    
    for i = 1:ss(1)
        
        if individual_velocities == true
            
            kurt(i) = ( nansum( spec(i,:).*(velocity(i,:)-vm(i)).^4, 2 ) )/( Ze(i)*sigma(i)^4 );
            
        else
            
            kurt(i) = ( nansum( spec(i,:).*(velocity-vm(i)).^4, 2 ) )/( Ze(i)*sigma(i)^4 );
        
        end % if ind...
        
    end % for i
    
else
    
    kurt = ( nansum( spec.*(velocity-vm).^4, 2 ) )/( Ze*sigma^4 );
    
end % if ss...

end % function