# Install Lean Guard 0.3.0

The command below is prepared to select the public **v0.3.0** release explicitly after publication. The bootstrap pins the reviewed 0.3.0 package bytes. At this commit the v0.3.0 public Release and anonymous remote `ValidateOnly` path are pending; do not run the command until the post-publication receipt confirms them.

## Prepared artifacts

| Artifact | SHA-256 |
| --- | --- |
| `install-v0.3.0.ps1` | `36bcef90f462f4cad91b79361eba22770dbd27062b58991bcbc77d21f629f3b9` |
| `HW-Lean-Guard-v0.3.0-Innessco.zip` | `9c675a353c7b50534f2d8a6b606f7e1a86ab91d9c7988e96451b506d38be7894` |

These identities must match the later published public 0.3.0 assets exactly. The versioned bootstrap validates the pinned ZIP, archive paths and strict package manifest before execution.

## Version-pinned single PowerShell command

First confirm Claude `/status` shows `Enterprise managed settings (remote)`. Run in the signed-in user's PowerShell:

```powershell
& { $ErrorActionPreference='Stop'; $ProgressPreference='SilentlyContinue'; $api='https:'+'//'+'api.github.com/repos/HenryWilliam-Git/hw-lean-guard-installer/releases/tags/v0.3.0'; $release=Invoke-RestMethod -UseBasicParsing -Headers @{ Accept='application/vnd.github+json'; 'User-Agent'='HW-Lean-Guard-Installer' } -Uri $api; if ($release.draft -ne $false -or $release.prerelease -ne $false -or $release.immutable -ne $true -or [string]$release.tag_name -cne 'v0.3.0') { throw 'Pinned public Lean Guard Release is not an approved immutable version.' }; $assets=@($release.assets | Where-Object { $_.name -ceq 'install-v0.3.0.ps1' }); if ($assets.Count -ne 1 -or [string]$assets[0].digest -notmatch '^sha256:[0-9a-f]{64}$') { throw 'Pinned public Lean Guard bootstrap identity is invalid.' }; $uri=[Uri][string]$assets[0].browser_download_url; if ($uri.Scheme -cne 'https' -or $uri.Host -cne 'github.com') { throw 'Pinned public Lean Guard bootstrap URL is invalid.' }; $path=Join-Path ([IO.Path]::GetTempPath()) ('HWLeanGuard-v030-'+[Guid]::NewGuid().ToString('N')+'.ps1'); try { $response=Invoke-WebRequest -UseBasicParsing -Uri $uri -OutFile $path -PassThru; $finalUri=if ($null -ne $response.BaseResponse.PSObject.Properties['ResponseUri']) { $response.BaseResponse.ResponseUri } else { $response.BaseResponse.RequestMessage.RequestUri }; if ($null -eq $finalUri -or $finalUri.Scheme -cne 'https') { throw 'Pinned public Lean Guard bootstrap download did not finish over HTTPS.' }; $actual='sha256:'+((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()); if ($actual -cne [string]$assets[0].digest) { throw 'Pinned public Lean Guard bootstrap SHA-256 mismatch.' }; & $path -ServerManagedPolicyConfirmed } finally { if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Force } } }
```

After publication, the command verifies the exact tag, immutable publication state, HTTPS transport and GitHub asset SHA-256 before executing the downloaded bootstrap. It requests UAC for machine installation only. HKCU Workbench readiness remains separately owned by Innessco. Replace `-ServerManagedPolicyConfirmed` with `-ValidateOnly` for a download-and-validation preview with no installation.

Use the [operator handoff](production-handoff.md) for readback and rollback. Organization instructions, server-managed hooks, FSLogix and fleet assignment remain separate controls. Do not substitute a `releases/latest` URL when selecting a fixed version.

The repository alias and versioned bootstrap are byte-identical. Existing immutable releases remain preserved.

## User-readiness boundary

The 0.3.0 public installer performs the machine phase only and reports HKCU Workbench readiness as `EXTERNAL_VALIDATION_REQUIRED`. It does not write user policy, choose an AppData/personal-storage path or implement backup. Innessco must apply and verify the user phase after the intended FSLogix profile is attached.
