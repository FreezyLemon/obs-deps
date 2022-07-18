autoload -Uz log_debug log_error log_info log_status log_output

## Dependency Information
local name='FFmpeg'
local version='4.4.1'
local url='https://github.com/FFmpeg/FFmpeg.git'
local hash='cc33e73618a981de7fd96385ecb34719de031f16'
local -a patches=(
  "* ${0:a:h}/patches/FFmpeg/0001-FFmpeg-9010.patch \
    97ac6385c2b7a682360c0cfb3e311ef4f3a48041d3f097d6b64f8c13653b6450"
  "* ${0:a:h}/patches/FFmpeg/0002-FFmpeg-4.4.1-OBS.patch \
    710fb5a381f7b68c95dcdf865af4f3c63a9405c305abef55d24c7ab54e90b182"
  "* ${0:a:h}/patches/FFmpeg/0004-FFmpeg-4.4.1-librist.patch \
    96345ca97b9a923a07c4dd38c20cb435241463eda2d69e13daa97faa758ed8cc"
  "* https://gitlab.com/1480c1/FFmpeg/-/commit/04b89e8ae3.patch \
    c785bdbbcab80b2fac97762848358d09bcf154c6e76d17cb029c1c9cc7ac8775"
  "* https://gitlab.com/1480c1/FFmpeg/-/commit/64e2fb3f9d.patch \
    f972ffa529fe52cbd8847c52b3d329dd67574750ba88b145aed5a1a94da7859e"
  "* https://gitlab.com/1480c1/FFmpeg/-/commit/0463f5d6d5.patch \
    6bee0094f0323c928b235879b02f57148ce2b314ce6d90aae98b0578edc4b659"
  "* https://gitlab.com/1480c1/FFmpeg/-/commit/c5f3143090.patch \
    155922c4390bd9e5e6cbc748319981e725015bf15390343d4aae880c0f7cddc9"
  "* https://gitlab.com/1480c1/FFmpeg/-/commit/c33b404885.patch \
    8e93e93baaabe5a889abd7d58eccf5d18064b33bf80aab77c9a343255de7fc6d"
  "* https://gitlab.com/1480c1/FFmpeg/-/commit/1dddb930aa.patch \
    452a105394895589407fdba6939e81fb3cccf02c6b80ba2d8ae0c6fbb478eb2f"
  "* https://gitlab.com/1480c1/FFmpeg/-/commit/50bc872635.patch \
    09b8c521a820ceb2b52c9c65abb72855697ddd41d9b051b90b6efce4ca6fb878"
  "* https://gitlab.com/1480c1/FFmpeg/-/commit/51c0b9e829.patch \
    6e3855474389a9dc9cb46aa81a3b4434214d81a1293b450e1fbb18c4babcdf6e"
  "* https://gitlab.com/1480c1/FFmpeg/-/commit/e3c4442b24.patch \
    dbecdc7c95ab5841ed5cfca79512a23c3100342592793190c4a6c7f215b0b5a2"
  "* https://gitlab.com/1480c1/FFmpeg/-/commit/ded0334d21.patch \
    ad8295a882ae4c2e211aec41683a84c847aee08d58b01cde42457a66f6902eba"
  "* https://gitlab.com/1480c1/FFmpeg/-/commit/70887d44ff.patch \
    ff81450cbf4db4ba2639868e7c40e07ad5ac34203f98628f4414a0ca84a3ec4f"
  "* https://gitlab.com/1480c1/FFmpeg/-/commit/fe100bc556.patch \
    1bb369ebb1b51896a730ba60d637e93fcbd95939e380a07f9989067184a55a42"
  "* https://gitlab.com/1480c1/FFmpeg/-/commit/6fd1533057.patch \
    8b315a3a9c477db9453c1bb6e5b5cdd36f8e0969c35d9f2163262936f3ad8446"
  "windows https://github.com/obsproject/FFmpeg/commit/9ee65983b32b3aa637a839f5171aa16d7bc3650d.patch?full_index=1 \
    a7b0850f6ab1e688a02ba98f05b2a60d6fc1cb306ca825a3bd4e7eacb2fc0a75"
  "windows https://github.com/obsproject/FFmpeg/commit/3558b7c140f86551cd65e7e7aa9815cc2db6e16b.patch?full_index=1 \
    865bbc3dd389569786a6f6972faee7d3e36a7f0d724226c286dd2dfa8ac4efdf"
  "windows https://github.com/obsproject/FFmpeg/commit/8451b7c1d4ade3477b9446b8cd5bfd6ddbf71e83.patch?full_index=1 \
    5c41f4702927b0dc35fae9d22f32f6d2ac54f69ca7042e375a38ffdd17fff3af"
  "windows https://github.com/obsproject/FFmpeg/commit/2927d888cbfda5d19b3147eb5b3a6f423b23cc33.patch?full_index=1 \
    5d00f30410a3ceb8c47bcd14935151ead13ed834d87e570771836b1e3e7b768a"
)

