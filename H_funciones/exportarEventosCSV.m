function exportarEventosCSV(LAN, nombreArchivo)
    % exportarEventosCSV: Exporta los eventos de LAN a un archivo .csv
    % Entrada:
    %   LAN - Estructura LAN que contiene los datos EEG y eventos.
    %   nombreArchivo - Nombre del archivo de salida (incluye .csv).
    %
    % Salida:
    %   Genera un archivo .csv con dos columnas: label y latencia.
    
    % Verifica que LAN tenga eventos
    if isfield(LAN, 'RT') && isfield(LAN.RT, 'label') && isfield(LAN.RT, 'latency') ...
            && ~isempty(LAN.RT.label) && ~isempty(LAN.RT.latency)
        
        % Extraer labels y latencias
        labels = LAN.RT.label;          % Celda de strings
        latencias = LAN.RT.latency;    % Latencias en samples (puntos de muestreo)

        % Convertir latencias de samples a segundos (opcional)
        % latencias = latencias / LAN.srate;

        % Preparar los datos para exportar
        datos = table(labels(:), latencias(:), 'VariableNames', {'Label', 'Latency'});

        % Escribir la tabla a un archivo .csv
        writetable(datos, nombreArchivo);
        
        fprintf('Archivo "%s" exportado correctamente.\n', nombreArchivo);
    else
        disp('LAN no contiene eventos con labels y/o latencias válidos.');
    end
end
