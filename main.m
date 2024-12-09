% main.m 
% --------------------------------------------------
% Mi primer script de MATLAB ... veamos como nos va.
% Hayo Breinbauer - 2024, Diciembre 9, un Lunes en la oficina
% FONDECYT 11200469
% --------------------------------------------------
% Por si comienzas en otro PC, atento: Tienes que instalar LAN_current
% --> Lo clonas/descargas desde el GitHub de neurocics/LAN_current
% --> Luego en MATLAB, en HOME - Set Path, tienes que agregar el directorio
% --> donde lo bajaste con todos sus subfolders para que MATLAB lo pueda usar.

clc
tic % Esto comienza el reloj de conteo del tiempo transcurrido, finaliza con toc (tic-toc)
clear

disp(['Iniciando Script main.m by Hayo'])
disp(['-------------------------------'])

% Vamos a probar con P04 como Test Subject

mi_path = '002-LUCIEN/SUJETOS/P04/EEG/'
% la Funcion Nombrar_HomePath es mia para encontrar mi directorio
% sincronizado independiente del computador en el que esté trabajando.

Ruta = Nombrar_HomePath(mi_path)
file = [Ruta, 'P04_NAVI'];

% Cargamos el Archivo escogido usando LAN Toolbox como una estructura tipo
% LAN
LAN =lan_read_file(file,'BA')

% Una estupidez de codigo de cierre que mide el tiempo que tardamos en
% correr todo el codigo, pero que además nos muestra que logramos completar
% el codigo completo, con la tranquilidad de un cierre del proceso...
% Espero

LAN % muestra la estructura del struct LAN
LAN.RT % muestra los eventos
LAN.RT.label % muestra los labels de cada evento (desordenado si no se ha ordenado)
preplo_plot(LAN)

elapsedTime = toc;  % Mide el tiempo transcurrido
disp(['Se fini... --> Tiempo transcurrido: ', num2str(elapsedTime), ' segundos']);
disp(['Escrito por Hayo'])
