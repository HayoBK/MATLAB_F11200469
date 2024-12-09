% Script para Utilidades de Rutas
% ----------------------------------------
%  Nombre_HomePath deberia poder llegar al directorio de '00-CurrentResearch', '001-FONDECYT_11200469'
%  y agregar un directorio mi path a la ruta. 
% ----------------------------------------


function ruta = Nombrar_HomePath(mi_path)
    % Nombrar_HomePath: Define una ruta base en función del equipo en uso
    % Entrada:
    %   - mi_path: Ruta relativa adicional desde la carpeta base
    % Salida:
    %   - ruta: Ruta completa resultante

    % Mostrar información del proceso
    disp('Proceso de Nombrar_HomePath: Identificando en qué computador estamos...');

    % Obtener el nombre del host
    nombre_host = getenv('COMPUTERNAME');  % Función para obtener el nombre del equipo
    disp(['Estamos en: ', nombre_host]);

    % Definir ruta base según el equipo
    if strcmp(nombre_host, 'DESKTOP-PQ9KP6K')
        home = 'D:/Mumin_UCh_OneDrive';
    elseif strcmp(nombre_host, 'MSI')
        home = 'D:/Titan-OneDrive';
    else
        error('El computador no está configurado. Por favor, agrega un caso para este equipo.');
    end

    % Construir la ruta completa
    ruta = fullfile(home, 'OneDrive', '2-Casper', '00-CurrentResearch', '001-FONDECYT_11200469', mi_path);
    disp(['Definimos una Ruta dirigiéndonos a: ', ruta]);
    disp('--------------- CHECK -------------');
    disp(' '); % Espaciado para legibilidad
end
