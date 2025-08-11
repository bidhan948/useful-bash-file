#!/bin/bash

# Set JMETER version (check for latest here: https://jmeter.apache.org/download_jmeter.cgi)
JMETER_VERSION="5.6.3"
JMETER_URL="https://downloads.apache.org//jmeter/binaries/apache-jmeter-$JMETER_VERSION.tgz"

# Change to desired directory, e.g., /opt or $HOME
cd $HOME

echo "Downloading JMeter $JMETER_VERSION..."
wget "$JMETER_URL" -O "apache-jmeter-$JMETER_VERSION.tgz"

echo "Extracting..."
tar -xzf "apache-jmeter-$JMETER_VERSION.tgz"

echo "Cleaning up..."
rm "apache-jmeter-$JMETER_VERSION.tgz"

echo "JMeter $JMETER_VERSION downloaded and extracted to $HOME/apache-jmeter-$JMETER_VERSION/"
echo "To run JMeter GUI:"
echo "  cd \$HOME/apache-jmeter-$JMETER_VERSION/bin && ./jmeter"

echo "To run JMeter CLI:"
echo "  cd \$HOME/apache-jmeter-$JMETER_VERSION/bin && ./jmeter -n -t your_test_plan.jmx -l results.jtl"
