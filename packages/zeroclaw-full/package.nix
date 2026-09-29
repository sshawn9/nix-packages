{
  lib,
  pkgs,
  ...
}:

let
  inherit (pkgs)
    rustPlatform
    fetchFromGitHub
    fetchNpmDeps
    npmHooks
    nodejs
    pkg-config
    protobuf
    sqlite
    writableTmpDirAsHomeHook
    gitMinimal
    jq
    versionCheckHook
    nix-update-script
    ;

  # Cargo's `default` set carries only the lean `default-channels` bundle, so
  # every channel and subsystem below has to be named. Names are from
  # `[features]` in the tagged Cargo.toml — they drift between releases, so
  # re-check this list whenever `version` moves.
  #
  # Deliberately left off:
  #   hardware / peripheral-rpi / probe / dev-sim — need real devices or a Pi
  #   voice-wake                                  — pulls an audio stack
  #   embedded-web                                — postInstall already ships
  #                                                 the dashboard next to the
  #                                                 binary
  #   channel-feishu                              — an alias for channel-lark
  features =
    [
      # Broad channel bundle: lark, line, slack, signal, mattermost, irc,
      # imessage, dingtalk, qq, bluesky, git, twitch, twitter, reddit, notion,
      # mqtt, amqp, linq, nextcloud, mochat, wecom, wecom-ws, clawdtalk,
      # whatsapp-cloud, voice-call.
      "channels-full"

      # Channels outside every bundle.
      "channel-matrix"
      "channel-nostr"
      "channel-wechat"

      # Git channel providers.
      "provider-github"
      "provider-gitea"

      # WhatsApp over the web client, alongside the Cloud API channel that
      # `channels-full` already carries.
      "whatsapp-web"

      # Subsystems.
      "memory-postgres"
      "observability-otel"
      "browser-native"
      "plugins-wasm"
      "webauthn"
    ]
    ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
      "sandbox-landlock"
      "sandbox-bubblewrap"
    ];
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "zeroclaw-full";
  version = "0.8.5";

  src = fetchFromGitHub {
    owner = "zeroclaw-labs";
    repo = "zeroclaw";
    tag = "v${finalAttrs.version}";
    hash = "sha256-X+2hSmbGibS0LJDew+CnXpJFW2k7w3fj/D54XHqLLzI=";
  };

  cargoHash = "sha256-a0tr5K6KReLRRN4X8sjJrriHy/n0LC7amlOHtM765eg=";

  npmDeps = fetchNpmDeps {
    inherit (finalAttrs) src;
    sourceRoot = "${finalAttrs.src.name}/web";
    hash = "sha256-vY5eHo9VkW7h1d0zQwS70FAClDjCTO9frJ5GzgI9INM=";
  };
  npmRoot = "web";

  buildFeatures = features;
  checkFeatures = features;

  # Upstream's release profile (`lto = "fat"`, `codegen-units = 1`) is kept as
  # shipped. It makes the final link a single rustc process holding the whole
  # program, which needs more memory than a hosted CI runner has; the workflow
  # adds swap rather than relaxing the profile here.

  postPatch = ''
    # build.rs runs `npm ci && npm run build` during compilation,
    # skip and handle it ourselves in postBuild
    substituteInPlace crates/zeroclaw-gateway/build.rs \
      --replace-fail 'build_web_dashboard();' '// dashboard built via postBuild'

    # upstream hardcodes a Debian cross toolchain name that doesn't exist in the Nix sandbox
    substituteInPlace .cargo/config.toml \
      --replace-fail 'linker = "aarch64-linux-gnu-gcc"' ""
  '';

  nativeBuildInputs = [
    pkg-config
    protobuf
    nodejs
    npmHooks.npmConfigHook
  ];

  buildInputs = [
    sqlite
  ];

  postBuild = ''
    cargo run --frozen --release --package xtask --bin web -- gen-api
    pushd web
    npm run build
    popd
  '';

  nativeCheckInputs = [
    writableTmpDirAsHomeHook
    gitMinimal
    # 0.8.4 added tests/architecture/release_workflow.rs, which shells out to
    # scripts/release/scoop_metadata.sh; that script needs jq.
    jq
  ];

  # wiremock tests require socket binding, which is denied in the darwin sandbox
  checkFlags = [
    "--skip=commands::update::tests::download_binary_preserves_missing_checksum_fallback"
    "--skip=commands::update::tests::download_binary_rejects_checksum_mismatch_without_writing"
    "--skip=commands::update::tests::download_binary_verifies_checksum_before_writing"
    "--skip=tests::exchange_pairing_code_posts_code_and_returns_token"
    "--skip=tests::fetch_pairing_code_reads_gateway_pair_code_response"
    "--skip=tests::gateway_addr_in_use_message_skips_occupied_restart_hint_port"
    "--skip=tests::gateway_restart_hint_uses_gateway_bind_fallback_for_hostnames"
    "--skip=integration::telegram_attachment_fallback::"
    "--skip=integration::telegram_finalize_draft::"
  ];

  # The gateway serves the web dashboard from <binary_dir>/web/dist at runtime
  postInstall = ''
    mkdir -p $out/bin/web
    cp -r web/dist $out/bin/web/dist
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Fast, small, and fully autonomous AI assistant infrastructure, built with every channel and subsystem feature";
    homepage = "https://github.com/zeroclaw-labs/zeroclaw";
    changelog = "https://github.com/zeroclaw-labs/zeroclaw/releases/tag/${finalAttrs.src.tag}";
    license = lib.licenses.mit;
    mainProgram = "zeroclaw";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
})
