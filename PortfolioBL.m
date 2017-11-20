classdef PortfolioBL < Portfolio
    %PortfolioBL Black-Litterman Optimization model implementation
    %   This Class extends the Portfolio object and implements methods to
    %   support Black-Litterman Optimization
    
    %   -------------------------------------------------------------------
    %   Author: Sri Krishnamurthy,CFA
    %   Contact: skrishna@mathworks.com
    %   Copyright 1984-2013 The MathWorks, Inc.
    
    
    properties
        % Views
        P % Link matrix ; Size : [No of Views * No of Assets]
        Q % Views vector Size: [ No of views]
        Alpha % Confidence
        Omega % Omega Matrix
        Tau % Tau parameter
        IndexData
        PI % Implied Excess Returns
        ExcessHistoricalReturns
        ExcessImpliedReturns
    end
    
    methods
        % Set Methods
        function obj = setP(obj,P)
            obj.P = P;
        end
        
        function obj = setAlpha(obj,Alpha)
            obj.Alpha = Alpha;
        end
        
        function obj = setQ(obj,Q)
            obj.Q = Q;
        end
        
        function obj = setTau(obj,Tau)
            obj.Tau = Tau;
        end
        
        function obj = setOmega(obj,Omega)
            obj.Omega = Omega;
        end
        
        function obj = setIndexData(obj,indexData)
            obj.IndexData = indexData;
        end
        
        function obj = setPI(obj,PI)
            obj.PI = PI;
        end
        % Compute Methods
        
        function obj = PortfolioBL(varargin)
            obj = obj@Portfolio(varargin{:});
        end
        
        % Function to compute the expected covariance and expected excess
        % returns vector
        function obj = computeBlackLitterman(obj)
            viewPart1 = obj.P'*(obj.Omega\obj.P);
            viewPart2 = obj.P'*(obj.Omega\obj.Q);
            if isempty(viewPart1)
                blMean = obj.PI;
            else
                blMean = (inv(obj.Tau*obj.AssetCovar) + viewPart1)...
                    \((obj.Tau*obj.AssetCovar)\obj.PI + viewPart2);
            end
            obj.AssetMean = blMean + obj.RiskFreeRate;
        end
        
        function obj = inputExpectedReturnViews(obj)
            views = View;
            obj.P = views.P;
            obj.Q = views.Q;
        end
        
        function obj = computeExcessHistoricalReturns(obj,portfolio,rfAsset)
            obj.ExcessHistoricalReturns = mean(portfolio-repmat(rfAsset,1,size(portfolio,2)))';
        end
        
        function obj = computeExcessImpliedReturns(obj,portfolio,market,rfAsset,mktCaps )
            % PI = delta*sigma*wMkt
            sigma = cov(portfolio);
            wMkt = mktCaps/(sum(mktCaps));
            % delta = Avg Excess return on market / Variance of market
            delta = mean(market - rfAsset)/(var(market));
            
            obj.ExcessImpliedReturns = delta * sigma * wMkt;
        end
        
        % Function to compute the Omega matrix
        function obj = computeOmega(obj)
            % Compute Omega using Black-Litterman's approach
            if ~isempty(obj.P)
                obj.Omega = obj.Tau*obj.P*obj.AssetCovar*obj.P'*obj.Alpha;
            else
                obj.Omega = [];
            end
        end
        
        % Helper function to review the Views matrix
        function reviewViewsMatrix(obj)
            f = figure('Position', [100 100 1000 150], 'Name','Analyst Views','Menubar','None');
            %f = figure('Position', [100 100 1000 150], 'Name','Analyst Views');
            t = uitable('Parent', f, 'Position', [25, 25, 950 100]);
            set(t, 'Data', [obj.Q obj.P]);
            rownames = cell(length(obj.Q));
            for i = 1: length(obj.Q)
                rownames{i} = strcat('View ',num2str(i));
            end
            set(t, 'RowName', rownames);
            set(t, 'ColumnName',['Q:View of expected excess returns',obj.AssetList]);
            foregroundColor = [1 1 1];
            set(t, 'ForegroundColor', foregroundColor);
            backgroundColor = [.2 .1 .1; .1 .1 .2];
            set(t, 'BackgroundColor', backgroundColor);
            s = sprintf('Q: Expected return values \nP is the absolute and relative views');
            set(t,'TooltipString',s)
        end
    end
end

