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
  "* ${0:a:h}/patches/FFmpeg/0003-FFmpeg-4.4.1-libaomenc.patch \
    993f429b3c3f4acac4929bfb9b51d074381f4937f2e86068a6039998cebc0aca"
  "* ${0:a:h}/patches/FFmpeg/0004-FFmpeg-4.4.1-librist.patch \
    96345ca97b9a923a07c4dd38c20cb435241463eda2d69e13daa97faa758ed8cc"
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
