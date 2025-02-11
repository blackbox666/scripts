FROM mcr.microsoft.com/dotnet/runtime:8.0

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    wget \
    xz-utils \
    libncurses6 \
    libtommath1 \
    procps \
    net-tools \
    && rm -rf /var/lib/apt/lists/*

RUN rm -f /usr/lib/x86_64-linux-gnu/libtommath.so.0 && \
    ln -s libtommath.so.1 /usr/lib/x86_64-linux-gnu/libtommath.so.0

RUN mkdir -p /root/moontrader /root/.config/moontrader-data/data && \
    wget -O mt.tar.xz https://cdn3.moontrader.com/beta/linux-x86_64/MoonTrader-linux-x86_64.tar.xz && \
    tar xf mt.tar.xz -C /root/moontrader && \
    rm mt.tar.xz

WORKDIR /root/moontrader
ENTRYPOINT ./MTCore --profile $PROFILE --watchdog-mode