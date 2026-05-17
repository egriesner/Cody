# Play Upload Handoff (2.0.0)

This handoff is the final step list for publishing `RIFT: The Bestiary Protocol` 2.0.0 to Google Play.

## 1) Local release candidate (recommended)

Run:

```bash
./tools/release_orchestrator.sh
```

Expected result:

- smoke/preflight pass
- release APK/AAB built
- checksums + release manifest generated under `build/`

## 2) Build release artifacts (manual fallback)

```bash
./tools/build_apk.sh release
./tools/build_apk.sh release aab
```

Artifacts:

- `build/rift-bestiary-protocol-release.apk`
- `build/rift-bestiary-protocol-release.aab`

## 3) Complete QA documents

- Fill `docs/RELEASE_CANDIDATE_CHECKLIST.md`
- Fill `docs/INTERNAL_TEST_REPORT_TEMPLATE.md`
- Run/record `docs/QA_SMOKE_CHECKLIST_2_0.md`
- Attach/sign off `docs/RELEASE_NOTES_2_0_0.md`
- Keep `build/release-checksums-*.txt` and `build/release-manifest-*.json` with the QA report

## 4) Play Console prep (manual)

- Set package: `com.codemaxstudios.rift`
- Ensure privacy policy URL is live
- Complete Data Safety
- Complete content rating + audience setup
- Upload screenshots, icon, and feature graphic
- Apply listing text from `docs/PLAY_STORE_LISTING_TEMPLATE.md`

## 5) CI publish path (recommended)

For release-candidate artifact bundles:

- **Actions -> Android Release Candidate Bundle -> Run workflow**

For Play publishing:

Required repository variable:

- `GOOGLE_PLAY_PACKAGE_NAME`

Required repository secrets:

- `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`
- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_ALIAS`
- `ANDROID_KEYSTORE_PASSWORD`

Then run:

- **Actions -> Android Play Store Publish -> Run workflow**
  - track: `internal` first
  - release status: `completed` or `draft`

## 6) Promote safely

1. Internal track validation
2. Closed testing validation
3. Production staged rollout
