# Build
FROM fedora:latest AS build-stage

ARG LLAMA_CPP_VERSION_ARG
ENV LLAMA_CPP_VERSION=$LLAMA_CPP_VERSION_ARG
COPY mc.pem /etc/pki/ca-trust/source/anchors/mc.pem
RUN update-ca-trust extract

RUN dnf group install -y c-development
RUN dnf install -y cmake git libcurl-devel

WORKDIR /build
RUN git -c http.sslVerify=false clone https://github.com/ggml-org/whisper.cpp.git

WORKDIR /build/whisper.cpp
# RUN sh ./models/download-ggml-model.sh base.en
RUN cmake -B build -DBUILD_SHARED_LIBS=OFF
RUN cmake --build build -j --config Release
RUN mkdir -p /tmp/whisper-bins && find /build/whisper.cpp -type f -perm '755' -name 'whisper-*' -exec cp {} /tmp/whisper-bins \;
RUN ls -al /usr/lib64/libstdc++*

# Release
FROM rockylinux/rockylinux:10-ubi-micro

# RUN dnf install -y libgomp libcurl dash shasum

COPY --from=build-stage /tmp/whisper-bins/whisper-* /usr/local/bin/
COPY --from=build-stage /usr/lib64/libgomp.so.* /usr/lib64/
COPY --from=build-stage /usr/lib64/libstdc++.so.* /usr/lib64/
COPY init.sh /usr/local/bin/

# ENTRYPOINT ["init.sh"]
CMD ["/usr/local/bin/whisper-server", "--host", "0.0.0.0", "--port", "80"]
