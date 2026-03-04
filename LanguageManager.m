classdef LanguageManager < handle
    % LANGUAGEMANAGER 
    
    properties (SetAccess = private)
        CurrentLanguage     % current language
        LanguageMap         %  Language key-value pair container
        SupportedLanguages  % Supported languages list
    end
    
    properties (Constant, Access = private)
        LanguageDir = 'languages'  % Language files directory
    end
    
    methods
        function obj = LanguageManager(defaultLanguage)
            % construction function
            % defaultLanguage - Default language code, e.g., 'chinese', 'english'
            
            % Initialize supported languages
            obj.SupportedLanguages = {'chinese', 'english', 'japanese', 'korean'};
            
            % Set default language
            if nargin < 1
                defaultLanguage = 'english';
            end
            obj.CurrentLanguage = defaultLanguage;
            
            % Initialize language mapping
            obj.LanguageMap = containers.Map();
            
            % Load default language
            obj.loadLanguage(defaultLanguage);
        end
        
        function success = loadLanguage(obj, languageCode)
            %  Load specified language
            % languageCode 
            
            success = false;
            
            % Check if language is supported
            if ~ismember(languageCode, obj.SupportedLanguages)
                warning('Language %s is not supported.', languageCode);
                return;
            end
            
            %  Build file path
            % filename = fullfile(obj.LanguageDir, [languageCode '.properties']);
            filename =  [languageCode '.properties'];
            % Check if file exists
            if ~exist(filename, 'file')
                warning('Language file not found: %s', filename);
                return;
            end
            
            try
                % Read and parse properties file
                newMap = obj.parsePropertiesFile(filename);
                
                % Update current language map
                obj.LanguageMap = newMap;
                obj.CurrentLanguage = languageCode;
                
                success = true;
                
                fprintf('Language loaded successfully: %s\n', languageCode);
                
            catch ME
                warning('Failed to load language file: %s', ME.message);
            end
        end
        
        function text = getText(obj, key, varargin)
            % Get text
            % key - Text key
            % varargin - Formatting parameters
            
            if obj.LanguageMap.isKey(key)
                text = obj.LanguageMap(key);
                
                % Text formatting (supports placeholders like %s)
                if ~isempty(varargin)
                    try
                        text = sprintf(text, varargin{:});
                    catch
                        % If formatting fails, return the original text
                    end
                end
            else
                % If the key is not found, return the key itself
                text = key;
                warning('Text key not found: %s', key);
            end
        end
        
        function success = reloadCurrentLanguage(obj)
            % Reload the current language
            success = obj.loadLanguage(obj.CurrentLanguage);
        end
        
        function langList = getAvailableLanguages(obj)
            % Get the list of available languages
            langList = {};
            
            % Check if the language directory exists
            if ~exist(obj.LanguageDir, 'dir')
                return;
            end
            
            % Get all properties files in the directory
            files = dir(fullfile(obj.LanguageDir, '*.properties'));
            
            for i = 1:length(files)
                [~, name, ~] = fileparts(files(i).name);
                langList{end+1} = name; %#ok<AGROW>
            end
        end
        
        function printAllText(obj)
            % Print all text key-value pairs (for debugging)
            fprintf('\n=== Language: %s ===\n', obj.CurrentLanguage);
            keys = obj.LanguageMap.keys();
            for i = 1:length(keys)
                fprintf('%s = %s\n', keys{i}, obj.LanguageMap(keys{i}));
            end
        end
    end
    
    methods (Access = private)
        function propMap = parsePropertiesFile(obj, filename)
            % Parse the properties file
            % filename - 文件路径
            
            propMap = containers.Map();
            
            % Open file (read Chinese using UTF-8 encoding)
            fid = fopen(filename, 'r', 'n', 'UTF-8');
            if fid == -1
                error('Unable to open file: %s', filename);
            end
            
            lineNumber = 0;
            
            try
                while ~feof(fid)
                    line = fgetl(fid);
                    lineNumber = lineNumber + 1;
                    
                    % Trim/Remove whitespace characters
                    line = strtrim(line);
                    
                    % Skip empty lines and comments
                    if isempty(line) || line(1) == '#' || line(1) == '!'
                        continue;
                    end
                    
                    % Split key-value pairs
                    eqPos = strfind(line, '=');
                    if isempty(eqPos)
                        warning('第 %d 行格式无效: %s', lineNumber, line);
                        continue;
                    end
                    
                    % Extract keys and values
                    key = strtrim(line(1:eqPos(1)-1));
                    value = strtrim(line(eqPos(1)+1:end));
                    
                    % Handle escape characters
                    value = obj.unescapeString(value);
                    
                    % Add to map
                    if ~isempty(key)
                        propMap(key) = value;
                    end
                end
                
                fclose(fid);
                
            catch ME
                fclose(fid);
                rethrow(ME);
            end
        end
        
        function str = unescapeString(~, str)
            % Handle escape characters
            % support \n, \t, \\, \uXXXX (Unicode)
            
            % Handle Unicode escape sequences（\uXXXX）
            unicodePattern = '\\u([0-9a-fA-F]{4})';
            matches = regexp(str, unicodePattern, 'tokens');
            
            for i = 1:length(matches)
                unicodeHex = matches{i}{1};
                unicodeChar = char(hex2dec(unicodeHex));
                str = strrep(str, ['\u' unicodeHex], unicodeChar);
            end
            
            % Handle other escape characters
            replacements = {
                '\\n', char(10);   % Line break / Newline
                '\\t', char(9);    % Tab / Tab character
                '\\\\', '\';       % Backslash
                '\\"', '"';        % Double quotes
                '\\''', '''';      % Single quotes
            };
            
            for i = 1:size(replacements, 1)
                str = strrep(str, replacements{i,1}, replacements{i,2});
            end
        end
    end
end