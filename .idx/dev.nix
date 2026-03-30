{ pkgs, ... }: {
  # 1. Install necessary system packages
  packages = [
    pkgs.flutter
    pkgs.dart
    pkgs.jdk17      # Essential for APK building
    pkgs.unzip      # Required by Flutter to manage tools
  ];

  env = {};

  idx = {
    extensions = [
      "dart-code.dart-code"
      "dart-code.flutter"
    ];

    # 2. Workspace lifecycle hooks (moved to the correct block)
    workspace = {
      onCreate = {
        # Automatically accept licenses and fetch dependencies
        init-flutter = "flutter pub get && yes | flutter doctor --android-licenses";
      };
    };

    # 3. This block tells IDX to provision the Android SDK for you
    previews = {
      enable = true;
      previews = {
        android = {
          # This triggers the automatic SDK setup
          manager = "flutter";
        };
      };
    };
  };
}