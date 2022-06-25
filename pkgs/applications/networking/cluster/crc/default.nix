{ lib
, buildGoModule
, fetchFromGitHub
, git
, stdenv
, testers
, crc
, runtimeShell
, coreutils
}:

buildGoModule rec {
  pname = "crc";
  version = "2.4.1";

  src = fetchFromGitHub {
    owner = "code-ready";
    repo = "crc";
    rev = "v${version}";
    sha256 = "4ckHvIswVwECAKsa/yN9rJSqZb04ZP1Zomq+1UdT1OY=";
    # makefile calculates git commit and needs the git folder for it
    leaveDotGit = true;
  };

  vendorSha256 = null;

  nativeBuildInputs = [ git ];

  buildPhase = ''
    runHook preBuild
    make HOME=$(mktemp -d) SHELL=${runtimeShell}
    runHook postBuild
  '';

  # tests are currently broken on aarch64-darwin
  # https://github.com/code-ready/crc/issues/3237
  doCheck = !(stdenv.isDarwin && stdenv.isAarch64);

  checkPhase = ''
    runHook preCheck
    substituteInPlace pkg/crc/oc/oc_linux_test.go \
      --replace "/bin/echo"  "${coreutils}/bin/echo"
    make test HOME=$(mktemp -d) SHELL=${runtimeShell}
    runHook postCheck
  '';

  passthru.tests.version = testers.testVersion {
    package = crc;
    command = "HOME=$(mktemp -d) crc version";
  };

  meta = with lib; {
    description = "Manages a local OpenShift 4.x cluster or a Podman VM optimized for testing and development purposes";
    homepage = "https://crc.dev";
    license = licenses.asl20;
    maintainers = with maintainers; [ shikanime tricktron ];
    mainProgram = "crc";
  };
}
