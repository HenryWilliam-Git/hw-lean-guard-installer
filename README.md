# Install Lean Guard 0.2.0

The command below selects the public **v0.2.0** release explicitly. The bootstrap pins the unchanged, already released 0.2.0 package bytes. Publication and anonymous validation are recorded separately.

## Verified artifacts

| Artifact | SHA-256 |
| --- | --- |
| `install-v0.2.0.ps1` | `91b373892d0acf1cb4ea4f2f5482c1c53ab27fbacc956845b50e8701258597e2` |
| `HW-Lean-Guard-v0.2.0-Innessco.zip` | `badd21ca3746732a7d255fc063cd5f330ba08a376b2b614040c2521485ed64ff` |

These are the prepared 0.2.0 artifact identities. The versioned bootstrap validates the pinned ZIP, archive paths and strict package manifest before execution.

## Version-pinned single PowerShell command

First confirm Claude `/status` shows `Enterprise managed settings (remote)`. Run in the signed-in user's PowerShell:

```powershell
& { $ErrorActionPreference='Stop'; $ProgressPreference='SilentlyContinue'; $api='https:'+'//'+'api.github.com/repos/HenryWilliam-Git/hw-lean-guard-installer/releases/tags/v0.2.0'; $release=Invoke-RestMethod -UseBasicParsing -Headers @{ Accept='application/vnd.github+json'; 'User-Agent'='HW-Lean-Guard-Installer' } -Uri $api; if ($release.draft -ne $false -or $release.prerelease -ne $false -or $release.immutable -ne $true -or [string]$release.tag_name -cne 'v0.2.0') { throw 'Pinned public Lean Guard Release is not an approved immutable version.' }; $assets=@($release.assets | Where-Object { $_.name -ceq 'install-v0.2.0.ps1' }); if ($assets.Count -ne 1 -or [string]$assets[0].digest -notmatch '^sha256:[0-9a-f]{64}$') { throw 'Pinned public Lean Guard bootstrap identity is invalid.' }; $uri=[Uri][string]$assets[0].browser_download_url; if ($uri.Scheme -cne 'https' -or $uri.Host -cne 'github.com') { throw 'Pinned public Lean Guard bootstrap URL is invalid.' }; $path=Join-Path ([IO.Path]::GetTempPath()) ('HWLeanGuard-v020-'+[Guid]::NewGuid().ToString('N')+'.ps1'); try { $response=Invoke-WebRequest -UseBasicParsing -Uri $uri -OutFile $path -PassThru; $finalUri=if ($null -ne $response.BaseResponse.PSObject.Properties['ResponseUri']) { $response.BaseResponse.ResponseUri } else { $response.BaseResponse.RequestMessage.RequestUri }; if ($null -eq $finalUri -or $finalUri.Scheme -cne 'https') { throw 'Pinned public Lean Guard bootstrap download did not finish over HTTPS.' }; $actual='sha256:'+((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()); if ($actual -cne [string]$assets[0].digest) { throw 'Pinned public Lean Guard bootstrap SHA-256 mismatch.' }; & $path -ServerManagedPolicyConfirmed } finally { if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Force } } }
```

The command verifies the exact tag, immutable publication state, HTTPS transport and GitHub asset SHA-256 before executing the downloaded bootstrap. It requests UAC for machine installation and restores the signed-in user's Workbench policy. Replace `-ServerManagedPolicyConfirmed` with `-ValidateOnly` for a download-and-validation preview with no installation.

After installation, verify version 0.2.0, installed-file hashes, detection checks and the existing Workbench policy. Preserve the prior verified package for owner-approved rollback. Organization instructions, server-managed hooks, FSLogix and fleet assignment remain separate controls. Do not substitute a `releases/latest` URL when selecting this rollback version.

The repository alias and versioned bootstrap are byte-identical. Existing immutable releases remain preserved.

## Known installation limitation

The 0.2.0 package can report access denied while rewriting an already-correct HKCU Workbench policy. The local runtime and exact existing policy were verified separately. No ACL changes or package modifications are included in this online installer update. See the operator handoff for details.
