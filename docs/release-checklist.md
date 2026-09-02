# MVP release checklist

The first release is an internal, local pilot for Windows and Chrome. It does
not include accounts, hosting, Electron or commits to product repositories.

## Environment

Run the environment check from the repository root:

```powershell
.\doctor.ps1
```

OpenCode is optional for the deterministic local mode, but it must be installed
and authorized before validating the OpenCode path. The gateway reuses that
local authorization; Prototype Forge never asks for or stores an API key.

## Functional acceptance

- [ ] `.\run-local.ps1` starts the gateway and opens the Studio.
- [ ] The local agent generates payment, login, banking and discovery scenarios.
- [ ] OpenCode generates a valid contract with the configured model.
- [ ] An invalid contract identifies the affected component, property and next
      action in the rejection panel.
- [ ] A running generation can be canceled, and a late response does not
      replace the visible prototype.
- [ ] The PM can switch phone, tablet and desktop previews.
- [ ] The PM can create projects, save revisions, compare revisions and add
      review notes.
- [ ] The PM can export a deterministic Flutter draft.
- [ ] The PM can export and re-import the local workspace backup.
- [ ] Reloading the browser preserves the local workspace.

## Technical gate

```powershell
.\check.ps1
git diff --check
```

The release branch should be clean after the gate passes. The PR should include
the commit, test output and the browser smoke-test result.

## Known pilot limitations

- Workspace data is stored in browser `localStorage`; the PM must use the
  backup action before clearing browser data.
- Canceling a request protects the UI state but does not terminate the remote
  OpenCode computation already in progress.
- The Material catalog is a public fixture. The company catalog is a separate
  integration milestone.
