# Use Ubuntu 22.04 as the base image
FROM ubuntu:22.04

# Set the working directory
WORKDIR /root

# Install basic utilities and development tools
RUN apt update && DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends \
  ca-certificates \
  wget \
  curl \
  gnupg \
  ripgrep \
  ltrace \
  file \
  python3-minimal \
  build-essential \
  git \
  cmake \
  ninja-build \
  jq

# Set up PATH for ROCm
ENV PATH="${PATH}:/opt/rocm/bin:/opt/rocm/llvm/bin"

# Install Rust
ARG RUST_VERSION=1.77.1
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain=${RUST_VERSION}
RUN . $HOME/.cargo/env && cargo install bindgen-cli --locked

# Install ROCm
ARG ROCM_VERSION=5.7.3
RUN echo "Package: *\nPin: release o=repo.radeon.com\nPin-Priority: 600" > /etc/apt/preferences.d/rocm-pin-600
RUN mkdir --parents --mode=0755 /etc/apt/keyrings && \
  sh -c 'wget https://repo.radeon.com/rocm/rocm.gpg.key -O - | gpg --dearmor | tee /etc/apt/keyrings/rocm.gpg > /dev/null' && \
  sh -c 'echo deb [arch=amd64 signed-by=/etc/apt/keyrings/rocm.gpg] https://repo.radeon.com/rocm/apt/${ROCM_VERSION} jammy main > /etc/apt/sources.list.d/rocm.list' && \
  apt update && DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends \
  rocminfo \
  rocm-gdb \
  rocprofiler \
  rocm-smi-lib \
  hip-runtime-amd \
  comgr \
  hipblaslt-dev \
  hipfft-dev \
  rocblas-dev \
  rocsolver-dev \
  rocsparse-dev \
  miopen-hip-dev \
  rocm-device-libs && \
  echo 'export PATH="$PATH:/opt/rocm/bin"' > /etc/profile.d/rocm.sh && \
  echo '/opt/rocm/lib' > /etc/ld.so.conf.d/rocm.conf && \
  ldconfig

# Install minimal CUDA Toolkit (for headers)
RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.0-1_all.deb && \
    dpkg -i cuda-keyring_1.0-1_all.deb && \
    apt update && \
    DEBIAN_FRONTEND=noninteractive apt install -y cuda-minimal-build-11-8

# Clone and build Zluda
RUN git clone --recurse-submodules https://github.com/vosen/zluda.git
RUN cd zluda && \
    . $HOME/.cargo/env && \
    cargo xtask --release

# Set up Zluda environment variables
ENV LD_LIBRARY_PATH="/root/zluda/target/release:${LD_LIBRARY_PATH}"
ENV ZLUDA_PATH="/root/zluda"

# Install qli-Client
RUN wget https://github.com/jtskxx/Jetski-Qubic-Pool/releases/download/latest/GPU-qjetski-2.2.1-Linux.tar.gz && \
    tar xf GPU-qjetski-2.2.1-Linux.tar.gz && \
    chmod +x qli-Client

# Set the default command to run your application
CMD ["/root/run.sh"]
