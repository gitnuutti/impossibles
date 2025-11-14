# CLAUDE.md - AI Assistant Guide for ASENTAJA Repository

## Repository Overview

**Repository Name:** impossibles (ASENTAJA project)
**License:** GNU General Public License v3.0
**Project Type:** Windows Deployment Tool
**Primary Language:** Batch Script / PowerShell
**Last Updated:** 2025-11-14

### Purpose

This repository contains **ASENTAJA** (Finnish for "installer"), an automated deployment and management tool for Planmeca Romexis dental imaging software suite. The tool handles:

- Automated download of latest installer packages from network shares
- Version detection and management
- Installer extraction and preparation
- Installation workflow automation
- Version reporting for installed components
- Post-installation configuration

### Managed Software Components

1. **Romexis** - Main dental imaging application (v6.5.2.x)
2. **Romexis Smart** - Simplified interface variant (v6.4.6.x)
3. **Romexis SmartLite** - Lightweight variant (v6.5.2.x)
4. **Romexis OrthoSimulator** - Orthodontic simulation module (v6.5.2.x)
5. **PlanCAD** - CAD/CAM planning software
6. **Cephalometric Analysis Module** - Orthodontic analysis tools

## Repository Structure

```
impossibles/
├── Core Scripts (Entry Points)
│   ├── startr_user.bat           # Main user-mode launcher (dual-window coordinator)
│   ├── startr_admin.bat          # Admin-mode window with elevated operations
│   └── click to get it.bat       # ASENTAJA installer/updater
│
├── PowerShell Automation
│   ├── latest.ps1                # Find latest installer versions from network
│   ├── dlnew.ps1                 # Download installers with progress tracking
│   ├── BinFileVersions.ps1       # Check versions of binary files/JARs
│   ├── rmx-post.ps1              # Post-installation configuration
│   ├── rmx-server-restart.ps1    # Romexis Server restart utility
│   └── sql_updater.ps1           # SQL database update automation
│
├── Batch Utilities
│   ├── extract_installers.bat    # Extract ZIP archives using 7-Zip
│   ├── BinFileVersions-Call.bat  # Wrapper for version checking script
│   ├── ShowApps.bat              # Display installed app versions from registry
│   ├── ShowFileVersions.bat      # Display file versions
│   ├── rmxconfig.bat             # Romexis configuration utility
│   └── ps execution policy*.bat  # PowerShell execution policy setters
│
├── Configuration Files
│   ├── variables.txt             # Main configuration (paths, version filters)
│   ├── apps.txt                  # List of apps to check in Control Panel
│   ├── files.txt                 # Binaries/JARs to check for versions
│   ├── extracted_to.txt          # Extraction path mapping (auto-generated)
│   └── latest_versions.txt       # Latest version snapshot (auto-generated)
│
├── Extraction Tools
│   ├── 7za.exe                   # 7-Zip standalone executable
│   ├── 7za.dll                   # 7-Zip library
│   └── 7zxa.dll                  # 7-Zip extraction library
│
├── UI Assets
│   ├── startr-ico.ico            # Main launcher icon
│   ├── admin icon.ico            # Admin tasks icon
│   ├── coffee-*.ico              # Various UI icons
│   ├── play-button-*.ico         # Action button icons
│   └── upload ico.ico            # Upload/deployment icon
│
├── Registry Tweaks
│   ├── reset_console_font-colors.reg  # Console appearance reset
│   └── reset console fonts.reg        # Font configuration reset
│
├── Archives
│   ├── startr_admin.rar          # Backup of admin script
│   └── startr_user.rar           # Backup of user script
│
└── Documentation
    ├── CLAUDE.md                 # This file - AI assistant guide
    ├── LICENSE                   # GNU GPL v3.0 license
    └── koe                       # Test file
```

## Configuration System

### variables.txt (Primary Configuration)

Located at: `/home/user/impossibles/variables.txt`

Key configuration parameters:

