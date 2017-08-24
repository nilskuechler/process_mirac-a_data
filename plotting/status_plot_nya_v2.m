function status_plot_nya_v2(varargin)

% plot status of the receiver
%
% input:
%   varargin can contain the date to be processed (datevec)

varargin_flag = false;
if ~isempty(varargin)
    datum = varargin{1};
    varargin_flag = true;
    idx = 1:1;
else
    idx = 1:10;
end
    

for h = idx

clear joy94

if varargin_flag == false
    datum = datevec(floor(now)-h+1);
end

yyyy = num2str(datum(1));
mm = num2str(datum(2),'%02d');
dd = num2str(datum(3),'%02d');

datapath = ['/data/obs/site/nya/mirac-a/l1/' yyyy '/' mm '/' dd '/'];
files = dir([datapath '*nya_2*nc']);

if isempty(files)
    continue
end

n = 1;
for i = 1:numel(files)
    data = netcdf2struct([datapath files(i).name],'time','TransPow','RR','status','T_rec','T_trans');
    
    nn = numel(data.time);
    
    joy94.time(n:n+nn-1) = data.time;
    joy94.TransPow(n:n+nn-1) = data.TransPow;
    joy94.RR(n:n+nn-1) = data.RR;
    joy94.blower(n:n+nn-1) = data.status./10;
    joy94.T_Rec(n:n+nn-1) = data.T_rec;
    joy94.T_trans(n:n+nn-1) = data.T_trans;
    
    n = n + nn;
end

% convert time into hours of the day
joy94.timevec = datevec(double(joy94.time)/3600/24 + datenum([2001,1,1,0,0,0]));
joy94.time_h = joy94.timevec(:,4) + joy94.timevec(:,5)/60 + joy94.timevec(:,6)/3600;


%%
% make figure;
fonts = 13;

fig = figure;
ax = tight_subplot(4,1,0,0.12,[0.1,0.12]);
xl = [0,24];

% transmitter power
axes(ax(1));
plot(joy94.time_h,joy94.TransPow,'k.')
xlim(xl);
set(gca,'xticklabel',{[]},'xtick',0:5:24);
ylabel('[W]')
fig = myfigure_options(fig);
yl = [0,1.8];
ylim(yl);
text(1,yl(2)-diff(yl)/10,'Transmitter Power','fontsize',fonts);
title(['JOYRAD-94 status, ' yyyy mm dd]);

% rain rate
axes(ax(2));
plot(joy94.time_h,joy94.RR,'k.')
xlim(xl);
set(gca,'xticklabel',{[]},'xtick',0:5:24,'yaxislocation','right');
ylabel('[mm/h]')
fig = myfigure_options(fig);
yl = get(gca,'ylim');
yl(1) = 0;
ylim(yl);
text(1,yl(2)-diff(yl)/10,'Rain Rate','fontsize',fonts);

% blower status
axes(ax(3));
plot(joy94.time_h,joy94.blower,'k.')
xlim(xl);
ylim([0,1.5])
set(gca,'xticklabel',{[]},'xtick',0:5:24,'ytick',[0,1]);
ylabel('0 = off')
fig = myfigure_options(fig);
yl = get(gca,'ylim');
text(1,yl(2)-diff(yl)/10,'Blower Status','fontsize',fonts);


% receiver and transmitter temp
axes(ax(4));
plot(joy94.time_h,joy94.T_Rec,'-','color',[0,0,0]); hold on;
plot(joy94.time_h,joy94.T_trans,'-','color',[0,0,1]); hold on;
xlim(xl);
set(gca,'xtick',0:5:24,'yaxislocation','right');
ylabel('[K]')
fig = myfigure_options(fig);
yl = get(gca,'ylim');
text(1,yl(2)-diff(yl)/10,'Rec. temperature','fontsize',fonts);
text(6,yl(2)-diff(yl)/10,'Trans. temperature','color',[0,0,1],'fontsize',fonts);
xlabel('Time [UTC]')

print(fig,'-dpng',[datapath 'mirac-a_status' yyyy mm dd],'-r100')

close all;
end % h

end % function

% ###################################

function ha = tight_subplot(Nh, Nw, gap, marg_h, marg_w)

% tight_subplot creates "subplot" axes with adjustable gaps and margins
%
% ha = tight_subplot(Nh, Nw, gap, marg_h, marg_w)
%
%   in:  Nh      number of axes in hight (vertical direction)
%        Nw      number of axes in width (horizontaldirection)
%        gap     gaps between the axes in normalized units (0...1)
%                   or [gap_h gap_w] for different gaps in height and width 
%        marg_h  margins in height in normalized units (0...1)
%                   or [lower upper] for different lower and upper margins 
%        marg_w  margins in width in normalized units (0...1)
%                   or [left right] for different left and right margins 
%
%  out:  ha     array of handles of the axes objects
%                   starting from upper left corner, going row-wise as in
%                   going row-wise as in
%
%  Example: ha = tight_subplot(3,2,[.01 .03],[.1 .01],[.01 .01])
%           for ii = 1:6; axes(ha(ii)); plot(randn(10,ii)); end
%           set(ha(1:4),'XTickLabel',''); set(ha,'YTickLabel','')

% Pekka Kumpulainen 20.6.2010   @tut.fi
% Tampere University of Technology / Automation Science and Engineering


if nargin<3; gap = .02; end
if nargin<4 || isempty(marg_h); marg_h = .05; end
if nargin<5; marg_w = .05; end

if numel(gap)==1; 
    gap = [gap gap];
end
if numel(marg_w)==1; 
    marg_w = [marg_w marg_w];
end
if numel(marg_h)==1; 
    marg_h = [marg_h marg_h];
end

axh = (1-sum(marg_h)-(Nh-1)*gap(1))/Nh; 
axw = (1-sum(marg_w)-(Nw-1)*gap(2))/Nw;

py = 1-marg_h(2)-axh; 

ha = zeros(Nh*Nw,1);
ii = 0;
for ih = 1:Nh
    px = marg_w(1);
    
    for ix = 1:Nw
        ii = ii+1;
        ha(ii) = axes('Units','normalized', ...
            'Position',[px py axw axh], ...
            'XTickLabel','', ...
            'YTickLabel','');
        px = px+axw+gap(2);
    end
    py = py-axh-gap(1);
end

end % function

% ####################################################
function [fig] = myfigure_options(fig)

set(gcf,'paperpositionmode','auto')
set(fig,'position',[50 50 1000 800])
set(gca,'fontsize',24,'linewidth',1.5)
grid;

end % function

% ###########################################################
function data = netcdf2struct(filename,varargin)

% can read sups_joy_mwr00_l2_clwvi_p00_20151101000003.nc files containing
% offset corrected cloud liquid water path

%%%% check existence of file
if ne(exist(filename,'file'),2)
    disp('file does not exist');
    data = -999.;
    return
end

%**** open file
ncid = netcdf.open(filename,'NC_NOWRITE');

for i = 1:numel(varargin)
    
    id = netcdf.inqVarID(ncid,varargin{i});
    data.(varargin{i}) = netcdf.getVar(ncid,id);
    
end

%***** close file
netcdf.close(ncid);
end % function
