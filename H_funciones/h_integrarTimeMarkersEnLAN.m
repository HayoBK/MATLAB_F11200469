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
    trials.start_corrected = trials.start_time + delta_promedio;  % Inicio corregido
    trials.end_corrected = trials.end_time + delta_promedio;      % Fin corregido
    trials.duration = trials.end_corrected - trials.start_corrected;  % Duración

    % Para fijaciones (con inicio y duración)
    fijaciones.start_corrected = fijaciones.start_time + delta_promedio;  % Inicio corregido
    fijaciones.end_corrected = fijaciones.start_corrected + fijaciones.duration;  % Fin calculado

    % Para blinks (con inicio y duración)
    blinks.start_corrected = blinks.start_time + delta_promedio;  % Inicio corregido
    blinks.end_corrected = blinks.start_corrected + blinks.duration;  % Fin calculado

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

    if LAN.srate ~= srate_deseada
        % Calcular los factores de remuestreo
        [p, q] = rat(srate_deseada / LAN.srate);
        % Remuestrear los datos de LAN
        LAN.data = resample(LAN.data', p, q)';
        % Actualizar la tasa de muestreo en LAN
        LAN.srate = srate_deseada;
    end

    %% Incorporar los datos corregidos a LAN
    % Inicializar o limpiar la estructura LAN.RT
    RT = struct('label', {{}}, 'latency', [], 'dur', []);
    
    % Función auxiliar para agregar eventos a LAN.RT
    function agregar_eventos(eventos, etiqueta)
        for i = 1:height(eventos)
            RT.label{end+1} = etiqueta;
            RT.latency(end+1) = eventos.start_corrected(i) * LAN.srate;  % Convertir a muestras
            RT.dur(end+1) = (eventos.end_corrected(i) - eventos.start_corrected(i)) * LAN.srate;  % Duración en muestras
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
    
    % Paso 1: Convertir la estructura RT en una tabla
    RT_table = struct2table(RT);

    % Paso 2: Ordenar la tabla por la columna 'latency'
    RT_table = sortrows(RT_table, 'latency');

    % Paso 3: Convertir la tabla ordenada de nuevo en una estructura
    RT = table2struct(RT_table);

    %Ahora modificamos LAN original
    cfg             = [];
    cfg.type        = 'RT';
    cfg.RT          = LAN.RT;
    cfg.est         = [RT.label];
    cfg.laten       = [RT.latency];
    cfg.resp        = [RT.dur];
    cfg.rw          = [1] ;      %   (ms)
    RT_new = rt_read(cfg);
    LAN.RT = RT.new
    
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
