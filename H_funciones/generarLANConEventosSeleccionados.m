function LAN_filtered = generarLANConEventosSeleccionados(LAN, eventos_seleccionados)
    % generarLANConEventosSeleccionadosDirectos: Filtra un archivo LAN para incluir solo
    % los eventos seleccionados, dados directamente como strings.
    %
    % Entrada:
    %   - LAN: Estructura LAN original.
    %   - eventos_seleccionados: Lista de eventos seleccionados (e.g., {'S101', 'S110'}).
    %
    % Salida:
    %   - LAN_filtered: Nueva estructura LAN con los eventos seleccionados.

    % Verificar si LAN tiene eventos
    if ~isfield(LAN, 'RT') || ~isfield(LAN.RT, 'label') || ~isfield(LAN.RT, 'latency')
        error('La estructura LAN no contiene eventos válidos.');
    end

    % Extraer los labels existentes
    labels = LAN.RT.label;  % Celda con los nombres de los eventos

    % Identificar índices de los eventos seleccionados
    indices_seleccionados = ismember(labels, eventos_seleccionados);

    % Filtrar los eventos
    LAN_filtered = LAN;  % Crear una copia de la estructura original
    LAN_filtered.RT.label = LAN.RT.label(indices_seleccionados);  % Filtrar labels
    LAN_filtered.RT.latency = LAN.RT.latency(indices_seleccionados);  % Filtrar latencias

    % Confirmar el filtrado
    fprintf('Se seleccionaron %d eventos de un total de %d.\n', ...
        sum(indices_seleccionados), length(labels));

    % (Opcional) Mostrar los eventos seleccionados
    disp('Eventos seleccionados:');
    disp(LAN_filtered.RT.label);
end
