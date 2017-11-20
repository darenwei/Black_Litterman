
clc;
clear;
close all;



%%  Data Cleaning

%load('/Users/hbhamra_macpro/Dropbox/NBDhanuka/Code/iSDF/SDF_Estimate/10ETFs.mat');
%load('/Users/hbhamra_macpro/Dropbox/NBDhanuka/Code/iSDF/SDF_Estimate/MonthTbill.mat');

%load('/Users/darenbetty/Dropbox/NBDhanuka/Code/iSDF/SDF_Estimate/10ETFs.mat');
%load('/Users/darenbetty/Dropbox/NBDhanuka/Code/iSDF/SDF_Estimate/MonthTbill.mat');



load('C:\Users\Daren\Dropbox\NBDhanuka\Code\iSDF\SDF_Estimate\10ETFs.mat');
load('C:\Users\Daren\Dropbox\NBDhanuka\Code\iSDF\SDF_Estimate\MonthTbill.mat');

ShortTreasury_ts = fints(datenum(iShares13YearTreasuryBondETF.Date),iShares13YearTreasuryBondETF.IndexLevel,'Short_USTreasury');
LongTreasury_ts = fints(datenum(iShares710YearTreasuryBondETF.Date),iShares710YearTreasuryBondETF.IndexLevel,'Long_USTreasury');
SP500_ts = fints(datenum(iSharesCoreSP500ETF.Date),iSharesCoreSP500ETF.IndexLevel,'SP500');
InvGradeBond_ts =  fints(datenum(iSharesCoreUSAggregateBondETF.Date),iSharesCoreUSAggregateBondETF.IndexLevel,'US_Investment_Grade_Bond');

Gold_ts =  fints(datenum(iSharesGoldTrust.Date),iSharesGoldTrust.IndexLevel,'Gold');
EmergingMarkets_ts =  fints(datenum(iSharesMSCIEmergingMarketsETF.Date),iSharesMSCIEmergingMarketsETF.IndexLevel,'MSCI_EmergingMarkets_Equity');
UKequity_ts  =  fints(datenum(iSharesMSCIUnitedKingdomETFfund.Date),iSharesMSCIUnitedKingdomETFfund.IndexLevel,'MSCI_UK_Equity');
Russell2000_ts = fints(datenum(iSharesRussell2000ETF.Date),iSharesRussell2000ETF.IndexLevel,'Russell2000');
SelectDividend_ts = fints(datenum(iSharesSelectDividendETF.Date),iSharesSelectDividendETF.IndexLevel,'SelectDividend');
RealEstate_ts = fints(datenum(iSharesUSRealEstateETF.Date),iSharesUSRealEstateETF.IndexLevel,'US_RealEstate');
Rf_ts =  fints(datenum(MonthTbill.Date),MonthTbill.Rf,'Rf')/100;


index_ts = merge(LongTreasury_ts,SP500_ts,InvGradeBond_ts,Gold_ts ,EmergingMarkets_ts,UKequity_ts,Russell2000_ts,SelectDividend_ts,RealEstate_ts ,'DateSetMethod','intersection');
index_monthly_ts = tomonthly(index_ts);

%clear ShortTreasury_ts  LongTreasury_ts SP500_ts InvGradeBond_ts Gold_ts EmergingMarkets_ts UKequity_ts Russell2000_ts SelectDividend_ts RealEstate_ts
clearvars -except index_ts Rf_ts index_monthly_ts
symbol = fieldnames(index_ts,1);




return_ts = tick2ret(index_ts);
return_monthly_ts = tick2ret(index_monthly_ts );

index_ts = merge(index_ts,Rf_ts,'DateSetMethod','intersection');

%return_ts = merge(return_ts,Rf_ts,'DateSetMethod','intersection');
Rf_mean = nanmean(index_ts.Rf);  % mean of annual Rf


Rf_ts = (1+ index_ts.Rf).^(1/252) -1;  % convert to daily rate
Rf_mean_daily = nanmean(fts2mat(Rf_ts,0));
Rf_mean_monthly = nanmean(tomonthly(Rf_ts));

return_daily = fts2mat(return_ts,0);
return_mean_annual = nanmean(return_daily)*252;
sigma = nancov(return_daily)*252;
return_monthly = fts2mat(return_monthly_ts,0);
return_daily(any(isnan(return_daily), 2), :) = [];
p_BL = PortfolioBL('AssetList', symbol);



