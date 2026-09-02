# GUI-260902 macOS acceptance harness

This directory is a staging area for testing the exact formal archive on
GitHub-hosted macOS runners. It does not modify the formal GUI or Word manual.
The repository contains only an AES-256-GCM encrypted release archive; its key
is supplied at run time through the `ARCHIVE_KEY_HEX` Actions secret.

## Fixed release input

- File: `GUI-260902.zip`
- Repository payload: `GUI-260902.zip.enc`
- SHA256: `24BC909FA1D7946B21E2FE644C674B1B072CD22DAAAF16A9A3600B96B9CA1CE0`
- MATLAB: R2024b
- Required product: Statistics and Machine Learning Toolbox

## Runner coverage

- `macos-15-intel`: Intel x64
- `macos-15`: Apple Silicon arm64

The workflow records macOS, CPU, MATLAB, Java, license, and function paths;
constructs the GUI invisibly for a CI-safe smoke test; runs the complete
257-test suite; and uploads evidence
separately for both architectures.

The standard Apple Silicon runner currently exposes 7 GB RAM, below
MathWorks' 8 GB minimum. Its result is useful compatibility evidence but must
be reported with that resource limitation; a supported-resource acceptance
still requires a 14 GB larger runner or a physical Mac with at least 8 GB RAM.

## Licensing constraint

MathWorks GitHub Actions automatically license MATLAB products for public
repositories. A private repository requires an `MLM_LICENSE_TOKEN` secret.
The encrypted payload must not be uploaded without the owner's explicit
approval, even though the plaintext source is not present in the repository.

The workflow accepts either route without modification: leave the secret empty
in an approved public repository, or create a private repository and add the
batch token as the `MLM_LICENSE_TOKEN` Actions secret.

Before dispatching the workflow, add the locally generated 64-character key as
the `ARCHIVE_KEY_HEX` Actions secret. Never commit or print that key.
