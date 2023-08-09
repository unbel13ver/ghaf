{lib, stdenv,  fetchFromGitHub }:

stdenv.mkDerivation rec {
  pname = "nc-vsock";
  version = "0.1";

  src = fetchFromGitHub {
    owner = "vadika";
    repo = pname;
    rev = "master";
    sha256 = "sha256-49MME5Aaa2Z5aL5Lv0QMOzlTJEh63CsvvQRbVd95Cmw";
  };

  meta = with lib; {
    description = "Utility which reads and writes data across networock connections";
    mainProgram = "nc-vsock";
    license = licenses.gpl2Plus;
    platforms = platforms.unix;
  };
}