%% Compute Excess Return Prior Distribution


%%%----------First Method, Use Historical Returns------------------------%%%%

%p_BL = p_BL.computeExcessImpliedReturns(return_monthly,market,rfAsset,mktCaps );


%%%----------Second Method, Use Market Implied Returns------------------------%%%%
%%%----------Second Method prefered ------------------------%%%%

gamma = 3;
n = length(symbol);
mkt_cap = zeros(n,1);
mkt_cap(1) = 0.3; % Gold
mkt_cap(2) = 9.6; % Long US bond
mkt_cap(3) = 7; % Emerging markets equity
mkt_cap(4) = 7; % Europe Equity -- UK equity
mkt_cap(5) = 3; % Europe small cap Equity  -- Russel 2000
mkt_cap(6) = 12; % US Equity  -- SP500
mkt_cap(7) = 10; % US Equity  -- value firm
mkt_cap(8) = 6.4; % US Investment grade bond
mkt_cap(9) = 3.6; % US real estate
weight_eq = mkt_cap/sum(mkt_cap);
p_BL.ExcessImpliedReturns = gamma*nancov(return_monthly)*12*weight_eq - 0.01;

%%

p_BL = PortfolioBL(p_BL,'AssetMean',nanmean(return_daily)*252, 'AssetCovar',nancov(return_daily)*252,'RiskFreeRate',Rf_mean_daily );
p_BL = p_BL.setDefaultConstraints;
%p_BL.plotFrontier;

f = figure;
tabgp = uitabgroup(f); % Define tab group
tab1 = uitab(tabgp,'Title','Efficient Frontier Plot'); % Create tab
ax = axes('Parent', tab1);
% Extract asset moments from portfolio and store in m and cov
[m, cov] = getAssetMoments(p_BL);
scatter(ax,sqrt(diag(cov)), m,'oc','filled'); % Plot mean and s.d.
xlabel('Risk')
ylabel('Expected Return')
text(sqrt(diag(cov))+0.0003,m,symbol,'FontSize',7); % Label ticker names

hold on;
plotFrontier(p_BL);

hold off;



%% Views on Assets Returns

% Step 1 : Compute and review Excess Returns
% Approach 1: Compute PI : Historical Eqm Excess returns

p_BL = p_BL.computeExcessHistoricalReturns(return_monthly*12,0 );
p_BL =p_BL.setPI(p_BL.ExcessHistoricalReturns);


% Approach 2: Compute PI : Implied Eqm Excess returns
p_BL =p_BL.setPI(p_BL.ExcessImpliedReturns);

%Step 2 : Input views 

% view 1  Long Bond 1% next year
view1P = zeros(1,n);
view1P(2)=1;
view1Q  =  0.01;

% view 2  SPX 5% next year
view2P = zeros(1,n);
view2P(6)=1;
view2Q  =  0.05;

% view 3  Real Estate 0.1% next year
view3P = zeros(1,n);
view3P(9)=1;
view3Q  =  0.01;


% view 4  UK Equity 3% next year
view4P = zeros(1,n);
view4P(4)=1;
view4Q  =  0.03;


% view 5  US Investment Grade Bond 1% next year
view5P = zeros(1,n);
view5P(8)=1;
view5Q  =  0.01;

% view 6  Gold 1% next year
view6P = zeros(1,n);
view6P(1)=1;
view6Q  =  0.01;

p_BL.P = [ view1P; view2P; view3P; view4P; view5P; view6P];
p_BL.Q = [ view1Q; view2Q; view3Q; view4Q; view5Q; view6Q];


% Step 3: Compute the confidence matrix Omega


% confidence level [0,1] Alpha = 0  if 100% confident, Alpha = + inf if 0% confidence 

Alpha = 1;  %% default
p_BL = p_BL.setAlpha(Alpha);


p_BL.reviewViewsMatrix;

% We will use Tau to be 0.1
p_BL = p_BL.setTau(0.1);

% Omega
% You can input the Omega matrix or compute it.

% method 1; Manually input: high, mid or low confidence level
% method 1 prefered%

Omega = eye(6,6)*0.1^2;  % last 3 views low confident
Omega(1,1) = 0.03^2;  % first viewis  mid confident
Omega(2,2) = 0.03^2;    % second view mid confident
Omega(3,3) = 0.01^2;    % third view high confident
p_BL.Omega = Omega;

