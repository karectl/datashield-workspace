FROM jupyter/datascience-notebook:latest

ARG TARGETARCH
ENV TARGETARCH=$TARGETARCH
USER root

RUN apt-get update -y && apt-get install -y --no-install-recommends \
 gdebi-core \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev

RUN pip install uv
WORKDIR /tmp
COPY pyproject.toml ./
COPY marimo-server-proxy/ ./marimo-server-proxy/
RUN uv pip install --system -r pyproject.toml

# RStudio Server installation
RUN wget -q https://s3.amazonaws.com/rstudio-ide-build/server/jammy/${TARGETARCH}/rstudio-server-2024.09.2-399-${TARGETARCH}.deb \
    && gdebi -n rstudio-server-2024.09.2-399-${TARGETARCH}.deb \
    && rm rstudio-server-2024.09.2-399-${TARGETARCH}.deb \
    && echo server-user=${NB_USER} >> /etc/rstudio/rserver.conf

# Datashield R packages
RUN R -e "install.packages(c('DSI', 'DSOpal', 'dsBaseClient'), repos = 'https://cloud.r-project.org')"

WORKDIR /home/${NB_USER}
USER ${NB_USER}

# Enable Jupyter proxy extensions
RUN jupyter server extension enable --py jupyter_server_proxy --sys-prefix && jupyter server extension enable elyra
