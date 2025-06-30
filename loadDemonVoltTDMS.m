function [data, commandVoltage, properties] = loadDemonVoltTDMS(filename)
%loadDemonVoltTDMS Loads electrochemistry data from a TDMS file.
%   [data, commandVoltage, properties] = loadDemonVoltTDMS(filename) reads
%   electrochemical data (voltammograms, command voltage, and properties)
%   from a specified .tdms file. This function relies on the 'TDMS Reader'
%   package by Jim Hokanson, available on MATLAB Central File Exchange.
%
%   Inputs:
%     filename - A string containing the full path and name of the .tdms
%                file to be loaded.
%
%   Outputs:
%     data - A matrix containing the acquired current data (voltammograms).
%            Each column represents a single voltammogram.
%     commandVoltage - A vector containing the applied command voltage
%                      for the voltammograms.
%     properties - A structure containing various properties and metadata
%                  extracted from the TDMS file.
%
%   Dependencies:
%     This function requires the 'TDMS Reader' package by Jim Hokanson.
%     Download from: https://www.mathworks.com/matlabcentral/fileexchange/30023-tdms-reader
%
%   Citation for TDMS Reader:
%     Jim Hokanson (2025). TDMS Reader (https://www.mathworks.com/matlabcentral/fileexchange/30023-tdms-reader),
%     MATLAB Central File Exchange. Retrieved June 12, 2025.


% Read the .tdms file using TDMS_getStruct from the TDMS Reader package: https://www.mathworks.com/matlabcentral/fileexchange/30023-tdms-reader
fileContents = TDMS_getStruct(filename,4);

%% combine voltammograms
dataFields = fields(fileContents.Data1);
voltammogramFields = dataFields(startsWith(dataFields,'c_'));
voltammogramNumber = cellfun(@str2num, erase(voltammogramFields,'c_'));
% sort in order if not already
[~,sortIndex]=sort(voltammogramNumber);
voltammogramFields = voltammogramFields(sortIndex);

voltammograms = [];
for fieldName = voltammogramFields'
    fieldValue = fileContents.Data1.(fieldName{1}).data;
    voltammograms = [voltammograms; fieldValue];
    clearvars fieldValue
end

%% Get additional information to return
commandVoltage = fileContents.Command_Voltage.Channel1.data; % command voltage data
properties = fileContents.Props; % other properties and metadata from the file

%% Convert 16-bit integer values into measured values
% get scaling coefficients
scalingCoefficients = fileContents.Scaling_Coefficients.Untitled.data;
gains = [properties.Current_Gain__nA_V_, properties.Current_Gain__nA_V__E2, ...
    properties.Current_Gain__nA_V__E3, properties.Current_Gain__nA_V__E4];

% convert 16-bit int to double
voltammograms = double(voltammograms);

% apply polynomial scaling
data = scalingCoefficients(1)*gains(1)+...
    scalingCoefficients(2)*gains(2)*voltammograms + ...
    scalingCoefficients(3)*gains(3)*(voltammograms.^2) + ...
    scalingCoefficients(4)*gains(4)*(voltammograms.^3);

end