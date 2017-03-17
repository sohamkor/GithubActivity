# Pull base image.
FROM tomcat

COPY activity.war /usr/local/tomcat/webapps
ENV PATH=$PATH:/usr/local/tomcat/bin:
CMD catalina.sh run
