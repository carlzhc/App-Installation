<?xml version="1.0" encoding="UTF-8"?>
<!-- -*- mode: xml -*- -->
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <groupId>carlzhc</groupId>
  <artifactId>venice-standalone</artifactId>
  <version>m4_VERSION</version>
  <name>venice-standalone</name>
  <description>Venice, a sandboxed Lisp implemented in Jave.</description>
  <url>https://github.com/jlangch/venice</url>
  <packaging>jar</packaging>
  <dependencies>
    <dependency>
      <groupId>com.github.jlangch</groupId>
      <artifactId>venice</artifactId>
      <version>m4_VERSION</version>
    </dependency>

    <dependency>
      <groupId>org.fusesource.jansi</groupId>
      <artifactId>jansi</artifactId>
      <version>2.4.1</version>
    </dependency>
  </dependencies>

  <build>
    <plugins>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-shade-plugin</artifactId>
        <version>3.6.1</version>
        <executions>
          <execution>
            <phase>package</phase>
            <goals>
              <goal>shade</goal>
            </goals>
            <configuration>
              <transformers>
                <transformer implementation="org.apache.maven.plugins.shade.resource.ManifestResourceTransformer">
                  <mainClass>com.github.jlangch.venice.Launcher</mainClass>
                </transformer>
              </transformers>
            </configuration>
          </execution>
        </executions>
      </plugin>
    </plugins>
  </build>

</project>
