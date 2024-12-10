function listarEventosUnicos(LAN)
    % listarEventosUnicos: Lista los eventos únicos en LAN.RT.label
    % Entrada:
    %   LAN - Estructura LAN que contiene los datos EEG y eventos
    %
    % Salida:
    %   Lista en la ventana de comandos de eventos únicos, sus etiquetas y
    %   el número de ocurrencias.

    % Verifica si existen eventos en LAN
    if isfield(LAN, 'RT') && isfield(LAN.RT, 'label') && ~isempty(LAN.RT.label)
        % Obtener todos los labels de eventos
        all_labels = LAN.RT.label;  % Debe ser una celda de strings
        
        % Encontrar labels únicos
        [unique_labels, ~, indices] = unique(all_labels);
        
        % Mostrar el listado único con conteo de ocurrencias
        disp('Listado de eventos únicos y su cantidad:');
        for i = 1:length(unique_labels)
            fprintf('Evento: %s - Cantidad: %d\n', unique_labels{i}, sum(indices == i));
        end
    else
        disp('No se encontraron eventos en LAN.RT.label.');
    end
end