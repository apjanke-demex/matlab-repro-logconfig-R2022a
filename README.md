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

Matlab Tech Support cases:

* Case #05479210 - 	R2022a binding SLF4J to log4j 2.x-1.2 bridge
* TODO: Submit a request specifically about this issue.

## Author

Andrew Janke <andrew@apjanke.net>.