% method 2; Use alpha and historical covariance to compute the confidence
% level
%p_BL.Omega = p_BL.Tau*p_BL.P*p_BL.AssetCovar*p_BL.P'*alpha ;


% Step 3 : Combine Implied Excess Returns with views to derive new Expected
% Return vectors
p_BL = p_BL.computeBlackLitterman;




%%  Compute portfolio weight

% Initial portfolio weight, 40% long bond, 60% SP500
wgt0 = zeros(n ,1);
wgt0(2)=0.4;
wgt0(6) = 0.6;
[risk0, ret0] = estimatePortMoments(p_BL, wgt0);

w1 = estimateMaxSharpeRatio(p_BL);  % maximum Sharpe Ratio portfolio


% set portfolio constraint
% e.g.  only rebalance up to 50% of total portfolio
lb = zeros(n,1);     
lb(2) = 0.2;
lb(6) = 0.3;

% No leverage;
ub = ones(n,1);
ub(2) = 1;
ub(6) = 1;





f = figure;
tabgp = uitabgroup(f); % Define tab group
tab1 = uitab(tabgp,'Title','Efficient Frontier Plot'); % Create tab
ax = axes('Parent', tab1);
% Extract asset moments from portfolio and store in m and cov
[m, cov] = getAssetMoments(p_BL);
scatter(ax,sqrt(diag(cov)), m,'oc','filled'); % Plot mean and s.d.
xlabel('Risk')
ylabel('Expected Return')
text(sqrt(diag(cov))+0.0003,m,symbol,'FontSize',7); % Label ticker names

hold on;
plotFrontier(p_BL);


p_BL = setBounds(p_BL, lb, ub);
w_new1 =  estimateFrontierByReturn(p_BL,ret0);
w_new2 = estimateFrontierByRisk(p_BL,risk0);

[risk1, ret1] = estimatePortMoments(p_BL, w1);
[risk2, ret2] = estimatePortMoments(p_BL, w_new1 );
[risk3, ret3] = estimatePortMoments(p_BL, w_new2 );





plot(risk0,ret0,'p','markers',15,'MarkerEdgeColor','r',...
    'MarkerFaceColor','r');

%plot(risk1,ret1,'p','markers',15,'MarkerEdgeColor','y',...
%    'MarkerFaceColor','y');
plot(risk2,ret2,'p','markers',15,'MarkerEdgeColor','b',...
    'MarkerFaceColor','g');
plot(risk3,ret3,'p','markers',15,'MarkerEdgeColor','k',...
    'MarkerFaceColor','k');

hold off;



tab2 = uitab(tabgp,'Title','Keep Return Portfolio Weight'); % Create tab
% Column names and column format
columnname = {'Ticker','Weight (%)'};
columnformat = {'char','numeric'};
% Define the data as a cell array
data = table2cell(table(symbol(w_new1>0),w_new1(w_new1>0)*100));
% Create the uitable
uit = uitable(tab2, 'Data', data, 'ColumnName', columnname,...
    'ColumnFormat', columnformat,'RowName',[]);
% Set width and height
uit.Position(3) = 450; % Widght
uit.Position(4) = 350; % Height

tab3 = uitab(tabgp,'Title','Keep Vol Portfolio Weight'); % Create tab
% Column names and column format
columnname = {'Ticker','Weight (%)'};
columnformat = {'char','numeric'};
% Define the data as a cell array
data = table2cell(table(symbol(w_new2>0),w_new2(w_new2>0)*100));
% Create the uitable
uit = uitable(tab3, 'Data', data,'ColumnName', columnname, 'ColumnFormat', columnformat,'RowName',[]);
% Set width and height
uit.Position(3) = 450; % Widght
uit.Position(4) = 350; % Height

tab4 = uitab(tabgp,'Title','Max Sharpe Ratio Portfolio Weight'); % Create tab
% Column names and column format
columnname = {'Ticker','Weight (%)'};
columnformat = {'char','numeric'};
% Define the data as a cell array
data = table2cell(table(symbol(w1>0),w1(w1>0)*100));
% Create the uitable
uit = uitable(tab4, 'Data', data,'ColumnName', columnname,...
    'ColumnFormat', columnformat,'RowName',[]);
% Set width and height
uit.Position(3) = 450; % Widght
uit.Position(4) = 350; % Height