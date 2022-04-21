# matlab-repro-logconfig-R2022a

Repro code for Andrew Janke's Matlab R2022a log configuration problem.

The issue is that the logging I do through the SLF4J API doesn't seem to respect the log configuration I set up using the Log4j 2 configuration API. This used to work in R2021b and earlier when I configured things using the Log4j 1 configuration API and then sent log messages through the SLF4J API.

## Usage

To use this repro code, get its Mcode folder on your Matlab path, and then use the `LogConfigReproForR22A` class:

```matlab
repro = LogConfigReproForR22A
repro.doRepro
```

## References

* Matlab Tech Support cases:
  * [Case #05479210](https://servicerequest.mathworks.com/mysr/cp_case_detail1?cc=us&id=5003q00001VFQeM) - R2022a binding SLF4J to log4j 2.x-1.2 bridge
  * TODO: Submit a request specifically about this issue.
* [SLF4M](https://slf4m.janklab.net/) - My Matlab logging framework that uses SLF4J and Log4j
* [List of 3rd-party Java JARs shipped with Matlab](https://docs.google.com/spreadsheets/d/1qL9NVwVhiA_BqX16Gr9-mMKqQ0MEOGxClGA0ms7mji0/edit?usp=sharing)

## Problem Description

I'm trying to configure logging in my Matlab session to use a custom appender format, additional output targets, customized level settings, and so on. This used to work in R2021b and earlier when I configured it using the Log4j 1.x configuration API. R2022a came out and upgraded the Log4j shipped with Matlab to Log4j 2.x. (2.17.1, specifically.) So I migrated my code to use the Log4j 2.x configuration API instead. But it doesn't work: If I then send log messages using the Log4j API directly, they seem to respect my custom configuration. But sending log messages using the SLF4J API seems to get the default log configuration instead.

For example, when I run this repro under R2022a (initial release, no update), I get the following:

```text
>> repro = LogConfigReproForR22A
repro = 
  LogConfigReproForR22A with no properties.
>> repro.doRepro
-----------------------------------------------------------------------------------------------------
MATLAB Version: 9.12.0.1884302 (R2022a)
MATLAB License Number: 40877452
Operating System: Microsoft Windows 10 Pro Version 10.0 (Build 19044)
Java Version: Java 1.8.0_202-b08 with Oracle Corporation Java HotSpot(TM) 64-Bit Server VM mixed mode
-----------------------------------------------------------------------------------------------------
MATLAB                                                Version 9.12        (R2022a)      License 40877452
Database Toolbox                                      Version 10.3        (R2022a)      License 40877452
MATLAB Compiler                                       Version 8.4         (R2022a)      License 40877452
MATLAB Compiler SDK                                   Version 7.0         (R2022a)      License 40877452
Mapping Toolbox                                       Version 5.3         (R2022a)      License 40877452
Optimization Toolbox                                  Version 9.3         (R2022a)      License 40877452
Parallel Computing Toolbox                            Version 7.6         (R2022a)      License 40877452
Spreadsheet Link                                      Version 3.4.7       (R2022a)      License 40877452
Statistics and Machine Learning Toolbox               Version 12.3        (R2022a)      License 40877452


My hand-built LogConfiguration:
BuiltConfiguration: org.apache.logging.log4j.core.config.builder.impl.BuiltConfiguration, configurationSource=NULL_SOURCE
Loggers:
  <root>: level=INFO additive=1
      AppenderRefs: stdout
Appenders:
  stdout: stdout

Log configuration after reconfigure():

Logger config state:
BuiltConfiguration: org.apache.logging.log4j.core.config.builder.impl.BuiltConfiguration, configurationSource=NULL_SOURCE
Loggers:
  <root>: level=INFO additive=1
      AppenderRefs: stdout
Appenders:
  stdout: stdout

Logger state:
Root (): INFO


Here's hello using Log4j 2.x directly:

configged log4j: 08:51:07.134 OFF   blah [] - Hello! (level OFF)
configged log4j: 08:51:07.149 FATAL blah [] - Hello! (level FATAL)
configged log4j: 08:51:07.165 ERROR blah [] - Hello! (level ERROR)
configged log4j: 08:51:07.165 WARN  blah [] - Hello! (level WARN)
configged log4j: 08:51:07.181 INFO  blah [] - Hello! (level INFO)

Here's hello using Log4j 1.x directly:

configged log4j: 08:51:07.259 OFF   blah [] - Hello! (level OFF)
configged log4j: 08:51:07.274 FATAL blah [] - Hello! (level FATAL)
configged log4j: 08:51:07.290 ERROR blah [] - Hello! (level ERROR)
configged log4j: 08:51:07.290 WARN  blah [] - Hello! (level WARN)
configged log4j: 08:51:07.306 INFO  blah [] - Hello! (level INFO)

Here's hello using SLF4J:

08:51:07.384 [main] ERROR blah - Hello! (level ERROR)


>> 
```

I expected the log output from SLF4J logging to respect the same configuration that the direct Log4j logging does.

I have no theory as to what's going on here.

### Workarounds

A workaround for this would be to do our logging from M-code to the Log4j API directly, instead of using SLF4J. I'd rather not do this, for a couple reasons:

1. SLF4J provides support for placeholder substitution in messages, and Log4j does not. This feature is exposed in our Matlab logging. Ditching it could require extensive changes to our code.
2. Other Java libraries (including some shipped with Matlab and used by standard Matlab functions) may be logging through SLF4J, and I'd like to be able to capture and control that logging activity too.

## Author

Andrew Janke <andrew@apjanke.net>.
