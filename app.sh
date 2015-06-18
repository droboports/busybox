CFLAGS="${CFLAGS:-} -ffunction-sections -fdata-sections"
LDFLAGS="-L${DEST}/lib -L${DEPS}/lib -Wl,--gc-sections"

### PCRE ###
_build_pcre() {
local VERSION="8.37"
local FOLDER="pcre-${VERSION}"
local FILE="${FOLDER}.tar.bz2"
local URL="ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/${FILE}"

_download_bz2 "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --host="${HOST}" --prefix="${DEPS}" --disable-shared --enable-static --disable-cpp --enable-utf --enable-unicode-properties
make
make install
popd
}

### LIBSEPOL ###
_build_libsepol() {
local VERSION="2.4"
local FOLDER="libsepol-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="https://raw.githubusercontent.com/wiki/SELinuxProject/selinux/files/releases/20150202/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
make install ARCH="arm" PREFIX="${DEST}" INCLUDEDIR="${DEPS}/include" INCDIR="${DEPS}/include/sepol" LIBDIR="${DEST}/lib" SHLIBDIR="${DEST}/lib" MAN3DIR="${DEPS}/man" MAN8DIR="${DEPS}/man" BINDIR="${DEPS}/bin"
rm -vf "${DEST}/lib/libsepol.a"
popd
}

### LIBSELINUX ###
# requires pcre, libsepol
_build_libselinux() {
local VERSION="2.4"
local FOLDER="libselinux-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="https://raw.githubusercontent.com/wiki/SELinuxProject/selinux/files/releases/20150202/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
make -j1 install ARCH="arm" PREFIX="${DEST}" INCLUDEDIR="${DEPS}/include" INCDIR="${DEPS}/include/selinux" LIBDIR="${DEST}/lib" SHLIBDIR="${DEST}/lib" MAN3DIR="${DEPS}/man" MAN5DIR="${DEPS}/man" MAN8DIR="${DEPS}/man" BINDIR="${DEPS}/bin" USRBINDIR="${DEPS}/sbin" SBINDIR="${DEPS}/sbin" LDLIBS="-L${DEST}/lib -L${DEPS}/lib -lselinux -lpcre"
rm -vf "${DEST}/lib/libselinux.a"
popd
}

### BUSYBOX ###
_build_busybox() {
local VERSION="1.23.2"
local FOLDER="busybox-${VERSION}"
local FILE="${FOLDER}.tar.bz2"
local URL="http://busybox.net/downloads/${FILE}"

_download_bz2 "${FILE}" "${URL}" "${FOLDER}"
cp -vf "src/busybox-${VERSION}-config" "target/${FOLDER}/.config"
pushd "target/${FOLDER}"
make
make install
"${STRIP}" -s -R .comment -R .note -R .note.ABI-tag "${DEST}/bin/busybox" "${DEST}/lib/libsepol.so.1" "${DEST}/lib/libselinux.so.1"
popd
}

_build() {
  _build_pcre
  _build_libsepol
  _build_libselinux
  _build_busybox
  _package
}
