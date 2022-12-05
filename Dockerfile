FROM openjdk:8-jdk-alpine

ENV PORT 8081

ADD target/jlsj.jar /JrebelBrains.jar
CMD java -jar /JrebelBrains.jar -p $PORT

