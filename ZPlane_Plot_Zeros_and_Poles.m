classdef ZPlaneAmplitude_Interface_II < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                   matlab.ui.Figure
        ClearallButton             matlab.ui.control.Button
        slidervalueLabel           matlab.ui.control.Label
        Slider                     matlab.ui.control.Slider
        ngulosradsSliderLabel      matlab.ui.control.Label
        Lineas_Fraccion            matlab.ui.control.Label
        Label_den                  matlab.ui.control.Label
        Label_num                  matlab.ui.control.Label
        UITable                    matlab.ui.control.Table
        labelFraccion              matlab.ui.control.Label
        labelDenominador           matlab.ui.control.Label
        labelNumerador             matlab.ui.control.Label
        IngresarButton             matlab.ui.control.Button
        DenominadorEditField       matlab.ui.control.EditField
        DenominadorEditFieldLabel  matlab.ui.control.Label
        NumeradorEditField         matlab.ui.control.EditField
        NumeradorEditFieldLabel    matlab.ui.control.Label
        UIAxes2                    matlab.ui.control.UIAxes
        UIAxes                     matlab.ui.control.UIAxes
    end

    
    properties (Access = private)
        H
        numerador
        denominador
        magnitudes
        magnitude
        angles
        z
        currentBall = [];
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: IngresarButton
        function IngresarButtonPushed(app, event)
       


            % Obtener el numerador y el denominador ingresados
            app.numerador = app.NumeradorEditField.Value;
            app.denominador = app.DenominadorEditField.Value;

            num_Z = str2num(app.numerador);   % convertir de string a número
            den_Z = str2num(app.denominador); % convertir de string a número
   
            ts = 0.1;  % periodo de muestreo
            H_z = tf(num_Z, den_Z, ts);  % control system toolbox tf, calcular la función de transferencia
            [poles, zeros] = pzmap(H_z);
            pzmap(app.UIAxes2, H_z);   % graficar con pzmap los ceros y polos del sistema ingresado
            % Modificar el estilo de los puntos (polos y ceros)
            

            % Obtener la expresión simbólica de la función de transferencia
            syms z % Definir el símbolo z
            [num, den] = tfdata(H_z, 'v'); % Obtener los coeficientes como arreglos
            tf_sym_num = poly2sym(num, z); 
            tf_sym_den = poly2sym(den, z); % Convertir los coeficientes a una expresión simbólica
            app.Label_num.Text = char(tf_sym_num);
            app.Label_den.Text = char(tf_sym_den);

            w = linspace(0, 2*pi, 2048); % Frecuencias de 0 a 2pi 
            [mag, ~] = freqz(num_Z, den_Z, w);  % obtener la magnitud de la repsuesta en frecuencia

            app.angles = 0 : pi/36 : 2*pi; % Define los ángulos de 0 a 2pi en incrementos de pi/36
            for index = 1:length(app.angles)
                app.z = exp(1i * app.angles(index)); % Calcula la posición en la circunferencia unitaria para el ángulo actual

                % Calcular la distancia de cada cero/polo a la circunferencia unitaria
                zero_distances = abs(zeros - app.z); 
                pole_distances = abs(poles - app.z); 
                
                % Operación con las distancias - obtener los productos
                zero_product = prod(zero_distances);
                pole_product = prod(pole_distances);
            
                % calculo de las magnitudes
                app.magnitude(index) = zero_product / pole_product;
                app.magnitudes(index) = zero_product / pole_product;             
                %fprintf('Ángulo: %.2f, Magnitud: %.4f\n', angles(index), magnitude(index));
                % Almacena los valores en la celda de datos
                data{index, 1} = app.angles(index);
                data{index, 2} = app.magnitudes(index);
            end

            plot(app.UIAxes, app.angles, app.magnitudes,'r','LineWidth',1.2);
            app.UITable.Data = data;

                    
        end

        % Value changing function: Slider
        function SliderValueChanging(app, event)
            sliderValue= event.Value;
            % Calcula el índice correspondiente al valor del slider
            index = round(sliderValue / (pi/36)) + 1;
            
            % Obtiene el vector x de 0 a 2pi en pasos de pi/6
            x = 0:pi/36:2*pi;
            % Actualiza la posición de la bolita en el gráfico
            mag_values = app.magnitudes; % Calcula sin(x)
            ball_x = x(index); % Posición x de la bolita
            ball_y = mag_values(index); % Posición y de la bolita

            %-----------------------------------------------------
            
            % Actualiza el gráfico en UIAxes
            plot(app.UIAxes, x, mag_values, 'b'); 
            
            hold(app.UIAxes, 'on');
            % Grafica la bolita roja en la posición correspondiente
            plot(app.UIAxes, ball_x, ball_y, 'ro', 'MarkerSize', 6, 'MarkerFaceColor', 'red'); % Graficar la bolita roja
            grid(app.UIAxes, 'on');
            hold(app.UIAxes, 'off');
            
            index2 = sliderValue;
            z_angle = exp(1i * index2);
            app.slidervalueLabel.Text = num2str(index2);
            
            % Verifica si la bolita ya ha sido graficada previamente
            if ~isempty(app.currentBall) && isvalid(app.currentBall)
                % Si existe, actualiza su posición
                set(app.currentBall, 'XData', real(z_angle), 'YData', imag(z_angle));
            else
                % Si no existe, grafica una bolita roja en la posición calculada por el slider en el círculo unitario
                hold(app.UIAxes2, 'on');
                app.currentBall = plot(app.UIAxes2, real(z_angle), imag(z_angle), 'ro', 'MarkerSize', 6, 'MarkerFaceColor', 'red');
                %grid(app.UIAxes2, 'on');
                %gridLines = findall(app.UIAxes2, 'Type', 'grid');
                %set(gridLines, 'Color', [0.1, 0.1, 0.1, 0.1]);
                hold(app.UIAxes2, 'off');
            end

        end

        % Button pushed function: ClearallButton
        function ClearallButtonPushed(app, event)
            % Limpiar el workspace
            evalin('base', 'clear all');
            
            % Cerrar todas las figuras
            close all;
            
            % Limpiar las gráficas en la app (si es necesario)
            % app.UIAxes es el nombre del componente de la gráfica en tu app
            cla(app.UIAxes, 'reset');
            cla(app.UIAxes2, 'reset')
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Color = [0.949 1 1];
            app.UIFigure.Position = [100 100 830 598];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.Resize = 'off';

            % Create UIAxes
            app.UIAxes = uiaxes(app.UIFigure);
            title(app.UIAxes, 'A(w)')
            xlabel(app.UIAxes, 'Frecuencia [rad/s]')
            ylabel(app.UIAxes, 'Amplitud')
            zlabel(app.UIAxes, 'Z')
            app.UIAxes.XLim = [0 6.28318530717959];
            app.UIAxes.XGrid = 'on';
            app.UIAxes.YGrid = 'on';
            app.UIAxes.FontSize = 9;
            app.UIAxes.Position = [279 26 510 236];

            % Create UIAxes2
            app.UIAxes2 = uiaxes(app.UIFigure);
            title(app.UIAxes2, 'Plano Z')
            xlabel(app.UIAxes2, 'Real ')
            ylabel(app.UIAxes2, 'Imaginario')
            zlabel(app.UIAxes2, 'Z')
            app.UIAxes2.XGrid = 'on';
            app.UIAxes2.YGrid = 'on';
            app.UIAxes2.FontSize = 9;
            app.UIAxes2.Position = [313 321 283 258];

            % Create NumeradorEditFieldLabel
            app.NumeradorEditFieldLabel = uilabel(app.UIFigure);
            app.NumeradorEditFieldLabel.HorizontalAlignment = 'right';
            app.NumeradorEditFieldLabel.FontWeight = 'bold';
            app.NumeradorEditFieldLabel.Position = [45 519 69 22];
            app.NumeradorEditFieldLabel.Text = 'Numerador';

            % Create NumeradorEditField
            app.NumeradorEditField = uieditfield(app.UIFigure, 'text');
            app.NumeradorEditField.Position = [129 519 100 22];

            % Create DenominadorEditFieldLabel
            app.DenominadorEditFieldLabel = uilabel(app.UIFigure);
            app.DenominadorEditFieldLabel.HorizontalAlignment = 'right';
            app.DenominadorEditFieldLabel.FontWeight = 'bold';
            app.DenominadorEditFieldLabel.Position = [32 488 82 22];
            app.DenominadorEditFieldLabel.Text = 'Denominador';

            % Create DenominadorEditField
            app.DenominadorEditField = uieditfield(app.UIFigure, 'text');
            app.DenominadorEditField.Position = [129 488 100 22];

            % Create IngresarButton
            app.IngresarButton = uibutton(app.UIFigure, 'push');
            app.IngresarButton.ButtonPushedFcn = createCallbackFcn(app, @IngresarButtonPushed, true);
            app.IngresarButton.BackgroundColor = [0 0 1];
            app.IngresarButton.FontWeight = 'bold';
            app.IngresarButton.FontColor = [1 1 1];
            app.IngresarButton.Position = [129 456 100 23];
            app.IngresarButton.Text = 'Ingresar';

            % Create labelNumerador
            app.labelNumerador = uilabel(app.UIFigure);
            app.labelNumerador.HorizontalAlignment = 'center';
            app.labelNumerador.FontName = 'Arial';
            app.labelNumerador.FontSize = 9;
            app.labelNumerador.FontWeight = 'bold';
            app.labelNumerador.Position = [251 509 147 22];
            app.labelNumerador.Text = '';

            % Create labelDenominador
            app.labelDenominador = uilabel(app.UIFigure);
            app.labelDenominador.HorizontalAlignment = 'center';
            app.labelDenominador.FontName = 'Arial';
            app.labelDenominador.FontSize = 9;
            app.labelDenominador.Position = [253 490 145 22];
            app.labelDenominador.Text = '';

            % Create labelFraccion
            app.labelFraccion = uilabel(app.UIFigure);
            app.labelFraccion.HorizontalAlignment = 'center';
            app.labelFraccion.VerticalAlignment = 'bottom';
            app.labelFraccion.FontWeight = 'bold';
            app.labelFraccion.Position = [253 504 147 22];
            app.labelFraccion.Text = '';

            % Create UITable
            app.UITable = uitable(app.UIFigure);
            app.UITable.ColumnName = {'Ángulo [rad]'; 'Magnitud A(w)'};
            app.UITable.RowName = {};
            app.UITable.Position = [44 26 209 358];

            % Create Label_num
            app.Label_num = uilabel(app.UIFigure);
            app.Label_num.HorizontalAlignment = 'center';
            app.Label_num.FontName = 'Corbel';
            app.Label_num.FontWeight = 'bold';
            app.Label_num.FontAngle = 'italic';
            app.Label_num.Position = [74 416 124 22];
            app.Label_num.Text = '---';

            % Create Label_den
            app.Label_den = uilabel(app.UIFigure);
            app.Label_den.HorizontalAlignment = 'center';
            app.Label_den.FontName = 'Corbel';
            app.Label_den.FontWeight = 'bold';
            app.Label_den.FontAngle = 'italic';
            app.Label_den.Position = [74 399 124 22];
            app.Label_den.Text = '---';

            % Create Lineas_Fraccion
            app.Lineas_Fraccion = uilabel(app.UIFigure);
            app.Lineas_Fraccion.HorizontalAlignment = 'center';
            app.Lineas_Fraccion.VerticalAlignment = 'bottom';
            app.Lineas_Fraccion.FontWeight = 'bold';
            app.Lineas_Fraccion.Position = [84 415 105 22];
            app.Lineas_Fraccion.Text = '_______________';

            % Create ngulosradsSliderLabel
            app.ngulosradsSliderLabel = uilabel(app.UIFigure);
            app.ngulosradsSliderLabel.HorizontalAlignment = 'right';
            app.ngulosradsSliderLabel.FontWeight = 'bold';
            app.ngulosradsSliderLabel.Position = [671 290 93 22];
            app.ngulosradsSliderLabel.Text = 'Ángulos [rad/s]';

            % Create Slider
            app.Slider = uislider(app.UIFigure);
            app.Slider.Limits = [0 6.28318530717959];
            app.Slider.Orientation = 'vertical';
            app.Slider.ValueChangingFcn = createCallbackFcn(app, @SliderValueChanging, true);
            app.Slider.Position = [700 331 3 239];

            % Create slidervalueLabel
            app.slidervalueLabel = uilabel(app.UIFigure);
            app.slidervalueLabel.HorizontalAlignment = 'center';
            app.slidervalueLabel.Position = [640 437 49 22];
            app.slidervalueLabel.Text = '0';

            % Create ClearallButton
            app.ClearallButton = uibutton(app.UIFigure, 'push');
            app.ClearallButton.ButtonPushedFcn = createCallbackFcn(app, @ClearallButtonPushed, true);
            app.ClearallButton.BackgroundColor = [1 0 0];
            app.ClearallButton.FontSize = 10;
            app.ClearallButton.FontWeight = 'bold';
            app.ClearallButton.FontColor = [1 1 1];
            app.ClearallButton.Position = [53 456 61 23];
            app.ClearallButton.Text = 'Clear all';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = ZPlaneAmplitude_Interface_II

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end