## Build Steps
setup() {
  log_info "Setup (%F{3}${target}%f)"
  setup_dep ${url} ${hash}
}

clean() {
  cd "${dir}"

  if [[ ${clean_build} -gt 0 && -f "build_${arch}/Makefile" ]] {
    log_info "Clean build directory (%F{3}${target}%f)"

    rm -rf "build_${arch}"
  }
}

patch() {
  autoload -Uz apply_patch

  log_info "Patch (%F{3}${target}%f)"

  cd "${dir}"

  local patch
  local _target
  local _url
  local _hash

  for patch (${patches}) {
    read _target _url _hash <<< "${patch}"

    if [[ "${target%%-*}" == ${~_target} ]] apply_patch "${_url}" "${_hash}"
  }
}

config() {
  autoload -Uz mkcd progress

  local -a ff_cflags=()
  local -a ff_cxxflags=()
  local -a ff_ldflags=()

  case ${target} {
    macos-universal)
      autoload -Uz universal_config && universal_config
      return
      ;;
    macos-*)
      local -A hide_libs=(
        xz libzlma
        sdl libSDL2
      )

      local lib lib_name lib_file
      for lib (${hide_libs}) {
        read -r lib_name lib_file <<< "${lib}"

        if [[ -d "${HOMEBREW_PREFIX}/opt/${lib_name}" && -h "${HOMEBREW_PREFIX}/lib/${lib_file}" ]] {
          brew unlink "${lib_name}"
        }
      }

      ff_cflags=(
        -I"${target_config[output_dir]}"/include
        -target "${arch}-apple-macos${MACOSX_DEPLOYMENT_TARGET}"
        ${c_flags}
      )
      ff_cxxflags=(
        -I"${target_config[output_dir]}"/include
        -target "${arch}-apple-macos${MACOSX_DEPLOYMENT_TARGET}"
        ${cxx_flags}
      )
      ff_ldflags=(
        -L"${target_config[output_dir]}"/lib
        -target "${arch}-apple-macos${MACOSX_DEPLOYMENT_TARGET}"
        ${ld_flags}
      )

      args+=(
        --cc=clang
        --cxx=clang++
        --host-cc=clang
        --extra-libs="-lstdc++"
        --arch="${arch}"
        --enable-libaom
        --enable-videotoolbox
        --enable-pthreads
        --enable-libtheora
        --enable-libmp3lame
        --enable-rpath
      )

      if [[ ${CPUTYPE} != "${arch}" ]] args+=(--enable-cross-compile)
    ;;
    linux-*)
      ff_cflags=(
        -I"${target_config[output_dir]}"/include
        ${c_flags}
      )
      ff_cxxflags=(
        -I"${target_config[output_dir]}"/include
        ${cxx_flags}
      )
      ff_ldflags=(
        -L"${target_config[output_dir]}"/lib
        ${ld_flags}
      )

      args+=(
        --arch="${arch}"
        --enable-libaom
        --enable-libsvtav1
        --enable-libtheora
        --enable-libmp3lame
        --enable-pthreads
        --extra-libs="-lpthread -lm"
      )

      if (( ${+commands[clang]} )) {
        args+=(
          --cc=clang
          --cxx=clang++
          --host-cc=clang
        )
      }

      if [[ ${CPUTYPE} != "${arch}" ]] args+=(--enable-cross-compile)
      ;;
    windows-x*)
      ff_cflags=(
        -I"${target_config[output_dir]}"/include
        -static-libgcc
        ${c_flags}
      )
      ff_cxxflags=(
        -I"${target_config[output_dir]}"/include
        -static-libgcc
        -static-libstdc++
        ${cxx_flags}
      )
      ff_ldflags=(
        -L"${target_config[output_dir]}"/lib
        -static-libgcc
        -static-libstdc++
        ${ld_flags}
      )

      if (( ! shared_libs )) {
        ff_ldflags+=(-Wl,-Bstatic -pthread)
        args+=(
          --disable-w32threads
          --enable-pthreads
        )
        autoload -Uz hide_dlls && hide_dlls
      } else {
        args+=(
            --enable-w32threads
            --disable-pthreads
          )
      }

      args+=(
        --arch="${target_config[cmake_arch]}"
        --target-os=mingw32
        --cross-prefix="${target_config[cross_prefix]}-w64-mingw32-"
        --pkg-config=pkg-config
        --enable-cross-compile
        --disable-mediafoundation
      )

      if [[ ${arch} == 'x64' ]] args+=(--enable-libaom --enable-libsvtav1)
    ;;
  }

  args+=(
    --prefix="${target_config[output_dir]}"
    --host-cflags="-I${target_config[output_dir]}/include"
    --host-ldflags="-I${target_config[output_dir]}/include"
    --extra-cflags="${ff_cflags}"
    --extra-cxxflags="${ff_cxxflags}"
    --extra-ldflags="${ff_ldflags}"
    --enable-version3
    --enable-gpl
    --enable-libx264
    --enable-libopus
    --enable-libvorbis
    --enable-libvpx
    --enable-librist
    --enable-libsrt
    --enable-shared
    --disable-static
    --disable-libjack
    --disable-indev=jack
    --disable-outdev=sdl
    --disable-doc
    --disable-postproc
  )

  if (( ! shared_libs )) args+=(--pkg-config-flags="--static")

  log_info "Config (%F{3}${target}%f)"
  cd "${dir}"

  mkcd "build_${arch}"

  log_debug "Configure options: ${args}"
  PKG_CONFIG_LIBDIR="${target_config[output_dir]}/lib/pkgconfig" \
  LD_LIBRARY_PATH="${target_config[output_dir]}/lib" \
  PATH="${(j.:.)cc_path}" \
  progress ../configure ${args}
}