```batch
# Version filters - specifies base version strings for each app
filter1=Planmeca_Romexis_6.5.2.
filter2=Planmeca_Romexis_SmartLite_6.5.2.
filter3=Planmeca_Romexis_Smart_6.4.6.231
filter4=Planmeca_Romexis_OrthoSimulator_6.5.2.74.

# Network source path (Windows UNC path)
dl_source_path=\\pmgroup.local\Data\Tuotekehitys\SW\Applics\Romexis\Asennus

# Local download/extract destinations
installers_download_to=C:\Users\Public\Desktop\romexis installers\downloaded
installers_extract_to=C:\Users\Public\Desktop\romexis installers\extracted

# Component-specific extraction paths
Romexis_extract_to=C:\Users\Public\Desktop\romexis installers\extracted\Planmeca_Romexis\Romexis
SmartLite_extract_to=...
Smart_extract_to=...
OrthoSimulator_extract_to=...
```

### apps.txt

Lists applications to check in Windows Registry (Control Panel):
- Romexis
- Romexis Cephalometric Analysis module
- PlanCAD
- Romexis Ortho Simulator
- Romexis Smart / SmartLite

### files.txt

Maps friendly names to file paths for version checking:
- Romexis Client JAR, Server JAR
- PMBRIDGE DLL
- Java runtime
- PlanCAD executable
- Cephalometric Analysis tools
- MS SQL Server components

## Core Workflows

### 1. ASENTAJA Installation/Update

**Entry Point:** `click to get it.bat`

**Purpose:** Installs or updates the ASENTAJA tool itself

**Process:**
1. Checks for source archive (local or network: `\\pmgroup.local\...\ASENTAJA.zip`)
2. Deletes old ASENTAJA folder if exists
3. Extracts ASENTAJA.zip to `%USERPROFILE%\AppData\Local\ASENTAJA`
4. Creates desktop shortcut to `startr_user.bat`
5. Auto-launches ASENTAJA after installation

**Key Features:**
- Handles locked file scenarios
- Validates extraction success
- Minimizes installer window after launch

### 2. Dual-Window Architecture

**Entry Points:** `startr_user.bat` + `startr_admin.bat`

The tool uses a sophisticated dual-window approach:

#### User Window (startr_user.bat)
- Runs with **domain user privileges** for network access
- Handles download operations from M-drive
- Coordinates with admin window via flag files
- Displays installer menu and version information
- Positioned: 10,20 | Size: 720x950px

**Security Check:** Refuses to run if started with "Run as Administrator" (blocks network drive access)

#### Admin Window (startr_admin.bat)
- Runs with **elevated privileges** for system operations
- Handles installation, extraction, registry operations
- Waits for downloads to complete
- Executes actual installer packages
- Positioned separately for side-by-side viewing

**Inter-Process Communication:**
- `.download_complete` flag file
- `.asentaja_admin_ready` flag file
- Synchronized state via filesystem

### 3. Version Discovery

**Script:** `latest.ps1`

**Purpose:** Finds the latest version of each component from network share

**Algorithm:**
1. Reads version filters from `variables.txt`
2. Scans source directory for matching ZIP files
3. Extracts version tuples from filenames
4. Normalizes version numbers (8-segment padding)
5. Sorts by version key + LastWriteTime
6. Writes results to `latest_versions.txt` (format: `filename|size`)

**Output Format:**
```
Planmeca_Romexis_6.5.2.163.183_Win.zip|5693715803
Planmeca_Romexis_SmartLite_6.5.2.94.150_Win.zip|3480528588
```

### 4. Download Management

**Script:** `dlnew.ps1`

**Purpose:** Downloads/updates installer packages with intelligent cleanup

**Features:**
- Reads latest versions from `latest_versions.txt`
- Filters based on install option (Romexis-only vs. all apps)
- Deletes outdated or corrupted downloads
- Verifies file sizes match expected values
- Shows real-time progress (percentage)
- Uses 1MB buffer for efficient copying
- Creates `.download_complete` flag when done

**Install Options:**
- Options 1,3,4,6: Romexis only (excludes Smart/SmartLite/OrthoSimulator)
- Other options: Download all components

### 5. Extraction Process

**Script:** `extract_installers.bat`

**Purpose:** Extract all downloaded ZIP files and organize contents

**Process:**
1. Loads paths from `variables.txt`
2. Creates extraction directory structure
3. For each ZIP file:
   - Determines base name (strips version suffix)
   - Creates target folder
   - Extracts using 7za.exe
   - Detects corruption (errorlevel check)
   - Deletes corrupted files automatically
   - Flattens directory structure for non-Romexis apps
