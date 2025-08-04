# Installation

### Build from source

Building from source will require ModuleBuilder from the PowerShell Gallery:

```powershell
Install-Module ModuleBuilder -Scope CurrentUser
git clone https:github.com/steviecoaster/automatedlab.utils.git
cd automatedlab.utils
. ./Build.ps1
Import-Module ./AutomatedLab.Utils/0.1.0/AutomatedLab.Utils.psd1
```

### Install through the PowerShell Gallery

#### Windows PowerShell

```powershell
Install-Module AutomatedLab.Utils -Scope CurrentUser
```

#### PowerShell 7+

```powershell
Install-PSResource AutomatedLab.Utils -Scope CurrentUser
```

### Chocolatey (COMING SOON)

```powershell
choco install automatedlab.utils -y -s https://community.chocolatey.org/api/v2
```