function fig = pcolorplot_vm(vm)

fig = figure;
pcolor(vm');
shading('flat');
colorbar;