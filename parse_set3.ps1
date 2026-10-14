# PowerShell script to parse NPTEL Soft Skills Practice Set 3 into JSON and JS
$mdPath = ".\NPTEL Soft Skills Practice Set 3 (100 Questions).md"
$content = Get-Content -Path $mdPath -Raw -Encoding UTF8

# Extract Answer Key
$answers = @{}
$keyMatches = [regex]::Matches($content, '(\d+)-(True|False|[A-D](?:,[A-D])*)')
foreach ($m in $keyMatches) {
    $qNum = [int]$m.Groups[1].Value
    $ansStr = $m.Groups[2].Value
    if ($ansStr -eq "True" -or $ansStr -eq "False") {
        $answers[$qNum] = @($ansStr)
    } else {
        $answers[$qNum] = @($ansStr.Split(',') | ForEach-Object { $_.Trim() })
    }
}
Write-Host "Parsed answers count: $($answers.Count)"

# Extract Weeks
# Week sections: ## Week 1 ... ## Week 12
$weekMap = @{}
$lines = $content -split "`r?`n"
$currentWeek = 1
foreach ($line in $lines) {
    if ($line -match '^##\s*Week\s*(\d+)') {
        $currentWeek = [int]$Matches[1]
    } elseif ($line -match '^\*\*Q(\d+)\.\*\*') {
        $weekMap[[int]$Matches[1]] = $currentWeek
    }
}

# Now parse each question block
# Questions start with **Q<num>.**
$qBlocks = [regex]::Split($content, '(?=\*\*Q\d+\.\*\*)')
$questions = [System.Collections.ArrayList]::new()

