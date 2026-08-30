{
  lib,
  pkgs,
  ...
}:

let
  platform = pkgs.stdenv.hostPlatform;

  # nixpkgs builds with Cargo's `default` feature set, which pulls in only the
  # lean `default-channels` bundle. Everything below is what `default` plus the
  # `channels-full` bundle still leave out.
  extraFeatures =
    [
      # Broad channel bundle: lark, line, slack, signal, mattermost, irc,
      # imessage, dingtalk, qq, bluesky, git, twitch, twitter, reddit, notion,
      # mqtt, amqp, linq, wati, nextcloud, mochat, wecom, wecom-ws, clawdtalk,
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
    ++ lib.optionals platform.isLinux [
      "sandbox-landlock"
      "sandbox-bubblewrap"
    ];
in
pkgs.zeroclaw.overrideAttrs (old: {
  pname = "zeroclaw-full";

  # `buildFeatures` is a `buildRustPackage` function argument, not a derivation
  # attribute, so overriding it here would be silently dropped. The builder
  # turns it into `cargoBuildFeatures`, which is what the cargo hooks read.
  cargoBuildFeatures = (old.cargoBuildFeatures or [ ]) ++ extraFeatures;

  # Keep the test build on the same feature set. Left at the default it would
  # compile the whole tree a second time with different features.
  cargoCheckFeatures = (old.cargoCheckFeatures or [ ]) ++ extraFeatures;

  meta = old.meta // {
    description = "${old.meta.description} (built with every channel and subsystem feature)";
  };
})
