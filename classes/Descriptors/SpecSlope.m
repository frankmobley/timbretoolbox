classdef SpecSlope < TVDescr
    
    properties (GetAccess = public, SetAccess = protected)
        tSupport    % All Descr classes have a temporal support vector that
        % indicates at what times the data refers to (in
        % samples).
        value
        rep
    end
    
    properties (Constant)
        yLabel = 'Spectral Slope (Hz^-1)';
        repType = 'GenTimeFreqDistr';
        descrFamilyLeader = '';
    end
    
    methods
        function specSlope = SpecSlope(gtfDistr, varargin)
            % varargin is an (optional) configuration structure containing
            % the (optional) fields below :
            % 
            specSlope = specSlope@TVDescr(gtfDistr);
            
            specSlope.tSupport = gtfDistr.tSupport;
            
            if ~isa(gtfDistr, 'Harmonic')
                distrProb = gtfDistr.value ./ repmat(sum(gtfDistr.value, 1)+eps, gtfDistr.fSize, 1); % === normalize distribution in Y dim
                
                numerator = gtfDistr.fSize * (gtfDistr.fSupport' * distrProb) - sum(gtfDistr.fSupport) * sum(distrProb);
                denominator = gtfDistr.fSize * sum(gtfDistr.fSupport.^2) - sum(gtfDistr.fSupport).^2;
            else
                partialProb = gtfDistr.partialAmps ./ repmat(sum(gtfDistr.partialAmps, 1)+eps, gtfDistr.nHarms,1);	% === divide by zero
                
                numerator = gtfDistr.nHarms * sum(gtfDistr.partialFreqs .* partialProb, 1) - sum(gtfDistr.partialFreqs, 1);
                denominator = gtfDistr.nHarms * sum(gtfDistr.partialFreqs.^2, 1) - sum(gtfDistr.partialFreqs, 1).^2;
            end
            specSlope.value	= numerator ./ denominator;
        end
        
        function sameConfig = HasSameConfig(descr, config)
            sameConfig = true;
        end
    end
    
end

