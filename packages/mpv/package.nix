{
  mpv,
  mpv-unwrapped,
  ...
}:

mpv.override {
  mpv-unwrapped = mpv-unwrapped.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./mpv-video-triple.patch ];
  });
}
