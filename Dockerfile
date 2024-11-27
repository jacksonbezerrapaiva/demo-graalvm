# Use uma imagem base do Ubuntu
FROM ubuntu:22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

# Atualizar pacotes e instalar dependências básicas
RUN apt-get update && \
    apt-get install -y \
    curl \
    unzip \
    zip \
    bash \
    git \
    && rm -rf /var/lib/apt/lists/*

# Instalar SDKMAN!
RUN curl -s "https://get.sdkman.io" | bash -s

# Adicionar SDKMAN! ao bashrc para garantir que ele seja carregado nas futuras instâncias de shell
RUN echo "source /root/.sdkman/bin/sdkman-init.sh" >> /root/.bashrc

# Iniciar o SDKMAN! e instalar o Java 21.0.2-GraalCE
RUN bash -c "source /root/.sdkman/bin/sdkman-init.sh && sdk install java 21.0.2-graalce"

# Instalar Maven
RUN bash -c "source /root/.sdkman/bin/sdkman-init.sh && sdk install maven"

# Definir o ambiente Java
ENV JAVA_HOME=/root/.sdkman/candidates/java/current
ENV PATH=$JAVA_HOME/bin:$PATH

# Verificar as versões instaladas do Java e Maven (com SDKMAN! corretamente inicializado)
RUN bash -c "source /root/.sdkman/bin/sdkman-init.sh && java -version && mvn -version"

# Definir o diretório de trabalho
WORKDIR /app

# Copiar arquivos do projeto para o contêiner
COPY . .

# Verificar versão do Maven e compilar o projeto Spring Boot
RUN bash -c "source /root/.sdkman/bin/sdkman-init.sh && mvn -v"
RUN bash -c "source /root/.sdkman/bin/sdkman-init.sh && mvn spring-boot:build-image -X"

# Listar os arquivos do diretório target após a construção da imagem
RUN ls target

# Estágio 2: Criar imagem final com distroless
FROM gcr.io/distroless/base-debian11

WORKDIR /app

# Copiar o arquivo gerado no estágio de construção
COPY --from=builder /app/target/demo /app/demo

# Definir o ponto de entrada para o aplicativo
ENTRYPOINT ["/app/demo"]