build() {
  autoload -Uz mkcd progress

  case ${target} {
    macos-universal)
      autoload -Uz universal_build && universal_build
      return
      ;;
  }

  log_info "Build (%F{3}${target}%f)"
  cd "${dir}/build_${arch}"

  log_debug "Running make -j ${num_procs}"
  PATH="${(j.:.)cc_path}" progress make -j "${num_procs}"
}

install() {
  autoload -Uz progress

  log_info "Install (%F{3}${target}%f)"

  if [[ ${target} == 'macos-universal' ]] {
    cd "${dir}/build_${CPUTYPE}"
  } else {
    cd "${dir}/build_${arch}"
  }

  make install

  _fixup_ffmpeg
}

function _fixup_ffmpeg() {
  autoload -Uz fix_rpaths create_importlibs
  log_info "Fixup (%F{3}${target}%f)"

  case ${target} {
    macos*)
      local -A other_arch=(arm64 x86_64 x86_64 arm64)
      local cross_lib
      local lib

      if [[ ${arch} == 'universal' ]] {
        log_info "Create universal binaries"
        for lib ("${target_config[output_dir]}"/lib/lib(sw|av|postproc)*.dylib(.)) {
          if [[ ! -e ${lib} || -h ${lib} ]] continue

          cross_lib=("../build_${other_arch[${CPUTYPE}]}/**/${~${lib##*/}%%.*}*.dylib(.)")

          lipo -create ${lib} ${~cross_lib[1]} -output ${lib}
          log_status "Combined ${lib##*/}"
        }
      }

      fix_rpaths "${target_config[output_dir]}"/lib/lib(sw|av|postproc)*.dylib
      ;;
    windows-x*)
      mv "${target_config[output_dir]}"/bin/(sw|av|postproc)*.lib "${target_config[output_dir]}"/lib

      if (( ! shared_libs )) { autoload -Uz restore_dlls && restore_dlls }
      ;;
  }
}
