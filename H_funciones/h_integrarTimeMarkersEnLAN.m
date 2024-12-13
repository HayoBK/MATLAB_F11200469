function [LAN, unique_trials] = h_integrarTimeMarkersEnLAN(Ruta, archivo_trials, archivo_fijaciones, archivo_blink, LAN, delta_promedio)
    % h_integrarTimeMarkersEnLAN: Incorpora datos de trials, fijaciones y blinks
    % a un archivo LAN, ajustando las latencias con delta_promedio y asegurando
    % la coherencia temporal mediante remuestreo si es necesario.
    %
    % Entradas:
    %   - Ruta: Ruta de los archivos .csv y donde guardar los resultados.
    %   - archivo_trials: Nombre del archivo CSV con los datos de trials.
    %   - archivo_fijaciones: Nombre del archivo CSV con los datos de fijaciones.
    %   - archivo_blink: Nombre del archivo CSV con los datos de blinks.
    %   - LAN: Estructura LAN donde se integrarán los datos.
    %   - delta_promedio: Corrección de tiempo en segundos.
    %
    % Salidas:
    %   - LAN: Estructura LAN modificada con los nuevos eventos integrados.
    %   - unique_trials: Lista de IDs de trials únicos encontrados.

    %% Cargar los datos desde los archivos .csv
    % Cargar datos de trials
    trials = readtable(fullfile(Ruta, archivo_trials));
    % Cargar datos de fijaciones
    fijaciones = readtable(fullfile(Ruta, archivo_fijaciones));
    % Cargar datos de blinks
    blinks = readtable(fullfile(Ruta, archivo_blink));

    %% Ajustar las latencias con delta_promedio
    % Para trials (con inicio y fin)
    % Para trials (con inicio y fin)
    trials.start_corrected = round((trials.start_time + delta_promedio) * 1000);  % Inicio corregido en ms
    trials.end_corrected = round((trials.end_time + delta_promedio) * 1000);      % Fin corregido en ms
    trials.duration = trials.end_corrected - trials.start_corrected;              % Duración en ms

    % Para fijaciones (con inicio y duración)
    fijaciones.start_corrected = round((fijaciones.start_time + delta_promedio) * 1000);  % Inicio corregido en ms
    fijaciones.end_corrected = fijaciones.start_corrected + round(fijaciones.duration * 1000);  % Fin calculado en ms

    % Para blinks (con inicio y duración)
    blinks.start_corrected = round((blinks.start_time + delta_promedio) * 1000);  % Inicio corregido en ms
    blinks.end_corrected = blinks.start_corrected + round(blinks.duration * 1000);  % Fin calculado en ms

    %% Filtrar eventos fuera del rango de los trials
    % Obtener el tiempo de inicio del primer trial y el tiempo de fin del último trial
    inicio_trials = min(trials.start_corrected);
    fin_trials = max(trials.end_corrected);

    % Filtrar fijaciones que ocurren dentro del rango de los trials
    valid_fijaciones = fijaciones.start_corrected >= inicio_trials & fijaciones.end_corrected <= fin_trials;
    fijaciones = fijaciones(valid_fijaciones, :);

    % Filtrar blinks que ocurren dentro del rango de los trials
    valid_blinks = blinks.start_corrected >= inicio_trials & blinks.end_corrected <= fin_trials;
    blinks = blinks(valid_blinks, :);

    %% Verificar y ajustar la tasa de muestreo
    % Suponiendo que los datos de eventos están en segundos y LAN.srate es la tasa de muestreo en Hz
    % Si las tasas de muestreo difieren, se debe remuestrear LAN.data
    % Aquí asumimos que los datos de LAN están en LAN.data y la tasa de muestreo en LAN.srate

    % Definir la tasa de muestreo deseada (por ejemplo, 1000 Hz)
    srate_deseada = 1000;  % Ajusta este valor según tus necesidades


    %% Incorporar los datos corregidos a LAN
    % Inicializar o limpiar la estructura LAN.RT
    RT = struct('label', {{}}, 'latency', [], 'dur', []);
    
    % Función auxiliar para agregar eventos a LAN.RT
    function agregar_eventos(eventos, etiqueta)
        for i = 1:height(eventos)
            RT.label{end+1} = etiqueta;
            RT.latency(end+1) = eventos.start_corrected(i) %* LAN.srate;  % Convertir a muestras
            RT.dur(end+1) = (eventos.end_corrected(i) - eventos.start_corrected(i)) %* LAN.srate;  % Duración en muestras
        end
    end

    % Agregar trials
    for i = 1:height(trials)
        agregar_eventos(trials(i, :), sprintf('TRIAL_%d', trials.trial_id(i)));
    end

    % Agregar fijaciones
    agregar_eventos(fijaciones, 'FIXATION');

    % Agregar blinks
    agregar_eventos(blinks, 'BLINK');
    
    % Obtener los índices que ordenarían el campo 'latency' de forma ascendente
    [~, indices] = sort([RT.latency]);

    % Aplicar el ordenamiento a cada campo de la estructura
    RT.label = RT.label(indices);
    RT.latency = RT.latency(indices);
    RT.dur = RT.dur(indices);


    %% Vamos a construir paso a paso una estructura RT
    RT_new = struct('label', {RT.label});
    
    % Suponiendo que RT.label es un arreglo de celdas de cadenas de texto
    [etiquetas_unicas, ~, indices] = unique(RT.label);
    
    % Crear un mapa de etiquetas a identificadores numéricos
    mapa_etiquetas = containers.Map(etiquetas_unicas, 1:length(etiquetas_unicas)); 
    RT_new.est = indices;
    RT_new.est = RT_new.est.';
    RT_new.laten = RT.latency;
    RT_new.OTHER = struct('names',  {RT.label});
    RT_new.rt = RT.dur;
    RT_new.resp = RT.dur;
    RT_new.latency = RT.latency;
    RT_new.misslaten = [];
    RT_new.missest = [];
    RT_new.nblock = 1;
    n = length(RT_new.laten);
    RT_new.good = true(1, n);
    
    LAN.RT = RT_new
    
    %% Generar un reporte de trials únicos encontrados
    unique_trials = unique(trials.trial_id);
    expected_trials = 1:max(unique_trials);  % Lista de trials esperados
    missing_trials = setdiff(expected_trials, unique_trials);  % Trials faltantes

    % Guardar el reporte en un archivo .txt
    reporte_trials = fullfile(Ruta, 'Reporte_Trials.txt');
    fid = fopen(reporte_trials, 'w');
    fprintf(fid, 'Trials encontrados: %s\n', mat2str(unique_trials'));
    if ~isempty(missing_trials)
        fprintf(fid, 'Trials faltantes: %s\n', mat2str(missing_trials'));
    else
        fprintf(fid, 'No hay trials faltantes.\n');
    end
    fclose(fid);

    % Confirmación
    fprintf('Los datos han sido incorporados a LAN y el reporte de trials se guardó en "%s".\n', reporte_trials);
end