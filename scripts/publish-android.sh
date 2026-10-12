#!/bin/bash
#
# publish-android.sh [local|central]
#
# Publishes dist/android/ffmpegkit-vp9.aar (build it with build-android.sh) as
# dev.mediacache:ffmpegkit-vp9:<version>, the version in common.sh.
#
#   local    publishToMavenLocal (~/.m2), unsigned unless a key is set. The default.
#   central  signs, bundles and uploads to the Maven Central Portal. Needs:
#              ORG_GRADLE_PROJECT_mavenCentralUsername / …Password   Central Portal user token
#              ORG_GRADLE_PROJECT_signingInMemoryKey                 armored secret key
#              ORG_GRADLE_PROJECT_signingInMemoryKeyPassword
#              ORG_GRADLE_PROJECT_signingInMemoryKeyId               optional
#            The deployment waits in the portal for you to press Publish, unless
#            PUBLISHING_TYPE=AUTOMATIC. Publish only once the GitHub Release with the
#            sources is public: the binaries point at it.
#

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

GRADLE_DIR="$ROOT_DIR/maven"
MODE="${1:-local}"
VERSION="$FFMPEGKIT_VP9_VERSION"
GRADLE=("$GRADLE_DIR/gradlew" -p "$GRADLE_DIR" -q "-PffmpegkitVp9Version=$VERSION")

case "$MODE" in
    local)
        "${GRADLE[@]}" publishToMavenLocal
        echo "✅ dev.mediacache:ffmpegkit-vp9:$VERSION in ~/.m2/repository"
        ;;
    central)
        for var in ORG_GRADLE_PROJECT_mavenCentralUsername ORG_GRADLE_PROJECT_mavenCentralPassword \
                   ORG_GRADLE_PROJECT_signingInMemoryKey ORG_GRADLE_PROJECT_signingInMemoryKeyPassword; do
            if [ -z "${!var:-}" ]; then
                echo "❌ $var is not set"
                exit 1
            fi
        done

        STAGING="$GRADLE_DIR/build/staging-repo"
        rm -rf "$STAGING"
        "${GRADLE[@]}" publishMavenPublicationToStagingRepository

        VERSION_DIR="dev/mediacache/ffmpegkit-vp9/$VERSION"
        if ! ls "$STAGING/$VERSION_DIR"/*.aar.asc > /dev/null 2>&1; then
            echo "❌ Artifacts were not signed"
            exit 1
        fi

        BUNDLE="$GRADLE_DIR/build/ffmpegkit-vp9-$VERSION-bundle.zip"
        rm -f "$BUNDLE"
        (cd "$STAGING" && zip -qr "$BUNDLE" "$VERSION_DIR")
        echo "📦 $BUNDLE"
        unzip -l "$BUNDLE" | awk 'NR > 3 { print "   " $4 }' | sed '/^   $/d'

        TOKEN="$(printf '%s:%s' "$ORG_GRADLE_PROJECT_mavenCentralUsername" "$ORG_GRADLE_PROJECT_mavenCentralPassword" | base64 | tr -d "\n")"
        DEPLOYMENT_ID="$(curl --fail-with-body -sS \
            -H "Authorization: Bearer $TOKEN" \
            -F "bundle=@$BUNDLE" \
            "https://central.sonatype.com/api/v1/publisher/upload?name=ffmpegkit-vp9-$VERSION&publishingType=${PUBLISHING_TYPE:-USER_MANAGED}")"
        echo "⬆️  Uploaded, deployment $DEPLOYMENT_ID"
        echo "   Watch https://central.sonatype.com/publishing/deployments"
        ;;
    *)
        echo "Usage: $0 [local|central]"
        exit 1
        ;;
esac
