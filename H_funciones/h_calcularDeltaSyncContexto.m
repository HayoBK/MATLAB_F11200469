function [delta_promedio, delta_std, delta_max] = h_calcularDeltaSyncContexto(Ruta, archivo_sync, LAN, contexto)
    % calcularDeltaSyncContexto: Calcula el DELTA entre relojes MATLAB y Python-LSL
    % considerando el contexto (NI o RV) y validando la cantidad de instancias de cada label.
    %
    % Entradas:
    %   - Ruta: Ruta donde se encuentra el archivo 'export_for_MATLAB_Sync.csv'.
    %   - archivo_sync: Nombre del archivo CSV de sincronización.
    %   - LAN: Estructura LAN con eventos y latencias.
    %   - contexto: Contexto a analizar ('NI' o 'RV').
    %
    % Salidas:
    %   - delta_promedio: Diferencia promedio entre los relojes.
    %   - delta_std: Desviación estándar de las diferencias.
    %   - delta_max: Máxima diferencia entre las latencias (drift).

    % Verificar que el contexto sea válido
    if ~ismember(contexto, {'NI', 'RV'})
        error('El contexto debe ser "NI" o "RV".');
    end

    % Leer el archivo CSV de Python-LSL
    file_path = fullfile(Ruta, archivo_sync);
    if ~isfile(file_path)
        error('El archivo "%s" no se encuentra en la ruta "%s".', archivo_sync, Ruta);
    end
    data_LSL = readtable(file_path);

    % Verificar columnas en el archivo
    if ~all(ismember({'labelLSL', 'latencyLSL'}, data_LSL.Properties.VariableNames))
        error('El archivo debe contener las columnas "labelLSL" y "latencyLSL".');
    end

    % Extraer labels y latencias de Python-LSL
    labels_LSL = data_LSL.labelLSL;
    latencies_LSL = data_LSL.latencyLSL;  % En segundos

    % Extraer labels y latencias de MATLAB (LAN)
    if ~isfield(LAN, 'RT') || ~isfield(LAN.RT, 'label') || ~isfield(LAN.RT, 'latency')
        error('La estructura LAN no contiene eventos válidos en LAN.RT.label o LAN.RT.latency.');
    end
    labels_LAN = LAN.RT.label;  % Celda de strings
    latencies_LAN = LAN.RT.latency / 1000;  % Convertir milisegundos a segundos

    % Validar que cada label aparece exactamente dos veces
    unique_labels = unique(labels_LAN);
    valid_indices = [];  % Para almacenar los índices de los labels válidos
    for i = 1:length(unique_labels)
        current_label = unique_labels{i};
        indices = find(strcmp(labels_LAN, current_label));
        if length(indices) == 2
            if strcmp(contexto, 'NI')
                valid_indices = [valid_indices; indices(1)];  % Primera instancia para NI
            elseif strcmp(contexto, 'RV')
                valid_indices = [valid_indices; indices(2)];  % Segunda instancia para RV
            end
        end
    end

    % Filtrar los labels y latencias válidos
    labels_LAN = labels_LAN(valid_indices);
    latencies_LAN = latencies_LAN(valid_indices);

    % Mapear equivalencias entre labels (e.g., S101 -> 1, S110 -> 10, etc.)
    equivalencias = containers.Map({'S101', 'S110', 'S120', 'S130'}, [1, 10, 20, 30]);

    % Encontrar las parejas comunes entre LSL y LAN
    deltas = [];
    for i = 1:length(labels_LAN)
        if equivalencias.isKey(labels_LAN{i})
            label_LSL_equivalente = equivalencias(labels_LAN{i});
            idx_LSL = find(labels_LSL == label_LSL_equivalente, 1);

            % Si hay una correspondencia, calcular la diferencia de latencias
            if ~isempty(idx_LSL)
                delta = latencies_LAN(i) - latencies_LSL(idx_LSL);
                deltas = [deltas; delta];
            end
        end
    end

    % Calcular métricas de sincronización
    delta_promedio = mean(deltas);
    delta_std = std(deltas);
    delta_max = max(deltas) - min(deltas);  % Máxima diferencia entre deltas

    % Calcular tiempo transcurrido entre el primer y último evento
    tiempo_transcurrido_segundos = max(latencies_LAN) - min(latencies_LAN);
    tiempo_transcurrido_minutos = tiempo_transcurrido_segundos / 60;

    % Calcular drift acumulado y porcentaje
    drift_acumulado = delta_max * 1000;  % En milisegundos
    drift_porcentaje = (drift_acumulado / (tiempo_transcurrido_segundos * 1000)) * 100;

    % Mostrar los resultados
    fprintf('Sincronización calculada para el contexto "%s":\n', contexto);
    fprintf('- Delta promedio: %.6f segundos\n', delta_promedio);
    fprintf('- Desviación estándar: %.6f segundos\n', delta_std);
    fprintf('- Máxima diferencia entre deltas: %.6f segundos\n', delta_max);
    fprintf('- Tiempo transcurrido: %.3f segundos (%.2f minutos)\n', tiempo_transcurrido_segundos, tiempo_transcurrido_minutos);
    fprintf('- Drift acumulado: %.6f ms (%.6f%% del tiempo transcurrido)\n', drift_acumulado, drift_porcentaje);
end