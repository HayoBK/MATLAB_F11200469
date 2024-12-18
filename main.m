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
% Otro paso para comenzar en otro PC es añadir a Add-on el modulo:
% --> Statistics and Machine Learning Toolbox
% --> DSP System Toolbox
% --> Signal Processing Toolbox

% PENDIENTES - DESAFIOS
% --> (a) poder manipular los Labels  --> CHECK
% --> (b) poder sincronizar (evaluar sincronia) con TIMESTAMPs en LSL_LAB
%           --> CHECK
% --> (c) preprocesar para filtrar, hacer ICA y toda esa brujeria EEG que
%           quiero comprender mejor lo que estoy haciendo
% --> (d) Incluir MULTIPLES PACIENTES para los análisis (hasta ahora solo
%           estoy con P33 de prueba

clc
tic % Esto comienza el reloj de conteo del tiempo transcurrido, finaliza con toc (tic-toc)
clear

disp(['Iniciando Script main.m by Hayo']);
disp(['-------------------------------']);

% ----------------------------------------------------------------------
% Vamos a probar con P33 como Test Subject
% -----------------------------------------------
Sujeto = 'P33';

% la Funcion Nombrar_HomePath es mia para encontrar mi directorio
% sincronizado independiente del computador en el que esté trabajando.
mi_path = ['002-LUCIEN/SUJETOS/',Sujeto,'/EEG/'];
Ruta = Nombrar_HomePath(mi_path);
file = [Ruta, Sujeto,'_NAVI'];

% ----------------------------------------------------------------------
% Cargamos el Archivo escogido usando LAN Toolbox como una estructura tipo
% LAN
% ----------------------------------------------------------------------

LAN =lan_read_file(file,'BA');

% ---------------------------------------------------------------------
% Codigo copiado de Billeke para hacer HIGH PASS FILTER
% uno puede invocar a designfilt en el command window
% para generar filtro a la pinta de uno y reemplazar la linea con los
% parametros de designfilt más abajo.
% ----------------------------------------------------------------------
% hight past filter in the continuos data 
   if 1
	    d1 = designfilt('highpassiir','FilterOrder',4, ...
	        'HalfPowerFrequency',0.25,'DesignMethod','butter', 'SampleRate',LAN.srate); % 0.25
	    for t=1:LAN.trials    
	    LAN.data{t} = single(filtfilt(d1,double(LAN.data{t}')))';
        end
        disp(['Filtrado Pasa Alto (by Billeke) REALIZADO CON EXITO ....'])
   end

% Empecemos a analizar los EVENTOS...
% ---------------------------------------------------------------------

% listarEventosUnicos(LAN);  %funcion en H_funciones para emitir un listado de los Eventos
% Ya no es necesario luego de todo el resto de los hueveos que hice...

%% -------------- SINCRONIZACION ------------------------
% Ahora vamos a determinar el delta de tiempo de sincronización entre LSL y
% EEG en base a comparar los Trials registrados en LSL-LabRecorder
% preprocesdos con la brujeria a prueba de errores version nuevemil en
% Python, y contrastarlos con los registros del EEG. 

% Importar los time_stamps de los mismos eventos desde LabRecorder_LSL
% precprocesados en Python en HF_FixationPupilExtraction.py
archivo_sync = 'export_for_MATLAB_Sync_NI.csv';

% Llamar a la función para contexto NI (puede ser RV, recuerda que algunos
% EEG estan mezclados como un continuo ambos experimentos) La diferencia
% elegirá entre el primer set de labels o el segundo
[delta_promedio_NI, delta_std, delta_max] = h_calcularDeltaSyncContexto(Ruta, archivo_sync, LAN, 'NI');

%Lo mismo para modalidad RV
archivo_sync = 'export_for_MATLAB_Sync_RV.csv';
[delta_promedio_RV, delta_std, delta_max] = h_calcularDeltaSyncContexto(Ruta, archivo_sync, LAN, 'RV');

%Grabar el Delta no es realmente necesario
%archivo_delta = fullfile(Ruta, 'Delta_Sync_LSL_a_EEG.mat');
%save(archivo_delta, 'delta_promedio');

% Habrá un reporte de la diferencias entre deltas de relojes, que sería el
% marcador de desincronización, que cuando lo probe, era de 9  milisegundos
% máximo (promedio 6 ms) en 19 minutos de experimento. Despreciable como
% error creo yo.  (un error de 0,00078%)

% Ahora ocuparmeos delta_promedio para traer los datos de Trials reales
% preprocesados en Python desde LSL, asi como fijaciones y blinks desde
% Pupil_Labs

% Esta función por la cresta que me costó armarla, pero funcionó:

[LAN, unique_trials] = h_integrarTimeMarkersEnLAN(Ruta,  ...
    'trials_forMATLAB_NI.csv', ...
    'fixation_forMATLAB_NI.csv', ...
    'blinks_forMATLAB_NI.csv', ...
    LAN, delta_promedio_NI, 'NI','solo');

%y ahora AÑaDIMOS (con 'add' como parametro final) los labels y eventos para RV cuando están continuos en un
% mismo EEG: 

[LAN, unique_trials] = h_integrarTimeMarkersEnLAN(Ruta,  ...
    'trials_forMATLAB_RV.csv', ...
    'fixation_forMATLAB_RV.csv', ...
    'blinks_forMATLAB_RV.csv', ...
    LAN, delta_promedio_RV, 'RV','add');

disp(['-----------------------------------------------------------------------'])
disp(['-----LOGRAMOS GENERAR el ARCHIVO LAN SINCRONIZADO... YEAH--------------'])


%% -----------------------LEGACY del proceso de aprender----------------------

% Esta proxima función es por si queremos exportar los eventos desde EEG
% para afuera en CSV --> Por si queremos analizar en Python cosas que
% hayamos guardado en eventos en EEG (no creo).
% exportarEventosCSV(LAN_filtered, 'P33_eventos_exportados_desdeMATLAB.csv');

%# Lexico para el Flujo de Datos a MATLAB en los Labels originales de EEG
% Dado que tengo todo más procesado en Python, es poco probabble que tenga
% que usarlos....
%# P_LEFT = 4
%# P_RIGHT = 6
%# P_FORWARD = 8
%# P_BACK = 2
%# P_STILL = 5
%# P_TRial es igual a 100 + Numero de Trial
%# P_FULLSTOP = 202
%# P_POSSIBLE_STOP = 201
%# P_FALSE_STOP = 203
%# P_GO_ON = 200
%# P_FORCE_START = 205


%% ------------------------- VEAMOS EL PLOT! ---------------------------

% prepro_plot(LAN) % con esta función podemos explorar El EEG. 
% listarEventosUnicos(LAN);  %funcion en H_funciones para emitir un listado de los Eventos
% delete(gcf) --> BORRAR los GUI.... sobre todo cuando se quedan pegados. 

%% CIERRE del Script -----------------------------------------------------
% Una estupidez de codigo de cierre que mide el tiempo que tardamos en
% correr todo el codigo, pero que además nos muestra que logramos completar
% el codigo completo, con la tranquilidad de un cierre del proceso...
% Espero

% Guardemos lo que logramos con LAN
name = ['hLAN_',Sujeto,'.mat'];
file_name = fullfile(Ruta, name);
save(file_name, 'LAN');

elapsedTime = toc;  % Mide el tiempo transcurrido
disp(['-----------------------------------------------------------------------']);
disp(['Se fini... --> Tiempo transcurrido: ', num2str(elapsedTime), ' segundos']);
disp(['Todo el Merito Mayor a Pablo Billeke en NeuroCICS']);
disp(['Escrito por Hayo Breibauer - www.labonce.cl']);
