function LAN = importarEventosDesdeCSV(nombreArchivo, LAN, srate, latencias_en_samples)
    % importarEventosDesdeCSV: Importa eventos desde un archivo .csv a LAN.RT
    %
    % Entrada:
    %   nombreArchivo - Nombre del archivo .csv con los eventos.
    %   LAN - Estructura LAN a la que se añadirán los eventos.
    %   srate - Tasa de muestreo (Hz) para convertir latencias (si están en segundos).
    %   latencias_en_samples - true si las latencias ya están en samples (opcional).
    %
    % Salida:
    %   LAN - Estructura LAN actualizada con los eventos importados.
    
    if nargin < 4
        latencias_en_samples = false; % Asume que las latencias están en segundos
    end

    % Leer el archivo CSV
    datos = readtable(nombreArchivo);

    % Verificar que las columnas necesarias existan
    if ~ismember('Label', datos.Properties.VariableNames) || ...
       ~ismember('Latency', datos.Properties.VariableNames)
        error('El archivo CSV debe contener columnas "Label" y "Latency".');
    end

    % Convertir latencias a samples si es necesario
    latencias = datos.Latency;
    if ~latencias_en_samples
        latencias = latencias * srate;
    end

    % Crear el campo LAN.RT si no existe
    if ~isfield(LAN, 'RT')
        LAN.RT = struct('label', {}, 'latency', {});
    end

    % Asignar los datos al campo LAN.RT
    LAN.RT.label = datos.Label;       % Labels de los eventos
    LAN.RT.latency = latencias(:);    % Latencias en samples

    % Confirmar el proceso
    disp('Eventos importados correctamente a LAN.RT:');
    disp(table(datos.Label, latencias, 'VariableNames', {'Label', 'Latency'}));
end
