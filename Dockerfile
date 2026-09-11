# ==============================================================================
# 阶段 1: 编译打包 (Build Stage)
# 使用包含 Maven 3.9 + Java 8 的轻量级 Alpine 镜像
# ==============================================================================
FROM maven:3.9.6-eclipse-temurin-8-alpine AS builder

# 设置容器内的工作目录
WORKDIR /build

# 1. 先单独复制 pom.xml（利用 Docker 缓存机制，若依赖未变则跳过下载）
COPY pom.xml .

# 2. 复制源码目录
COPY src ./src


# 将原来的: RUN mvn clean package -DskipTests
# 改为增加 -U (强制更新依赖) 和 --fail-never 或补充参数：
RUN mvn clean package -DskipTests -U -e
# ==============================================================================
# 阶段 2: 运行环境 (Run Stage)
# 只保留运行所需的 JRE 8，极大缩小最终镜像体积（仅 100MB+）
# ==============================================================================
FROM eclipse-temurin:8-jre-alpine

# 设置运行时工作目录
WORKDIR /app

# 从第一阶段 (builder) 的构建产物中，把 target/ 下的 jar 包复制出来并重命名为 app.jar
# 使用 *.jar 通配符，彻底避免因版本号不匹配导致的 "file not found" 报错
COPY --from=builder /build/target/*.jar app.jar

# 声明容器暴露的端口（Spring Boot 默认端口）
EXPOSE 8085

# 启动命令：
# -Xms256m -Xmx384m: 限制堆内存，避免超过 Render 免费版的 512MB 限制
# -Djava.security.egd=file:/dev/./urandom: 加快 Linux 环境下 Tomcat 启动速度
ENTRYPOINT ["java", "-Xms256m", "-Xmx384m", "-Djava.security.egd=file:/dev/./urandom", "-jar", "app.jar"]
