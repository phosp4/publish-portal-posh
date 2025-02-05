# AUTHOR: Samuel Dobrik
# VERBOSE MESSAGES BY: chatgpt.com
# BEFORE USING:
#   Import-Module ./Publish-Portal.psm1 -Force
# BEFORE TESTING:
#   $VerbosePreference = "continue"
# TESTING:
#   Publish-Portal -Statistics -Destination "samuel_dobrik@s.ics.upjs.sk:/home/samuel_dobrik/public_html"
#   Publish-Portal

# constants
$OUTPUT_FOLDER = "site"
$WEBSITE_TITLE = "Shellpress"

function New-Html {
    Param(
        [Parameter(Position = 0, mandatory=$true)]
        [string] $body
    )
    begin {
        $out = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$WEBSITE_TITLE</title>
</head>
<body>`n
"@
    }
    process {
        $out += $body
    }
    end {
        $out += @"
`n</body>
</html>
"@
        $out
    }
}

function New-HtmlList {
    Param(
        [Parameter(Position = 0, mandatory=$true)]
        [string] $list
    )
    $out = @"
    <h1>$WEBSITE_TITLE Articles</h1>
    <ul>`n
"@
    $out += $list

    $out += @"
    </ul>
"@
    # return final string
    $out
}

function Publish-Portal {

    # inputs
    Param(
        [Parameter(Position = 0, mandatory=$false, ValueFromRemainingArguments = $true)]
        [string[]] $InputFiles,

        [Parameter(mandatory=$false)]
        [string] $Destination,

        [Parameter(mandatory=$false)]
        [switch] $Statistics
    )

    Write-Verbose "Creating the output folder: $OUTPUT_FOLDER."
    # create the output folder, rewrites it if it exists!
    if (Test-Path -Path $OUTPUT_FOLDER) {
        Remove-Item -Path $OUTPUT_FOLDER -Recurse -Force
    }
    New-Item -ItemType "directory" -Path $OUTPUT_FOLDER -Force > $null

    # check if empty
    if ($InputFiles.count -eq 0) {
        Write-Verbose "No input files provided. Using all markdown files in the current directory."
        $InputFiles = Get-ChildItem -Filter *.markdown
    }

    $htmlList = ""
    $wordCount = 0
    $articlesCount = 0

    foreach ($file in $InputFiles) {

        Write-Verbose "Processing file: $file."

        # check if the file exists
        if (-not (Test-Path $file -PathType Leaf)) {
            Write-Error "Skipping $file, it is not a valid file."
            continue
        }

        # add up number of words and articles
        $wordCount += (Get-Content $file | Measure-Object -Word).Words
        $articlesCount += 1

        # create file object
        $fileObj = (Get-Item $file)

        # extract details about file
        $date = $fileObj.LastWriteTime.ToString("yyyy-MM-dd")
        $title = (Get-Content -Path $($fileObj.Name) -TotalCount 1) -replace '\# ', '' # get the first line and remove '#'
        $fileBaseName = ($fileObj.Basename)

        Write-Verbose "Generating HTML for file: $fileBaseName."

        # generate the html file
        pandoc $fileObj.Name -o "$OUTPUT_FOLDER/$fileBaseName.html" --from=markdown --to=html --standalone --metadata title=$title

        # add to html list with correct formatting
        $htmlList += "        <li><a href='$fileBaseName.html'>$title</a> ($date)</li>`n"
    }

    if ($articlesCount -eq 0) {
        Write-Verbose "No articles processed. Exiting function."
        return
    }

    Write-Verbose "Generating HTML list for the index."
    # generate HTML list for the index
    $bodyForIndexHtml = New-HtmlList $htmlList

    if ($Statistics) {

        Write-Verbose "Generating statistics HTML file."

        # create html file with statistics
        $bodyForStatsHtml = "    <h1>Statistics</h1>`n"
        $bodyForStatsHtml += "    <p>Word count: $wordCount</p>`n"
        $bodyForStatsHtml += "    <p>Articles count: $articlesCount</p>`n"
        Set-Content -Path "$OUTPUT_FOLDER/stats.html" -Value $(New-Html $bodyForStatsHtml)

        #add hyperlink to index html
        $bodyForIndexHtml += "    <a href='stats.html'>Statistics</a>`n"
    }

    Write-Verbose "Creating index HTML document."
    # create html document
    Set-Content -Path "$OUTPUT_FOLDER/index.html" -Value $(New-Html $bodyForIndexHtml)

    if ($Destination -ne "") {
        Write-Verbose "Attempting to upload files to server: $Destination."
        try {
            scp $OUTPUT_FOLDER/* $Destination
            Write-Verbose "Files successfully transferred to $Destination."
        }
        catch {
            Write-Error "Failed to transfer files to $Destination."
        }
    }
}