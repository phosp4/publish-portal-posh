# Publish Portal in PowerShell (Shellpress)

Shellpress is a PowerShell module for generating and publishing HTML articles from Markdown files.

## Usage

### Import the Module

Before using the module, import it:

```powershell
Import-Module ./Publish-Portal.psm1 -Force
```

### Publish Articles

To publish articles, run the Publish-Portal function:

```powershell
Publish-Portal -Statistics -Destination "user@server:/path/to/destination"
```

### Parameters

- Statistics: Generates a statistics HTML file with word and article counts.
- Destination: Specifies the remote server destination for uploading the generated HTML files.