4. Writes path mappings to `extracted_to.txt`

**Error Handling:**
- Auto-deletes corrupted archives
- Returns exit code 99 for corruption (triggers retry)
- Warns if files are locked

### 6. Version Reporting

**Scripts:**
- `BinFileVersions.ps1` - Binary/JAR version extraction
- `ShowApps.bat` - Registry-based version display

#### BinFileVersions.ps1

Specialized version detection:
- **Java executables:** Parses `java -version` output, extracts build tags
- **RomexisServer.jar:** Runs `java -jar RomexisServer.jar -version`
- **Generic JARs:** Extracts MANIFEST.MF and reads Implementation-Version
- **Binaries:** Reads FileVersion/ProductVersion from Windows metadata

**Output Format:**
```
 - Romexis Client jar              6.5.2.163.183
 - Romexis Server jar              6.5.2.163.183
 - Romexis Java                    11.0.26 build: Zulu11.78+15-CA
```

#### ShowApps.bat

Queries Windows Registry for installed applications:
- Searches: HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall
- Includes: WOW6432Node (32-bit apps on 64-bit Windows)
- Includes: HKCU (user-installed apps)
- Displays: DisplayName + DisplayVersion

## Development Conventions

### Coding Standards

#### Batch Scripts (.bat)

1. **Headers:**
   - Include version/date comment at top
   - Example: `rem nuutti date.version 1311.1`

2. **EnableDelayedExpansion:**
   - Always use for variable manipulation in loops
   - `setlocal EnableExtensions EnableDelayedExpansion`

3. **Directory Management:**
   - Use `pushd "%~dp0"` to ensure script directory context
   - Match with `popd` before exit

4. **Error Handling:**
   - Check errorlevel after critical operations
   - Use `>nul 2>&1` to suppress unwanted output
   - Provide clear error messages to users

5. **User Feedback:**
   - Use echo with visual separators (lines of dashes)
   - Clear messaging for wait states
   - Progress indicators for long operations

#### PowerShell Scripts (.ps1)

1. **Strict Mode:**
   - Always start with `Set-StrictMode -Version Latest`
   - Set `$ErrorActionPreference = 'Stop'`

2. **Path Handling:**
   - Expand environment variables: `[Environment]::ExpandEnvironmentVariables($path)`
   - Use `[System.IO.Path]::GetFullPath()` for absolute paths
   - Check path existence before operations

3. **Version Parsing:**
   - Use regex to extract version numbers
   - Normalize to consistent segment count
   - Sort with zero-padded keys for proper ordering

4. **Progress Reporting:**
   - Use `Write-Host` with `-NoNewline` for in-place updates
   - Show percentage completion for file operations
   - Carriage return (`\r`) for progress bar effect

5. **File I/O:**
   - Use .NET streams for large file operations
   - Implement proper resource cleanup (try/finally)
   - Buffer size: 1MB for optimal performance

### File Naming Conventions

- **Batch scripts:** lowercase with underscores (`startr_user.bat`)
- **PowerShell:** lowercase with dashes for utilities (`rmx-post.ps1`)
- **Config files:** lowercase `.txt` extension
- **Icons:** descriptive names with spaces allowed
- **Archives:** Match primary script name with `.rar` extension

### Configuration Management

1. **variables.txt Format:**
   - `key=value` pairs
   - Comments start with `#` or `;`
   - Environment variables expanded by caller
   - No inline comments

2. **List Files (apps.txt, files.txt):**
   - One entry per line
   - Comments start with `#`
   - Optional format: `Label=Path` or `Label|Path`
   - Blank lines ignored

3. **Generated Files:**
   - `latest_versions.txt`: `filename|size`
   - `extracted_to.txt`: `varname=path`
   - `.download_complete`: Flag file (empty or single word)

## Security Considerations

### Credential Management

1. **Network Access:**
   - UNC paths require domain user context
   - Never hardcode credentials
   - User runs as themselves for network share access

2. **Privilege Separation:**
   - User window: Network operations (non-admin)
   - Admin window: System operations (elevated)
   - Clear separation of concerns