foreach ($block in $qBlocks) {
    if ($block -notmatch '^\*\*Q(\d+)\.\*\*\s*\\?\[(Single|Multiple|True/False|Match)\\?\]\s*(.+)') {
        continue
    }
    $qNum = [int]$Matches[1]
    $rawType = $Matches[2]
    $rest = $Matches[3].Trim()
    
    $week = if ($weekMap.ContainsKey($qNum)) { $weekMap[$qNum] } else { 1 }
    $ans = if ($answers.ContainsKey($qNum)) { $answers[$qNum] } else { @("A") }

    $qObj = [ordered]@{
        id = $qNum
        week = $week
        topic = "Week $week Concepts"
    }

    if ($rawType -eq "Single" -or $rawType -eq "Multiple") {
        $qObj["type"] = if ($rawType -eq "Single") { "single" } else { "multiple" }
        
        # Parse Question Text and Options (A)... (B)... (C)... (D)...
        if ($rest -match '^(.*?)\s*\(A\)\s*(.*?)\s*\(B\)\s*(.*?)\s*\(C\)\s*(.*?)\s*\(D\)\s*(.*?)$') {
            $qObj["text"] = $Matches[1].Trim()
            $qObj["options"] = @(
                @{ id = "A"; text = $Matches[2].Trim() },
                @{ id = "B"; text = $Matches[3].Trim() },
                @{ id = "C"; text = $Matches[4].Trim() },
                @{ id = "D"; text = $Matches[5].Trim() }
            )
        } else {
            $qObj["text"] = $rest
            $qObj["options"] = @()
        }
        $qObj["answer"] = $ans
        $qObj["explanation"] = "Correct answer is " + ($ans -join ", ") + "."
    }
    elseif ($rawType -eq "True/False") {
        $qObj["type"] = "truefalse"
        $qObj["text"] = $rest.Trim()
        $qObj["options"] = @(
            @{ id = "True"; text = "True" },
            @{ id = "False"; text = "False" }
        )
        $qObj["answer"] = $ans
        $qObj["explanation"] = "The statement is " + $ans[0] + "."
    }
    elseif ($rawType -eq "Match") {
        $qObj["type"] = "match"
        
        # Lines in match block
        $bLines = ($block -split "`r?`n") | Where-Object { $_.Trim() -ne "" }
        $mainText = $rest.Trim()
        if ($mainText -match '^(.*?)\s*(?:Column A:|$)') {
            $mainText = $Matches[1].Trim()
        }
        if (-not $mainText) { $mainText = "Match Column A with Column B." }
        $qObj["text"] = $mainText

        # Find Column A line
        $colALine = ($bLines | Where-Object { $_ -match '^Column A:' }) -replace '^Column A:\s*', ''
        # Find Column B line
        $colBLine = ($bLines | Where-Object { $_ -match '^Column B:' }) -replace '^Column B:\s*', ''
        # Find Options line
        $optLine = ($bLines | Where-Object { $_ -match '^\(A\)' })

        # Parse Column A items: P. ... Q. ... R. ... S. ...
        $colAItems = @()
        if ($colALine -match 'P\.\s*(.*?)\s+Q\.\s*(.*?)\s+R\.\s*(.*?)\s+S\.\s*(.*)') {
            $colAItems = @(
                @{ id = "P"; text = $Matches[1].Trim() },
                @{ id = "Q"; text = $Matches[2].Trim() },
                @{ id = "R"; text = $Matches[3].Trim() },
                @{ id = "S"; text = $Matches[4].Trim() }
            )
        }
        $qObj["columnA"] = $colAItems

        # Parse Column B items: 1. ... 2. ... 3. ... 4. ...
        $colBItems = @()
        if ($colBLine -match '1\.\s*(.*?)\s+2\.\s*(.*?)\s+3\.\s*(.*?)\s+4\.\s*(.*)') {
            $colBItems = @(
                @{ id = "1"; text = $Matches[1].Trim() },
                @{ id = "2"; text = $Matches[2].Trim() },
                @{ id = "3"; text = $Matches[3].Trim() },
                @{ id = "4"; text = $Matches[4].Trim() }
            )
        }
        $qObj["columnB"] = $colBItems

        # Parse Options: (A) ... (B) ... (C) ... (D) ...
        $matchOpts = @()
        if ($optLine -match '\(A\)\s*(.*?)\s*\(B\)\s*(.*?)\s*\(C\)\s*(.*?)\s*\(D\)\s*(.*)') {
            $optTexts = @{
                "A" = $Matches[1].Trim()
                "B" = $Matches[2].Trim()
                "C" = $Matches[3].Trim()
                "D" = $Matches[4].Trim()
            }
            foreach ($optId in @("A", "B", "C", "D")) {
                $pStr = $optTexts[$optId]
                $pairs = [ordered]@{}
                # P-2, Q-3, R-1, S-4
                if ($pStr -match 'P-(\d+),\s*Q-(\d+),\s*R-(\d+),\s*S-(\d+)') {
                    $pairs["P"] = $Matches[1]
                    $pairs["Q"] = $Matches[2]
                    $pairs["R"] = $Matches[3]
                    $pairs["S"] = $Matches[4]
                }
                $matchOpts += @{
                    id = $optId
                    text = $pStr
                    pairs = $pairs
                }
            }
        }
        $qObj["options"] = $matchOpts
        $qObj["answer"] = $ans
        
        # Build explanation showing correct pairs
        $correctOpt = $matchOpts | Where-Object { $_.id -eq $ans[0] }
        if ($correctOpt) {
            $qObj["explanation"] = "Correct matching option is ($($ans[0])): " + $correctOpt.text + "."
        } else {
            $qObj["explanation"] = "Correct match option is ($($ans[0]))."
        }
    }

    [void]$questions.Add($qObj)
}

Write-Host "Total questions parsed: $($questions.Count)"

# Output JS and JSON with forced answer array
$finalQuestions = @()
foreach ($q in $questions) {
    # Ensure answer is strictly an array of strings
    $ansArr = @()
    if ($q.answer -is [System.Collections.IEnumerable] -and $q.answer -isnot [string]) {
        foreach ($a in $q.answer) { $ansArr += "$a" }
    } else {
        $ansArr = @("$($q.answer)")
    }
    $q["answer"] = $ansArr
    $finalQuestions += $q
}

# Output JSON
$jsonStr = $finalQuestions | ConvertTo-Json -Depth 10
# Replace single-item answer strings like "answer": "B" with "answer": [ "B" ] if any escaped
Set-Content -Path ".\questions_set3.json" -Value $jsonStr -Encoding UTF8

# Output JS
$jsStr = "window.BANK_SET3 = " + $jsonStr + ";"
Set-Content -Path ".\questions_set3.js" -Value $jsStr -Encoding UTF8

Write-Host "Successfully wrote questions_set3.json and questions_set3.js with window.BANK_SET3"
