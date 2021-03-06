{ stdenv, fetchurl, makeWrapper
, xorg, imlib2, libjpeg, libpng
, curl, libexif, jpegexiforient, perlPackages }:

with stdenv.lib;

stdenv.mkDerivation rec {
  pname = "feh";
  version = "3.2.1";

  src = fetchurl {
    url = "https://feh.finalrewind.org/${pname}-${version}.tar.bz2";
    sha256 = "070axq8jpibcabmjfv4fmjmpk3k349vzvh4qhsi4n62bkcwl35wg";
  };

  outputs = [ "out" "man" "doc" ];

  nativeBuildInputs = [ makeWrapper xorg.libXt ];

  buildInputs = [ xorg.libX11 xorg.libXinerama imlib2 libjpeg libpng curl libexif ];

  makeFlags = [
    "PREFIX=${placeholder "out"}" "exif=1"
  ] ++ optional stdenv.isDarwin "verscmp=0";

  installTargets = [ "install" ];
  postInstall = ''
    wrapProgram "$out/bin/feh" --prefix PATH : "${makeBinPath [ libjpeg jpegexiforient ]}" \
                               --add-flags '--theme=feh'
  '';

  checkInputs = [ perlPackages.perl perlPackages.TestCommand ];
  preCheck = ''
    export PERL5LIB="${perlPackages.TestCommand}/${perlPackages.perl.libPrefix}"
  '';
  postCheck = ''
    unset PERL5LIB
  '';

  doCheck = true;

  meta = {
    description = "A light-weight image viewer";
    homepage = "https://feh.finalrewind.org/";
    license = licenses.mit;
    maintainers = with maintainers; [ viric willibutz globin ];
    platforms = platforms.unix;
  };
}
