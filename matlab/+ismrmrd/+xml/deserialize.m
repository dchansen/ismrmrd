function [header] = deserialize(xmlstring)
%DESERIALIZE Summary of this function goes here
%   Detailed explanation goes here

    % Get a parser
    db = javax.xml.parsers.DocumentBuilderFactory.newInstance().newDocumentBuilder();

    % Turn the string into a stream
    isrc = org.xml.sax.InputSource();
    isrc.setCharacterStream(java.io.StringReader(xmlstring))

    % Parse it
    dom = db.parse(isrc);

    % Get the root element
    rootNode = dom.getDocumentElement();

    % Fill it
    header = parseNode(rootNode);

end

% ----- Subfunction parseChild -----
function info = parseNode(theNode)

% Walk down the tree
childNodes = getChildNodes(theNode);
numChildNodes = getLength(childNodes);

info = struct;

for n = 1:numChildNodes
    theChild = item(childNodes,n-1);
    name = char(getNodeName(theChild));

    %Some elements occur more than once
    if isfield(info,name)
        num = length(info.(name))+1;
    else
        num = 1;
    end

    if strcmp(name, 'encoding')
        if num == 1
            info.encoding = struct('encodedSpace',struct,'reconSpace',struct, ...
                'encodingLimits', struct, 'trajectory', '', ...
                'trajectoryDescription', struct,  ...
                'parallelImaging', struct, 'echoTrainLength', []);
        end
        temp = parseNode(theChild);
        fnames = fieldnames(temp);
        for f = 1:length(fnames)
            info.encoding(num).(fnames{f}) = temp.(fnames{f});
        end
        continue;
    end
    
    % kspace_encoding_step_1/2 can be either part of the acceleration
    % factor or part of the encoding limits.
    if (strcmp(name, 'kspace_encoding_step_1') || strcmp(name, 'kspace_encoding_step_2'))
        if strcmp(char(theChild.getParentNode.getNodeName),'encodingLimits') 
            info.(name) = parseNode(theChild);
        else
            info.(name) = str2num(getTextContent(theChild));
        end
        continue;
    end
        
    if isCompoundType(name)        
        if num == 1
            info.(name) = parseNode(theChild);
        else
            info.(name)(num) = parseNode(theChild);
        end
        continue;
    end

    if isUserParameterType(name)
        if num == 1
            info.(name) = parseUserParameter(theChild);
        else
            info.(name)(num) = parseUserParameter(theChild);
        end
        continue;
    end

    if isStringType(name)
        if num == 1
            info.(name) = char(getTextContent(theChild));
        else
            info.(name)(num) = char(getTextContent(theChild));
        end
        continue;
    end

    if isNumericalType(name)
        if num == 1
            info.(name) = str2num(getTextContent(theChild));
        else
            info.(name)(num) = str2num(getTextContent(theChild));
        end
        continue;
    end

    if isDateType(name)
        if num == 1
            info.(name) = char(getTextContent(theChild));
        else
            info.(name)(num) = char(getTextContent(theChild));
        end
        continue;
    end

end

end

%%%%%%%%%%%%%%%%%%%
function info = parseUserParameter(theNode)

    paramType = char(getNodeName(theNode));
    childNodes = getChildNodes(theNode);
    numChildNodes = getLength(childNodes);
    
    info = struct;
    info.value = [];
    
    for n = 1:numChildNodes
        theChild = item(childNodes,n-1);
        if strcmp(getNodeName(theChild),'name')
            info.name = char(getTextContent(theChild));
        end
        if strcmp(getNodeName(theChild),'value')
            if strcmp(paramType, 'userParameterLong') || strcmp(paramType, 'userParameterDouble')
                info.value(end+1) = str2num(getTextContent(theChild));
            end

            if strcmp(paramType, 'userParameterString') || strcmp(paramType, 'userParameterBase64')
                info.value = char(getTextContent(theChild));
            end
        end
    end
end

% ----- Type specific functions ----
function status = isCompoundType(name)

    % treat encoding separately
    headerNodeNames = { ...
        'subjectInformation', ...
        'studyInformation', ...
        'measurementInformation', ...
        'acquisitionSystemInformation', ...
        'experimentalConditions', ...
        'coilLabel', ...
        'encoding', ...
        'sequenceParameters', ...
        'userParameters', ...
        'measurementDependency', ...
        'referencedImageSequence', ...
        'encodedSpace', ...
        'reconSpace', ...
        'encodingLimits', ...
        'trajectoryDescription', ...
        'parallelImaging', ...
        'accelerationFactor', ...
        'matrixSize', ...
        'fieldOfView_mm', ...
        'kspace_encoding_step_0', ...
        'kspace_encoding_step_1', ...
        'kspace_encoding_step_2', ...
        'average', ...
        'slice', ...
        'contrast', ...
        'phase', ...
        'repetition', ...
        'set', ...
        'segment', ...
        'waveformInformation'
     };
    
    status = ismember(name, headerNodeNames);
end

function status = isNumericalType(name)
    headerNumericalTypes = { ...
      'version', ...
      'patientWeight', ...
      'accessionNumber', ...
      'initialSeriesNumber', ...
      'systemFieldStrength_T', ...
      'relativeReceiverNoiseBandwidth', ...
      'receiverChannels', 'coilNumber', ...
      'H1resonanceFrequency_Hz', ...
      'TR', ...
      'TE', ...
      'TI', ...
      'flipAngle_deg', ...
      'sequence_type', ...
      'echo_spacing', ...
      'echoTrainLength', ...
      'x', 'y', 'z', ...
      'minimum', 'maximum', 'center'};
  
    status = ismember(name, headerNumericalTypes);
end

function status = isStringType(name)
    headerStringTypes = {...
      'patientName', ...
      'patientID', ...
      'patientGender', ...
      'studyID', ...
      'referringPhysicianName', ...
      'studyDescription', ...
      'studyInstanceUID', ...
      'measurementID', ...
      'patientPosition', ...
      'protocolName', ...
      'seriesDescription', ...
      'seriesInstanceUIDRoot', ...
      'frameOfReferenceUID', ...
      'referencedSOPInstanceUID', ...
      'dependencyType', ...
      'measurementID', ...
      'systemVendor', ...
      'systemModel', ...
      'institutionName', ...
      'stationName', ...
      'trajectory', ...
      'identifier', ...
      'coilName', ...
      'calibrationMode',...
      'interleavingDimension',...
      'sequence_type',...
      'waveformName',...
      'waveformType'
    };

      status = ismember(name, headerStringTypes);
end

function status = isDateType(name)
    headerDateTypes = {...
      'patientBirthdate', ...
      'studyDate', ...
      'studyTime', ...
      'seriesDate', ...
      'seriesTime'};
    status = ismember(name, headerDateTypes);
end

function status = isUserParameterType(name)
    typeNames =  { ...
        'userParameterLong', ...
        'userParameterDouble', ...
        'userParameterString', ....
        'userParameterBase64'};

    status = ismember(name, typeNames);
end
