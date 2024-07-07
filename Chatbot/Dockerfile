#escape =`

#FROM mcr.microsoft.com/windows:ltsc2019-amd64 AS base
FROM mcr.microsoft.com/windows/servercore:ltsc2019-amd64 AS base

#SHELL ["cmd", "/S", "/C"]
# Install ASP.NET Core 3.1
RUN powershell -Command `
        $ErrorActionPreference = 'Stop'; `
        $ProgressPreference = 'SilentlyContinue'; `
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12; `
        Invoke-WebRequest `
            -UseBasicParsing `
            -Uri https://dot.net/v1/dotnet-install.ps1 `
            -OutFile dotnet-install.ps1;

Run powershell -executionpolicy bypass -Command `
        $ErrorActionPreference = 'Stop'; `
        $ProgressPreference = 'SilentlyContinue'; `
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12; `
        ./dotnet-install.ps1 `
            -InstallDir '/Program Files/dotnet' `
            -Channel 3.1 `
            -Runtime aspnetcore;

Run powershell -Command `
        $ErrorActionPreference = 'Stop'; `
        $ProgressPreference = 'SilentlyContinue'; `
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12; `
        Remove-Item -Force dotnet-install.ps1 `
        && setx /M PATH "%PATH%;C:\Program Files\dotnet"
#Run setx /M PATH "%PATH%;C:\Program Files\dotnet"
#SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop';", "$ProgressPreference = 'SilentlyContinue';"]

WORKDIR /app

#EXPOSE 80
#EXPOSE 8001

FROM mcr.microsoft.com/windows/servercore:ltsc2019-amd64 AS build
# Install .NET Core 3.1 SDK
RUN powershell -Command `
        $ErrorActionPreference = 'Stop'; `
        $ProgressPreference = 'SilentlyContinue'; `
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12; `
        Invoke-WebRequest `
            -UseBasicParsing `
            -Uri https://dot.net/v1/dotnet-install.ps1 `
            -OutFile dotnet-install.ps1;

Run powershell -executionpolicy bypass -Command `
        $ErrorActionPreference = 'Stop'; `
        $ProgressPreference = 'SilentlyContinue'; `
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12; `
        ./dotnet-install.ps1 `
            -InstallDir '/Program Files/dotnet' `
            -Channel 3.1;

Run powershell -Command `
        $ErrorActionPreference = 'Stop'; `
        $ProgressPreference = 'SilentlyContinue'; `
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12; `
        Remove-Item -Force dotnet-install.ps1 `
        && setx /M PATH "%PATH%;C:\Program Files\dotnet"

WORKDIR /src
COPY . .
WORKDIR /src/contrib-swiplcs-master/SwiPlCs
RUN dotnet restore "SwiPLcs.csproj"
WORKDIR /src/chatbot

Run powershell -command `
        $ErrorActionPreference = 'Stop'; `
        $ProgressPreference = 'SilentlyContinue'; `
        xcopy Alice.pl ..\..\app\publish\ /E /I `
        && xcopy mysql-connector-odbc.zip ..\..\app\publish\ /E /I 

#Run xcopy Alice.pl ..\..\app\publish\ /E /I
#Run xcopy imdb.zip ..\..\app\publish\ /E /I
        
RUN powershell -Command `
        $ErrorActionPreference = 'Stop'; `
        $ProgressPreference = 'SilentlyContinue'; `
        expand-archive -Path 'swipl.zip' -DestinationPath "../../app/publish"; `
        && powershell -Command expand-archive -Path 'mysql-connector-odbc.zip' "../../app/publish"; `
		&& setx /m PATH "%PATH%;C:\app\swipl\bin"; `
        && del swipl.zip
		
RUN dotnet restore "Chatbot.csproj"
RUN dotnet build "Chatbot.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "Chatbot.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "Chatbot.dll"]

RUN setx /m PATH "%PATH%;C:\app\swipl\bin"

#RUN dotnet publish "Chatbot.csproj" -c Release -o /app/publish /p:UseAp            pHost=false