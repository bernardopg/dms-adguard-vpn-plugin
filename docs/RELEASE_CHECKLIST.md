# Release Checklist

Step-by-step process for publishing a new plugin version. Ensures consistency across manifest, changelog, and release notes.

---

## 1. Bump Version

- [ ] Choose the new [semantic version](https://semver.org/) (e.g., `1.2.0`).
- [ ] Update `"version"` in `plugin.json`.
- [ ] Verify `"requires_dms"` still matches the features used.

## 2. Update Release Docs

- [ ] Move `[Unreleased]` entries in `CHANGELOG.md` into a new `## [x.y.z] — YYYY-MM-DD` section.
- [ ] Create `docs/releases/vX.Y.Z.md` with highlights and compatibility notes.
- [ ] Cross-check consistency:

  | Source | Field | Must match |
  | --- | --- | --- |
  | `plugin.json` | `version` | `x.y.z` |
  | `CHANGELOG.md` | section heading | `[x.y.z] — date` |
  | `docs/releases/` | filename | `vX.Y.Z.md` |

## 3. Run Quality Checks

```bash
node scripts/check-i18n-keys.mjs   # i18n key parity
bash scripts/lint-markdown.sh       # Markdown lint
bash scripts/validate-qml.sh        # QML syntax validation
```

- [ ] All three pass with no errors.

## 4. Manual Validation

```bash
dms ipc plugins reload adguardVPplugin
dms ipc plugins status adguardVPplugin
```

Verify in the widget/popout:

- [ ] Connect / Disconnect works.
- [ ] Connect by location (fastest + specific) works.
- [ ] Status, config, and license refresh correctly.
- [ ] Favorites, search, auto-connect behave as expected.
- [ ] No critical errors in the main flow.

## 5. Commit & Tag

```bash
git add -A
git commit -m "release: vX.Y.Z"
git tag vX.Y.Z
git push origin main --tags
```

## 6. Publish

- [ ] Open/update the registry submission PR at [AvengeMedia/dms-plugin-registry](https://github.com/AvengeMedia/dms-plugin-registry) with the new version.
- [ ] Confirm the registry CI validates the updated `plugin.json`.