3. **Code Execution:**
   - PowerShell execution policy set to RemoteSigned
   - Scope: CurrentUser (doesn't require admin)
   - Bypass flag used with `-File` for explicit scripts

### File System Safety

1. **Deletion Operations:**
   - Always check file locks before deletion
   - Provide retry mechanisms for locked files
   - Warn user when manual intervention needed

2. **Extraction Safety:**
   - Validate archives before extraction
   - Delete corrupted files automatically
   - Prevent directory traversal (7za handles this)

3. **Path Validation:**
   - Expand environment variables
   - Convert to absolute paths
   - Create directories if missing
   - Handle spaces in paths correctly

### Input Validation

1. **Configuration Files:**
   - Validate paths exist before use
   - Check for required parameters
   - Provide meaningful errors for missing config

2. **Version Strings:**
   - Regex validation for version formats
   - Handle malformed version gracefully
   - Fallback to '0' for unparseable versions

## Git Workflow

### Branch Strategy

**Current Branch:** `claude/claude-md-mhyn7s5joa1gs22w-01USRL2Zu3hcgqXvwP1CYmZa`

This repository uses feature branches:
- Format: `claude/<descriptive-name>-<session-id>`
- All AI assistant work on designated feature branches
- Merge to main via pull requests
- NEVER force push to main

### Commit Message Format

Use conventional commits style:
- `feat:` New features
- `fix:` Bug fixes
- `docs:` Documentation updates
- `refactor:` Code restructuring
- `chore:` Maintenance tasks

Examples:
```
feat: Add progress tracking to download script
fix: Handle locked files during extraction
docs: Update CLAUDE.md with workflow details
```

### Git Best Practices

1. **Before Committing:**
   - Test scripts in Windows environment if possible
   - Verify configuration file syntax
   - Check for hardcoded paths
   - Ensure no credentials in code

2. **Pushing:**
   - Use: `git push -u origin <branch-name>`
   - Branch must start with 'claude/'
   - Retry on network failures (2s, 4s, 8s, 16s backoff)

3. **Fetching:**
   - Prefer: `git fetch origin <branch-name>`
   - Keep local branches up to date
   - Resolve conflicts promptly

## Development Workflow for AI Assistants

### Initial Analysis

When starting work on this repository:

1. **Understand Windows Context:**
   - This is a Windows-specific tool
   - Batch and PowerShell are native languages
   - Paths use backslashes and drive letters
   - Case-insensitive filesystem

2. **Review Configuration:**
   - Read `variables.txt` first
   - Understand version filters
   - Note network path dependencies
   - Check default installation paths

3. **Identify Dependencies:**
   - Network share availability
   - 7-Zip tools (included)
   - PowerShell 5.1+ assumed
   - Windows 10/11 target platform
   - Domain environment assumed

### Making Changes

1. **Planning:**
   - Use TodoWrite for multi-step tasks
   - Consider both user and admin window impacts
   - Think about error scenarios
   - Plan for network failures

2. **Code Modifications:**
   - Test logic in Batch/PowerShell syntax
   - Preserve Windows line endings (CRLF)
   - Maintain consistent indentation
   - Add comments for complex logic
   - Update version comments if applicable

3. **Configuration Updates:**
   - Validate syntax before committing
   - Document new parameters
   - Provide sensible defaults
   - Consider backward compatibility

4. **Testing Considerations:**
   - Scripts cannot be fully tested in Linux environment
   - Validate syntax and logic
   - Check for common Windows pitfalls:
     - Spaces in paths
     - Drive letter handling
     - Environment variable expansion
     - Errorlevel checking

### Common Pitfalls to Avoid

1. **Path Issues:**
   - Don't use forward slashes in Batch (use backslash)
   - Always quote paths with variables
   - Use `%~dp0` for script directory
   - Remember Windows uses `;` as PATH separator

2. **Variable Expansion:**
   - Use `!var!` in loops with DelayedExpansion
   - Use `%var%` in regular contexts
   - Call command for double expansion

3. **PowerShell Specifics:**
   - Cmdlets are case-insensitive but use PascalCase convention
   - Use `-ErrorAction SilentlyContinue` for expected failures
   - Pipe to `Out-Null` to suppress output, not `>$null`

4. **Batch Scripting:**
   - Errorlevel checks: `if errorlevel 1` means >= 1
   - Prefer: `if %errorlevel% == 0`
   - Parentheses in if/for require special handling
   - Line continuation: use `^` at end of line

## Troubleshooting Guide

### Common Issues

#### 1. "Cannot access installer archive"

**Cause:** Network path unavailable or ASENTAJA.zip missing

**Solutions:**
- Verify network connectivity to `\\pmgroup.local`
- Check VPN connection if working remotely
- Ensure domain authentication is active
- Try local fallback path if configured

#### 2. "Cannot delete old ASENTAJA folder"

**Cause:** Files in use by another process

**Solutions:**
- Close all command windows running ASENTAJA
- Close any file explorers viewing the folder
- Logout/login to Windows
- Check Task Manager for hung processes

#### 3. "Do not use 'run as admin' to start ASENTAJA"

**Cause:** startr_user.bat started with elevated privileges

**Explanation:**
- Elevated processes lose network drive mapping
- Need domain user context for UNC paths
- ASENTAJA will request elevation separately for admin tasks

**Solution:**
- Use regular desktop shortcut (not "Run as administrator")
- Right-click > Open (not Run as administrator)

#### 4. Download Failures

**Symptoms:** Files not downloading or incomplete

**Checks:**
- Network share accessible (`\\pmgroup.local\...`)
- User has read permissions on source folder
- Sufficient disk space in download folder
- latest_versions.txt exists and not empty

**Solutions:**
- Run `latest.ps1` manually to refresh version list
- Check filter settings in `variables.txt`
- Verify disk space: `C:\Users\Public\Desktop\romexis installers\`

#### 5. Extraction Errors

**Symptoms:** "Deleting CORRUPTED" messages

**Causes:**
- Incomplete download
- Network interruption during copy
- Disk write errors
- Antivirus interference

**Automatic Handling:**
- Corrupted files deleted automatically
- Script returns exit code 99
- Caller should retry download
- Fresh download attempted on next run

#### 6. Version Detection Issues

**Symptoms:** "unknown" or "not found" version numbers

**Checks:**
- File paths in `files.txt` are correct
- Files exist at specified locations
- Java is installed (for .jar version checks)
- Sufficient permissions to read files

**Solutions:**
- Verify installation paths match configuration
- Update `files.txt` with correct paths
- Ensure Java path: `C:\Program Files\Planmeca\Romexis\tools\jre_x64\bin\java.exe`

## Integration Points

### External Dependencies

1. **Network Infrastructure:**
   - Domain: `pmgroup.local`
   - Share path: `\Data\Tuotekehitys\SW\Applics\Romexis\Asennus`
   - Requires: Domain user authentication
   - Access: Read-only sufficient

2. **Windows Registry:**
   - Uninstall keys for app version detection
   - Console settings (HKCU\Console)
   - VirtualTerminalLevel for ANSI escape codes

3. **File System Locations:**
   - Program Files: `C:\Program Files\Planmeca\`
   - Public Desktop: `C:\Users\Public\Desktop\`
   - User AppData: `%USERPROFILE%\AppData\Local\ASENTAJA`
   - Temp directory: `%TEMP%` for extraction operations

4. **System Requirements:**
   - Windows 10/11 (64-bit)
   - PowerShell 5.1 or later
   - .NET Framework (for PowerShell)
   - Domain membership (for network access)

### Installer Integration

ASENTAJA prepares but doesn't directly execute installers. The actual installation is triggered through:

1. **Silent Installation Flags:**
   - Romexis: Uses InstallShield response files (.iss)
   - Path referenced: `DPEND\Record_ISS`

2. **Post-Installation:**
   - `rmx-post.ps1`: Configuration tasks
   - `sql_updater.ps1`: Database schema updates
   - `rmx-server-restart.ps1`: Service management

3. **Installation Variables:**
   - Set via environment or config files
   - Referenced by installer packages
   - Controlled by `install_option` environment variable

## Maintenance and Updates

### Updating Version Filters

When new major versions release:

1. Edit `variables.txt`
2. Update filter values:
   ```
   filter1=Planmeca_Romexis_6.6.0.
   ```
3. Test with `latest.ps1` to verify detection
4. Document version change in commit message

### Adding New Components

To add support for new Romexis modules:

1. **Add filter to variables.txt:**
   ```
   filter5=Planmeca_Romexis_NewModule_1.0.
   ```

2. **Add extraction path:**
   ```
   NewModule_extract_to=C:\...\extracted\Planmeca_Romexis_NewModule
   ```

3. **Update apps.txt** (if registry-installed):
   ```
   Romexis New Module
   ```

4. **Update files.txt** (for version checking):
   ```
   New Module EXE=C:\Program Files\Planmeca\...\NewModule.exe
   ```

5. **Test full workflow:**
   - Version detection (latest.ps1)
   - Download (dlnew.ps1)
   - Extraction (extract_installers.bat)
   - Version reporting

### Updating Documentation

Keep this CLAUDE.md current:

1. **After workflow changes:** Document new procedures
2. **After config changes:** Update configuration examples
3. **After adding features:** Add to relevant sections
4. **Include version info:** Date last updated
5. **Reference locations:** File paths and line numbers when helpful

## Advanced Topics

### Inter-Window Synchronization

The dual-window architecture uses filesystem-based IPC:

**Flag Files:**
```batch
.asentaja_admin_ready     # Admin window is ready and waiting
.download_complete        # Downloads finished, ready for extraction
```

**Typical Flow:**
1. User window starts admin window
2. Admin window creates `.asentaja_admin_ready`
3. User window starts download process
4. Download script creates `.download_complete`
5. Admin window detects flag, proceeds with extraction
6. User window waits for extraction completion
7. Both windows present installation menu

**Synchronization Pattern:**
```batch
rem User window waits for admin
:WAIT_ADMIN
if not exist ".asentaja_admin_ready" (
    timeout /t 1 /nobreak >nul
    goto WAIT_ADMIN
)

rem Admin window waits for download
:WAIT_DOWNLOAD
if not exist ".download_complete" (
    timeout /t 2 /nobreak >nul
    goto WAIT_DOWNLOAD
)
```

### Version Comparison Algorithm

**Normalization Process:**

1. **Extract version tuple from filename:**
   - Find filter match position
   - Extract numeric segments after filter
   - Fallback: Longest numeric sequence in filename
   - Final fallback: '0'

2. **Normalize to 8 segments:**
   ```powershell
   Input:  6.5.2.163.183
   Output: 6.5.2.163.183.0.0.0
   ```

3. **Build sort key:**
   ```powershell
   Each segment zero-padded to 6 digits:
   006000.005000.002000.000163.000183.000000.000000.000000
   ```

4. **Sort by:**
   - Primary: Version key (descending)
   - Secondary: LastWriteTime (descending)

This ensures:
- Correct version ordering (6.5.10 > 6.5.9)
- Newest file wins if versions match
- Consistent behavior across all components

### Custom Installation Options

The `install_option` environment variable controls filtering:

**Romexis-Only Modes (1, 3, 4, 6):**
```powershell
# In dlnew.ps1
$romexisOnlyOptions = @('1', '3', '4', '6')
if ($romexisOnlyOptions -contains $installOption) {
    # Filter: Keep only Planmeca_Romexis_*
    # Exclude: *Smart*, *OrthoSimulator*
}
```

**Full Install Modes (Other values):**
- Downloads all components
- Includes Smart, SmartLite, OrthoSimulator
- Suitable for comprehensive deployments

### Window Positioning

UI positioning uses Win32 API via PowerShell:

```powershell
Add-Type -Namespace Native -Name Win32 -MemberDefinition @'
[DllImport("kernel32.dll")]
public static extern IntPtr GetConsoleWindow();

[DllImport("user32.dll")]
public static extern bool MoveWindow(
    IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);

[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
'@

$hWnd = [Native.Win32]::GetConsoleWindow()
[Native.Win32]::ShowWindow($hWnd, 9)  # 9 = SW_RESTORE
[Native.Win32]::MoveWindow($hWnd, $xpos, $ypos, $width, $height, $true)
```

**User Window:** 10,20 @ 720x950
**Admin Window:** Different position (TBD in startr_admin.bat)

### Console Appearance

**ANSI Escape Code Support:**
```batch
rem Enable VirtualTerminalLevel for ANSI codes
reg add HKCU\Console /v VirtualTerminalLevel /t REG_DWORD /d 1 /f >nul 2>&1
```

**Color Reset:**
```batch
color 07  # Light gray on black
powershell -Command "$Host.UI.RawUI.BackgroundColor='Black';
                     $Host.UI.RawUI.ForegroundColor='Gray';Clear-Host"
```

**Registry Reset:**
- `reset_console_font-colors.reg`: Restores default console colors
- Deletes HKCU\Console, then sets defaults
- ScreenColors: 0x07 (gray on black)
- PopupColors: 0xF5 (purple on white)

## Future Enhancements

Potential improvements for consideration:

1. **Logging System:**
   - Centralized log file
   - Timestamp all operations
   - Separate logs for user/admin windows
   - Log rotation/cleanup

2. **Rollback Capability:**
   - Keep previous version archives
   - Automated rollback on installation failure
   - Version history tracking

3. **Notification System:**
   - Email notifications for admins
   - Teams/Slack webhooks
   - Installation completion alerts

4. **Automated Testing:**
   - Mock network share for testing
   - Validate extraction without full download
   - Version comparison unit tests

5. **GUI Alternative:**
   - Windows Forms or WPF frontend
   - Visual progress bars
   - Integrated log viewer
   - Configuration editor

6. **Remote Deployment:**
   - Push installations to remote PCs
   - Group Policy integration
   - SCCM/Intune compatibility

7. **Database Integration:**
   - Track installations across organization
   - Inventory management
   - License tracking
   - Compliance reporting

## Notes for AI Assistants

### Critical Understanding Points

1. **This is a Windows-only tool:**
   - Batch and PowerShell are appropriate
   - Cannot be tested in Linux/Mac environments
   - Syntax validation is key

2. **Domain environment assumptions:**
   - Users are domain authenticated
   - Network shares use UNC paths
   - Privilege separation is intentional

3. **Production deployment tool:**
   - Used for real medical software
   - Stability is critical
   - Test thoroughly before suggesting changes
   - Consider backward compatibility

4. **Configuration-driven:**
   - Avoid hardcoding values
   - Use variables.txt for all configurable items
   - Document configuration changes

5. **User experience matters:**
   - Clear error messages
   - Progress indicators
   - Visual feedback
   - Defensive programming

### When Modifying Code

1. **Preserve Windows conventions:**
   - CRLF line endings
   - Backslash paths
   - Case-insensitive logic

2. **Maintain dual-window architecture:**
   - Don't merge user/admin windows
   - Keep synchronization logic
   - Preserve privilege separation

3. **Test error paths:**
   - Network failures
   - Locked files
   - Corrupted downloads
   - Missing configuration

4. **Document changes:**
   - Update CLAUDE.md
   - Add inline comments
   - Update version comments
   - Note breaking changes

5. **Consider deployment:**
   - Will existing installations work?
   - Migration path for config changes?
   - Backward compatibility needs?

### Questions to Ask User

Before making significant changes:

1. **Version filter changes:**
   - "What version range should be supported?"
   - "Exclude older versions completely?"

2. **Path changes:**
   - "Are installation paths standardized?"
   - "Support custom installation locations?"

3. **Feature additions:**
   - "Integration with existing tools needed?"
   - "Logging/auditing requirements?"

4. **Error handling:**
   - "How should unrecoverable errors be handled?"
   - "Notification requirements for failures?"

## Conclusion

This ASENTAJA repository is a sophisticated Windows deployment automation tool for Planmeca Romexis dental software. It demonstrates advanced Batch and PowerShell scripting techniques, implements security best practices through privilege separation, and provides a robust user experience through dual-window coordination and comprehensive error handling.

When working with this codebase, prioritize:
- **Reliability:** Medical software deployment requires stability
- **Security:** Proper privilege separation and input validation
- **Usability:** Clear feedback and error messages for technicians
- **Maintainability:** Well-documented, configuration-driven design

---

**Last Updated:** 2025-11-14
**Project Status:** Active deployment tool
**Primary Maintainer:** Configure via git repository settings
**Next Review:** After major Romexis version update
