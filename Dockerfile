# Build
FROM fedora:latest AS build-stage

ARG LLAMA_CPP_VERSION_ARG
ENV LLAMA_CPP_VERSION=$LLAMA_CPP_VERSION_ARG

RUN dnf group install -y c-development
RUN dnf install -y cmake git libcurl-devel

WORKDIR /build
RUN git -c http.sslVerify=false clone https://github.com/ggerganov/llama.cpp.git

WORKDIR /build/llama.cpp
RUN git checkout $LLAMA_CPP_VERSION && git branch -v
RUN cmake -B build -DBUILD_SHARED_LIBS=OFF -DLLAMA_CURL=ON
RUN cmake --build build --config Release
RUN mkdir -p /tmp/llama-bins && find /build/llama.cpp -type f -perm '755' -name 'llama-*' -exec cp {} /tmp/llama-bins \;

# Release
FROM fedora:latest

ENV LLAMA_ARG_CTX_SIZE=16384
ENV LLAMA_ARG_N_PARALLEL=4
ENV LLAMA_ARG_ENDPOINT_METRICS=1
ENV LLAMA_ARG_ENDPOINT_SLOTS=1
ENV LLAMA_ARG_HOST=0.0.0.0
ENV LLAMA_ARG_TIMEOUT=900
ENV LLAMA_ARG_THREADS=-1
ENV MODEL_URL=https://huggingface.co/bartowski/Meta-Llama-3.1-8B-Instruct-GGUF/resolve/main/Meta-Llama-3.1-8B-Instruct-Q8_0.gguf
ENV MODEL_SHA256=9da71c45c90a821809821244d4971e5e5dfad7eb091f0b8ff0546392393b6283
ENV LLAMA_ARG_PORT=80

RUN dnf install -y libgomp libcurl dash shasum

COPY --from=build-stage /tmp/llama-bins/llama-server tmp/llama-bins/llama-cli /usr/local/bin/
COPY init.sh /usr/local/bin/

ENTRYPOINT ["init.sh"]

# CMD ["-c", "2048"]
