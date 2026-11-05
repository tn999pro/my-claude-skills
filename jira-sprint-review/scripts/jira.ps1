#!/usr/bin/env pwsh
# Jira Cloud REST helper — token-based, alternativa estable al MCP de Atlassian.
# Auth por API token (Basic). Sin OAuth, sin SSE, sin re-auth.
# Requiere variables de entorno: JIRA_BASE, JIRA_EMAIL, JIRA_TOKEN
#
# Uso:
#   .\jira.ps1 myself
#   .\jira.ps1 search "assignee=currentUser() AND statusCategory!=Done ORDER BY updated DESC"
#   .\jira.ps1 get SCRUM-27
#   .\jira.ps1 transitions SCRUM-27
#   .\jira.ps1 transition SCRUM-27 31        # WRITE — pedir confirmacion (Fase 5)
#   .\jira.ps1 comment SCRUM-27 "texto"      # WRITE — pedir confirmacion (Fase 5)

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('myself','search','get','transitions','transition','comment')]
    [string]$Command,
    [Parameter(ValueFromRemainingArguments)][string[]]$Rest
)

$ErrorActionPreference = 'Stop'

function Get-JiraConfig {
    foreach ($v in 'JIRA_BASE','JIRA_EMAIL','JIRA_TOKEN') {
        if (-not (Test-Path "env:$v")) {
            throw "Falta la variable de entorno $v. Configura JIRA_BASE, JIRA_EMAIL y JIRA_TOKEN."
        }
    }
    $auth = [Convert]::ToBase64String(
        [Text.Encoding]::UTF8.GetBytes("$($env:JIRA_EMAIL):$($env:JIRA_TOKEN)"))
    [pscustomobject]@{ Base = ($env:JIRA_BASE).TrimEnd('/'); Auth = "Basic $auth" }
}

function Invoke-Jira {
    param([string]$Method, [string]$Path, $Body)
    $cfg = Get-JiraConfig
    $params = @{
        Method  = $Method
        Uri     = "$($cfg.Base)$Path"
        Headers = @{ Authorization = $cfg.Auth; Accept = 'application/json' }
    }
    if ($null -ne $Body) {
        $params.ContentType = 'application/json'
        $params.Body        = ($Body | ConvertTo-Json -Depth 20)
    }
    Invoke-RestMethod @params
}

# Aplana ADF (Atlassian Document Format) a texto legible.
function ConvertFrom-Adf {
    param($Node)
    if ($null -eq $Node) { return '' }
    $text = ''
    if ($Node.type -eq 'text') { $text += $Node.text }
    if ($Node.content) { foreach ($c in $Node.content) { $text += (ConvertFrom-Adf $c) } }
    if ($Node.type -in @('paragraph','heading','listItem','blockquote','codeBlock','rule')) {
        $text += "`n"
    }
    return $text
}

switch ($Command) {
    'myself' {
        $me = Invoke-Jira GET '/rest/api/3/myself'
        [pscustomobject]@{ accountId=$me.accountId; displayName=$me.displayName; email=$me.emailAddress } |
            ConvertTo-Json
    }
    'search' {
        if (-not $Rest -or -not $Rest[0]) { throw 'Uso: search "<JQL>"' }
        $jql = $Rest[0]
        $all = [System.Collections.Generic.List[object]]::new()
        $token = $null
        do {
            $body = @{ jql=$jql; fields=@('summary','status','assignee','description'); maxResults=100 }
            if ($token) { $body.nextPageToken = $token }
            $resp = Invoke-Jira POST '/rest/api/3/search/jql' $body
            foreach ($i in $resp.issues) {
                $all.Add([pscustomobject]@{
                    key         = $i.key
                    summary     = $i.fields.summary
                    status      = $i.fields.status.name
                    assignee    = $i.fields.assignee.displayName
                    description = (ConvertFrom-Adf $i.fields.description).Trim()
                })
            }
            $token = $resp.nextPageToken
        } while (-not $resp.isLast)
        $all | ConvertTo-Json -Depth 6
    }
    'get' {
        if (-not $Rest -or -not $Rest[0]) { throw 'Uso: get <ISSUE-KEY>' }
        $i = Invoke-Jira GET "/rest/api/3/issue/$($Rest[0])?fields=summary,status,assignee,description"
        [pscustomobject]@{
            key=$i.key; summary=$i.fields.summary; status=$i.fields.status.name
            assignee=$i.fields.assignee.displayName
            description=(ConvertFrom-Adf $i.fields.description).Trim()
        } | ConvertTo-Json -Depth 6
    }
    'transitions' {
        if (-not $Rest -or -not $Rest[0]) { throw 'Uso: transitions <ISSUE-KEY>' }
        $t = Invoke-Jira GET "/rest/api/3/issue/$($Rest[0])/transitions"
        $t.transitions | Select-Object id, name, @{n='to';e={$_.to.name}} | ConvertTo-Json -Depth 4
    }
    'transition' {
        if (-not $Rest -or $Rest.Count -lt 2) { throw 'Uso: transition <ISSUE-KEY> <transitionId>' }
        Invoke-Jira POST "/rest/api/3/issue/$($Rest[0])/transitions" @{ transition=@{ id=$Rest[1] } } | Out-Null
        "OK: $($Rest[0]) -> transition $($Rest[1])"
    }
    'comment' {
        if (-not $Rest -or $Rest.Count -lt 2) { throw 'Uso: comment <ISSUE-KEY> "<texto>"' }
        $adf = @{ body=@{ type='doc'; version=1; content=@(@{ type='paragraph'; content=@(@{ type='text'; text=$Rest[1] }) }) } }
        Invoke-Jira POST "/rest/api/3/issue/$($Rest[0])/comment" $adf | Out-Null
        "OK: comentario agregado a $($Rest[0])"
    }
}
