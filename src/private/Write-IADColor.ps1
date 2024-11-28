Function Write-IADColor {
    <#
    .SYNOPSIS
        Writes text to the console with multiple colors on a single line.

    .DESCRIPTION
        The Write-IADColor function allows you to write text to the console using different colors for each part of the text. It provides a way to create colorful output in PowerShell scripts.

    .PARAMETER Text
        An array of strings to be written to the console. Each element can have a different color.

    .PARAMETER Color
        An array of ConsoleColor values corresponding to the colors for each element in the Text array.

    .PARAMETER NoNewline
        If specified, prevents adding a new line at the end of the output.

    .EXAMPLE
        PS C:\> Write-IADColor -Text "Hello", " ", "World" -Color Red, White, Blue

        Outputs "Hello World" with "Hello" in red, a space in white, and "World" in blue.

    .EXAMPLE
        PS C:\> Write-IADColor -Text "Status:", " OK" -Color Yellow, Green -NoNewline

        Outputs "Status: OK" with "Status:" in yellow and "OK" in green, without adding a new line.

    .NOTES
        The number of elements in the Text and Color arrays should match.

    .LINK
        https://www.reddit.com/r/PowerShell/comments/5pdepn/writecolor_multiple_colors_on_a_single_line/
    #>
    Param (
        [String[]]$Text,
        [ConsoleColor[]]$Color,
        [Switch]$NoNewline = $false
    )

    For ([int]$i = 0; $i -lt $Text.Length; $i++) {
        Write-Host $Text[$i] -Foreground $Color[$i] -NoNewLine
    }

    If ($NoNewline -eq $false) {
        Write-Host ''
    }
}
