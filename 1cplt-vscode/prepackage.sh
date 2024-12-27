cd ../1cplt-rascal
mvn package -Drascal.compile.skip -Drascal.tutor.skip -DskipTests
cp target/1cplt-rascal*.jar ../1cplt-vscode/assets/jars/1cplt-rascal.jar
