% main.m 
% --------------------------------------------------
% Mi primer script de MATLAB ... veamos como nos va.
% --------------------------------------------------
% Por si comienzas en otro PC, atento: Tienes que instalar LAN_current
% --> Lo clonas/descargas desde el GitHub de neurocics/LAN_current
% --> Luego en MATLAB, en HOME - Set Path, tienes que agregar el directorio
% --> donde lo bajaste con todos sus subfolders para que MATLAB lo pueda usar.

clc
tic %  
clear

disp(['Iniciando Script main.m by Hayo'])
disp(['-------------------------------'])
mi_path = '002-LUCIEN/SUJETOS/P04/EEG'
Ruta = Nombrar_HomePath(mi_path)

disp(Ruta)

elapsedTime = toc;  % Mide el tiempo transcurrido
disp(['Tiempo transcurrido: ', num2str(elapsedTime), ' segundos']);
disp(['Escrito por Hayo'])
