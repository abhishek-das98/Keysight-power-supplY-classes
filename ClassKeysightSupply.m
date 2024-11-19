classdef (Sealed) ClassKeysightSupply < handle


    properties (Dependent = true)

        MaxVoltage_SinglePowerSupply
        MaxVoltage_TriplePowerSupply
        VoltageResolution

    end
    properties (Access = private)

        PossibleNames = {'SinglePowerSupply', 'TriplePowerSupply'}
        viRscNameSingle = 'USB0::10893::5634::MY61002609::0::INSTR'; % Power Supply USB Address, Readable from the instrument itself
        viRscNameTriple = 'USB0::10893::4354::MY61007414::0::INSTR'
        InstrObj
        CurrentSupplyName

        MaxVoltage_SinglePowerSupply_Private
        MaxVoltage_TriplePowerSupply_Private

        VoltageResolutionPrivate = 0.01;
        UploadTimeOut = 20;
    end

    methods (Access = private)

        function obj = ClassKeysightSupply()
        end
    end


    methods(Static)

        function obj = getInstance(SupplyName)
            persistent localObj
            if isempty(localObj) || ~isvalid(localObj)
                localObj = ClassKeysightSupply;
            end
            obj = localObj;
        end
    end

    methods

        % Connect to the power supply
        function connect(obj, SupplyName)

            obj.CurrentSupplyName = SupplyName;
            viRscName = obj.selectResource(SupplyName); % The function selectResource is defined below, at the end of the code

            % Check if InstrObj is already connected to prevent reconnection
            if isempty(obj.InstrObj) || ~isvalid(obj.InstrObj)
                % Create a VISA object with the appropriate vendor and resource
                obj.InstrObj = visa('keysight', viRscName);
                obj.InstrObj.Timeout = obj.UploadTimeOut;
            else
                error('Failed to open: %s. The instrument is already connected.', viRscName);
            end

            % Try to open the connection
            try
                fopen(obj.InstrObj);  % Open the VISA connection

                % Verify the connection by querying the instrument ID
                fprintf(obj.InstrObj, '*IDN?');  % Send ID query
                idn = fscanf(obj.InstrObj);      % Read the response
                fprintf('Connected to: %s\n', idn);  % Display the instrument ID

            catch ME
                % If connection fails, display the error message
                error('Failed to connect to the instrument: %s', ME.message);
            end
        end



        function disconnect(obj) % function to disconnect the instrument

            try

                if ~isempty(obj.InstrObj) && strcmp(obj.InstrObj.Status, 'open')

                    fclose(obj.InstrObj);
                    delete(obj.InstrObj);
                    obj.InstrObj = [];
                    fprintf('Connection closed\n');
                else
                    fprintf('No active conenction found to close. \n')

                end

            catch ME

                error('Failed to disconnect from the instrument: %s', ME.message);

            end

        end

    end

    methods

        function MaxVoltage_SinglePowerSupply = get.MaxVoltage_SinglePowerSupply(obj) % function to set the Maximum voltage of the instrument
            MaxVoltage_SinglePowerSupply = obj.MaxVoltage_SinglePowerSupply_Private;
        end

        function MaxVoltage_TriplePowerSupply = get.MaxVoltage_TriplePowerSupply(obj) % function to set the Maximum voltage of the instrument
            MaxVoltage_TriplePowerSupply = obj.MaxVoltage_TriplePowerSupply_Private;
        end

        function VoltageResolution=get.VoltageResolution(obj) % function to set the voltage resolution of the instrument
            VoltageResolution=obj.VoltageResolutionPrivate;
        end

        function setVoltage(obj, voltage, channel)
            try
                if isempty(obj.InstrObj) || ~strcmp(obj.InstrObj.Status, 'open')
                    error('The connection to the power supply is not open.');
                end

                % Construct the command with the "set" command type
                cmd = obj.constructCommand('VOLT', voltage, channel, 'set');
                fprintf(obj.InstrObj, cmd);  % Send the command

                if strcmp(obj.CurrentSupplyName, 'TriplePowerSupply')
                    fprintf('[%s] Voltage set to %.2f V on Channel %d\n', obj.CurrentSupplyName, voltage, channel);
                else
                    fprintf('[%s] Voltage set to %.2f V\n', obj.CurrentSupplyName, voltage);
                end
            catch ME
                error('Failed to set the voltage: %s', ME.message);
            end
        end



        function setCurrent(obj, current, channel)
            try
                if isempty(obj.InstrObj) || ~strcmp(obj.InstrObj.Status, 'open')
                    error('The connection to the power supply is not open.');
                end

                % Construct the command with the "set" command type
                cmd = obj.constructCommand('CURR', current, channel, 'set');
                fprintf(obj.InstrObj, cmd);  % Send the command

                if strcmp(obj.CurrentSupplyName, 'TriplePowerSupply')
                    fprintf('[%s] Current set to %.2f A on Channel %d\n', obj.CurrentSupplyName, current, channel);
                else
                    fprintf('[%s] Current set to %.2f A\n', obj.CurrentSupplyName, current);
                end
            catch ME
                error('Failed to set the current: %s', ME.message);
            end
        end




        function readVoltage(obj, channel)
            try
                if isempty(obj.InstrObj) || ~strcmp(obj.InstrObj.Status, 'open')
                    error('The connection to the power supply is not open.');
                end

                % Construct the command with the "read" command type
                cmd = obj.constructCommand('MEAS:VOLT?', [], channel, 'read');
                fprintf(obj.InstrObj, cmd);  % Send the command

                voltageStr = fscanf(obj.InstrObj);
                voltage = str2double(voltageStr);

                if strcmp(obj.CurrentSupplyName, 'TriplePowerSupply')
                    fprintf('[%s] Voltage on Channel %d: %.2f V\n', obj.CurrentSupplyName, channel, voltage);
                else
                    fprintf('[%s] Voltage: %.2f V\n', obj.CurrentSupplyName, voltage);
                end
            catch ME
                error('Failed to read the voltage: %s', ME.message);
            end
        end


        function readCurrent(obj, channel)
            try
                if isempty(obj.InstrObj) || ~strcmp(obj.InstrObj.Status, 'open')
                    error('The connection to the power supply is not open.');
                end

                % Construct the command with the "read" command type
                cmd = obj.constructCommand('MEAS:CURR?', [], channel, 'read');
                fprintf(obj.InstrObj, cmd);  % Send the command

                currentStr = fscanf(obj.InstrObj);
                current = str2double(currentStr);

                if strcmp(obj.CurrentSupplyName, 'TriplePowerSupply')
                    fprintf('[%s] Current on Channel %d: %.2f A\n', obj.CurrentSupplyName, channel, current);
                else
                    fprintf('[%s] Current: %.2f A\n', obj.CurrentSupplyName, current);
                end
            catch ME
                error('Failed to read the current: %s', ME.message);
            end
        end


        function powerOn(obj, channel)
            try
                if isempty(obj.InstrObj) || ~strcmp(obj.InstrObj.Status, 'open')
                    error('The connection to the power supply is not open.');
                end

                % Construct the command with the "power" command type
                cmd = obj.constructCommand('OUTP ON', [], channel, 'power');
                fprintf(obj.InstrObj, cmd);  % Send the command

                if strcmp(obj.CurrentSupplyName, 'TriplePowerSupply')
                    fprintf('[%s] Power turned ON for Channel %d\n', obj.CurrentSupplyName, channel);
                else
                    fprintf('[%s] Power turned ON\n', obj.CurrentSupplyName);
                end
            catch ME
                error('Failed to power on: %s', ME.message);
            end
        end



        function powerOff(obj, channel)
            try
                if isempty(obj.InstrObj) || ~strcmp(obj.InstrObj.Status, 'open')
                    error('The connection to the power supply is not open.');
                end

                % Construct the command with the "power" command type
                cmd = obj.constructCommand('OUTP OFF', [], channel, 'power');
                fprintf(obj.InstrObj, cmd);  % Send the command

                if strcmp(obj.CurrentSupplyName, 'TriplePowerSupply')
                    fprintf('[%s] Power turned OFF for Channel %d\n', obj.CurrentSupplyName, channel);
                else
                    fprintf('[%s] Power turned OFF\n', obj.CurrentSupplyName);
                end
            catch ME
                error('Failed to power off: %s', ME.message);
            end
        end


        function cmd = constructCommand(obj, baseCmd, value, channel, commandType)
            % Helper function to construct SCPI commands with proper channel validation

            if nargin < 5
                error('Command type must be specified as "read", "power", or "set".');
            end

            % Validate channel number for TriplePowerSupply
            if strcmp(obj.CurrentSupplyName, 'TriplePowerSupply')
                if nargin >= 4 && (~ismember(channel, [1, 2, 3]) || isempty(channel))
                    error('Invalid channel number. Valid channels are 1, 2, or 3.');
                end
            end

            switch commandType
                case 'read'
                    if strcmp(obj.CurrentSupplyName, 'SinglePowerSupply')
                        cmd = baseCmd;  % Example: "MEAS:VOLT?"
                    else
                        cmd = sprintf('%s (@%d)', baseCmd, channel);  % Example: "MEAS:VOLT? (@2)"
                    end

                case 'set'
                    if strcmp(obj.CurrentSupplyName, 'SinglePowerSupply')
                        cmd = sprintf('%s %.2f', baseCmd, value);  % Example: "VOLT 5.00"
                    else
                        cmd = sprintf('%s %.2f, (@%d)', baseCmd, value, channel);  % Example: "VOLT 12.00, (@2)"
                    end

                case 'power'
                    if strcmp(obj.CurrentSupplyName, 'SinglePowerSupply')
                        cmd = sprintf('%s', baseCmd);  % Example: "OUTP ON"
                    else
                        cmd = sprintf('%s, (@%d)', baseCmd, channel);  % Example: "OUTP ON, (@2)"
                    end

                otherwise
                    error('Invalid command type. Use "read", "power", or "set".');
            end
        end





        function rscName = selectResource(obj, SupplyName)
            % Function to select the appropriate resource string based on the supply name

            % Define valid supply names
            validNames = obj.PossibleNames;

            % Check if the provided supply name is valid
            if ~ismember(SupplyName, validNames)
                % Construct the error message with valid supply names
                errorMessage = sprintf('Invalid power supply name. Valid names are: %s', ...
                    strjoin(validNames, ', '));  % Adds comma and space between names
                error(errorMessage);  % Trigger the error with the complete message
            end

            % Select the appropriate resource string based on the valid supply name
            switch SupplyName
                case 'SinglePowerSupply'
                    rscName = obj.viRscNameSingle;
                case 'TriplePowerSupply'
                    rscName = obj.viRscNameTriple;
                otherwise
                    error('Unknown power supply name.');
            end
        end


    end

end





