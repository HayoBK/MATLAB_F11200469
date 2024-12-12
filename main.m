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
% --> (a) poder manipular los Labels
% --> (b) poder sincronizar (evaluar sincronia) con TIMESTAMPs en LSL_LAB

clc
tic % Esto comienza el reloj de conteo del tiempo transcurrido, finaliza con toc (tic-toc)
clear

disp(['Iniciando Script main.m by Hayo'])
disp(['-------------------------------'])

% ----------------------------------------------------------------------
% Vamos a probar con P33 como Test Subject
% -----------------------------------------------
mi_path = '002-LUCIEN/SUJETOS/P33/EEG/'
% la Funcion Nombrar_HomePath es mia para encontrar mi directorio
% sincronizado independiente del computador en el que esté trabajando.

Ruta = Nombrar_HomePath(mi_path)
file = [Ruta, 'P33_NAVI'];

% ----------------------------------------------------------------------
% Cargamos el Archivo escogido usando LAN Toolbox como una estructura tipo
% LAN
% ----------------------------------------------------------------------

LAN =lan_read_file(file,'BA')
oriLAN = LAN
% ---------------------------------------------------------------------
% Codigo copiado de Billeke para hacer HIGH PASS FILTER
% uno puede invocar a designfilt en el command window
% para generar filtro a la pinta de uno y reemplazar la linea con los
% parametros de designfilt más abajo.
% ----------------------------------------------------------------------
% hight past filter in the continuos data 
   if 1
	    d1 = designfilt('highpassiir','FilterOrder',4, ...
	        'HalfPowerFrequency',0.75,'DesignMethod','butter', 'SampleRate',LAN.srate); % 0.25
	    for t=1:LAN.trials    
	    LAN.data{t} = single(filtfilt(d1,double(LAN.data{t}')))';
        end
        disp(['Filtrado Pasa Alto (by Billeke) REALIZADO CON EXITO ....'])
   end

% Empecemos a analizar los EVENTOS...
% ---------------------------------------------------------------------

% listarEventosUnicos(LAN);  %funcion en H_funciones para emitir un listado de los Eventos



%% -------------- SINCRONIZACION ------------------------
% Ahora vamos a determinar el delta de tiempo de sincronización entre LSL y
% EEG en base a comparar los Trials registrados en LSL-LabRecorder
% preprocesdos con la brujeria a prueba de errores version nuevemil en
% Python, y contrastarlos con los registros del EEG. 

% Importar los time_stamps de los mismos eventos desde LabRecorder_LSL
% precprocesados en Python
archivo_sync = 'export_for_MATLAB_Sync.csv';

% Llamar a la función para contexto NI (puede ser RV, recuerda que algunos
% EEG estan mezclados como un continuo ambos experimentos)
[delta_promedio, delta_std, delta_max] = h_calcularDeltaSyncContexto(Ruta, archivo_sync, LAN, 'NI');
archivo_delta = fullfile(Ruta, 'Delta_Sync_LSL_a_EEG.mat');
save(archivo_delta, 'delta_promedio');
% Habrá un reporte de la diferencias entre deltas de relojes, que sería el
% marcador de desincronización, que cuando lo probe, era de 9  milisegundos
% máximo (promedio 6 ms) en 19 minutos de experimento. Despreciable como
% error creo yo.  (un error de 0,00078%)

% Ahora ocuparmeos delta_promedio para traer los datos de Trials reales
% preprocesados en Python desde LSL, asi como fijaciones y blinks desde
% Pupil_Labs
%LAN.RT = struct('label', {{}}, 'latency', [], 'dur', []);
[LAN, unique_trials] = h_integrarTimeMarkersEnLAN(Ruta, 'trials_forMATLAB_NI.csv', 'fixation_forMATLAB.csv', 'blinks_forMATLAB.csv', LAN, delta_promedio);
% Mostrar los trials únicos encontrados
fprintf('Trials únicos identificados: %s\n', mat2str(unique_trials));


%% -----------------------------------------------------------------------

% Esta proxima función es por si queremos exportar los eventos desde EEG
% para afuera en CSV --> Por si queremos analizar en Python cosas que
% hayamos guardado en eventos en EEG (no creo).
% exportarEventosCSV(LAN_filtered, 'P33_eventos_exportados_desdeMATLAB.csv');

%# Lexico para el Flujo de Datos a MATLAB:
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


% ---------------------------------------------------------------------
% Algunas funciones para evaluar LAN
% -----------------------------------------------------------
% LAN % muestra la estructura del struct LAN
% LAN.RT % muestra los eventos
% LAN.RT.label % muestra los labels de cada evento (desordenado si no se ha ordenado)
%% ------------------------- VEAMOS EL PLOT! ---------------------------
% prepro_plot(LAN) % con esta función podemos explorar El EEG. 

% CIERRE del Script -----------------------------------------------------
% Una estupidez de codigo de cierre que mide el tiempo que tardamos en
% correr todo el codigo, pero que además nos muestra que logramos completar
% el codigo completo, con la tranquilidad de un cierre del proceso...
% Espero

elapsedTime = toc;  % Mide el tiempo transcurrido
disp(['Se fini... --> Tiempo transcurrido: ', num2str(elapsedTime), ' segundos']);
disp(['Escrito por Hayo'])
