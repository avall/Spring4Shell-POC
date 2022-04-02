# Pin our tomcat version to something that has not been updated to remove the vulnerability
# https://hub.docker.com/layers/tomcat/library/tomcat/9.0.59-jdk11/images/sha256-383a062a98c70924fb1b1da391a054021b6448f0aa48860ae02f786aa5d4e2ad?context=explore
#FROM lunasec/tomcat-9.0.59-jdk11

#ADD src/ /helloworld/src
#ADD pom.xml /helloworld

#  Build spring app
#RUN apt update && apt install maven -y
#WORKDIR /helloworld/
#RUN mvn clean package

#  Deploy to tomcat
#RUN mv target/helloworld.war /usr/local/tomcat/webapps/

#EXPOSE 8080
#CMD ["catalina.sh", "run"]



FROM adoptopenjdk/openjdk11:jdk-11.0.10_9-slim as compiler
LABEL stage=compiler
WORKDIR workdir

COPY . .
RUN ./mvnw package

# build
FROM adoptopenjdk:11-jre-hotspot as builder
LABEL stage=builder
WORKDIR application

COPY --from=compiler workdir/main/target/application.jar ./
RUN java -Djarmode=layertools -jar application.jar extract

# image
FROM adoptopenjdk:11-jre-hotspot
WORKDIR application

COPY --from=builder application/dependencies/ ./
COPY --from=builder application/spring-boot-loader/ ./
COPY --from=builder application/snapshot-dependencies/ ./
COPY --from=builder application/application/ ./

RUN cp /opt/java/openjdk/lib/security/cacerts /application/kafka.client.truststore.jks

VOLUME /tmp
EXPOSE 8081
ENTRYPOINT ["java","-Xms256m","-Xmx512m", "org.springframework.boot.loader.JarLauncher"]
