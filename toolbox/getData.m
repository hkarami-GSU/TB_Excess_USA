function data2=getData(cumulative1,cadtemporal,caddisease,datatype,cadregion,DT,datevecfirst1,datevecend1,date1,outbreak1,forecastingperiod)

if forecastingperiod==0
    data2=NaN;
else
    if cumulative1==1
        filename1=strcat('./input/cumulative-',cadtemporal,'-',caddisease,'-',datatype,'-',cadregion,'-',datestr(datenum(datevecend1),'mm-dd-yyyy'),'.txt');
    else
        filename1=strcat('./input/',cadtemporal,'-',caddisease,'-',datatype,'-',cadregion,'-',datestr(datenum(datevecend1),'mm-dd-yyyy'),'.txt');
    end

% Check if column specific file exists
    if ~exist(filename1, 'file')
        % Robust search using wildcard
        date_str = datestr(datenum(datevecend1),'mm-dd-yyyy');
        search_pattern = strcat('./input/*', date_str, '-col', num2str(outbreak1), '.txt');
        found_files = dir(search_pattern);
        
        if ~isempty(found_files)
            filename1 = strcat('./input/', found_files(1).name);
        else
            % Fallback to exact construction
            if cumulative1==1
                specific_filename = strcat('./input/cumulative-',cadtemporal,'-',caddisease,'-',datatype,'-',cadregion,'-',datestr(datenum(datevecend1),'mm-dd-yyyy'),'-col',num2str(outbreak1),'.txt');
            else
                specific_filename = strcat('./input/',cadtemporal,'-',caddisease,'-',datatype,'-',cadregion,'-',datestr(datenum(datevecend1),'mm-dd-yyyy'),'-col',num2str(outbreak1),'.txt');
            end
            
            if exist(specific_filename, 'file')
                filename1 = specific_filename;
            end
        end
    end

    data=load(filename1);

    dataprov=data';

    data1=dataprov(outbreak1,:)';

    if cumulative1==1
        data1=[data1(1);diff(data1)];
    end

    if DT==365

        years1=datevecfirst1(1):1:date1(1);

        if length(data1)<length(years1)+forecastingperiod
            error('Forecasting period is too long and cannot be evaluated with the available data.')
        else
            data2=data1(length(years1)+1:1:length(years1)+forecastingperiod);
        end

        %data2=data1(length(years1)+1:1:length(years1)+forecastingperiod);

    else

        datenum1=datenum(datevecfirst1):DT:datenum(date1);

        index1=length(datenum1):1:length(datenum1)+forecastingperiod-1;

        index1
        length(data1)

        if index1(end)>length(data1)
            error('Forecasting period is too long and cannot be evaluated with the available data.')
        else
            data2=data1(index1);
        end

        %data2=data1(length(datenum1):1:length(datenum1)+forecastingperiod-1);

    end
end
