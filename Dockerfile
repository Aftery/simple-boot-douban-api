# ==============================================================================
# 阶段 1: 编译打包 (Build Stage)
# 使用 Java 17 + Maven (Debian 底层)，网络协议栈与证书完整，可精准解析 2.7.13 parent
# ==============================================================================
FROM maven:3.8.8-eclipse-temurin-17 AS builder

WORKDIR /build

# 1. 复制 pom.xml 与源码
COPY pom.xml .
COPY src ./src

# 2. 执行构建 (-U 强制刷新 parent，-e 打印异常，跳过测试)
RUN mvn clean package -DskipTests -U -e

# ==============================================================================
# 阶段 2: 运行环境 (Run Stage)
# 使用轻量级 JRE 8 运行产物，完美匹配你的 <java.version>8</java.version>
# ==============================================================================
FROM eclipse-temurin:8-jre-alpine

WORKDIR /app

# 从打包阶段复制 jar 包
COPY --from=builder /build/target/*.jar app.jar

EXPOSE 8080

# 限制堆内存防止 Render 免费版 512MB OOM 强杀
ENTRYPOINT ["java", "-Xms256m", "-Xmx384m", "-Djava.security.egd=file:/dev/./urandom", "-jar", "app.jar"]
